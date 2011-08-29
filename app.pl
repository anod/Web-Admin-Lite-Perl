#!/usr/bin/env perl
use Mojolicious::Lite;
use POSIX qw(strftime);

get '/' => sub {
    my $self = shift;

	my %cpuinfo = cpuinfo();
	my %meminfo = meminfo();
	my %diskusage = diskusage();
	
	my $mem_total = int(int($meminfo{'MemTotal'}) / 1024);
	my $mem_free = int((int($meminfo{'Cached'}) + int($meminfo{'MemFree'}) + int($meminfo{'Buffers'})) / 1024);
	my $mem_free_perc = int($mem_free * 100 / $mem_total);

	my $swap_total = int(int($meminfo{'SwapTotal'}) / 1024);
	my $swap_free = int(int($meminfo{'SwapFree'}) / 1024);
	my $swap_free_perc = int($swap_free * 100 / $swap_total);

	$self->app->log->debug($self->app->dumper(%diskusage));

	$self->stash(
		timenow => strftime("%a %b %e %H:%M:%S %Y", localtime),
		kernel => qx(uname -r),
		hostname => qx(hostname),
		uptime => strftime( "%H:%M:%S", uptime(), 0,0,0,0,0),
		
		cpu_vendor => $cpuinfo{'vendor_id'},
		cpu_count => $cpuinfo{'cpu cores'},
		cpu_model => $cpuinfo{'model name'},
		cpu_speed => $cpuinfo{'cpu MHz'},
		cpu_l2_cache => $cpuinfo{'cache size'},
		
		mem_total => $mem_total,
		mem_free => $mem_free,
		mem_free_perc => $mem_free_perc,
		
		swap_total => $swap_total,
		swap_free => $swap_free,
		swap_free_perc => $swap_free_perc,
		
		disk_total => $diskusage{'TotalAvail'},
		disk_free => $diskusage{'TotalFree'},
	);
	
	
} => 'sysinfo';

get '/terminal' => 'terminal';

get '/terminal/execute' => sub {
    my $self = shift;
    my $cmd = $self->param('cmd');
    $self->render(text => `$cmd` );
};

get '/users' => sub {
    my $self = shift;
    open(PASSWD, "<", "/etc/passwd") or die "cannot read users: $!";
	$self->stash(
		users => [
			map { [ split /:/ ] } <PASSWD>
		]
	);
	close PASSWD;
} => 'users';

get '/users/add' => sub {
    my $self = shift;
   	my $save = $self->param('save');
   	my $name = $self->param('name');
  
  	if ($save && $name) {
  		my $home_dir = $self->param('home_dir');
  		my $group_name = $self->param('group_name');
  		my $shell = $self->param('shell');

  		$self->app->log->debug("Adding user $name group: $group_name home dir: $home_dir shell: $shell");
 		
	    $self->redirect_to('users', 
	    	act => 'add', 
	    	name => \$name, 
	    	result => qx(useradd -d $home_dir -g $group_name -s $shell $name 2>&1)
	    );
	    return;
  	}
	$self->stash(
		name => "",
		group_name => "",
		home_dir => "",
		shell => ""
  	);

} => 'users.mod';

get '/users/edit/:name' => sub {
    my $self = shift;
    my $name = $self->stash('name');
   	my $save = $self->param('save');
   
  	if ($save && $name) {
  		my $home_dir = $self->param('home_dir');
  		my $group_name = $self->param('group_name');
  		my $shell = $self->param('shell');
  		$self->app->log->debug("Saving user $name group: $group_name home dir: $home_dir shell: $shell");
 		
	    $self->redirect_to('users',
	    	act => 'edit', 
	    	name => \$name, 
	    	result => qx(usermod -d $home_dir -g $group_name -s $shell $name 2>&1)
	    );
	    return;
  	}
    open(PASSWD, "<", "/etc/passwd") or die "cannot read users: $!";
	my @user = map { split /:/ } grep /^$name:/,  <PASSWD>;
	close PASSWD;
	
	my ($name_real, $x, $uid, $gid, $description, $home, $shell) = @user;

	$self->app->log->debug($self->dumper($shell));

	my $group_name = getgrgid($gid);

	$self->stash(
		name => $name_real,
		group_name => $group_name,
		home_dir => $home,
		shell => $shell
  	);
} => 'users.mod';

get '/users/del/:name' => sub {
    my $self = shift;
    my $name = $self->stash('name');
  	if ($name) {
  		my $result=qx(userdel $name 2>&1);
  		$self->app->log->debug("Deleting user $name - $result");
 		
	    $self->redirect_to('users',
	    	act => 'del', 
	    	name => $name, 
	    	result => $result
	    );
	    return;
  	}
    $self->redirect_to('users');
};

get '/tasks' => sub {
    my $self = shift;
	
	$self->stash(
		loadavg => loadavg(),
		tasks => [
			map { [ split /\s+/ ] }
			split /\n/, qx(ps axh -o comm,stat,\%cpu,nice,pid,rss,user)
		]
	);

} => 'tasks';

get '/tasks/kill' => sub {
    my $self = shift;
	my $pid = $self->param('pid');
    $self->redirect_to('tasks', killed => qx(kill $pid 2>&1));
};

get '/backup' => sub {
    my $self = shift;

} => 'backup';


app->start;


# Read the uptime.
sub uptime {
	# Read the uptime in seconds from /proc/uptime, skip the idle time...
	open FILE, "< /proc/uptime" or die return ("Cannot open /proc/uptime: $!");
		my ($uptime, undef) = split / /, <FILE>;
	close FILE;
	return ($uptime);
}

# Read the load average.
sub loadavg {
	# Read the values from /proc/loadavg and put them in an array.
	open FILE, "< /proc/loadavg" or die return ("Cannot open /proc/loadavg: $!");
		my ($avg1, $avg5, $avg15, undef, undef) = split / /, <FILE>;
		my @loadavg = ($avg1, $avg5, $avg15);
	close FILE;
	return (@loadavg);
}

sub cpuinfo {
	open FILE, "< /proc/cpuinfo" or die return ("Cannot open /proc/cpuinfo: $!");
	my %cpuinfo;
	while (<FILE>)
	{
   		chomp;
   		my ($key, $val) = split /:/;
   		$key =~ s/^\s+//;
		$key =~ s/\s+$//;
   		$val =~ s/^\s+//;
		$val =~ s/\s+$//;
		if ($key ne '') {
	   		$cpuinfo{$key} = $val;
		}
	}
	close FILE;
 
	return (%cpuinfo);
}

sub meminfo {
	open FILE, "< /proc/meminfo" or die return ("Cannot open /proc/meminfo: $!");
	my %cpuinfo;
	while (<FILE>)
	{
   		chomp;
   		my ($key, $val) = split /:/;
   		$key =~ s/^\s+//;
		$key =~ s/\s+$//;
   		$val =~ s/^\s+//;
		$val =~ s/\s+$//;
		if ($key ne '') {
	   		$cpuinfo{$key} = $val;
		}
	}
	close FILE;
 
	return (%cpuinfo);
}

sub diskusage {
	my @info = map { split /\s+/ } grep /^total/, qx(df -kPh --total);
	my %diskusage;
	$diskusage{'TotalAvail'} = $info[1];
	$diskusage{'TotalFree'} = $info[3];
	return (%diskusage);
}
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

	#$self->app->log->debug($self->app->dumper(%diskusage));

	$self->stash(
		ostype => qx(uname -o),
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
		disk_free_perc => int($diskusage{'TotalFree'} * 100 / $diskusage{'TotalAvail'}),
	);
	
	
} => 'sysinfo';

get '/time/update' => sub {
	#date --set="2 OCT 2006 18:00:00"
};

get '/terminal' => sub {
    my $self = shift;
	
	opendir(DIR, "commands");
	my @commands= readdir(DIR); 
	closedir(DIR);
	
	$self->stash(
		commands => [
			map { (my $s = $_) =~ s/\.pl$//; $s } grep { /\.pl$/ } @commands
		]
	);


} => 'terminal';

any '/terminal/execute' => sub {
    my $self = shift;
    my $cmd = $self->param('cmd');
    my $response = '';
	if ($cmd ne '') {
		$cmd =~ /([^\s]+)(.*)/;

		my $custom = "commands/$1.pl";
		my $params = $2;
		$self->app->log->debug("Check for custom command: '$custom'");
		if (-e $custom) {
			$self->app->log->debug("Executing custom command: '$custom $params'");
	    	$response = qx(perl $custom $params 2>&1);	
		} else {
			$self->app->log->debug("Fallback to built-in command: '$cmd'");
	    	$response = qx($cmd 2>&1);	
		}
	}

	$self->app->log->debug("Response: $response");
	
	$self->render(text =>  $response);	
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
 	$self->stash(act=> 'add', name => "", group_name => "", home_dir => "", shell => "");

} => 'users.mod';

get '/users/edit/:name' => sub {
    my $self = shift;
    my $name = $self->stash('name');
	my @user = user_info($name);
	my ($name_real, $x, $uid, $gid, $description, $home, $shell) = @user;

#	$self->app->log->debug($self->dumper($shell));

	my $group_name = getgrgid($gid);

	$self->stash(
		act => 'edit',
		name => $name_real,
		group_name => $group_name,
		home_dir => $home,
		shell => $shell
  	);
} => 'users.mod';


post '/users/save' => sub {
    my $self = shift;
    my $name = $self->param('name');
    my $act = $self->param('act');
	my $home_dir = $self->param('home_dir');
  	my $group_name = $self->param('group_name');
  	my $shell = $self->param('shell');
  	
  	$self->app->log->debug("Saving user $name group: $group_name home dir: $home_dir shell: $shell");
 		
	my $url = $self->url_for("users");
	
	my $result = ($act eq 'add') ? 
		qx(useradd -d $home_dir -g $group_name -s $shell $name 2>&1)
		:	
		qx(usermod -d $home_dir -g $group_name -s $shell $name 2>&1)
	;
	
	$self->redirect_to($url->query(
	   	act => $act, 
	   	name => $name, 
	   	result => $result
	));
};

get '/users/del/:name' => sub {
    my $self = shift;
    my $name = $self->stash('name');
  	if ($name) {
  		my $result=qx(userdel $name 2>&1);
  		$self->app->log->debug("Deleting user $name - $result");
 		
		my $url = $self->url_for("users");
		$self->redirect_to($url->query(
			act => 'del', 
	    	name => $name, 
	    	result => $result
		));

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

	my $url = $self->url_for("tasks");
	$self->redirect_to($url->query(
		killed => qx(kill $pid 2>&1)
	));
};

get '/backup/(:action)' => sub {
    my $self = shift;
	$self->redirect_to('backup');
};

get '/backup' => sub {
    my $self = shift;
    my $backup_dir = $self->param('dir');
    if ($backup_dir eq '') {
		my @user = user_info(getlogin());
		my ($name_real, $x, $uid, $gid, $description, $home, $shell) = @user;
		$backup_dir = $home.'/for_backup';
    }
	
	$self->stash(
		backup_dir => $backup_dir
	);
} => 'backup';

post '/backup/create' => sub {
    my $self = shift;
	my $backup_file = $self->param('backup_folder') || '';
	my $result = '';
	
	$self->app->log->debug("Create a backup for file: $backup_file ...");
	
	my $exitcode = 255;
	if ($backup_file eq '') {
		$result = 'Backup file cannot be empty';	
	} else {
		$result = qx(tar cpzf /tmp/last.tgz $backup_file 2>&1);
		$exitcode = $? >> 8;
	}
	$self->app->log->debug("Exit code: $exitcode");
	$self->app->log->debug("Result: $result");
    if ($exitcode == 0) { 
	 	use Mojolicious::Static; 
	    my $static = Mojolicious::Static->new();
  		$self->res->headers->content_disposition(qq|attatchment; filename="backup.tgz"|);
  		$static->serve($self, '/tmp/last.tgz'); 
  		$self->rendered;
    } else {
		my $url = $self->url_for("/backup");
		$self->redirect_to($url->query(result => $result, dir => $backup_file));
    }
};

post '/backup/restore' => sub {
    my $self = shift;
	my $url = $self->url_for("/backup");
 	if (my $upload = $self->req->upload('restore_file')) {
	    my $name = $upload->filename;
	    $upload->move_to("/tmp/$name");
	    
		$self->app->log->debug("Restoring backup from file: $name ...");
		my $result = qx(tar xpfz '/tmp/$name' -C / 2>&1);
		my $exitcode = $? >> 8;
		if ($exitcode == 0) {
			$result = "File $name restored succesfully";
		}
		$self->app->log->debug("Result: $result");
		$self->redirect_to($url->query(result => $result));
    } else {
		$self->redirect_to($url->query(result => "Problem uploading file."));
    }
};

get '/search/:reqcmd' => [reqcmd => ['find', 'grep']] => sub {
    my $self = shift;
	my $search_params = $self->session->{search};
	my $reqcmd  = $self->param('reqcmd');
	
	$self->app->log->debug($self->app->dumper(${$search_params}{'find_path'}));
	
	if ( ${$search_params}{'cmd'} eq $reqcmd) {
		for my $key (keys %{$search_params}) {
			my $value =  ${$search_params}{$key};
			$self->param($key, $value);	
		}
	}	
	
	$self->stash(
		find_path => ${$search_params}{'find_path'} || qx(pwd)
	);	
	$self->render('search.'.$reqcmd);
};

get '/search/help/:cmd' => sub {
    my $self = shift;
    my $opt = $self->param('opt') || '';
    my $cmd = $self->param('cmd');
    my $response = '';
    
    if ($cmd eq 'find' || $cmd eq 'grep') {
		if ($opt ne '') {
    		$response = man_opts($cmd,$opt);
	    	$response =~ s/\n/<br\/>/g;
    	}
    }
	$self->render(text => $response || 'No info found');	
};

post '/search/result' => sub {
    my $self = shift;
	my $cmd = $self->param('cmd') || '';
	my $result = '';
	$self->app->log->debug("Search Command: '$cmd'");
	
	my $params = params_to_hash($self);
	
	$self->session({search => $params});
	
	if ($cmd eq 'find') {
		$result = run_find($params);
 	} elsif ($cmd eq 'grep') {
		$result = run_grep($params);
	}

	app->log->debug("result: ".$result);

	$self->stash(
		result => $result
	);
} => 'search.result';

app->secret('kesT4dU4');
app->start('daemon');

######################
# HELP FUNCTIONS
######################

# convert get parameters ot hash
sub params_to_hash {
	my ($c) = @_;
	my @names = $c->param;
	my %params = ();
	for my $key (@names) { 
		$params{$key} = $c->param($key);
	}
	return \%params;
}

# exec find accroding to provided params 
sub run_find() {
	my $params = shift;
	my @fargs = ();
	my @name_args = qw(empty executable readable writable delete);
	my @map_args =  qw(path regex amin cmin mmin uname group perm size inum maxdepth mindepth exec);

	my $find_path = ${$params}{'find_path'};
	if ($find_path eq '') {
		return 'Find path is required';
	}
	
    push(@fargs, "-".${$params}{'follow_sym_links'});
    push(@fargs, $find_path);
    	
	for my $elem (@name_args) {
		if (exists(${$params}{$elem}) && ${$params}{$elem} ne '') {
			push(@fargs, "-".$elem);
		}
    }

	if (exists(${$params}{'type'}) && ${$params}{'type'} ne '') {
		push(@fargs, "-type ".${$params}{'type'});
	}
	if (exists(${$params}{'size'}) && ${$params}{'size'} ne '') {
		push(@fargs, "-size ".${$params}{'size'}.${$params}{'size_type'});
	}
    
	if (exists(${$params}{'name'}) && ${$params}{'name'} ne '') {
		#check for case insensetive flag
		if (exists(${$params}{'iname'}) && ${$params}{'iname'} ne '') {
			push(@fargs, "-iname ".${$params}{'name'});
		} else {
			push(@fargs, "-name ".${$params}{'name'});
		}
	}    

 	for my $elem (@map_args) {
		if (exists(${$params}{$elem}) && ${$params}{$elem} ne '') {
			push(@fargs, "-".$elem." ".${$params}{$elem});
		}
    }

    my $find = "find ".join(' ',@fargs);
    app->log->debug("`$find`"); 

	#TODO escape args
    return $find."\n\n".qx($find);
}

# exec grep accroding to provided params 
sub run_grep() {
	my $params = shift;
	my @gargs = ();
	my @name_args = qw(i v r b n c);

	my $pattern = ${$params}{'pattern'};
	if ($pattern eq '') {
		return 'pattern is required';
	}

	my $path = ${$params}{'path'};
	if ($path eq '') {
		return 'path is required';
	}
    	
	for my $elem (@name_args) {
		if (exists(${$params}{$elem}) && ${$params}{$elem} ne '') {
			push(@gargs, "-".$elem);
		}
    }

    push(@gargs, $pattern);
    push(@gargs, $path);
    
    my $grep = "grep ".join(' ',@gargs);
    app->log->debug("`$grep`"); 

	#TODO escape args
    return $grep."\n\n".qx($grep);
}

# user info by name
sub user_info {
	my ($name) = @_;
    open(PASSWD, "<", "/etc/passwd") or die "cannot read users: $!";
	my @user = map { split /:/ } grep /^$name:/,  <PASSWD>;
	close PASSWD;
	return (@user);
}

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

# retrieve information about CPU
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

# retrieve memory information
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

# retrieve disk usage information
sub diskusage {
	my @info = map { split /\s+/ } grep /^total/, qx(df -kPh --total);
	my %diskusage;
	$diskusage{'TotalAvail'} = $info[1];
	$diskusage{'TotalFree'} = $info[3];
	return (%diskusage);
}

sub man_opts {
	my ($func,$option) = @_;
	
	my $result = qx(man -7 --nh --nj $func);

#	if ($result =~ /(\s\s\s+)\Q$option\E\b([^\n]+)\n([^\n]+)$/m) {
#		return $2.$3;
#	} else {
#		return "Option not matched";
#	}

	my $info='';
	my $spaces;
	my $inside = 0;
	foreach my $line (split("\n", $result)) {
		if (!$inside) {
    		if ($line =~ /^(\s*)\Q$option\E\b/p) {
        		# start of this option
        		$spaces = $1;
        		$inside = 1;
        		$line =~ s/^\s+//;
        		$info.=$line."\n";
    		}
		}else {
	    	if ($line =~ /^$spaces\S/) {
	        	# start of next option;
	        	return $info;
	    	}
	    	elsif ($line =~ /^\S/) {
	        	# start of next section
	        	return $info;
	    	}
	    	else {
        		$line =~ s/^\s+//;
	        	$info.=$line."\n";
	    	}
		}
	}
	return $info;
}

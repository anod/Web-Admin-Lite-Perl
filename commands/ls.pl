#!/usr/bin/env perl

use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use File::stat;
use Fcntl ':mode';

my $all = 0;
my $long = 0;
my $help = 0;

GetOptions(
	'help|?' => \$help,
	'all|a' => \$all,
	'l' => \$long,
	
) or pod2usage(2);

pod2usage(1) if $help;

cmd_ls($all,$long);

sub cmd_ls
{
	my ($all,$long) = @_;
	my $pattern= '*';
	
	$dir=$ENV{PWD};
	opendir( DIR, $dir) || return ();
	my @files= sort grep { /^$pattern$/ } readdir(DIR);
	closedir( DIR);
	
	@files =  grep(/^[^\.].*/,@files) if !$all;

	print 'total '.total_blocks(@files)."\n";

	@files = map { long_format($_) } @files;
	
	
	$delim = $long ? "\n" : " ";
	print_list($delim, @files);
	print "\n";
	return ();
}

sub total_blocks() 
{
	my (@files) = @_;
	my $blocks = 0;
	for my $filename (@files) {
		my $sb = stat($filename);
		$blocks+=$sb->blksize;
	}
	return $blocks / 1024;
}

sub long_format() 
{
	my ($filename) = @_;
	my $sb = stat($filename);
	my $name  = getpwuid($sb->uid);
	my $group  = getgrgid($sb->gid);
	my $time = scalar localtime $sb->mtime;
	my $mode = mode_string($sb->mode); 	
    return sprintf "%s %d %s %s %s %s %s",
           $mode, $sb->nlink, $name, $group, $sb->size, $time, $filename;
}

sub mode_string()
{
  my ($mode) = @_; 
  my $str = ftypelet($mode);
  $str.=rwx(($mode & 0700) << 0);
  $str.=rwx(($mode & 0070) << 3);
  $str.=rwx(($mode & 0007) << 6);

}

sub ftypelet()
{
  my ($mode) = @_;
  return 'b' if S_ISBLK($mode); #block special files
  return 'c' if S_ISCHR($mode); #character special files
  return 'd' if S_ISDIR($mode); #directories
  return '-' if S_ISREG($mode); #regular files
  return 'p' if S_ISFIFO($mode);#fifos
  return 'l' if S_ISLNK($mode); #symbolic links
  return 's' if S_ISSOCK($mode);#sockets
  return '?';
}

sub rwx() {
	my ($bits) = @_;
	my $str = "";
	$str.= ($bits & S_IRUSR) ? 'r' : '-';
	$str.= ($bits & S_IWUSR) ? 'w' : '-';
  	$str.= ($bits & S_IXUSR) ? 'x' : '-';
	return $str;
}


sub print_list
{

	my ($delim,@list)= @_;

    return unless @list;
    my ($lines, $columns, $mark, $index);

    ## find width of widest entry
    my $maxwidth = 0;
	my $screen_width=$ENV{COLUMNS};

	if (ref $list[0] and ref $list[0] eq 'ARRAY') {
		$maxwidth= $list[1];
		@list= @{$list[0]};
	}

	unless ($maxwidth) {
		grep(length > $maxwidth && ($maxwidth = length), @list);
	}
	$maxwidth++;

	$columns = $maxwidth >= $screen_width?1:int($screen_width / $maxwidth);

    ## if there's enough margin to interspurse among the columns, do so.
    $maxwidth += int(($screen_width % $maxwidth) / $columns);

    $lines = int((@list + $columns - 1) / $columns);
    $columns-- while ((($lines * $columns) - @list + 1) > $lines);

    $mark = $#list - $lines;
    for (my $l = 0; $l < $lines; $l++) {
        for ($index = $l; $index <= $mark; $index += $lines) {
			my $tmp= my $item= $list[$index];
			$tmp=~ s/\001(.*?)\002//g;
			$item=~s/\001//g;
			$item=~s/\002//g;
			my $diff= length($item)-length($tmp);
			my $dispsize= $maxwidth+$diff;
            print sprintf("%-${dispsize}s", $item);
        }
		if ($index<=$#list) {
			my $item= $list[$index];
			$item=~s/\001//g; $item=~s/\002//g;
			print "$item";
		}
        print $delim;
    }
}

__END__

=head1 NAME

ls - list directory contents

=head1 SYNOPSIS

ls.pl [options] [file ...]

Options: 
	
=over 8

=item B<-a, --all>

do not ignore entries starting with .

=item B<-d, --directory>

list directory entries instead of contents, and do not dereference symbolic links

=item B<-l>

use a long listing format
   
=item B<-s, --size>

print the allocated size of each file, in blocks
         
=item B<-t>

sort by modification time

=back

=head1 DESCRIPTION

B<This program> list directory contents

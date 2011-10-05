#!/usr/bin/env perl
#
#  PROGRAM: mv

use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use File::stat;
use POSIX qw(ceil);
use Fcntl ':mode';

my $opt_force = 0;
my $opt_target_dircetory = '';
my $opt_no_target_dircetory = 0;
my $opt_update = 0;

GetOptions(
	'help|?' => \$opt_help,
	'f|force' => \$opt_force,
	't|target-directory=s' => \$opt_target_dircetory,
	'T|no-target-dircetory' => \$opt_no_target_dircetory,
	'u|update' => \$opt_update,
) or pod2usage(2);

pod2usage(1) if $opt_help;

$count = @ARGV;

pod2usage(1) if ($count < 2);


cmd_mv(
	$opt_force,$opt_target_dircetory,$opt_no_target_dircetory,$opt_update,
	@ARGV
);


sub cmd_mv
{
	my ($opt_force,$opt_target_dircetory,$opt_no_target_dircetory,$opt_update, @files) = @_;
	my ($from,$to);
	
	if ($opt_target_dircetory) { #move all sources to directory
		$to = $opt_target_dircetory;
		if (! -d $to) {
			print "Target print not a directory.\n";
			return;
		}
		while(@files) {
			$from=shift(@files);
			move($opt_force,$from,"$to/$from");
		}
		return;
	}
	
	$to = pop @files;
	
	if (!$opt_no_target_dircetory && -d $to) {
		while(@files) {
			$from=shift(@files);
			move($opt_force,$from,"$to/$from");
		}
		return;		
	}
	
	$count = @files;
	if ($count > 1) {
		print "Too many arguments\n";
		return;	
	}

	$from = shift(@files);
	if ($opt_no_target_dircetory || ! -d $to) {
		move($opt_force, $from, $to);		
	} else {
		move($opt_force, $from, "$to/$from");		
	}
}

sub move {
    my($force, $from, $to) = @_;
    
    if ($force) {
    	unlink	$to;
    };
    
	if (! rename $from, $to) {
		print "Cannot move $from to $to\n"
	};
}

__END__

=head1 NAME

mv -  move (rename) files

=head1 SYNOPSIS

mv.pl [OPTION]... [-T] SOURCE DEST
mv.pl [OPTION]... SOURCE... DIRECTORY
mv.pl [OPTION]... -t DIRECTORY SOURCE...

Options: 
	
=over 8

=item B<-f, --force>

do not prompt before overwriting

=item B<-t, --target-directory=DIRECTORY>

move all SOURCE arguments into DIRECTORY
   
=item B<-T, --no-target-directory>

treat DEST as a normal file

=item B<-u, --update>

move only when the SOURCE file is newer than the destination file or when the destination file is missing

=back

=head1 DESCRIPTION

Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY.

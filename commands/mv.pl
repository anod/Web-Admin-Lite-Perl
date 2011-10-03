#!/usr/bin/env perl
#
#  PROGRAM: mv

use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use File::stat;
use POSIX qw(ceil);
use Fcntl ':mode';

my $opt_force = 0;
my $opt_target_dircetory = 0;
my $opt_no_target_dircetory = 0;
my $opt_update = 0;

GetOptions(
	'help|?' => \$opt_help,
	'f|force' => \$opt_force,
	't|target-directory' => \$opt_target_dircetory,
	'T|no-target-dircetory' => \$opt_no_target_dircetory,
	'u|update' => \$opt_update,
) or pod2usage(2);

pod2usage(1) if $opt_help;

my @files = @ARGV;

pod2usage(1) if !@files;

cmd_mv($opt_force,$opt_target_dircetory,$opt_no_target_dircetory,$opt_update);


sub cmd_mv
{
	my ($opt_force,$opt_target_dircetory,$opt_no_target_dircetory,$opt_update) = @_;
	
	
}

sub move {
    my($from,$to) = @_;
    my($copied,$fromsz,$tosz1,$tomt1,$tosz2,$tomt2,$sts,$ossts);

    if (-d $to && ! -d $from) {
		$to = _catname($from, $to);
    }

    ($tosz1,$tomt1) = (stat($to))[7,9];
    $fromsz = -s $from;

    return 1 if rename $from, $to;

    ($sts,$ossts) = ($! + 0, $^E + 0);
    # Did rename return an error even though it succeeded, because $to
    # is on a remote NFS file system, and NFS lost the server's ack?
    return 1 if defined($fromsz) && !-e $from &&           # $from disappeared
                (($tosz2,$tomt2) = (stat($to))[7,9]) &&    # $to's there
                ($tosz1 != $tosz2 or $tomt1 != $tomt2) &&  #   and changed
                $tosz2 == $fromsz;                         # it's all there

    ($tosz1,$tomt1) = (stat($to))[7,9];  # just in case rename did something
    return 1 if ($copied = copy($from,$to)) && unlink($from);

    ($tosz2,$tomt2) = ((stat($to))[7,9],0,0) if defined $tomt1;
    unlink($to) if !defined($tomt1) or $tomt1 != $tomt2 or $tosz1 != $tosz2;
    ($!,$^E) = ($sts,$ossts);
    return 0;
}

sub _catname {
    my($from, $to) = @_;
    if (not defined &basename) {
		require File::Basename;
		import  File::Basename 'basename';
    }

    return File::Spec->catfile($to, basename($from));
}


sub print_wc
{
 	my ($fname, $lines, $words, $chars)=@_;
 
	($lines ne "")  && printf("% 8d", $lines);
 	($words ne "") && printf("% 8d", $words);
 	($chars ne "") && printf("% 8d", $chars);
 	($fname ne "-") ? print " $fname" : print " total";
 	print "\n";
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

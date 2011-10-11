#!/usr/bin/env perl
#
#  PROGRAM: tail

use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use File::stat;
use POSIX qw(ceil);
use Fcntl ':mode';

my $opt_lines = 10;
my $opt_verbose = 0;

GetOptions(
	'help|?' => \$opt_help,
	'n|lines:i' => \$opt_lines,
	'v|verbose' => \$opt_verbose
) or pod2usage(2);

pod2usage(1) if $opt_help;

$count=@ARGV;

pod2usage(1) if $count < 1;
	
cmd_tail($opt_lines,$opt_verbose,@ARGV);

sub cmd_tail
{
	my ($opt_lines,$opt_verbose, @files) = @_;

	$count=@files;
	$opt_verbose = 1 if $count > 1;
	
	while(@files) {
		$from=shift(@files);
		
		open FILE, "<$from" or die "Couldn't open $from: $!";
		seek FILE,-1, 2;  #get past last eol 
		my $count=0;
		
		if ($opt_verbose) {
			print "==> $from <==\n";
		}
		while (1){
		   seek FILE,-1,1;
		   read FILE,$byte,1;
		   if(ord($byte) == 10 ){
		   		$count++;
		   		if($count == $opt_lines){
		   			last
		   		}
		  	}
		   seek FILE,-1,1;
			 if (tell FILE == 0){
			 	last
			}
		}
		$/=undef;
		my $tail = <FILE>;
		print "$tail\n";
		close FILE;
	}
}


__END__

=head1 NAME

tail -  Output the last part of files, print the last part (10 lines by default) of each FILE; 

=head1 SYNOPSIS

tail [options]... [file]....

Options: 
	
=over 8

=item B<-n N, --lines=N>

Output the last N lines.

=item B<-v, --verbose>

Always print file name headers.
If more than one FILE is specified, `tail' prints a one-line header consisting of ==> FILE NAME <== before the output for each FILE. 

=back

=head1 DESCRIPTION

Output the last part of files, print the last part (10 lines by default) of each FILE; 
#!/usr/bin/env perl
#
#  PROGRAM: wc

use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use File::stat;
use POSIX qw(ceil);
use Fcntl ':mode';

my $opt_lines = 0;
my $opt_words = 0;
my $opt_chars = 0;
my $opt_help = 0;

GetOptions(
	'help|?' => \$opt_help,
	'l|lines' => \$opt_lines,
	'w|words' => \$opt_words,
	'm|chars' => \$opt_chars,
) or pod2usage(2);

pod2usage(1) if $opt_help;

my @files = @ARGV;

pod2usage(1) if !@files;

if (!$opt_lines && !$opt_words && !$opt_chars) {
	$opt_lines = $opt_words = $opt_chars = 1;
}

my ($tot_lines, $tot_words, $tot_chars) = 0;

while(@files) {
	my $fname=$files[0];
	
	my ($lines, $words, $chars)=cmd_wc($opt_lines,$opt_words,$opt_chars,$fname);
 	$tot_lines+=$lines;
 	$tot_words+=$words;
 	$tot_chars+=$chars;
	shift(@files);
}

print_wc("-",
	($opt_lines) ? $tot_lines : "",
	($opt_words) ? $tot_words : "",
	($opt_chars) ? $tot_chars : "",
);


sub cmd_wc
{
	my ($opt_lines,$opt_words,$opt_chars,$fname) = @_;
	my $pattern= '*';
	
  	my $lines=0;
 	my $words=0;
 	my $chars=0;
 
 	open(FILE, $fname) || die "Couldn\'t open file $fname";
 	foreach my $line (<FILE>) {
 
 		$chars+=length($line);
 		$line=~/\n$/ and ++$lines;
 
 
 		$line=~s/^[ \t]*//g;
 		$line=~s/[ \t\r\n]*$//g;
 		my @w=split(/[ \t]+/, $line);
 		$words+=@w;
 	}
 
 	close(FILE);
 
	print_wc(
		$fname,
		($opt_lines) ? $lines : "",
		($opt_words) ? $words : "",
		($opt_chars) ? $chars : "",
	);
 	return ($lines, $words, $chars);
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

wc - print newline, word, and byte counts for each file

=head1 SYNOPSIS

wc.pl [options] [file ...]

Options: 
	
=over 8

=item B<-m, --chars>

print the character counts

=item B<-l, --lines>

print the newline counts
   
=item B<-w, --words>

print the word counts

=back

=head1 DESCRIPTION

B<This program> print newline, word, and byte counts for each file

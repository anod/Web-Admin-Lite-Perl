#!/usr/bin/env perl

use Getopt::Long qw(:config auto_help no_ignore_case bundling);
use Pod::Usage;

my $all = 0;
my $long = 0;

GetOptions('all|a' => \$all, 'l' => \$long);

print 'Do not ignore . ' if $all;
print 'Long listing ' if $long;

__END__

=head1 NAME

sample - Using Getopt::Long and Pod::Usage

=head1 SYNOPSIS

sample [options] [file ...]

 Options:
   -help            brief help message
   -man             full documentation
   
=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

#!/usr/bin/env perl

use Getopt::Long qw(:config auto_help no_ignore_case bundling);
use Pod::Usage;

my $all = 0;
my $long = 0;

GetOptions('all|a' => \$all, 'l' => \$long);

#print 'Do not ignore . ' if $all;
#print 'Long listing ' if $long;

cmd_ls();

sub cmd_ls
{
	my $pattern= '*';
	$dir=$ENV{PWD};
	opendir( DIR, $dir) || return ();
	my @files= grep { /^$pattern$/ } readdir(DIR);
	closedir( DIR);
	print_list(sort @files);
	return (1,undef);
}

sub print_list
{
	my @list= @_;
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
        print "\n";
    }
}

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

#!/usr/bin/env perl
#
#  PROGRAM: cat

#  for each arg, open the file and print it
FILE: foreach (@ARGV) {
	open(FILE, $_) || ((warn "Can't open file $_\n"), next FILE);
	while (<FILE>) {
		print;
	}
	close(FILE);
}
#!/usr/bin/perl
use utf8;
use open qw(:std :utf8);

use POSIX;

while( <DATA> ) {
	chomp;
	chomp( my $sys = `date +$_` );
	chomp( my $ppt = `$^X bin/date +$_` );
	my $posix = POSIX::strftime( $_, localtime );

	printf "%s <%10s>  <%20s>  <%20s>  <%20s>\n", ($sys eq $ppt ? '✓' : '✗' ), $_, $sys, $ppt, $posix;
	}


__DATA__
%a
%A
%b
%B
%c
%C
%d
%D
%e
%F
%g
%G
%h
%H
%I
%j
%k
%l
%m
%M
%n
%p
%P
%q
%r
%R
%s
%S
%t
%T
%u
%U
%V
%w
%W
%x
%X
%y
%Y
%z
%Z

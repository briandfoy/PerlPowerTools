#!/usr/bin/perl

# units.t - test for script units

use strict;
use warnings;

use Test::More tests => 28;

use FindBin;

run_tests();

sub run_tests {
    my ( $progname, $argv_ar ) = @_;

    require $FindBin::Bin . '/../bin/units';

    my %got;
    my $rounded;

    my $class = 'PerlPowerTools::units';

    # linear dimension tests, returning type => 'dimless'

    %got = PerlPowerTools::units::test($class, 'm','m');
    is rnd($got{p}), 1;
    is rnd($got{q}), 1;

    %got = PerlPowerTools::units::test($class, 'm','cm');
    is rnd($got{p}), 0.01;
    is rnd($got{q}), 100;

    %got = PerlPowerTools::units::test($class, 'meters','feet');
    is rnd($got{q}), 3.28084;
    is rnd($got{p}), 0.3048;

    %got = PerlPowerTools::units::test($class, 'cm3','gallons');
    is rnd($got{q}), 0.000264172;
    is rnd($got{p}), 3785.41;

    %got = PerlPowerTools::units::test($class, 'meters/s','furlongs/fortnight');
    is rnd($got{q}), 6012.88;
    is rnd($got{p}), 0.00016631;

    %got = PerlPowerTools::units::test($class, '1|2 in','cm');
    is rnd($got{q}), 1.27;
    is rnd($got{p}), 0.787402;

    %got = PerlPowerTools::units::test($class, 'month','year');
    is rnd($got{q}), rnd(1/12);
    is rnd($got{p}), 12;

    return;
}

sub rnd {
    sprintf '%.6g', $_[0];
}

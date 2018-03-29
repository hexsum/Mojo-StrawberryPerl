#!/usr/bin/perl

package DBI::Test::DBD::CSV::List;

use strict;
use warnings;
use parent "DBI::Test::List";

sub test_cases
{
    my @pm = glob "lib/DBI/Test/Case/DBD/CSV/*.pm";
    s{lib/DBI/Test/Case/DBD/CSV/(\S+)\.pm}{DBD::CSV::$1} for @pm;
    return @pm;
    } # test_cases

1;

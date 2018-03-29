package DBI::Test::Case::DBD::CSV::t11_dsnlist;

use strict;
use warnings;

use parent qw( DBI::Test::DBD::CSV::Case);

use Test::More;
use DBI::Test;
use DBI;

sub supported_variant
{
    my ($self,    $test_case, $cfg_pfx, $test_confs,
	$dsn_pfx, $dsn_cred,  $options) = @_;

    $self->is_test_for_mocked ($test_confs) and return;

    return $self->SUPER::supported_variant ($test_case, $cfg_pfx, $test_confs,
	$dsn_pfx, $dsn_cred, $options);
    } # supported_variant

use vars q{$AUTOLOAD};
sub AUTOLOAD
{
    (my $sub = $AUTOLOAD) =~ s/.*:/DBI::Test::DBD::CSV::Case::/;
    {	no strict "refs";
	$sub->(@_);
	}
    } # AUTOLOAD

sub run_test
{
    my ($self, $dbc) = @_;
    my @DB_CREDS = @$dbc;
    $DB_CREDS[3]->{PrintError} = 0;
    $DB_CREDS[3]->{RaiseError} = 0;
    if ($ENV{DBI_PUREPERL}) {
	eval "use Text::CSV;";
	$@ or $DB_CREDS[3]->{csv_class}  = "Text::CSV"
	}

    defined $ENV{DBI_SQL_NANO} or
	eval "use SQL::Statement;";

    my $dbh = connect_ok (@DB_CREDS,		"Connect with dbi:CSV:");

    ok ($dbh->ping,				"ping");

    # This returns at least ".", "lib", and "t"
    ok (my @dsn = DBI->data_sources ("CSV"),	"data_sources");
    ok (@dsn >= 2,				"more than one");
    ok ($dbh->disconnect,			"disconnect");

    # Try different DSN's
    foreach my $d (qw( . example lib t )) {
	ok (my $dns = Connect ("dbi:CSV:f_dir=$d"), "use $d as f_dir");
	ok ($dbh->disconnect,			"disconnect");
	}

    done_testing ();
    } # run_test

1;

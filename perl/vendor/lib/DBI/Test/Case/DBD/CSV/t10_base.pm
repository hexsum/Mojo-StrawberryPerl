package DBI::Test::Case::DBD::CSV::t10_base;

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

    ok (my $switch = DBI->internal, "DBI->internal");
    is (ref $switch, "DBI::dr", "Driver class");

    # This is a special case. install_driver should not normally be used.
    ok (my $drh = DBI->install_driver ("CSV"), "Install driver");

    is (ref $drh, "DBI::dr", "Driver class installed");

    ok ($drh->{Version}, "Driver version $drh->{Version}");

    my $dbh = connect_ok (@DB_CREDS, "Connect with dbi:CSV:");

    my $csv_version_info = $dbh->csv_versions ();
    ok ($csv_version_info, "csv_versions");
    diag ($csv_version_info);

    done_testing ();
    }

1;

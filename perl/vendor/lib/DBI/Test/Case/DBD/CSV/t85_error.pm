package DBI::Test::Case::DBD::CSV::t85_error;

use strict;
use warnings;

use parent qw( DBI::Test::DBD::CSV::Case );

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

my @tbl_def = (
    [ "id",   "INTEGER",  4, 0 ],
    [ "name", "CHAR",    64, 0 ],
    );

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
    $DB_CREDS[3]->{f_dir} = DbDir ();
    if ($ENV{DBI_PUREPERL}) {
	eval "use Text::CSV;";
	$@ or $DB_CREDS[3]->{csv_class}  = "Text::CSV"
	}

    defined $ENV{DBI_SQL_NANO} or
	eval "use SQL::Statement;";

    my $dbh = connect_ok (@DB_CREDS,	"Connect with dbi:CSV:");

    ok (my $tbl = FindNewTable ($dbh),	"find new test table");

    like (my $def = TableDefinition ($tbl, @tbl_def),
	    qr{^create table $tbl}i,	"table definition");
    do_ok ($dbh, $def,			"create table");
    my $tbl_file = DbFile ($tbl);
    ok (-s $tbl_file,			"file exists");
    ok ($dbh->disconnect,		"disconnect");
    undef $dbh;

    ok (-f $tbl_file,			"file still there");
    open my $fh, ">>", $tbl_file;
    print $fh qq{1, "p0wnd",",""",0\n};	# Very bad content
    close $fh;

    ok ($dbh = connect_ok (@DB_CREDS,	"Connect with dbi:CSV:"));
    {   local $dbh->{PrintError} = 0;
	local $dbh->{RaiseError} = 0;
	my $sth = prepare_ok ($dbh, "select * from $tbl", "prepare");
	is ($sth->execute, undef,	"execute should fail");
	# It is safe to regex on this text, as it is NOT local dependant
	like ($dbh->errstr, qr{\w+ \@ line [0-9?]+ pos [0-9?]+}, "error message");
	};
    do_ok ($dbh, "drop table $tbl",	"drop");
    ok ($dbh->disconnect,		"disconnect");

    done_testing ();
    } # run_test

1;

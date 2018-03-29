package DateTime::TimeZone::Local::Android;
$DateTime::TimeZone::Local::Android::VERSION = '1.98';
use strict;
use warnings;

use Try::Tiny;

use parent 'DateTime::TimeZone::Local';

sub Methods {
    return qw(
        FromEnv
        FromGetProp
        FromDefault
    );
}

sub EnvVars { return 'TZ' }

# https://chromium.googlesource.com/native_client/nacl-bionic/+/upstream/master/libc/tzcode/localtime.c
sub FromGetProp {
    my $name = `getprop persist.sys.timezone`;
    chomp $name;
    my $tz = try {
        local $SIG{__DIE__};
        DateTime::TimeZone->new( name => $name );
    };

    return $tz if $tz;
}

# See the link above. Android always defaults to UTC
sub FromDefault {
    return try {
        local $SIG{__DIE__};
        DateTime::TimeZone->new( name => 'UTC' );
    };
}

1;

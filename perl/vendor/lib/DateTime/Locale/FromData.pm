package DateTime::Locale::FromData;

use strict;
use warnings;

use DateTime::Locale::Util qw( parse_locale_code );
use Params::Validate qw( validate_pos );

our $VERSION = '1.03';

my @FormatLengths;

BEGIN {
    my @methods = qw(
        code
        name
        language
        script
        territory
        variant
        native_name
        native_language
        native_script
        native_territory
        native_variant
        am_pm_abbreviated
        date_format_full
        date_format_long
        date_format_medium
        date_format_short
        time_format_full
        time_format_long
        time_format_medium
        time_format_short
        day_format_abbreviated
        day_format_narrow
        day_format_wide
        day_stand_alone_abbreviated
        day_stand_alone_narrow
        day_stand_alone_wide
        month_format_abbreviated
        month_format_narrow
        month_format_wide
        month_stand_alone_abbreviated
        month_stand_alone_narrow
        month_stand_alone_wide
        quarter_format_abbreviated
        quarter_format_narrow
        quarter_format_wide
        quarter_stand_alone_abbreviated
        quarter_stand_alone_narrow
        quarter_stand_alone_wide
        era_abbreviated
        era_narrow
        era_wide
        default_date_format_length
        default_time_format_length
        first_day_of_week
        version
        glibc_datetime_format
        glibc_date_format
        glibc_date_1_format
        glibc_time_format
        glibc_time_12_format
    );

    for my $meth (@methods) {
        my $sub = sub { $_[0]->{$meth} };
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        *{$meth} = $sub;
    }

    @FormatLengths = qw( short medium long full );

    for my $length (@FormatLengths) {
        my $meth = 'datetime_format_' . $length;
        my $key  = 'computed_' . $meth;

        my $sub = sub {
            my $self = shift;

            return $self->{$key} if exists $self->{$key};

            return $self->{$key} = $self->_make_datetime_format($length);
        };

        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        *{$meth} = $sub;
    }
}

sub new {
    my $class = shift;
    my $data  = shift;

    return bless {
        %{$data},
        default_date_format_length => 'medium',
        default_time_format_length => 'medium',
    }, $class;
}

sub date_format_default {
    return $_[0]->date_format_medium;
}

sub time_format_default {
    return $_[0]->time_format_medium;
}

sub datetime_format {
    return $_[0]->{datetime_format_medium};
}

sub datetime_format_default {
    return $_[0]->datetime_format_medium;
}

sub _make_datetime_format {
    my $self   = shift;
    my $length = shift;

    my $dt_key    = 'datetime_format_' . $length;
    my $date_meth = 'date_format_' . $length;
    my $time_meth = 'time_format_' . $length;

    my $dt_format = $self->{$dt_key};
    $dt_format =~ s/\{0\}/$self->$time_meth/eg;
    $dt_format =~ s/\{1\}/$self->$date_meth/eg;

    return $dt_format;
}

sub set_default_date_format_length {
    my $self = shift;
    my ($l)
        = validate_pos( @_, { regex => qr/^(?:full|long|medium|short)$/i } );

    $self->{default_date_format_length} = lc $l;
}

sub set_default_time_format_length {
    my $self = shift;
    my ($l)
        = validate_pos( @_, { regex => qr/^(?:full|long|medium|short)/i } );

    $self->{default_time_format_length} = lc $l;
}

sub date_formats {
    my %formats;
    for my $length (@FormatLengths) {
        my $meth = 'date_format_' . $length;
        $formats{$length} = $_[0]->$meth;
    }
    return \%formats;
}

sub time_formats {
    my %formats;
    for my $length (@FormatLengths) {
        my $meth = 'time_format_' . $length;
        $formats{$length} = $_[0]->$meth;
    }
    return \%formats;
}

sub available_formats {
    my $self = shift;

    $self->{computed_available_formats}
        ||= [ sort keys %{ $self->_available_formats } ];

    return @{ $self->{computed_available_formats} };
}

sub format_for {
    my $self = shift;
    my $for  = shift;

    return $self->_available_formats->{$for};
}

sub _available_formats { $_[0]->{available_formats} }

sub prefers_24_hour_time {
    my $self = shift;

    return $self->{prefers_24_hour_time}
        if exists $self->{prefers_24_hour_time};

    $self->{prefers_24_hour_time} = $self->time_format_short =~ /h|K/ ? 0 : 1;
}

sub language_code {
    my $self = shift;
    return ( $self->{parsed_code} ||= { parse_locale_code( $self->code ) } )
        ->{language};
}

sub script_code {
    my $self = shift;
    return ( $self->{parsed_code} ||= { parse_locale_code( $self->code ) } )
        ->{script};
}

sub territory_code {
    my $self = shift;
    return ( $self->{parsed_code} ||= { parse_locale_code( $self->code ) } )
        ->{territory};
}

sub variant_code {
    my $self = shift;
    return ( $self->{parsed_code} ||= { parse_locale_code( $self->code ) } )
        ->{variant};
}

sub id {
    $_[0]->code;
}

sub language_id {
    $_[0]->language_code;
}

sub script_id {
    $_[0]->script_code;
}

sub territory_id {
    $_[0]->territory_code;
}

sub variant_id {
    $_[0]->variant_code;
}

sub STORABLE_freeze {
    my $self    = shift;
    my $cloning = shift;

    return if $cloning;

    return $self->code;
}

sub STORABLE_thaw {
    my $self = shift;
    shift;
    my $serialized = shift;

    my $obj = DateTime::Locale->load($serialized);

    %{$self} = %{$obj};

    return $self;
}

1;

# ABSTRACT: Class for locale objects instantiated from pre-defined data

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Locale::FromData - Class for locale objects instantiated from pre-defined data

=head1 VERSION

version 1.03

=head1 SYNOPSIS

  my $locale = DateTime::Locale::FromData->new(%lots_of_data)

=head1 DESCRIPTION

This class is used to represent locales instantiated from the data in the
DateTime::Locale::Data module.

=head1 METHODS

This class provides the following methods:

=over 4

=item * $locale->code

The complete locale id, something like "en-US".

=item * $locale->language_code

The language portion of the code, like "en".

=item * $locale->script_code

The script portion of the code, like "Hant".

=item * $locale->territory_code

The territory portion of the code, like "US".

=item * $locale->variant_code

The variant portion of the code, like "POSIX".

=item * $locale->name

The locale's complete name, which always includes at least a language
component, plus optional territory and variant components. Something like
"English United States". The value returned will always be in English.

=item * $locale->language

=item * $locale->script

=item * $locale->territory

=item * $locale->variant

The relevant component from the locale's complete name, like "English"
or "United States".

=item * $locale->native_name

The locale's complete name in localized form as a UTF-8 string.

=item * $locale->native_language

=item * $locale->native_script

=item * $locale->native_territory

=item * $locale->native_variant

The relevant component from the locale's complete native name as a UTF-8
string.

=back

The following methods all return an array reference containing the specified
data.

The methods with "format" in the name should return strings that can be used a
part of a string, like "the month of July". The stand alone values are for use
in things like calendars as opposed to a sentence.

The narrow forms may not be unique (for example, in the day column heading for
a calendar it's okay to have "T" for both Tuesday and Thursday).

The wide name should always be the full name of thing in question. The narrow
name should be just one or two characters.

=over 4

=item * $locale->month_format_wide

=item * $locale->month_format_abbreviated

=item * $locale->month_format_narrow

=item * $locale->month_stand_alone_wide

=item * $locale->month_stand_alone_abbreviated

=item * $locale->month_stand_alone_narrow

=item * $locale->day_format_wide

=item * $locale->day_format_abbreviated

=item * $locale->day_format_narrow

=item * $locale->day_stand_alone_wide

=item * $locale->day_stand_alone_abbreviated

=item * $locale->day_stand_alone_narrow

=item * $locale->quarter_format_wide

=item * $locale->quarter_format_abbreviated

=item * $locale->quarter_format_narrow

=item * $locale->quarter_stand_alone_wide

=item * $locale->quarter_stand_alone_abbreviated

=item * $locale->quarter_stand_alone_narrow

=item * $locale->am_pm_abbreviated

=item * $locale->era_wide

=item * $locale->era_abbreviated

=item * $locale->era_narrow

=back

The following methods return strings appropriate for the
C<< DateTime->format_cldr >> method:

=over 4

=item * $locale->date_format_full

=item * $locale->date_format_long

=item * $locale->date_format_medium

=item * $locale->date_format_short

=item * $locale->time_format_full

=item * $locale->time_format_long

=item * $locale->time_format_medium

=item * $locale->time_format_short

=item * $locale->datetime_format_full

=item * $locale->datetime_format_long

=item * $locale->datetime_format_medium

=item * $locale->datetime_format_short

=back

A locale may also offer one or more formats for displaying part of a datetime,
such as the year and month, or hour and minute.

=over 4

=item * $locale->format_for($name)

These are accessed by passing a name to C<< $locale->format_for(...)  >>,
where the name is a CLDR-style format specifier.

The return value is a string suitable for passing to C<< $dt->format_cldr >>,
so you can do something like this:

  print $dt->format_cldr( $dt->locale->format_for('MMMdd') )

which for the "en" locale would print out something like "08 Jul".

Note that the localization may also include additional text specific to the
locale. For example, the "MMMMd" format for the "zh" locale includes the
Chinese characters for "day" (日) and month (月), so you get something like
"S<8月23日>".

=item * $locale->available_formats

This should return a list of all the format names that could be passed
to C<< $locale->format_for >>.

=back

There are also some miscellaneous methods:

=over 4

=item * $locale->prefers_24_hour_time

Returns a boolean indicating whether or not the locale prefers 24-hour time.

=item * $locale->first_day_of_week

Returns a number from 1 to 7 indicating the I<local> first day of the
week, with Monday being 1 and Sunday being 7.

=item * $locale->version

The CLDR version from which this locale was generated.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Locale>
(or L<bug-datetime-locale@rt.cpan.org|mailto:bug-datetime-locale@rt.cpan.org>).

There is a mailing list available for users of this distribution,
L<mailto:datetime@perl.org>.

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2016 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

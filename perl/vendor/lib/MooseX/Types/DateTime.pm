package MooseX::Types::DateTime; # git description: v0.12-2-g35c46dd
# ABSTRACT: L<DateTime> related constraints and coercions for Moose

use strict;
use warnings;

our $VERSION = '0.13';

use 5.008003;
use Moose 0.41 ();
use DateTime 0.4302 ();
use DateTime::Duration 0.4302 ();
use DateTime::Locale 0.4001 ();
use DateTime::TimeZone 0.95 ();

use MooseX::Types::Moose 0.30 qw/Num HashRef Object Str/;

use namespace::clean 0.19;

use MooseX::Types 0.30 -declare => [qw( DateTime Duration TimeZone Locale Now )];
use if MooseX::Types->VERSION >= 0.42, 'namespace::autoclean';

class_type "DateTime";
class_type "DateTime::Duration";
class_type "DateTime::TimeZone";

subtype DateTime, as 'DateTime';
subtype Duration, as 'DateTime::Duration';
subtype TimeZone, as 'DateTime::TimeZone';

subtype 'DateTime::Locale', as Object,
    where { $_->isa('DateTime::Locale::root') || $_->isa('DateTime::Locale::FromData') };
subtype Locale, as 'DateTime::Locale';

subtype( Now,
    as Str,
    where { $_ eq 'now' },
    ($Moose::VERSION >= 2.0100
        ? Moose::Util::TypeConstraints::inline_as {
           'no warnings "uninitialized";'.
           '!ref(' . $_[1] . ') and '. $_[1] .' eq "now"';
        }
        : Moose::Util::TypeConstraints::optimize_as {
            no warnings 'uninitialized';
            !ref($_[0]) and $_[0] eq 'now';
        }
    ),
);

our %coercions = (
    DateTime => [
        from Num, via { 'DateTime'->from_epoch( epoch => $_ ) },
        from HashRef, via { 'DateTime'->new( %$_ ) },
        from Now, via { 'DateTime'->now },
    ],
    "DateTime::Duration" => [
        from Num, via { DateTime::Duration->new( seconds => $_ ) },
        from HashRef, via { DateTime::Duration->new( %$_ ) },
    ],
    "DateTime::TimeZone" => [
        from Str, via { DateTime::TimeZone->new( name => $_ ) },
    ],
    "DateTime::Locale" => [
        from Moose::Util::TypeConstraints::find_or_create_isa_type_constraint("Locale::Maketext"),
        via { DateTime::Locale->load($_->language_tag) },
        from Str, via { DateTime::Locale->load($_) },
    ],
);

for my $type ( "DateTime", DateTime ) {
    coerce $type => @{ $coercions{DateTime} };
}

for my $type ( "DateTime::Duration", Duration ) {
    coerce $type => @{ $coercions{"DateTime::Duration"} };
}

for my $type ( "DateTime::TimeZone", TimeZone ) {
    coerce $type => @{ $coercions{"DateTime::TimeZone"} };
}

for my $type ( "DateTime::Locale", Locale ) {
    coerce $type => @{ $coercions{"DateTime::Locale"} };
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::DateTime - L<DateTime> related constraints and coercions for Moose

=head1 VERSION

version 0.13

=head1 SYNOPSIS

Export Example:

    use MooseX::Types::DateTime qw(TimeZone);

    has time_zone => (
        isa => TimeZone,
        is => "rw",
        coerce => 1,
    );

    Class->new( time_zone => "Africa/Timbuktu" );

=head1 DESCRIPTION

This module packages several L<Moose::Util::TypeConstraints> with coercions,
designed to work with the L<DateTime> suite of objects.

=for stopwords Namespaced

Namespaced Example:

    use MooseX::Types::DateTime;

    has time_zone => (
        isa => 'DateTime::TimeZone',
        is => "rw",
        coerce => 1,
    );

    Class->new( time_zone => "Africa/Timbuktu" );

=head1 CONSTRAINTS

=over 4

=item L<DateTime>

A class type for L<DateTime>.

=over 4

=item from C<Num>

Uses L<DateTime/from_epoch>. Floating values will be used for sub-second
precision, see L<DateTime> for details.

=item from C<HashRef>

Calls L<DateTime/new> with the hash entries as arguments.

=back

=item L<Duration>

A class type for L<DateTime::Duration>

=over 4

=item from C<Num>

Uses L<DateTime::Duration/new> and passes the number as the C<seconds> argument.

Note that due to leap seconds, DST changes etc this may not do what you expect.
For instance passing in C<86400> is not always equivalent to one day, although
there are that many seconds in a day. See L<DateTime/"How Date Math is Done">
for more details.

=item from C<HashRef>

Calls L<DateTime::Duration/new> with the hash entries as arguments.

=back

=item L<DateTime::Locale>

A class type for L<DateTime::Locale::root> with the name L<DateTime::Locale>.

=over 4

=item from C<Str>

The string is treated as a language tag (e.g. C<en> or C<he_IL>) and given to
L<DateTime::Locale/load>.

=item from L<Locale::Maktext>

The C<Locale::Maketext/language_tag> attribute will be used with L<DateTime::Locale/load>.

=item L<DateTime::TimeZone>

A class type for L<DateTime::TimeZone>.

=over 4

=item from C<Str>

Treated as a time zone name or offset. See L<DateTime::TimeZone/USAGE> for more
details on the allowed values.

Delegates to L<DateTime::TimeZone/new> with the string as the C<name> argument.

=back

=back

=back

=head1 SEE ALSO

L<MooseX::Types::DateTime::MoreCoercions>

L<DateTime>, L<DateTimeX::Easy>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-DateTime>
(or L<bug-MooseX-Types-DateTime@rt.cpan.org|mailto:bug-MooseX-Types-DateTime@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
irc://irc.perl.org/#moose.

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Dagfinn Ilmari Mannsåker Florian Ragwitz John Napiorkowski Shawn M Moore Dave Rolsky

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

John Napiorkowski <jjnapiork@cpan.org>

=item *

Shawn M Moore <sartak@gmail.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

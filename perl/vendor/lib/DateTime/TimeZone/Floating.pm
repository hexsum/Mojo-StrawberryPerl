package DateTime::TimeZone::Floating;
$DateTime::TimeZone::Floating::VERSION = '1.98';
use strict;
use warnings;

use parent 'Class::Singleton', 'DateTime::TimeZone::OffsetOnly';

sub new {
    return shift->instance;
}

sub _new_instance {
    my $class = shift;

    return bless {
        name   => 'floating',
        offset => 0
    }, $class;
}

sub is_floating {1}

sub STORABLE_thaw {
    my $self       = shift;
    my $cloning    = shift;
    my $serialized = shift;

    my $class = ref $self || $self;

    my $obj;
    if ( $class->isa(__PACKAGE__) ) {
        $obj = __PACKAGE__->new();
    }
    else {
        $obj = $class->new();
    }

    %$self = %$obj;

    return $self;
}

1;

# ABSTRACT: A time zone that is always local

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::TimeZone::Floating - A time zone that is always local

=head1 VERSION

version 1.98

=head1 SYNOPSIS

  my $floating_tz = DateTime::TimeZone::Floating->new;

=head1 DESCRIPTION

This class is used to provide the DateTime::TimeZone API needed by
DateTime.pm, but for floating times, as defined by the RFC 2445 spec.
A floating time has no time zone, and has an effective offset of zero.

=head1 USAGE

This class has the same methods as a real time zone object, but the
C<short_name_for_datetime()>, and C<category()> methods both return
undef.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-TimeZone>
(or L<bug-datetime-timezone@rt.cpan.org|mailto:bug-datetime-timezone@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2016 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

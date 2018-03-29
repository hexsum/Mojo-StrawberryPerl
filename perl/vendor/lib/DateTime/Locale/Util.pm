package DateTime::Locale::Util;

use strict;
use warnings;

use Exporter qw( import );

our $VERSION = '1.03';

our @EXPORT_OK = 'parse_locale_code';

sub parse_locale_code {
    my @pieces = split /-/, $_[0];

    return unless @pieces;

    my %codes = ( language => lc shift @pieces );
    if ( @pieces == 1 ) {
        if ( length $pieces[0] == 2 || $pieces[0] =~ /^\d\d\d$/ ) {
            $codes{territory} = uc shift @pieces;
        }
    }
    elsif ( @pieces == 3 ) {
        $codes{script}    = _tc( shift @pieces );
        $codes{territory} = uc shift @pieces;
        $codes{variant}   = uc shift @pieces;
    }
    elsif ( @pieces == 2 ) {

        # I don't think it's possible to have a script + variant with also
        # having a territory.
        if ( length $pieces[1] == 2 || $pieces[1] =~ /^\d\d\d$/ ) {
            $codes{script}    = _tc( shift @pieces );
            $codes{territory} = uc shift @pieces;
        }
        else {
            $codes{territory} = uc shift @pieces;
            $codes{variant}   = uc shift @pieces;
        }
    }

    return %codes;
}

sub _tc {
    return ucfirst lc $_[0];
}

1;

# ABSTRACT: Utility code for DateTime::Locale

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Locale::Util - Utility code for DateTime::Locale

=head1 VERSION

version 1.03

=head1 DESCRIPTION

There are no user-facing parts in this module.

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

use strict;
use warnings;
package Module::Runtime::Conflicts; # git description: v0.001-10-gca2cd12
# ABSTRACT: Provide information on conflicts for Module::Runtime
# KEYWORDS: conflicts breaks modules prerequisites upgrade
# vim: set ts=8 sts=4 sw=4 tw=78 et :

our $VERSION = '0.002';

use Module::Runtime ();
use Dist::CheckConflicts
    -dist      => 'Module::Runtime',
    -conflicts => {
        # listed modules are the highest *non-working* version when used in
        # combination with the indicated version of Module::Runtime

        eval { Module::Runtime->VERSION('0.014'); 1 } ? (
            'Moose' => '2.1202',
            'MooseX::NonMoose' => '0.24',
            'Elasticsearch' => '1.00',
        ) : (),
    },
    -also => [
        'Package::Stash::Conflicts',
        'Moose::Conflicts',
    ];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Runtime::Conflicts - Provide information on conflicts for Module::Runtime

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    `moose-outdated`

or

    use Module::Runtime::Conflicts;
    Module::Runtime::Conflicts->check_conflicts;

=head1 DESCRIPTION

This module provides conflicts checking for L<Module::Runtime>, which had a
recent release that broke some versions of L<Moose>. It is called from
L<Moose::Conflicts> and C<moose-outdated>.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Runtime-Conflicts>
(or L<bug-Module-Runtime-Conflicts@rt.cpan.org|mailto:bug-Module-Runtime-Conflicts@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::CheckConflicts>

=item *

L<Moose::Conflicts>

=item *

L<Dist::Zilla::Plugin::Breaks>

=item *

L<Dist::Zilla::Plugin::Test::CheckBreaks>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

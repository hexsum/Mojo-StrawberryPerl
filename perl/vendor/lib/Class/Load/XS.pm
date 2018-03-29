package Class::Load::XS;
# git description: v0.08-18-g349ac6e
$Class::Load::XS::VERSION = '0.09';

use strict;
use warnings;

use Class::Load 0.20;

use XSLoader;
XSLoader::load(
    __PACKAGE__,
    exists $Class::Load::XS::{VERSION}
        ? ${ $Class::Load::XS::{VERSION} }
        : (),
);

1;

# ABSTRACT: XS implementation of parts of Class::Load
# KEYWORDS: class module load require use runtime XS

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Load::XS - XS implementation of parts of Class::Load

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use Class::Load;

=head1 DESCRIPTION

This module provides an XS implementation for portions of L<Class::Load>. See
L<Class::Load> for API details.

=for Pod::Coverage is_class_loaded

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Jesse Luehrs hurricup

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <github@froods.org>

=item *

hurricup <hurricup@gmail.com>

=back

=cut

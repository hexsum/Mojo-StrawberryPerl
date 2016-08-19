package B::Hooks::EndOfScope; # git description: 0.19-2-g86b1dd5
# ABSTRACT: Execute code after a scope finished compilation
# KEYWORDS: code hooks execution scope

use strict;
use warnings;

our $VERSION = '0.20';

# note - a %^H tie() fallback will probably work on 5.6 as well,
# if you need to go that low - sane patches passing *all* tests
# will be gladly accepted
use 5.008001;

BEGIN {
  use Module::Implementation 0.05;
  Module::Implementation::build_loader_sub(
    implementations => [ 'XS', 'PP' ],
    symbols => [ 'on_scope_end' ],
  )->();
}

use Sub::Exporter::Progressive 0.001006 -setup => {
  exports => [ 'on_scope_end' ],
  groups  => { default => ['on_scope_end'] },
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B::Hooks::EndOfScope - Execute code after a scope finished compilation

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    on_scope_end { ... };

=head1 DESCRIPTION

This module allows you to execute code when perl finished compiling the
surrounding scope.

=head1 FUNCTIONS

=head2 on_scope_end

    on_scope_end { ... };

    on_scope_end $code;

Registers C<$code> to be executed after the surrounding scope has been
compiled.

This is exported by default. See L<Sub::Exporter> on how to customize it.

=head1 PURE-PERL MODE CAVEAT

While L<Variable::Magic> has access to some very dark sorcery to make it
possible to throw an exception from within a callback, the pure-perl
implementation does not have access to these hacks. Therefore, what
would have been a compile-time exception is instead converted to a
warning, and your execution will continue as if the exception never
happened.

To explicitly request an XS (or PP) implementation one has two choices. Either
to import from the desired implementation explicitly:

 use B::Hooks::EndOfScope::XS
   or
 use B::Hooks::EndOfScope::PP

or by setting C<$ENV{B_HOOKS_ENDOFSCOPE_IMPLEMENTATION}> to either C<XS> or
C<PP>.

=head1 SEE ALSO

L<Sub::Exporter>

L<Variable::Magic>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=B-Hooks-EndOfScope>
(or L<bug-B-Hooks-EndOfScope@rt.cpan.org|mailto:bug-B-Hooks-EndOfScope@rt.cpan.org>).

=head1 AUTHORS

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Peter Rabbitson <ribasushi@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Simon Wilper Tatsuhiko Miyagawa Tomas Doran

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Simon Wilper <sxw@chronowerks.de>

=item *

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

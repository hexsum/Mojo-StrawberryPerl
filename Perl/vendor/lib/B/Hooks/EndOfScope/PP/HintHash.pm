# Implementation of a pure-perl on_scope_end for perl 5.8.X
# (relies on lack of compile/runtime duality of %^H before 5.10
# which makes guard object operation possible)

package # hide from the pauses
  B::Hooks::EndOfScope::PP::HintHash;

use strict;
use warnings;

our $VERSION = '0.20';

use Scalar::Util ();

# This is the original implementation, which sadly is broken
# on perl 5.10+ within string evals
sub on_scope_end (&) {
  $^H |= 0x020000;

  # localised %^H behaves funny on 5.8 - a
  # 'local %^H;'
  # is in effect the same as
  # 'local %^H = %^H;'
  # therefore make sure we use different keys so that things do not
  # fire too early due to hashkey overwrite
  push @{
    $^H{sprintf '__B_H_EOS__guardstack_0X%x', Scalar::Util::refaddr(\%^H) }
      ||= bless ([], 'B::Hooks::EndOfScope::PP::_SG_STACK')
  }, shift;
}

package # hide from the pauses
  B::Hooks::EndOfScope::PP::_SG_STACK;

use warnings;
use strict;

sub DESTROY {
  B::Hooks::EndOfScope::PP::__invoke_callback($_) for @{$_[0]};
}

1;

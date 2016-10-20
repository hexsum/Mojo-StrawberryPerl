###############################################################################
# core math lib for BigInt, representing big numbers by the GMP library

package Math::BigInt::GMP;

use 5.006002;
use strict;
use warnings;

our $VERSION = '1.51';

use XSLoader;
XSLoader::load "Math::BigInt::GMP", $VERSION;

sub import { }                  # catch and throw away
sub api_version() { 2; }

###############################################################################
# Routines not present here are in GMP.xs

##############################################################################
# Return the nth digit, negative values count backward.

sub _digit {
    my ($c, $x, $n) = @_;

    my $str = _str($c, $x);
    $n ++;
    substr($str , -$n, 1);
}

# Return a Perl numerical scalar.

sub _num {
    my ($c, $x) = @_;
    return 0 + _str($c, $x);
}

# Return binomial coefficient (n over k). The code is based on _nok() in
# Math::BigInt::Calc.

sub _nok {
    # Return binomial coefficient (n over k).
    # Given refs to arrays, return ref to array.
    # First input argument is modified.

    my ($c, $n, $k) = @_;

    # If k > n/2, or, equivalently, 2*k > n, compute nok(n, k) as
    # nok(n, n-k), to minimize the number if iterations in the loop.

    {
        my $twok = _mul($c, _two($c), _copy($c, $k));   # 2 * k
        if (_acmp($c, $twok, $n) > 0) {                 # if 2*k > n
            $k = _sub($c, _copy($c, $n), $k);           # k = n - k
        }
    }

    # Example:
    #
    # / 7 \       7!       1*2*3*4 * 5*6*7   5 * 6 * 7       6   7
    # |   | = --------- =  --------------- = --------- = 5 * - * -
    # \ 3 /   (7-3)! 3!    1*2*3*4 * 1*2*3   1 * 2 * 3       2   3

    if (_is_zero($c, $k)) {
        $n = _one($c);
        return $n;
    }

    # Make a copy of the original n, since we'll be modifying n in-place.

    my $n_orig = _copy($c, $n);

    # n = 5, f = 6, d = 2 (cf. example above)

    _sub($c, $n, $k);
    _inc($c, $n);

    my $f = _copy($c, $n);
    _inc($c, $f);

    my $d = _two($c);

    # while f <= n (the original n, that is) ...

    while (_acmp($c, $f, $n_orig) <= 0) {

        # n = (n * f / d) == 5 * 6 / 2 (cf. example above)

        _mul($c, $n, $f);
        _div($c, $n, $d);

        # f = 7, d = 3 (cf. example above)

        _inc($c, $f);
        _inc($c, $d);
    }

    return $n;
}

###############################################################################
# routine to test internal state for corruptions

sub _check
  {
  # no checks yet, pull it out from the test suite
  my ($x) = $_[1];
  return "$x is not a reference to Math::BigInt::GMP"
   if ref($x) ne 'Math::BigInt::GMP';
  0;
  }

sub _log_int
  {
  my ($c,$x,$base) = @_;

  # X == 0 => NaN
  return if _is_zero($c,$x);

  $base = _new($c,2) unless defined $base;
  $base = _new($c,$base) unless ref $base;

  # BASE 0 or 1 => NaN
  return if (_is_zero($c, $base) ||
             _is_one($c, $base));

  my $cmp = _acmp($c,$x,$base);         # X == BASE => 1
  if ($cmp == 0)
    {
    # return one
    return (_one($c), 1);
    }
  # X < BASE
  if ($cmp < 0)
    {
    return (_zero($c),undef);
    }

  # Compute a guess for the result based on:
  # $guess = int ( length_in_base_10(X) / ( log(base) / log(10) ) )
  my $len = _alen($c,$x);
  my $log = log( _str($c,$base) ) / log(10);

  # calculate now a guess based on the values obtained above:
  my $x_org = _copy($c,$x);

  # keep the reference to $x, modifying it in place
  _set($c, $x, int($len / $log) - 1);

  my $trial = _pow ($c, _copy($c, $base), $x);
  my $a = _acmp($c,$trial,$x_org);

  if ($a == 0)
    {
    return ($x,1);
    }
  elsif ($a > 0)
    {
    # too big, shouldn't happen
    _div($c,$trial,$base); _dec($c, $x);
    }

  # find the real result by going forward:
  my $base_mul = _mul($c, _copy($c,$base), $base);
  my $two = _two($c);

  while (($a = _acmp($c, $trial, $x_org)) < 0)
    {
    _mul($c,$trial,$base_mul); _add($c, $x, $two);
    }

  my $exact = 1;
  if ($a > 0)
    {
    # overstepped the result
    _dec($c, $x);
    _div($c,$trial,$base);
    $a = _acmp($c,$trial,$x_org);
    if ($a > 0)
      {
      _dec($c, $x);
      }
    $exact = 0 if $a != 0;
    }

  ($x,$exact);
  }

sub STORABLE_freeze {
    my ($self, $cloning) = @_;
    return Math::BigInt::GMP->_str($self);
}

sub STORABLE_thaw {
    my ($self, $cloning, $serialized) = @_;
    Math::BigInt::GMP->_new_attach($self, $serialized);
    return $self;
}

1;

__END__

=pod

=head1 NAME

Math::BigInt::GMP - Use the GMP library for Math::BigInt routines

=head1 SYNOPSIS

Provides support for big integer calculations by means of the GMP c-library.

Math::BigInt::GMP now no longer uses Math::GMP, but provides it's own XS layer
to access the GMP c-library. This cut's out another (perl sub routine) layer
and also reduces the memory footprint by not loading Math::GMP and Carp at
all.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint-gmp at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-GMP>
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::GMP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt-GMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-BigInt-GMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-BigInt-GMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-BigInt-GMP/>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-GMP>

=item * The Bignum mailing list

=over 4

=item * Post to mailing list

C<bignum at lists.scsys.co.uk>

=item * View mailing list

L<http://lists.scsys.co.uk/pipermail/bignum/>

=item * Subscribe/Unsubscribe

L<http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/bignum>

=back

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tels E<lt>http://bloodgate.com/E<gt> in 2001-2007.

Thanx to Chip Turner for providing Math::GMP, which was inspiring my work.

=head1 SEE ALSO

L<Math::BigInt>, L<Math::BigFloat>, and the other backends
L<Math::BigInt::Calc>, L<Math::BigInt::GMP>, and L<Math::BigInt::Pari>.

The other GMP modules L<Math::GMP>, L<Math::GMPf>, L<Math::GMPq>, L<Math::GMPz>

=cut

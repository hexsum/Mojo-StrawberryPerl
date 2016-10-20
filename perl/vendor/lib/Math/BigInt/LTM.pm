package Math::BigInt::LTM;

use strict;
use warnings;

use CryptX;

sub api_version() { 2 }

sub CLONE_SKIP { 1 } # prevent cloning

##############################################################################
# routine to test internal state

sub _check {
  my ($c, $x) = @_;
  return 0 if ref $x eq 'Math::BigInt::LTM';
  return "$x is not a reference to Math::BigInt::LTM";
}

##############################################################################
# Return the nth digit, negative values count backward.

sub _digit {
  my ($c, $x, $n) = @_;
  substr(_str($c, $x), -($n+1), 1);
}

##############################################################################
# Return a Perl numerical scalar.

sub _num {
  my ($c, $x) = @_;
  return 0 + _str($c, $x);
}

##############################################################################
# _fac() - n! (factorial)

sub _fac {
  my ($c, $x) = @_;
  if (_is_zero($c, $x) || _is_one($c, $x)) {
    _set($c, $x, 1);
  }
  else {
    my $copy = _copy($c, $x);
    my $one = _new($c, 1);
    while(_acmp($c, $copy, $one) > 0) {
      $copy = _dec($c, $copy);
      $x  = _mul($c, $x, $copy);
    }
  }
  return $x;
}

##############################################################################
# Return binomial coefficient (n over k).
# based on _nok() in Math::BigInt::GMP

sub _nok {
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

##############################################################################
# based on _log_int() in Math::BigInt::GMP

sub _log_int {
  my ($c,$x,$base) = @_;

  # X == 0 => NaN
  return if _is_zero($c,$x);

  $base = _new($c,2) unless defined $base;
  $base = _new($c,$base) unless ref $base;

  # BASE 0 or 1 => NaN
  return if (_is_zero($c, $base) ||
             _is_one($c, $base));

  my $cmp = _acmp($c,$x,$base);         # X == BASE => 1
  if ($cmp == 0) {
    # return one
    return (_one($c), 1);
  }
  # X < BASE
  if ($cmp < 0) {
    return (_zero($c),undef);
  }

  # Compute a guess for the result based on:
  # $guess = int ( length_in_base_10(X) / ( log(base) / log(10) ) )
  my $len = _len($c,$x);
  my $log = log( _str($c,$base) ) / log(10);

  # calculate now a guess based on the values obtained above:
  my $x_org = _copy($c,$x);

  # keep the reference to $x, modifying it in place
  _set($c, $x, int($len / $log) - 1);

  my $trial = _pow ($c, _copy($c, $base), $x);
  my $a = _acmp($c,$trial,$x_org);

  if ($a == 0) {
    return ($x,1);
  }
  elsif ($a > 0) {
    # too big, shouldn't happen
    _div($c,$trial,$base); _dec($c, $x);
  }

  # find the real result by going forward:
  my $base_mul = _mul($c, _copy($c,$base), $base);
  my $two = _two($c);

  while (($a = _acmp($c, $trial, $x_org)) < 0) {
    _mul($c,$trial,$base_mul); _add($c, $x, $two);
  }

  my $exact = 1;
  if ($a > 0) {
    # overstepped the result
    _dec($c, $x);
    _div($c,$trial,$base);
    $a = _acmp($c,$trial,$x_org);
    if ($a > 0) {
      _dec($c, $x);
    }
    $exact = 0 if $a != 0;
  }

  return ($x, $exact);
}

1;

__END__

=pod

=head1 NAME

Math::BigInt::LTM - Use the libtommath library for Math::BigInt routines

=head1 SYNOPSIS

 use Math::BigInt lib => 'LTM';

 ## See Math::BigInt docs for usage.

=head1 DESCRIPTION

Provides support for big integer calculations by means of the libtommath c-library.

I<Since: CryptX-0.029>

=head1 SEE ALSO

L<Math::BigInt>, L<https://github.com/libtom/libtommath>

=cut

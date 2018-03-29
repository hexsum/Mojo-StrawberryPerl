package Crypt::RSA::Key; 
use strict;
use warnings;

## Crypt::RSA::Keys
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use base 'Class::Loader';
use base 'Crypt::RSA::Errorhandler';
use Math::Prime::Util      qw(prime_set_config random_nbit_prime is_strong_pseudoprime primes);
use Bytes::Random::Secure  qw(random_bytes);
use Crypt::RSA::DataFormat qw(bitsize);
use Math::BigInt try => 'GMP, Pari';
use Crypt::RSA::Key::Private;
use Crypt::RSA::Key::Public;
use Carp;

$Crypt::RSA::Key::VERSION = '1.99';

my %MODMAP = ( 
    Native_PKF => { Module => "Crypt::RSA::Key::Public" },
    Native_SKF => { Module => "Crypt::RSA::Key::Private" },
       SSH_PKF => { Module => "Crypt::RSA::Key::Public::SSH"  }, 
       SSH_SKF => { Module => "Crypt::RSA::Key::Private::SSH" }, 
);


sub new { 
    my $class = shift;
    my $self = {};
    # Use one BRS object per key object.  It should be ok to re-use between
    # keys, since BRS is a CSPRNG.  We could share one BRS object between all
    # objects which would be a bit more efficient (that would be similar to
    # using BRS's functional interface).
    $self->{RandomObject} = Bytes::Random::Secure->new( Bits => 256 );
    bless $self, $class;
    $self->_storemap ( %MODMAP );
    return $self;
}


sub generate {

    my ($self, %params) = @_; 

    my $key;
    unless ($params{q} && $params{p} && $params{e}) { 

        return $self->error ("Missing argument.") unless $params{Size};

        return $self->error ("Keysize too small.") if 
            $params{Size} < 48;

        return $self->error ("Odd keysize.") if 
            $params{Size} % 2; 

        my $size = int($params{Size}/2);  
        my $verbosity = $params{Verbosity} || 0;

        my $randobj = $self->{RandomObject};
        my $randsub = $params{RandomSub} || sub { $randobj->irand() };
        return $self->error("RandomSub must be a CODE reference.")
               unless ref($randsub) eq 'CODE';
        prime_set_config( irand => $randsub );

        # Switch from Maurer prime to nbit prime, then add some more primality
        # testing.  This is faster and gives us a wider set of possible primes.
        my @prplist = @{primes( 200 )};

        while (1) {
          my $p = random_nbit_prime($size);
          my $q = random_nbit_prime($size);
          $p = Math::BigInt->new("$p") unless ref($p) eq 'Math::BigInt';
          $q = Math::BigInt->new("$q") unless ref($q) eq 'Math::BigInt';

          next unless bitsize($p * $q) == $params{Size};

          # p and q have passed the strong BPSW test, so it would be shocking
          # if they were not prime.  We'll add a few more tests because they're
          # cheap and we want to be extra careful, but also don't want to spend
          # the time doing a full primality proof.  The results will have
          # passed BPSW as well as being strong pseudoprimes to the first 46
          # prime bases.
          do { carp "$p passes BPSW but fails pseudoprime tests!"; next; }
            unless is_strong_pseudoprime($p, @prplist);
          do { carp "$q passes BPSW but fails pseudoprime tests!"; next; }
            unless is_strong_pseudoprime($q, @prplist);

          # We could add some more conditions here.  Possibilities:
          #  - make sure |p-q| is large enough.  With large bit sizes this is
          #    exceedingly unlikely, but we could easily double check.
          #  - run some trivial factoring tests, or check the smoothness of
          #    p-1 and q-1.  Using random_strong_prime could also do this.

          $key = { p => $p, q => $q, e => Math::BigInt->new(65537) };
          last;
        }
    } 

    if ($params{KF}) { 
        $params{PKF} = { Name => "$params{KF}_PKF" };
        $params{SKF} = { Name => "$params{KF}_SKF" }
    }

    my $pubload = $params{PKF} ? $params{PKF} : { Name => "Native_PKF" };
    my $priload = $params{SKF} ? $params{SKF} : { Name => "Native_SKF" };

    my $pubkey = $self->_load (%$pubload) || 
        return $self->error ("Couldn't load the public key module: $@");
    my $prikey = $self->_load ((%$priload), Args => ['Cipher' => $params{Cipher}, 'Password' => $params{Password} ]) || 
        return $self->error ("Couldn't load the private key module: $@");
    $pubkey->Identity ($params{Identity});
    $prikey->Identity ($params{Identity});

    $pubkey->e ($$key{e} || $params{e});
    $prikey->e ($$key{e} || $params{e});
    $prikey->p ($$key{p} || $params{p});
    $prikey->q ($$key{q} || $params{q});

    $prikey->phi ( ($prikey->p - 1) * ($prikey->q - 1) );

    $prikey->d ( ($pubkey->e)->copy->bmodinv($prikey->phi) );
    $prikey->n ( $prikey->p * $prikey->q );
    $pubkey->n ( $prikey->n );

    $prikey->dp ($prikey->d % ($prikey->p - 1));
    $prikey->dq ($prikey->d % ($prikey->q - 1));
    $prikey->u ( ($prikey->p)->copy->bmodinv($prikey->q) );

    return $self->error ("d is too small. Regenerate.") if
        bitsize($prikey->d) < 0.25 * bitsize($prikey->n);

    $$key{p} = 0; $$key{q} = 0; $$key{e} = 0;

    if ($params{Filename}) { 
        $pubkey->write (Filename => "$params{Filename}.public");
        $prikey->write (Filename => "$params{Filename}.private");
    }

    return ($pubkey, $prikey);

}

1;

=head1 NAME

Crypt::RSA::Key - RSA Key Pair Generator.

=head1 SYNOPSIS

    my $keychain = new Crypt::RSA::Key;
    my ($public, $private) = $keychain->generate ( 
                              Identity  => 'Lord Macbeth <macbeth@glamis.com>',
                              Size      => 2048,  
                              Password  => 'A day so foul & fair', 
                              Verbosity => 1,
                             ) or die $keychain->errstr();

=head1 DESCRIPTION

This module provides a method to generate an RSA key pair.

=head1 METHODS

=head2 new()

Constructor.  

=head2 generate()

generate() generates an RSA key of specified bitsize. It returns a list of
two elements, a Crypt::RSA::Key::Public object that holds the public part
of the key pair and a Crypt::RSA::Key::Private object that holds that
private part. On failure, it returns undef and sets $self->errstr to
appropriate error string. generate() takes a hash argument with the
following keys:

=over 4

=item B<Size>

Bitsize of the key to be generated. This should be an even integer > 48.
Bitsize is a mandatory argument.

=item B<Password>

String with which the private key will be encrypted. If Password is not
provided the key will be stored unencrypted.

=item B<Identity>

A string that identifies the owner of the key. This string usually takes
the form of a name and an email address. The identity is not bound to the
key with a signature. However, a future release or another module will
provide this facility. 

=item B<Cipher>

The block cipher which is used for encrypting the private key. Defaults to
`Blowfish'. Cipher could be set to any value that works with Crypt::CBC(3)
and Tie::EncryptedHash(3).

=item B<Verbosity> 

When set to 1, generate() will draw a progress display on STDOUT.

=item B<Filename>

The generated key pair will be written to disk, in $Filename.public and
$Filename.private files, if this argument is provided. Disk writes can be
deferred by skipping this argument and achieved later with the write()
method of Crypt::RSA::Key::Public(3) and Crypt::RSA::Key::Private(3).

=item B<KF> 

A string that specifies the key format. As of this writing, two key
formats, `Native' and `SSH', are supported. KF defaults to `Native'.

=item B<SKF> 

Secret (Private) Key Format. Instead of specifying KF, the user could
choose to specify secret and public key formats separately. The value for
SKF can be a string ("Native" or "SSH") or a hash reference that specifies
a module name, its constructor and constructor arguments. The specified
module is loaded with Class::Loader(3) and must be interface compatible
with Crypt::RSA::Key::Private(3).

=item B<PKF> 

Public Key Format. This option is like SKF but for the public key.

=item B<RandomSub>

A code reference that returns a 32-bit random number when called.  This will
be used to generate random data for selecting the random primes needed for key
generation.  The default source is almost always a good choice so you should
never need to use this parameter for normal use.  It is specifically available
for special needs such as selecting a non-blocking seed source for tests.

=back

=head1 ERROR HANDLING

See B<ERROR HANDLING> in Crypt::RSA(3) manpage.

=head1 BUGS

There's an inefficiency in the way generate() ensures the key pair is
exactly Size bits long. This will be fixed in a future release.

=head1 AUTHOR

Vipul Ved Prakash, E<lt>mail@vipul.netE<gt>

=head1 SEE ALSO

Crypt::RSA(3), Crypt::RSA::Key::Public(3), Crypt::RSA::Key::Private(3), 
Tie::EncryptedHash(3), Class::Loader(3),
Math::Prime::Util(3)

=cut



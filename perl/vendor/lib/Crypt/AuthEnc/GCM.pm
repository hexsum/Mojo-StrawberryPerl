package Crypt::AuthEnc::GCM;

use strict;
use warnings;

use base qw(Crypt::AuthEnc Exporter);
our %EXPORT_TAGS = ( all => [qw( gcm_encrypt_authenticate gcm_decrypt_verify )] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

use CryptX;
use Crypt::Cipher;

sub new { my $class = shift; _new(Crypt::Cipher::_trans_cipher_name(shift), @_) }

sub gcm_encrypt_authenticate {
  my $cipher_name = shift;
  my $key = shift;
  my $iv = shift;
  my $adata = shift;
  my $plaintext = shift;

  my $m = Crypt::AuthEnc::GCM->new($cipher_name, $key);
  $m->iv_add($iv);
  $m->adata_add(defined $adata ? $adata : ''); #XXX-TODO if no aad we have to pass empty string
  my $ct = $m->encrypt_add($plaintext);
  my $tag = $m->encrypt_done;
  return ($ct, $tag);
}

sub gcm_decrypt_verify {
  my $cipher_name = shift;
  my $key = shift;
  my $iv = shift;
  my $adata = shift;
  my $ciphertext = shift;
  my $tag = shift;

  my $m = Crypt::AuthEnc::GCM->new($cipher_name, $key);
  $m->iv_add($iv);
  $m->adata_add(defined $adata ? $adata : ''); #XXX-TODO if no aad we have to pass empty string
  my $ct = $m->decrypt_add($ciphertext);
  return $m->decrypt_done($tag) ? $ct : undef;
}

1;

=pod

=head1 NAME

Crypt::AuthEnc::GCM - Authenticated encryption in GCM mode

=head1 SYNOPSIS

 ### OO interface

 # encrypt and authenticate
 my $ae = Crypt::AuthEnc::GCM->new("AES", $key);
 $ae->iv_add('data_iv1');
 $ae->iv_add('data_iv2');
 $ae->aad_add('data_aad1');
 $ae->aad_add('data_aad2');
 $ct = $ae->encrypt_add('data1');
 $ct = $ae->encrypt_add('data2');
 $ct = $ae->encrypt_add('data3');
 $tag = $ae->encrypt_done();

 # decrypt and verify
 my $ae = Crypt::AuthEnc::GCM->new("AES", $key);
 $ae->iv_add('data_iv1');
 $ae->iv_add('data_iv2');
 $ae->aad_add('data_aad1');
 $ae->aad_add('data_aad2');
 $pt = $ae->decrypt_add($ciphertext1);
 $pt = $ae->decrypt_add($ciphertext2);
 $pt = $ae->decrypt_add($ciphertext3);
 $tag = $ae->decrypt_done();

 ### functional interface
 use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);

 my ($ciphertext, $tag) = gcm_encrypt_authenticate('AES', $key, $iv, $adata, $plaintext);
 my $plaintext = gcm_decrypt_verify('AES', $key, $iv, $adata, $ciphertext, $tag);

=head1 DESCRIPTION

Galois/Counter Mode (GCM) - provides encryption and authentication.

=head1 EXPORT

Nothing is exported by default.

You can export selected functions:

  use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);

=head1 FUNCTIONS

=head2 gcm_encrypt_authenticate

 my ($ciphertext, $tag) = gcm_encrypt_authenticate($cipher, $key, $iv, $adata, $plaintext);

 # $cipher .. 'AES' or name of any other cipher with 16-byte block len
 # $key ..... AES key of proper length (128/192/256bits)
 # $iv ...... initial vector
 # $adata ... additional authentication data

=head2 gcm_decrypt_verify

 my $plaintext = gcm_decrypt_verify($cipher, $key, $iv, $adata, $ciphertext, $tag);

 # on error returns undef

=head1 METHODS

=head2 new

 my $ae = Crypt::AuthEnc::GCM->new($cipher, $key);

 # $cipher .. 'AES' or name of any other cipher
 # $key ..... encryption key of proper length

=head2 iv_add

 $ae->iv_add($iv_data);                 #can be called multiple times

=head2 aad_add

Can be called B<after> all C<iv_add> calls but before the first C<encrypt_add> or C<decrypt_add>;

 $ae->aad_add($aad_data);               #can be called multiple times

=head2 encrypt_add

 $ciphertext = $ae->encrypt_add($data);        #can be called multiple times

=head2 encrypt_done

 $tag = $ae->encrypt_done();

=head2 decrypt_add

 $plaintext = $ae->decrypt_add($ciphertext);   #can be called multiple times

=head2 decrypt_done

 my $result = $ae->decrypt_done($tag);  # returns 1 (success) or 0 (failure)
 #or
 my $tag = $ae->decrypt_done;           # returns $tag value

=head2 reset

 $ae->reset;

=head2 clone

 my $ae_new = $ae->clone;

=head1 SEE ALSO

=over

=item * L<CryptX|CryptX>, L<Crypt::Mode::CCM|Crypt::Mode::CCM>, L<Crypt::Mode::EAX|Crypt::Mode::EAX>, L<Crypt::Mode::OCB|Crypt::Mode::OCB>

=item * L<https://en.wikipedia.org/wiki/Galois/Counter_Mode>

=back

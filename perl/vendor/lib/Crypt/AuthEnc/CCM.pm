package Crypt::AuthEnc::CCM;

use strict;
use warnings;

use base qw(Crypt::AuthEnc Exporter);
our %EXPORT_TAGS = ( all => [qw( ccm_encrypt_authenticate ccm_decrypt_verify )] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

use CryptX;
use Crypt::Cipher;

### the following functions are implemented in XS:
# - _memory_encrypt
# - _memory_decrypt

sub ccm_encrypt_authenticate {
  my $cipher_name = shift;
  my $key = shift;
  my $nonce = shift;
  my $header = shift;
  my $tag_len = shift;
  my $plaintext = shift;
  return _memory_encrypt(Crypt::Cipher::_trans_cipher_name($cipher_name), $key, $nonce, $header, $tag_len, $plaintext);
}

sub ccm_decrypt_verify {
  my $cipher_name = shift;
  my $key = shift;
  my $nonce = shift;
  my $header = shift;
  my $ciphertext = shift;
  my $tag = shift;
  return _memory_decrypt(Crypt::Cipher::_trans_cipher_name($cipher_name), $key, $nonce, $header, $ciphertext, $tag);
}

1;

=pod

=head1 NAME

Crypt::AuthEnc::CCM - Authenticated encryption in CCM mode

=head1 SYNOPSIS

 use Crypt::AuthEnc::CCM qw(ccm_encrypt_authenticate ccm_decrypt_verify);

 my ($ciphertext, $tag) = ccm_encrypt_authenticate('AES', $key, $nonce, $header, $tag_len, $plaintext);

 #### send ($ciphertext, $tag, $nonce, $header) to other party

 my $plaintext = ccm_decrypt_verify('AES', $key, $nonce, $header, $ciphertext, $tag);

=head1 DESCRIPTION

CCM is a encrypt+authenticate mode that is centered around using AES (or any 16-byte cipher) as aprimitive.
Unlike EAX and OCB mode, it is only meant for packet mode where the length of the input is known in advance.

=head1 EXPORT

Nothing is exported by default.

You can export selected functions:

  use Crypt::AuthEnc::CCM qw(ccm_encrypt_authenticate ccm_decrypt_verify);

=head1 FUNCTIONS

=head2 ccm_encrypt_authenticate

 my ($ciphertext, $tag) = ccm_encrypt_authenticate($cipher, $key, $nonce, $header, $tag_len, $plaintext);

 # $cipher .. 'AES' or name of any other cipher with 16-byte block len
 # $key ..... AES key of proper length (128/192/256bits)
 # $nonce ... unique nonce/salt (no need to keep it secret)
 # $header .. meta-data you want to send with the message but not have encrypted

=head2 ccm_decrypt_verify

  my $plaintext = ccm_decrypt_verify($cipher, $key, $nonce, $header, $ciphertext, $tag);

  # on error returns undef

=head1 SEE ALSO

=over

=item * L<CryptX|CryptX>, L<Crypt::Mode::EAX|Crypt::Mode::EAX>, L<Crypt::Mode::GCM|Crypt::Mode::GCM>, L<Crypt::Mode::OCB|Crypt::Mode::OCB>

=item * L<https://en.wikipedia.org/wiki/CCM_mode|https://en.wikipedia.org/wiki/CCM_mode>

=back

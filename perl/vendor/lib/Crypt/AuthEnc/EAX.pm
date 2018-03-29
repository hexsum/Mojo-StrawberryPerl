package Crypt::AuthEnc::EAX;

use strict;
use warnings;

use base qw(Crypt::AuthEnc Exporter);
our %EXPORT_TAGS = ( all => [qw( eax_encrypt_authenticate eax_decrypt_verify )] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

use CryptX;
use Crypt::Cipher;

### the following methods/functions are implemented in XS:
# - _new
# - DESTROY
# - clone
# - encrypt_add
# - encrypt_done
# - decrypt_add
# - decrypt_done
# - header_add

sub new { my $class = shift; _new(Crypt::Cipher::_trans_cipher_name(shift), @_) }

sub eax_encrypt_authenticate {
  my $cipher_name = shift;
  my $key = shift;
  my $nonce = shift;
  my $header = shift;
  my $plaintext = shift;

  my $m = Crypt::AuthEnc::EAX->new($cipher_name, $key, $nonce);
  $m->header_add($header) if defined $header;
  my $ct = $m->encrypt_add($plaintext);
  my $tag = $m->encrypt_done;
  return ($ct, $tag);
}

sub eax_decrypt_verify {
  my $cipher_name = shift;
  my $key = shift;
  my $nonce = shift;
  my $header = shift;
  my $ciphertext = shift;
  my $tag = shift;

  my $m = Crypt::AuthEnc::EAX->new($cipher_name, $key, $nonce);
  $m->header_add($header) if defined $header;
  my $ct = $m->decrypt_add($ciphertext);
  return $m->decrypt_done($tag) ? $ct : undef;
}


1;

=pod

=head1 NAME

Crypt::AuthEnc::EAX - Authenticated encryption in EAX mode

=head1 SYNOPSIS

 ### example 1
 use Crypt::AuthEnc::EAX;

 # encrypt + authenticate
 my $ae = Crypt::AuthEnc::EAX->new("AES", $key, $nonce);
 $ae->header_add('headerdata part1');
 $ae->header_add('headerdata part2');
 $ct = $ae->encrypt_add('data1');
 $ct = $ae->encrypt_add('data2');
 $ct = $ae->encrypt_add('data3');
 $tag = $ae->encrypt_done();

 # decrypt + verify
 my $ae = Crypt::AuthEnc::EAX->new("AES", $key, $nonce);
 $ae->header_add('headerdata part1');
 $ae->header_add('headerdata part2');
 $pt = $ae->decrypt_add('ciphertext1');
 $pt = $ae->decrypt_add('ciphertext2');
 $pt = $ae->decrypt_add('ciphertext3');

 my $result = $ae->decrypt_done($tag);
 #or
 my $tag_dec = $ae->decrypt_done;
 die "TAG mismatch" unless $tag eq $tag_dec;

 ### example 2
 use Crypt::AuthEnc::EAX qw(eax_encrypt_authenticate eax_decrypt_verify);

 my ($ciphertext, $tag) = eax_encrypt_authenticate('AES', $key, $nonce, $header, $plaintext);
 my $plaintext = eax_decrypt_verify('AES', $key, $nonce, $header, $ciphertext, $tag);

=head1 DESCRIPTION

EAX is a mode that requires a cipher, CTR and OMAC support and provides encryption and authentication.
It is initialized with a random nonce that can be shared publicly, a header which can be fixed and public,
and a random secret symmetric key.

=head1 EXPORT

Nothing is exported by default.

You can export selected functions:

  use Crypt::AuthEnc::EAX qw(eax_encrypt_authenticate eax_decrypt_verify);

=head1 FUNCTIONS

=head2 eax_encrypt_authenticate

 my ($ciphertext, $tag) = eax_encrypt_authenticate($cipher, $key, $nonce, $header, $plaintext);

 # $cipher .. 'AES' or name of any other cipher with 16-byte block len
 # $key ..... AES key of proper length (128/192/256bits)
 # $nonce ... unique nonce/salt (no need to keep it secret)
 # $header .. meta-data you want to send with the message but not have encrypted

=head2 eax_decrypt_verify

  my $plaintext = eax_decrypt_verify($cipher, $key, $nonce, $header, $ciphertext, $tag);

  # on error returns undef

=head1 METHODS

=head2 new

 my $ae = Crypt::AuthEnc::EAX->new($cipher, $key, $nonce);
 #or
 my $ae = Crypt::AuthEnc::EAX->new($cipher, $key, $nonce, $header);

 # $cipher .. 'AES' or name of any other cipher with 16-byte block len
 # $key ..... AES key of proper length (128/192/256bits)
 # $nonce ... unique nonce/salt (no need to keep it secret)
 # $header .. meta-data you want to send with the message but not have encrypted

=head2 header_add

 $ae->header_add($header_data);                 #can be called multiple times

=head2 encrypt_add

 $ciphertext = $ae->encrypt_add($data);         #can be called multiple times

=head2 encrypt_done

 $tag = $ae->encrypt_done();

=head2 decrypt_add

 $plaintext = $ae->decrypt_add($ciphertext);    #can be called multiple times

=head2 decrypt_done

 my $result = $ae->decrypt_done($tag);  # returns 1 (success) or 0 (failure)
 #or
 my $tag = $ae->decrypt_done;           # returns $tag value

=head2 clone

 my $ae_new = $ae->clone;

=head1 SEE ALSO

=over

=item * L<CryptX|CryptX>, L<Crypt::Mode::CCM|Crypt::Mode::CCM>, L<Crypt::Mode::GCM|Crypt::Mode::GCM>, L<Crypt::Mode::OCB|Crypt::Mode::OCB>

=item * L<https://en.wikipedia.org/wiki/EAX_mode|https://en.wikipedia.org/wiki/EAX_mode>

=back

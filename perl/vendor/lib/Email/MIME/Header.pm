use strict;
use warnings;
package Email::MIME::Header;
# ABSTRACT: the header of a MIME message
$Email::MIME::Header::VERSION = '1.937';
use parent 'Email::Simple::Header';

use Email::MIME::Encode;
use Encode 1.9801;

#pod =head1 DESCRIPTION
#pod
#pod This object behaves like a standard Email::Simple header, with the following
#pod changes:
#pod
#pod =for :list
#pod * the C<header> method automatically decodes encoded headers if possible
#pod * the C<header_raw> method returns the raw header; (read only for now)
#pod * stringification uses C<header_raw> rather than C<header>
#pod
#pod Note that C<header_set> does not do encoding for you, and expects an
#pod encoded header.  Thus, C<header_set> round-trips with C<header_raw>,
#pod not C<header>!  Be sure to properly encode your headers with
#pod C<Encode::encode('MIME-Header', $value)> before passing them to
#pod C<header_set>.
#pod
#pod Alternately, if you have Unicode (character) strings to set in headers, use the
#pod C<header_str_set> method.
#pod
#pod =cut

sub header_str {
  my $self  = shift;
  my $wanta = wantarray;

  return unless defined $wanta; # ??

  my @header = $wanta ? $self->header_raw(@_)
                      : scalar $self->header_raw(@_);

  local $@;
  foreach my $header (@header) {
    next unless defined $header;
    next unless $header =~ /=\?/;

    _maybe_decode(\$header);
  }
  return $wanta ? @header : $header[0];
}

sub header {
  my ($self, $name) = @_;
  return $self->header_str($name);
}

sub header_str_set {
  my ($self, $name, @vals) = @_;

  my @values = map {
    Email::MIME::Encode::maybe_mime_encode_header($name, $_, 'UTF-8')
  } @vals;

  $self->header_set($name => @values);
}

sub header_str_pairs {
  my ($self) = @_;

  my @pairs = $self->header_pairs;
  for (grep { $_ % 2 } (1 .. $#pairs)) {
    _maybe_decode(\$pairs[$_]);
  }

  return @pairs;
}

sub _maybe_decode {
  my ($str_ref) = @_;

  # The eval is to cope with unknown encodings, like Latin-62, or other
  # nonsense that gets put in there by spammers and weirdos
  # -- rjbs, 2014-12-04
  my $new;
  $$str_ref = $new
    if eval { $new = Encode::decode("MIME-Header", $$str_ref); 1 };
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Header - the header of a MIME message

=head1 VERSION

version 1.937

=head1 DESCRIPTION

This object behaves like a standard Email::Simple header, with the following
changes:

=over 4

=item *

the C<header> method automatically decodes encoded headers if possible

=item *

the C<header_raw> method returns the raw header; (read only for now)

=item *

stringification uses C<header_raw> rather than C<header>

=back

Note that C<header_set> does not do encoding for you, and expects an
encoded header.  Thus, C<header_set> round-trips with C<header_raw>,
not C<header>!  Be sure to properly encode your headers with
C<Encode::encode('MIME-Header', $value)> before passing them to
C<header_set>.

Alternately, if you have Unicode (character) strings to set in headers, use the
C<header_str_set> method.

=head1 AUTHORS

=over 4

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Casey West <casey@geeknest.com>

=item *

Simon Cozens <simon@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Simon Cozens and Casey West.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

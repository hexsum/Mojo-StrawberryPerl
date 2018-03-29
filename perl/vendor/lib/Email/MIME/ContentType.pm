use strict;
use warnings;
package Email::MIME::ContentType;
# ABSTRACT: Parse a MIME Content-Type Header
$Email::MIME::ContentType::VERSION = '1.018';
use Carp;
use Exporter 5.57 'import';
our @EXPORT = qw(parse_content_type);

#pod =head1 SYNOPSIS
#pod
#pod   use Email::MIME::ContentType;
#pod
#pod   # Content-Type: text/plain; charset="us-ascii"; format=flowed
#pod   my $ct = 'text/plain; charset="us-ascii"; format=flowed';
#pod   my $data = parse_content_type($ct);
#pod
#pod   $data = {
#pod     type       => "text",
#pod     subtype    => "plain",
#pod     attributes => {
#pod       charset => "us-ascii",
#pod       format  => "flowed"
#pod     }
#pod   };
#pod
#pod =cut

our $STRICT_PARAMS = 1;

my $tspecials = quotemeta '()<>@,;:\\"/[]?=';
my $ct_default = 'text/plain; charset=us-ascii';
my $extract_quoted =
    qr/(?:\"(?:[^\\\"]*(?:\\.[^\\\"]*)*)\"|\'(?:[^\\\']*(?:\\.[^\\\']*)*)\')/;

# For documentation, really:
{
  my $type    = qr/[^$tspecials]+/;
  my $subtype = qr/[^$tspecials]+/;
  my $params  = qr/;.*/;

  sub parse_content_type { # XXX This does not take note of RFC2822 comments
      my $ct = shift;

      # If the header isn't there or is empty, give default answer.
      return parse_content_type($ct_default) unless defined $ct and length $ct;

      # It is also recommend (sic.) that this default be assumed when a
      # syntactically invalid Content-Type header field is encountered.
      return parse_content_type($ct_default)
          unless $ct =~ m[ ^ ($type) / ($subtype) \s* ($params)? $ ]x;

      my ($type, $subtype) = (lc $1, lc $2);
      return {
          type       => $type,
          subtype    => $subtype,
          attributes => _parse_attributes($3),

          # This is dumb.  Really really dumb.  For backcompat. -- rjbs,
          # 2013-08-10
          discrete   => $type,
          composite  => $subtype,
      };
  }
}

sub _parse_attributes {
    local $_ = shift;
    my $attribs = {};
    while ($_) {
        s/^;//;
        s/^\s+// and next;
        s/\s+$//;
        unless (s/^([^$tspecials]+)=\s*//) {
          # We check for $_'s truth because some mail software generates a
          # Content-Type like this: "Content-Type: text/plain;"
          # RFC 1521 section 3 says a parameter must exist if there is a
          # semicolon.
          carp "Illegal Content-Type parameter $_" if $STRICT_PARAMS and $_;
          return $attribs;
        }
        my $attribute = lc $1;
        my $value = _extract_ct_attribute_value();
        $attribs->{$attribute} = $value;
    }
    return $attribs;
}

sub _extract_ct_attribute_value { # EXPECTS AND MODIFIES $_
    my $value;
    while ($_) { 
        s/^([^$tspecials]+)// and $value .= $1;
        s/^($extract_quoted)// and do {
            my $sub = $1; $sub =~ s/^["']//; $sub =~ s/["']$//;
            $value .= $sub;
        };
        /^;/ and last;
        /^([$tspecials])/ and do { 
            carp "Unquoted $1 not allowed in Content-Type!"; 
            return;
        }
    }
    return $value;
}

1;

#pod =func parse_content_type
#pod
#pod This routine is exported by default.
#pod
#pod This routine parses email content type headers according to section 5.1 of RFC
#pod 2045. It returns a hash as above, with entries for the type, the subtype, and a
#pod hash of attributes.
#pod
#pod For backward compatibility with a really unfortunate misunderstanding of RFC
#pod 2045 by the early implementors of this module, C<discrete> and C<composite> are
#pod also present in the returned hashref, with the values of C<type> and C<subtype>
#pod respectively.
#pod
#pod =head1 WARNINGS
#pod
#pod This is not a valid content-type header, according to both RFC 1521 and RFC
#pod 2045:
#pod
#pod   Content-Type: type/subtype;
#pod
#pod If a semicolon appears, a parameter must.  C<parse_content_type> will carp if
#pod it encounters a header of this type, but you can suppress this by setting
#pod C<$Email::MIME::ContentType::STRICT_PARAMS> to a false value.  Please consider
#pod localizing this assignment!
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::ContentType - Parse a MIME Content-Type Header

=head1 VERSION

version 1.018

=head1 SYNOPSIS

  use Email::MIME::ContentType;

  # Content-Type: text/plain; charset="us-ascii"; format=flowed
  my $ct = 'text/plain; charset="us-ascii"; format=flowed';
  my $data = parse_content_type($ct);

  $data = {
    type       => "text",
    subtype    => "plain",
    attributes => {
      charset => "us-ascii",
      format  => "flowed"
    }
  };

=head1 FUNCTIONS

=head2 parse_content_type

This routine is exported by default.

This routine parses email content type headers according to section 5.1 of RFC
2045. It returns a hash as above, with entries for the type, the subtype, and a
hash of attributes.

For backward compatibility with a really unfortunate misunderstanding of RFC
2045 by the early implementors of this module, C<discrete> and C<composite> are
also present in the returned hashref, with the values of C<type> and C<subtype>
respectively.

=head1 WARNINGS

This is not a valid content-type header, according to both RFC 1521 and RFC
2045:

  Content-Type: type/subtype;

If a semicolon appears, a parameter must.  C<parse_content_type> will carp if
it encounters a header of this type, but you can suppress this by setting
C<$Email::MIME::ContentType::STRICT_PARAMS> to a false value.  Please consider
localizing this assignment!

=head1 AUTHORS

=over 4

=item *

Simon Cozens <simon@cpan.org>

=item *

Casey West <casey@geeknest.com>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Matthew Green Thomas Szukala

=over 4

=item *

Matthew Green <mrg@eterna.com.au>

=item *

Thomas Szukala <ts@abusix.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Simon Cozens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

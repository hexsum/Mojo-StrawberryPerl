use strict;
use warnings;
package Email::MIME::Encode;
# ABSTRACT: a private helper for MIME header encoding
$Email::MIME::Encode::VERSION = '1.937';
use Email::Address;
use Encode ();
use MIME::Base64();

my %encoders = (
    'Date'        => \&_date_time_encode,
    'From'        => \&_mailbox_list_encode,
    'Sender'      => \&_mailbox_encode,
    'Reply-To'    => \&_address_list_encode,
    'To'          => \&_address_list_encode,
    'Cc'          => \&_address_list_encode,
    'Bcc'         => \&_address_list_encode,
    'Message-ID'  => \&_msg_id_encode,
    'In-Reply-To' => \&_msg_id_encode,
    'References'  => \&_msg_id_encode,
    'Subject'     => \&_unstructured_encode,
    'Comments'    => \&_unstructured_encode,
);

sub maybe_mime_encode_header {
    my ($header, $val, $charset) = @_;

    return $val unless defined $val;
    return $val unless $val =~ /\P{ASCII}/
                    || $val =~ /=\?/;

    $header =~ s/^Resent-//;

    return $encoders{$header}->($val, $charset)
        if exists $encoders{$header};

    return _unstructured_encode($val, $charset);
}

sub _date_time_encode {
    my ($val, $charset) = @_;
    return $val;
}

sub _mailbox_encode {
    my ($val, $charset) = @_;
    return _mailbox_list_encode($val, $charset);
}

sub _mailbox_list_encode {
    my ($val, $charset) = @_;
    my @addrs = Email::Address->parse($val);

    @addrs = map {
        my $phrase = $_->phrase;
        $_->phrase(mime_encode($phrase, $charset))
            if defined $phrase && $phrase =~ /\P{ASCII}/;
        my $comment = $_->comment;
        $_->comment(mime_encode($comment, $charset))
            if defined $comment && $comment =~ /\P{ASCII}/;
        $_;
    } @addrs;

    return join(', ', map { $_->format } @addrs);
}

sub _address_encode {
    my ($val, $charset) = @_;
    return _address_list_encode($val, $charset);
}

sub _address_list_encode {
    my ($val, $charset) = @_;
    return _mailbox_list_encode($val, $charset); # XXX is this right?
}

sub _msg_id_encode {
    my ($val, $charset) = @_;
    return $val;
}

sub _unstructured_encode {
    my ($val, $charset) = @_;
    return mime_encode($val, $charset);
}

# XXX this is copied directly out of Courriel::Header
# eventually, this should be extracted out into something that could be shared
sub mime_encode {
    my $text    = shift;
    my $charset = Encode::find_encoding(shift)->mime_name();

    my $head = '=?' . $charset . '?B?';
    my $tail = '?=';

    my $base_length = 75 - ( length($head) + length($tail) );

    # This code is copied from Mail::Message::Field::Full in the Mail-Box
    # distro.
    my $real_length = int( $base_length / 4 ) * 3;

    my @result;
    my $chunk = q{};
    while ( length( my $chr = substr( $text, 0, 1, '' ) ) ) {
        my $chr = Encode::encode( $charset, $chr, 0 );

        if ( length($chunk) + length($chr) > $real_length ) {
            push @result, $head . MIME::Base64::encode_base64( $chunk, q{} ) . $tail;
            $chunk = q{};
        }

        $chunk .= $chr;
    }

    push @result, $head . MIME::Base64::encode_base64( $chunk, q{} ) . $tail
        if length $chunk;

    return join q{ }, @result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Encode - a private helper for MIME header encoding

=head1 VERSION

version 1.937

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

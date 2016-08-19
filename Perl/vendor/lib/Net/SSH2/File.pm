package Net::SSH2::File;

use strict;
use warnings;
use Carp;

# methods

# tie interface

sub PRINT {
    my $self = shift;
    my $sep = defined($,) ? $, : '';
    $self->write(join $sep, @_)
}

sub PRINTF {
    my $self = shift;
    $self->write(sprintf @_)
}

sub WRITE {
    my ($self, $buf, $len, $offset) = @_;
    $self->write(substr($buf, $offset, $len))
}

sub READLINE {
    my $self = shift;

    if (wantarray) {
        my @lines;
        my $line;
        push @lines, $line while defined($line = $self->READLINE);
        return @lines;
    }
    
    my ($line, $eol, $c) = ('', $/);
    $line .= $c while $line !~ /\Q$eol\E$/ and defined($c = $self->GETC);
    length($line) ? $line : undef
}

sub GETC {
    my $self = shift;
    my $buf;
    $self->read($buf, 1) ? $buf : undef
}

sub READ {
    my ($self, $rbuf, $len, $offset) = @_;
    my ($tmp, $count);
    return unless defined($count = $self->read($tmp, $len));
    substr($$rbuf, $offset) = $tmp;
    $count
}

sub CLOSE {
}

sub BINMODE {
}

sub EOF {
    0
}

1;
__END__

=head1 NAME

Net::SSH2::File - SSH2 SFTP file object

=head1 DESCRIPTION

An SFTP file object is created by the L<Net::SSH2::SFTP> C<open> method.

=head2 read ( buffer, size )

Read size bytes from the file into a given buffer.  Returns number of bytes
read, or undef on failure.

=head2 write ( buffer )

Write buffer to the remote file.

The C<libssh2_sftp_write> function wrapped by this method has a
complex and quite difficult (if not impossible at all) to use API. It
tries to hide the packet pipelining being done under the hood in order
to attain decent throughput.

Net::SSH2 can not hide that complexity without negatively affecting
the transmission speed so it provides just a thin wrapper for that
library function.

An excerpt from C<libssh2_sftp_write> manual page follows:

  WRITE AHEAD

  Starting in libssh2 version 1.2.8, the default behavior of libssh2
  is to create several smaller outgoing packets for all data you pass
  to this function and it will return a positive number as soon as the
  first packet is acknowledged from the server.

  This has the effect that sometimes more data has been sent off but
  isn't acked yet when this function returns, and when this function
  is subsequently called again to write more data, libssh2 will
  immediately figure out that the data is already received remotely.

  In most normal situation this should  not cause any problems, but it
  should be noted that if you've once called libssh2_sftp_write() with
  data and  it returns short, you  MUST still assume that  the rest of
  the data  might've been cached  so you need  to make sure  you don't
  alter that  data and think  that the version  you have in  your next
  function invoke will be detected or used.

  The reason  for this funny behavior  is that SFTP can  only send 32K
  data in each packet and it gets all packets acked individually. This
  means we  cannot use a  simple serial approach  if we want  to reach
  high performance even on high latency connections. And we want that.


=head2 stat

Returns file attributes; see Net::SSH2::SFTP::stat.

=head2 setstat ( key, value... )

Sets file attributes; see Net::SSH2::SFTP::setstat.

=head2 seek ( offset )

Set the file pointer offset.

=head2 tell

Returns the current file pointer offset.

=head1 SEE ALSO

L<Net::SSH2::SFTP>.

Check L<Net::SFTP::Foreign> for a high level, perlish and easy to use
SFTP client module. It can work on top of Net::SSH2 via the
L<Net::SFTP::Foreign::Backend::Net_SSH2> backend module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006 by David B. Robins E<lt>dbrobins@cpan.orgE<gt>;

Copyright (C) 2015 by Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>;

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

The documentation for this package contains and excerpt from libssh2
manual pages. You can consult the license of the libssh2 project for
the conditions regulating the copyright of that part.

=cut

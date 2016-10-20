package Net::SSH2;

our $VERSION = '0.58';

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

use Socket;
use IO::File;
use File::Basename;
use Errno;

use base 'Exporter';

# constants

my @EX_callback = qw(
        LIBSSH2_CALLBACK_DEBUG
        LIBSSH2_CALLBACK_DISCONNECT
        LIBSSH2_CALLBACK_IGNORE
        LIBSSH2_CALLBACK_MACERROR
        LIBSSH2_CALLBACK_X11
);

my @EX_channel = qw(
        LIBSSH2_CHANNEL_EXTENDED_DATA_IGNORE
        LIBSSH2_CHANNEL_EXTENDED_DATA_MERGE
        LIBSSH2_CHANNEL_EXTENDED_DATA_NORMAL
);

my @EX_socket = qw(
        LIBSSH2_SOCKET_BLOCK_INBOUND
        LIBSSH2_SOCKET_BLOCK_OUTBOUND
);

my @EX_trace = qw(
        LIBSSH2_TRACE_TRANS
        LIBSSH2_TRACE_KEX
        LIBSSH2_TRACE_AUTH
        LIBSSH2_TRACE_CONN
        LIBSSH2_TRACE_SCP
        LIBSSH2_TRACE_SFTP
        LIBSSH2_TRACE_ERROR
        LIBSSH2_TRACE_PUBLICKEY
        LIBSSH2_TRACE_SOCKET
);

my @EX_error = qw(
        LIBSSH2_ERROR_ALLOC
        LIBSSH2_ERROR_BANNER_NONE
        LIBSSH2_ERROR_BANNER_SEND
        LIBSSH2_ERROR_CHANNEL_CLOSED
        LIBSSH2_ERROR_CHANNEL_EOF_SENT
        LIBSSH2_ERROR_CHANNEL_FAILURE
        LIBSSH2_ERROR_CHANNEL_OUTOFORDER
        LIBSSH2_ERROR_CHANNEL_PACKET_EXCEEDED
        LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED
        LIBSSH2_ERROR_CHANNEL_UNKNOWN
        LIBSSH2_ERROR_CHANNEL_WINDOW_EXCEEDED
        LIBSSH2_ERROR_DECRYPT
        LIBSSH2_ERROR_FILE
        LIBSSH2_ERROR_HOSTKEY_INIT
        LIBSSH2_ERROR_HOSTKEY_SIGN
        LIBSSH2_ERROR_INVAL
        LIBSSH2_ERROR_INVALID_MAC
        LIBSSH2_ERROR_INVALID_POLL_TYPE
        LIBSSH2_ERROR_KEX_FAILURE
        LIBSSH2_ERROR_KEY_EXCHANGE_FAILURE
        LIBSSH2_ERROR_METHOD_NONE
        LIBSSH2_ERROR_METHOD_NOT_SUPPORTED
        LIBSSH2_ERROR_PASSWORD_EXPIRED
        LIBSSH2_ERROR_PROTO
        LIBSSH2_ERROR_PUBLICKEY_UNRECOGNIZED
        LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED
        LIBSSH2_ERROR_REQUEST_DENIED
        LIBSSH2_ERROR_SCP_PROTOCOL
        LIBSSH2_ERROR_SFTP_PROTOCOL
        LIBSSH2_ERROR_SOCKET_DISCONNECT
        LIBSSH2_ERROR_SOCKET_NONE
        LIBSSH2_ERROR_SOCKET_SEND
        LIBSSH2_ERROR_SOCKET_TIMEOUT
        LIBSSH2_ERROR_TIMEOUT
        LIBSSH2_ERROR_ZLIB
        LIBSSH2_ERROR_EAGAIN
);

my @EX_hash = qw(
        LIBSSH2_HOSTKEY_HASH_MD5
        LIBSSH2_HOSTKEY_HASH_SHA1
);

my @EX_method = qw(
        LIBSSH2_METHOD_COMP_CS
        LIBSSH2_METHOD_COMP_SC
        LIBSSH2_METHOD_CRYPT_CS
        LIBSSH2_METHOD_CRYPT_SC
        LIBSSH2_METHOD_HOSTKEY
        LIBSSH2_METHOD_KEX
        LIBSSH2_METHOD_LANG_CS
        LIBSSH2_METHOD_LANG_SC
        LIBSSH2_METHOD_MAC_CS
        LIBSSH2_METHOD_MAC_SC
);

my @EX_fxf = qw(
        LIBSSH2_FXF_APPEND
        LIBSSH2_FXF_CREAT
        LIBSSH2_FXF_EXCL
        LIBSSH2_FXF_READ
        LIBSSH2_FXF_TRUNC
        LIBSSH2_FXF_WRITE
);

my @EX_fx = qw(
        LIBSSH2_FX_BAD_MESSAGE
        LIBSSH2_FX_CONNECTION_LOST
        LIBSSH2_FX_DIR_NOT_EMPTY
        LIBSSH2_FX_EOF
        LIBSSH2_FX_FAILURE
        LIBSSH2_FX_FILE_ALREADY_EXISTS
        LIBSSH2_FX_INVALID_FILENAME
        LIBSSH2_FX_INVALID_HANDLE
        LIBSSH2_FX_LINK_LOOP
        LIBSSH2_FX_LOCK_CONFlICT
        LIBSSH2_FX_NOT_A_DIRECTORY
        LIBSSH2_FX_NO_CONNECTION
        LIBSSH2_FX_NO_MEDIA
        LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM
        LIBSSH2_FX_NO_SUCH_FILE
        LIBSSH2_FX_NO_SUCH_PATH
        LIBSSH2_FX_OK
        LIBSSH2_FX_OP_UNSUPPORTED
        LIBSSH2_FX_PERMISSION_DENIED
        LIBSSH2_FX_QUOTA_EXCEEDED
        LIBSSH2_FX_UNKNOWN_PRINCIPLE
        LIBSSH2_FX_WRITE_PROTECT
);

my @EX_sftp = qw(
        LIBSSH2_SFTP_ATTR_ACMODTIME
        LIBSSH2_SFTP_ATTR_EXTENDED
        LIBSSH2_SFTP_ATTR_PERMISSIONS
        LIBSSH2_SFTP_ATTR_SIZE
        LIBSSH2_SFTP_ATTR_UIDGID
        LIBSSH2_SFTP_LSTAT
        LIBSSH2_SFTP_OPENDIR
        LIBSSH2_SFTP_OPENFILE
        LIBSSH2_SFTP_PACKET_MAXLEN
        LIBSSH2_SFTP_READLINK
        LIBSSH2_SFTP_REALPATH
        LIBSSH2_SFTP_RENAME_ATOMIC
        LIBSSH2_SFTP_RENAME_NATIVE
        LIBSSH2_SFTP_RENAME_OVERWRITE
        LIBSSH2_SFTP_SETSTAT
        LIBSSH2_SFTP_STAT
        LIBSSH2_SFTP_SYMLINK
        LIBSSH2_SFTP_TYPE_BLOCK_DEVICE
        LIBSSH2_SFTP_TYPE_CHAR_DEVICE
        LIBSSH2_SFTP_TYPE_DIRECTORY
        LIBSSH2_SFTP_TYPE_FIFO
        LIBSSH2_SFTP_TYPE_REGULAR
        LIBSSH2_SFTP_TYPE_SOCKET
        LIBSSH2_SFTP_TYPE_SPECIAL
        LIBSSH2_SFTP_TYPE_SYMLINK
        LIBSSH2_SFTP_TYPE_UNKNOWN
        LIBSSH2_SFTP_VERSION
);

my @EX_disconnect = qw(
        SSH_DISCONNECT_AUTH_CANCELLED_BY_USER
        SSH_DISCONNECT_BY_APPLICATION
        SSH_DISCONNECT_COMPRESSION_ERROR
        SSH_DISCONNECT_CONNECTION_LOST
        SSH_DISCONNECT_HOST_KEY_NOT_VERIFIABLE
        SSH_DISCONNECT_HOST_NOT_ALLOWED_TO_CONNECT
        SSH_DISCONNECT_ILLEGAL_USER_NAME
        SSH_DISCONNECT_KEY_EXCHANGE_FAILED
        SSH_DISCONNECT_MAC_ERROR
        SSH_DISCONNECT_NO_MORE_AUTH_METHODS_AVAILABLE
        SSH_DISCONNECT_PROTOCOL_ERROR
        SSH_DISCONNECT_PROTOCOL_VERSION_NOT_SUPPORTED
        SSH_DISCONNECT_RESERVED
        SSH_DISCONNECT_SERVICE_NOT_AVAILABLE
        SSH_DISCONNECT_TOO_MANY_CONNECTIONS
);

our %EXPORT_TAGS = (
    all        => [
        @EX_callback, @EX_channel, @EX_error, @EX_socket, @EX_trace, @EX_hash,
        @EX_method, @EX_fx, @EX_fxf, @EX_sftp, @EX_disconnect,
    ],
    # ssh
    callback   => \@EX_callback,
    channel    => \@EX_channel,
    error      => \@EX_error,
    socket     => \@EX_socket,
    trace      => \@EX_trace,
    hash       => \@EX_hash,
    method     => \@EX_method,
    disconnect => \@EX_disconnect,
    # sftp
    fx         => \@EX_fx,
    fxf        => \@EX_fxf,
    sftp       => \@EX_sftp,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

# load IO::Socket::IP when available, otherwise fallback to IO::Socket::INET.

my $socket_class = do {
    local ($SIG{__DIE__}, $SIG{__WARN__}, $@, $!);
    eval {
        require IO::Socket::IP;
        'IO::Socket::IP';
    }
} || do {
    require IO::Socket::INET;
    'IO::Socket::INET'
};

# methods

sub new {
    my $class = shift;
    my %opts  = @_;

    my $self = $class->_new;

    $self->trace($opts{trace}) if defined $opts{trace};

    return $self;
}

sub connect {
    my $self = shift;
    croak "Net::SSH2::connect: not enough parameters" if @_ < 1;

    my $wantarray = wantarray;

    # try to connect, or get a file descriptor
    my ($fd, $sock);
    if (@_ == 1) {
        $sock = shift;
        if ($sock =~ /^\d{1,10}$/) {
            $fd = $sock;
        } elsif(ref $sock) {
            # handled below
        } else {
            @_ = ($sock, getservbyname(qw(ssh tcp)) || 22);
        }
    }

    my %opts = splice @_, 2 if @_ >= 4;
    $opts{Timeout} ||= 30;

    if (@_ == 2) {
        $sock = $socket_class->new(
            PeerHost => $_[0],
            PeerPort => $_[1],
            Timeout => $opts{Timeout},
        );

        if (not $sock) {
            if (not defined $wantarray) {
                croak "Net::SSH2: failed to connect to $_[0]:$_[1]: $!"
            } else {
                return; # to support ->connect ... or die
            }
        }

        $sock->sockopt(SO_LINGER, pack('SS', 0, 0));
    }

    # get a file descriptor
    $fd ||= fileno($sock);
    croak "Net::SSH2::connect: can't get file descriptor for $sock"
     unless defined $fd;
    if ($^O eq 'MSWin32') {
        require Win32API::File;
        $fd = Win32API::File::FdGetOsFHandle($fd);
    }

    # enable compression when requested and if the underlying libssh2
    # supports it
    $self->flag(COMPRESS => 1)
        if $opts{Compress} and ($self->version)[1] >= 0x010200;

    # pass it in, do protocol
    return $self->_startup($fd, $sock);
}

sub _auth_methods {
    return {
        'agent' => {
            ssh => 'agent',
            method => \&auth_agent,
            params => [qw(_fallback username)],
        },
        'hostbased'     => {
            ssh    => 'hostbased',
            method => \&auth_hostbased,
            params => [qw(username publickey privatekey
                       hostname local_username? passphrase?)],
        },
        'publickey'     => {
            ssh    => 'publickey',
            method => \&auth_publickey,
            params => [qw(username publickey? privatekey passphrase?)],
        },
        'keyboard'      => {
            ssh    => 'keyboard-interactive',
            method => \&auth_keyboard,
            params => [qw(_interact _fallback username cb_keyboard?)]
        },
        'keyboard-auto' => {
            ssh    => 'keyboard-interactive',
            method => \&auth_keyboard,
            params => [qw(username password)],
        },
        'password'      => {
            ssh    => 'password',
            method => \&auth_password,
            params => [qw(username password cb_password?)],
        },
        'password-interact'  => {
             ssh    => 'password',
             method => \&auth_password_interact,
             params => [qw(_interact _fallback username cb_password?)],
        },
        'none'          => {
            ssh    => 'none',
            method => \&auth_password,
            params => [qw(username)],
        },
    };
}

my @rank_default = qw(hostbased publickey keyboard-auto password agent keyboard password-interact none);

sub _auth_rank {
    my ($self, $rank) = @_;
    $rank ||= \@rank_default;
    my $libver = ($self->version)[1] || 0;
    return @$rank if $libver > 0x010203;
    return grep { $_ ne 'agent' } @$rank;
}

my $password_when_you_mean_passphrase_warned;
sub auth {
    my ($self, %p) = @_;

    my @rank = $self->_auth_rank(delete $p{rank});

    # if fallback is set, interact with the user even when a password
    # is given
    $p{fallback} = 1 unless defined $p{password} or defined $p{passphrase};

    TYPE: for(my $i = 0; $i < @rank; $i++) {
        my $type = $rank[$i];
        my $data = $self->_auth_methods->{$type};
        confess "unknown authentication method '$type'" unless $data;

        # do we have the required parameters?
        my @pass;
        for my $param(@{$data->{params}}) {
            my $p = $param;
            my $opt = $p =~ s/\?$//;
            my $pseudo = $p =~ s/^_//;

            if ($p eq 'passphrase' and not exists $p{$p} and defined $p{password}) {
                $p = 'password';
                $password_when_you_mean_passphrase_warned++
                    or carp "Using the key 'password' to refer to a passphrase is deprecated. Use 'passphrase' instead";
            }

            if ($pseudo) {
                next TYPE unless $p{$p};
            }
            else {
                next TYPE unless $opt or defined $p{$p};
                push @pass, $p{$p};  # if it's optional, store undef
            }
        }

        # invoke the authentication method
        return $type if $data->{method}->($self, @pass) and $self->auth_ok;
    }
    return;  # failure
}

my $term_readkey_unavailable_warned;
my $term_readkey_loaded;
sub _load_term_readkey {
    return 1 if $term_readkey_loaded ||= do {
        local ($@, $!, $SIG{__DIE__}, $SIG{__WARN__});
        eval { require Term::ReadKey; 1 }
    };

    carp "Unable to load Term::ReadKey, will not ask for passwords at the console!"
        unless $term_readkey_unavailable_warned++;
    return;
}

sub auth_password_interact {
    my ($self, $username, $cb) = @_;
    _load_term_readkey or return;
    local $| = 1;
    my $rc;
    for (0..2) {
        print "[user $username] password?\n";
        Term::ReadKey::ReadMode('noecho');
        my $password = Term::ReadKey::ReadLine(0);
        Term::ReadKey::ReadMode('normal');
        chomp $password;
        $rc = $self->auth_password($username, $password, $cb);
        last if $rc or $self->error != LIBSSH2_ERROR_AUTHENTICATION_FAILED();
        print "Password authentication failed!\n";
    }
    return $rc;
}

sub scp_get {
    my ($self, $remote, $path) = @_;
    $path = basename $remote if not defined $path;

    my %stat;
    $self->blocking(1);
    my $chan = $self->_scp_get($remote, \%stat) or return;

    # read and commit blocks until we're finished
    my $file;
    if (ref $path) {
        $file = $path;
    }
    else {
        my $mode = $stat{mode} & 0777;
        $file = IO::File->new($path, O_WRONLY | O_CREAT | O_TRUNC, $mode);
        unless ($file) {
            $self->_set_error(LIBSSH2_ERROR_FILE(), "Unable to open local file: $!");
            return;
        }
        binmode $file;
    }

    my $size = $stat{size};
    while ($size > 0) {
        my $bytes_read = $chan->read(my($buf), (($size > 40000 ? 40000 : $size)));
        if ($bytes_read) {
            $size -= $bytes_read;
            while (length $buf) {
                my $bytes_written = $file->syswrite($buf, length $buf);
                if ($bytes_written) {
                    substr $buf, 0, $bytes_written, '';
                }
                elsif ($! != Errno::EAGAIN() &&
                       $! != Errno::EINTR()) {
                    $self->_set_error(LIBSSH2_ERROR_FILE(), "Unable to write to local file: $!");
                    return;
                }
            }
        }
        elsif (!defined($bytes_read) and
               $self->error != LIBSSH2_ERROR_EAGAIN()) {
            return;
        }
    }

    # process SCP acknowledgment and send same
    $chan->read(my $eof, 1);
    $chan->write("\0");
    return 1;
}

sub scp_put {
    my ($self, $path, $remote) = @_;
    $remote = basename $path if not defined $remote;

    my $file;
    if (ref $path) {
        $file = $path;
    }
    else {
        $file = IO::File->new($path, O_RDONLY);
        unless ($file) {
            $self->_set_error(LIBSSH2_ERROR_FILE(), "Unable to open local file: $!");
            return;
        }
        binmode $file;
    }

    my @stat = $file->stat;
    unless (@stat) {
        $self->_set_error(LIBSSH2_ERROR_FILE(), "Unable to stat local file: $!");
        return;
    }

    my $mode = $stat[2] & 0777;  # mask off extras such as S_IFREG
    $self->blocking(1);
    my $chan = $self->_scp_put($remote, $mode, @stat[7, 8, 9]) or return;

    # read and transmit blocks until we're finished
    my $size = $stat[7];
    while ($size > 0) {
        my $bytes_read = $file->sysread(my($buf), ($size > 32768 ? 32768 : $size));
        if ($bytes_read) {
            $size -= $bytes_read;
            while (length $buf) {
                my $bytes_written = $chan->write($buf);
                if (defined $bytes_written) {
                    substr($buf, 0, $bytes_written, '');
                }
                elsif ($chan->error != LIBSSH2_ERROR_EAGAIN()) {
                    return;
                }
            }
        }
        elsif (defined $bytes_read) {
            $self->_set_error(LIBSSH2_ERROR_FILE(), "Unexpected end of local file");
            return;
        }
        elsif ($! != Errno::EAGAIN() and
               $! != Errno::EINTR()) {
            $self->_set_error(LIBSSH2_ERROR_FILE(), "Unable to read local file: $!");
            return;
        }
    }

    # send/receive SCP acknowledgement
    $chan->write("\0");
    return $chan->read(my($eof), 1) || undef;
}

my %Event;

sub _init_poll {
    for my $event(qw(
     pollin pollpri pollext pollout pollerr pollhup pollnval pollex
     session_closed channel_closed listener_closed
    )) {
        no strict 'refs';
        my $name = 'LIBSSH2_POLLFD_'.uc($event);
        (my $_event = $event) =~ s/^poll//;
        $Event{$_event} = &$name;
    }
}

sub poll {
    my ($self, $timeout, $event) = @_;
    $timeout ||= 0;

    # map incoming event structure (files to handles, events to integers)
    my @event;
    for my $in (@$event) {
        my ($handle, $events) = @{$in}{qw(handle events)};
        $handle = fileno $handle
         unless ref $handle and ref($handle) =~ /^Net::SSH2::/;
        my $out = { handle => $handle, events => 0 };
        $events = [$events] if not ref $events and $events =~ /^\D+$/;
        if (UNIVERSAL::isa($events, 'ARRAY')) {
            for my $name(@$events) {
                my $value = $Event{$name};
                croak "Net::SSH2::poll: can't translate event '$name'"
                 unless defined $value;
                $out->{events} |= $value;
            }
        } else {
            $out->{events} = $events || 0;
        }
        push @event, $out;
    }

    my $count = $self->_poll($timeout, \@event);
    return if not defined $count;

    # map received event structure (bitmask to hash of flags)
    my $i = 0;
    for my $item(@event) {
        my $revents = $item->{revents};
        my $out = $event->[$i++]->{revents} = { value => $revents };
        my $found = 0;  # can't mask off values, since there are dupes
        while (my ($name, $value) = each %Event) {
            $out->{$name} = 1, $found |= $value if $revents & $value;
        }
        $out->{unknown} = $revents & ~$found if $revents & ~$found;
    }
    $count
}

sub _cb_kbdint_response_default {
    my ($self, $user, $name, $instr, @prompt) = @_;
    _load_term_readkey or return;

    local $| = 1;
    my $prompt = "[user $user] ";
    $prompt .= "$name\n" if $name;
    $prompt .= "$instr\n" if $instr;
    $prompt =~ s/ $/\n/;
    print $prompt;

    my @out;
    for my $prompt(@prompt) {
        print STDERR "$prompt->{text}";

        Term::ReadKey::ReadMode('noecho') unless $prompt->{echo};
        chomp(my $value = Term::ReadKey::ReadLine(0));
        Term::ReadKey::ReadMode('normal') unless $prompt->{echo};
        push @out, $value;
    }
    @out
}

my $hostkey_warned;
sub hostkey {
    $hostkey_warned++ or carp "Net::SSH2 'hostkey' method is obsolete, use 'hostkey_hash' instead";
    shift->hostkey_hash(@_);
}

# mechanics

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Net::SSH2::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Net::SSH2', $VERSION);

_init_poll();

require Net::SSH2::Channel;
require Net::SSH2::SFTP;
require Net::SSH2::File;
require Net::SSH2::Listener;
require Net::SSH2::KnownHosts;

1;
__END__

=head1 NAME

Net::SSH2 - Support for the SSH 2 protocol via libssh2.

=head1 SYNOPSIS

  use Net::SSH2;

  my $ssh2 = Net::SSH2->new();

  $ssh2->connect('example.com') or die $!;

  if ($ssh2->auth_keyboard('fizban')) {
      my $chan = $ssh2->channel();
      $chan->exec('program');

      my $sftp = $ssh2->sftp();
      my $fh = $sftp->open('/etc/passwd') or die;
      print $_ while <$fh>;
  }

=head1 DESCRIPTION

C<Net::SSH2> is a perl interface to the libssh2 (L<http://www.libssh2.org>)
library.  It supports the SSH2 protocol (there is no support for SSH1)
with all of the key exchanges, ciphers, and compression of libssh2.

Unless otherwise indicated, methods return a true value on success and
false on failure; use the error method to get extended error information.

The typical order is to create the SSH2 object, set up the connection methods
you want to use, call connect, authenticate with one of the C<auth> methods,
then create channels on the connection to perform commands.

=head1 EXPORTS

Exports the following constant tags:

=over 4

=item all

All constants.

=back

ssh constants:

=over 4

=item callback

=item channel

=item error

=item socket

=item trace

Tracing constants for use with C<< ->trace >> and C<< ->new(trace => ...) >>.

=item hash

Key hash constants.

=item method

=item disconnect

Disconnect type constants.

=back

SFTP constants:

=over 4

=item fx

=item fxf

=item sftp

=back

=head1 METHODS

=head2 new

Create new SSH2 object.

To turn on tracing with a debug build of libssh2 use:

    my $ssh2 = Net::SSH2->new(trace => -1);

=head2 banner ( text )

Set the SSH2 banner text sent to the remote host (prepends required "SSH-2.0-").

=head2 version

In scalar context, returns libssh2 version/patch e.g. 0.18 or "0.18.0-20071110".
In list context, returns that version plus the numeric version (major, minor,
and patch, each encoded as 8 bits, e.g. 0x001200 for version 0.18) and the
default banner text (e.g. "SSH-2.0-libssh2_0.18.0-20071110").

=head2 error

Returns the last error code; returns false if no error.  In list context,
returns (code, error name, error string).

Note that the returned error value is only meaningful after some other
method indicates an error by returning false.

=head2 sock

Returns a reference to the underlying L<IO::Socket> object (usually a
derived class as L<IO::Socket::IP> or L<IO::Socket::INET>), or
C<undef> if not yet connected.

=head2 trace

Calls libssh2_trace with supplied bitmask, to enable all tracing use:

    $ssh2->trace(-1);

You need a debug build of libssh2 with tracing support.

=head2 timeout ( timeout_ms )

Enables a global timeout (in milliseconds) which will affect every action.

libssh2 version 1.2.9 or higher is required to use this method.

=head2 method ( type [, values... ] )

Sets or returns a method preference; for get, pass in the type only; to set,
pass in either a list of values or a comma-separated string.  Values can only
be queried after the session is connected.

The following methods can be set or queried:

=over 4

=item KEX

Key exchange method names. Supported values:

=over 4

=item diffie-hellman-group1-sha1

Diffie-Hellman key exchange with SHA-1 as hash, and Oakley Group 2 (see RFC
2409).

=item diffie-hellman-group14-sha1

Diffie-Hellman key exchange with SHA-1 as hash, and Oakley Group 14 (see RFC
3526).

=item diffie-hellman-group-exchange-sha1

Diffie-Hellman key exchange with SHA-1 as hash, using a safe-prime/generator
pair (chosen by server) of arbitrary strength (specified by client) (see IETF
draft secsh-dh-group-exchange).

=back

=item HOSTKEY

Public key algorithms. Supported values:

=over 4

=item ssh-dss

Based on the Digital Signature Standard (FIPS-186-2).

=item ssh-rsa

Based on PKCS#1 (RFC 3447).

=back

=item CRYPT_CS

Encryption algorithm from client to server. Supported algorithms:

=over 4

=item aes256-cbc

AES in CBC mode, with 256-bit key.

=item rijndael-cbc@lysator.liu.se

Alias for aes256-cbc.

=item aes192-cbc

AES in CBC mode, with 192-bit key.

=item aes128-cbc

AES in CBC mode, with 128-bit key.

=item blowfish-cbc

Blowfish in CBC mode.

=item arcfour

ARCFOUR stream cipher.

=item cast128-cbc

CAST-128 in CBC mode.

=item 3des-cbc

Three-key 3DES in CBC mode.

=item none

No encryption.

=back

=item CRYPT_SC

Encryption algorithm from server to client. See L<CRYPT_CS> for supported
algorithms.

=item MAC_CS

Message Authentication Code (MAC) algorithms from client to server. Supported
values:

=over 4

=item hmac-sha1

SHA-1 with 20-byte digest and key length.

=item hmac-sha1-96

SHA-1 with 20-byte key length and 12-byte digest length.

=item hmac-md5

MD5 with 16-byte digest and key length.

=item hmac-md5-96

MD5 with 16-byte key length and 12-byte digest length.

=item hmac-ripemd160

RIPEMD-160 algorithm with 20-byte digest length.

=item hmac-ripemd160@openssh.com

Alias for hmac-ripemd160.

=item none

No encryption.

=back

=item MAC_SC

Message Authentication Code (MAC) algorithms from server to client. See
L<MAC_SC> for supported algorithms.

=item COMP_CS

Compression methods from client to server. Supported values:

=over 4

=item zlib

The "zlib" compression method as described in RFC 1950 and RFC 1951.

=item none

No compression

=back

=item COMP_SC

Compression methods from server to client. See L<COMP_CS> for supported
compression methods.

=back

=head2 connect ( handle | host [, port [, Timeout => secs ] [, Compress => 1]] )

Accepts a handle over which to conduct the SSH 2 protocol.  The handle may be:

=over 4

=item an C<IO::*> object

=item a glob reference

=item an integer file descriptor

=item a host name and port

In order to handle IPv6 addresses the optional module
L<IO::Socket::IP> needs to be installed (otherwise the module will use
the IPv4 only core module L<IO::Socket::INET> to establish the
connection).

=back

=head2 disconnect ( [description [, reason [, language]]] )

Send a clean disconnect message to the remote server.  Default values are empty
strings for description and language, and C<SSH_DISCONNECT_BY_APPLICATION> for
the reason.

=head2 hostkey_hash ( hash type )

Returns a hash of the host key; note that the key is raw data and may contain
nulls or control characters.  The type may be:

=over 4

=item MD5 (16 bytes)

=item SHA1 (20 bytes)

=back

Note: in previous versions of the module this method was called
C<hostkey>.

=head2 remote_hostkey

Returns the public key of the remote host and its type which is one of
C<LIBSSH2_HOSTKEY_TYPE_RSA>, C<LIBSSH2_HOSTKEY_TYPE_DSS>, or
C<LIBSSH2_HOSTKEY_TYPE_UNKNOWN>.

=head2 auth_list ( [username] )

Get a list (or comma-separated string in scalar context) of authentication
methods supported by the server; or returns C<undef>.  If C<undef> is returned
and L<auth_ok> is true, the server accepted an unauthenticated session for the
given username.

=head2 auth_ok

Returns true iff the session is authenticated.

=head2 auth_password ( username [, password [, callback ]] )

Authenticate using a password (C<PasswordAuthentication> must be
enabled in C<sshd_config> or equivalent for this to work.)

If the password has expired, if a callback code reference was given, it's
called as C<callback($self, $username)> and should return a password.  If
no callback is provided, LIBSSH2_ERROR_PASSWORD_EXPIRED is returned.

=head2 auth_password_interact ( username [, callback])

Prompts the user for the password interactively using Term::ReadKey.

=head2 auth_publickey ( username, publickey_path, privatekey_path [, passphrase ] )

Note that public key and private key are names of files containing the keys!

Authenticate using keys and an optional passphrase.

When libssh2 is compiled using OpenSSL as the crypto backend, passing
this method C<undef> as the public key argument is acceptable (OpenSSH
is able to extract the public key from the private one).

=head2 auth_publickey_frommemory ( username, publickey_blob, privatekey_blob [, passphrase ] )

Authenticate using the given public/private key and an optional
passphrase. The keys must be PEM encoded.

This method requires libssh2 1.6.0 or later compiled with the OpenSSL
backend.

=head2 auth_hostbased ( username, publickey, privatekey, hostname,
 [, local username [, passphrase ]] )

Host-based authentication using an optional passphrase.  The local username
defaults to be the same as the remote username.

=head2 auth_keyboard ( username, password | callback )

Authenticate using "keyboard-interactive".  Takes either a password, or a
callback code reference which is invoked as C<callback-E<gt>(self, username,
name, instruction, prompt...)> (where each prompt is a hash with C<text> and
C<echo> keys, signifying the prompt text and whether the user input should be
echoed, respectively) which should return an array of responses.

If only a username is provided, the default callback will handle standard
interactive responses; L<Term::ReadKey> is required.

=head2 auth_agent ( username )

Try to authenticate using ssh-agent. This requires libssh2 version 1.2.3 or
later.

=head2 auth ( ... )

This is a general, prioritizing authentication mechanism that can use any
of the previous methods.  You provide it some parameters and (optionally)
a ranked list of methods you want considered (defaults to all).  It will
remove any unsupported methods or methods for which it doesn't have parameters
(e.g. if you don't give it a public key, it can't use publickey or hostkey),
and try the rest, returning whichever one succeeded or a false value if they
all failed. If a parameter is passed with an undef value, a default value
will be supplied if possible.

The parameters are:

=over 4

=item rank

An optional ranked list of methods to try.  The names should be the
names of the L<Net::SSH2> C<auth> methods, e.g. 'keyboard' or
'publickey', with the addition of 'keyboard-auto' for automated
'keyboard-interactive' and 'password-interact' that prompts the user
for the password interactively.

=item username

=item password

=item publickey

=item privatekey

=item passphrase

As in the methods, publickey and privatekey are filenames.

=item hostname

=item local_username

=item interact

If this is set to a true value, interactive methods will be considered.

=item fallback

If a password is given but authentication using it fails, the module
will fall back to ask the user for another password if this
parameter is set to a true value.

=item cb_keyboard

L<auth_keyboard> callback.

=item cb_password

L<auth_password> callback.

=back

For historical reasons and in order to maintain backward compatibility
with older versions of the module, when the C<password> argument is
given, it is also used as the passphrase (and a deprecation warning
generated).

In order to avoid that behaviour the C<passphrase> argument must be
also passed (it could be C<undef>). For instance:

  $ssh2->auth(username => $user,
              privatekey => $privatekey_path,
              publickey => $publickey_path,
              password => $password,
              passphrase => undef);

This work around will be removed in a not too distant future version
of the module.

=head2 flag (key, value)

Sets the given session flag.

The currently supported flag values are:

=over 4

=item COMPRESS

If set before the connection negotiation is performed, compression
will be negotiated for this connection.

Compression can also be enabled passing the C<Compress> option
L</connect>.

=item SIGPIPE

if set, Net::SSH2/libssh2 will not attempt to block SIGPIPEs but will
let them trigger from the underlying socket layer.

=back

=head2 keepalive_config(want_reply, interval)

Set how often keepalive messages should be sent.

C<want_reply> indicates whether the keepalive messages should request
a response from the server. C<interval> is number of seconds that can
pass without any I/O.

=head2 keepalive_send

Send a keepalive message if needed.

On failure returns undef. On success returns how many seconds you can
sleep after this call before you need to call it again.

Note that the underlying libssh2 function C<libssh2_keepalive_send>
can not recover from EAGAIN errors. If this method fails with such
error, the SSH connection may become corrupted.

=head2 channel ( [type, [window size, [packet size]]] )

Creates and returns a new channel object.  The default type is "session".
See L<Net::SSH2::Channel>.

=head2 tcpip ( host, port [, shost, sport ] )

Creates a TCP connection from the remote host to the given host:port,
returning a new channel.

The C<shost> and C<sport> arguments are merely informative and passed
to the remote SSH server as the origin of the connection. They default
to 127.0.0.1:22.

Note that this method does B<not> open a new port on the local machine
and forwards incoming connections to the remote side.

=head2 listen ( port [, host [, bound port [, queue size ]]] )

Sets up a TCP listening port on the remote host.  Host defaults to 0.0.0.0;
if bound port is provided, it should be a scalar reference in which the bound
port is returned.  Queue size specifies the maximum number of queued connections
allowed before the server refuses new connections.

Returns a new Net::SSH2::Listener object.

=head2 scp_get ( remote [, local ] )

Retrieve a file with scp; local path defaults to basename of remote.  C<local>
may be an IO object (e.g. IO::File, IO::Scalar).

=head2 scp_put ( local [, remote ] )

Send a file with scp; remote path defaults to same as local.  C<local> may be
an IO object instead of a filename (but it must have a valid stat method).

=head2 sftp

Return SecureFTP interface object (see L<Net::SSH2::SFTP>).

=head2 public_key

Return public key interface object (see L<Net::SSH2::PublicKey>).

=head2 known_hosts

Returns known hosts interface object (see L<Net::SSH2::KnownHosts>).

=head2 poll ( timeout, arrayref of hashes )

Pass in a timeout in milliseconds and an arrayref of hashes with the following
keys:

=over 4

=item handle

May be a L<Net::SSH2::Channel> or L<Net::SSH2::Listener> object, integer file
descriptor, or perl file handle.

=item events

Requested events.  Combination of LIBSSH2_POLLFD_* constants (with the POLL
prefix stripped if present), or an arrayref of the names ('in', 'hup' etc.).

=item revents

Returned events.  Returns a hash with the (lowercased) names of the received
events ('in', 'hup', etc.) as keys with true values, and a C<value> key with
the integer value.

=back

Returns undef on error, or the number of active objects.

=head2 block_directions

Get the blocked direction when a function returns LIBSSH2_ERROR_EAGAIN, returns
LIBSSH2_SOCKET_BLOCK_INBOUND or LIBSSH2_SOCKET_BLOCK_OUTBOUND from the socket
export group.

=head2 debug ( state )

Class method (affects all Net::SSH2 objects).  Pass 1 to enable, 0 to disable.
Debug output is sent to stderr via C<warn>.

=head2 blocking ( flag )

Enable or disable blocking.  Note that if blocking is disabled, methods that
create channels may fail, e.g. C<channel>, C<SFTP>, C<scp_*>.

=head1 SEE ALSO

L<Net::SSH2::Channel>, L<Net::SSH2::Listener>,
L<Net::SSH2::SFTP>, L<Net::SSH2::File>, L<Net::SSH2::Dir>.

LibSSH2 documentation at L<http://www.libssh2.org>.

IETF Secure Shell (secsh) working group at
L<http://www.ietf.org/html.charters/secsh-charter.html>.

L<Net::SSH::Any> and L<Net::SFTP::Foreign> integrate nicely with Net::SSH2.

Other Perl modules related to SSH you may find interesting:
L<Net::OpenSSH>, L<Net::SSH::Perl>, L<Net::OpenSSH::Parallel>,
L<Net::OpenSSH::Compat>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2010 by David B. Robins (dbrobins@cpan.org).

Copyright (C) 2010 - 2015 by Rafael Kitover (rkitover@cpan.org).

Copyright (C) 2011 - 2015 by Salvador FandiE<ntilde>o (salva@cpan.org).

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

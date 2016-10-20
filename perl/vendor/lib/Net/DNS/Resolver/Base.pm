package Net::DNS::Resolver::Base;

#
# $Id: Base.pm 1458 2016-02-23 10:27:04Z willem $
#
use vars qw($VERSION);
$VERSION = (qw$LastChangedRevision: 1458 $)[1];


use strict;
use integer;
use Carp;
use IO::Select;
use IO::Socket;

use Net::DNS::RR;
use Net::DNS::Packet;

use constant INT16SZ  => 2;
use constant PACKETSZ => 512;

#
#  Implementation notes wrt IPv6 support when using perl before 5.20.0.
#
#  In general we try to be gracious to those stacks that do not have IPv6 support.
#  We test that by means of the availability of IO::Socket::INET6
#
#  We have chosen not to use mapped IPv4 addresses, there seem to be
#  issues with this; as a result we use separate sockets for each
#  family type.
#
#  inet_pton is not available on WIN32, so we only use the getaddrinfo
#  call to translate IP addresses to socketaddress
#
#  The configuration options force_v4, force_v6, prefer_v4 and prefer_v6
#  are provided to control IPv6 behaviour for test purposes.
#
# Olaf Kolkman, RIPE NCC, December 2003.


use constant USE_SOCKET_IP => defined eval 'use Socket 1.98; require IO::Socket::IP';

use constant USE_SOCKET_INET => defined eval 'require IO::Socket::INET';

use constant USE_SOCKET_INET6 => defined eval 'require IO::Socket::INET6';

use constant IPv4 => USE_SOCKET_IP || USE_SOCKET_INET;
use constant IPv6 => USE_SOCKET_IP || USE_SOCKET_INET6;


# If SOCKSified Perl, use TCP instead of UDP and keep the socket open.
use constant SOCKS => scalar eval 'require Config; $Config::Config{usesocks}';


use constant UTIL => defined eval 'require Scalar::Util';

sub _tainted { UTIL ? Scalar::Util::tainted(shift) : undef }

sub _untaint {
	map { m/^(.*)$/; $1 } grep defined, @_;
}


#
# Set up a closure to be our class data.
#
{
	my $defaults = bless {
		nameserver4	=> ['127.0.0.1'],
		nameserver6	=> ['::1'],
		port		=> 53,
		srcaddr4	=> '0.0.0.0',
		srcaddr6	=> '::',
		srcport		=> 0,
		searchlist	=> [],
		retrans		=> 5,
		retry		=> 4,
		usevc		=> ( SOCKS ? 1 : 0 ),
		igntc		=> 0,
		recurse		=> 1,
		defnames	=> 1,
		dnsrch		=> 1,
		debug		=> 0,
		errorstring	=> 'unknown error or no error',
		tsig_rr		=> undef,
		answerfrom	=> '',
		tcp_timeout	=> 120,
		udp_timeout	=> 30,
		persistent_tcp	=> ( SOCKS ? 1 : 0 ),
		persistent_udp	=> 0,
		dnssec		=> 0,
		adflag		=> 0,	# see RFC6840, 5.7
		cdflag		=> 0,	# see RFC6840, 5.9
		udppacketsize	=> 0,	# value bounded below by PACKETSZ
		force_v4	=> ( IPv6 ? 0 : 1 ),
		force_v6	=> 0,	# only relevant if IPv6 is supported
		prefer_v4	=> ( IPv6 ? 1 : 0 ),
		},
			__PACKAGE__;


	sub _defaults { return $defaults; }
}


# These are the attributes that the user may specify in the new() constructor.
my %public_attr = map { $_ => $_ } qw(
		nameserver
		nameservers
		port
		srcaddr
		srcport
		domain
		searchlist
		retrans
		retry
		usevc
		igntc
		recurse
		defnames
		dnsrch
		debug
		tcp_timeout
		udp_timeout
		persistent_tcp
		persistent_udp
		dnssec
		adflag
		cdflag
		force_v4
		force_v6
		prefer_v4
		prefer_v6
		);


my $initial;

sub new {
	my ( $class, %args ) = @_;

	my $self;
	my $base = $class->_defaults;
	my $init = $initial;
	$initial ||= bless {%$base}, $class;
	if ( my $file = $args{config_file} ) {
		$self = bless {%$initial}, $class;
		$self->_read_config_file($file);		# user specified config
		$self->nameservers( _untaint $self->nameservers );
		$self->searchlist( _untaint $self->searchlist );
		%$base = %$self unless $init;			# define default configuration

	} elsif ($init) {
		$self = bless {%$base}, $class;

	} else {
		$class->_init();				# define default configuration
		$self = bless {%$base}, $class;
	}

	while ( my ( $attr, $value ) = each %args ) {
		next unless $public_attr{$attr};
		my $ref = ref($value);
		croak "usage: $class->new( $attr => [...] )"
				if $ref && ( $ref ne 'ARRAY' );
		$self->$attr( $ref ? @$value : $value );
	}

	return $self;
}


my %resolv_conf = (			## map traditional resolv.conf option names
	attempts => 'retry',
	inet6	 => 'prefer_v6',
	timeout	 => 'retrans',
	);

my %env_option = (			## any resolver attribute except as listed below
	%public_attr,
	%resolv_conf,
	map { $_ => 0 } qw(nameserver nameservers domain searchlist),
	);

sub _read_env {				## read resolver config environment variables
	my $self = shift;

	$self->nameservers( map split, $ENV{RES_NAMESERVERS} ) if exists $ENV{RES_NAMESERVERS};

	$self->domain( $ENV{LOCALDOMAIN} ) if exists $ENV{LOCALDOMAIN};

	$self->searchlist( map split, $ENV{RES_SEARCHLIST} ) if exists $ENV{RES_SEARCHLIST};

	if ( exists $ENV{RES_OPTIONS} ) {
		foreach ( map split, $ENV{RES_OPTIONS} ) {
			my ( $name, $val ) = split( m/:/, $_, 2 );
			my $attribute = $env_option{$name} || next;
			$val = 1 unless defined $val;
			$self->$attribute($val);
		}
	}
}


sub _read_config_file {			## read resolver config file
	my $self = shift;
	my $file = shift;

	my @ns;

	local *FILE;

	open( FILE, $file ) or croak "Could not open $file: $!";

	local $_;
	while (<FILE>) {
		s/[;#].*$//;					# strip comments

		/^nameserver/ && do {
			my ( $keyword, @ip ) = grep defined, split;
			push @ns, @ip;
			next;
		};

		/^option/ && do {
			my ( $keyword, @option ) = grep defined, split;
			foreach (@option) {
				my ( $name, $val ) = split( m/:/, $_, 2 );
				my $attribute = $resolv_conf{$name} || next;
				$val = 1 unless defined $val;
				$self->$attribute($val);
			}
			next;
		};

		/^domain/ && do {
			my ( $keyword, $domain ) = grep defined, split;
			$self->domain($domain);
			next;
		};

		/^search/ && do {
			my ( $keyword, @searchlist ) = grep defined, split;
			$self->searchlist(@searchlist);
			next;
		};
	}

	close(FILE);

	$self->nameservers(@ns);
}


sub string {
	my $self = shift;
	$self = $self->_defaults unless ref($self);

	my @nslist = $self->nameservers();
	my $domain = $self->domain;
	return <<END;
;; RESOLVER state:
;; domain	= $domain
;; searchlist	= @{$self->{searchlist}}
;; nameservers	= @nslist
;; defnames	= $self->{defnames}	dnsrch		= $self->{dnsrch}
;; retrans	= $self->{retrans}	retry		= $self->{retry}
;; recurse	= $self->{recurse}	igntc		= $self->{igntc}
;; usevc	= $self->{usevc}	port		= $self->{port}
;; tcp_timeout	= $self->{tcp_timeout}	persistent_tcp	= $self->{persistent_tcp}
;; udp_timeout	= $self->{udp_timeout}	persistent_udp	= $self->{persistent_udp}
;; prefer_v4	= $self->{prefer_v4}	force_v4	= $self->{force_v4}
;; debug	= $self->{debug}	force_v6	= $self->{force_v6}
END

}


sub print { print &string; }


sub domain {
	my $self   = shift;
	my ($head) = $self->searchlist(@_);
	my @list   = grep defined, $head;
	wantarray ? @list : "@list";
}

sub searchlist {
	my $self = shift;
	$self = $self->_defaults unless ref($self);

	return $self->{searchlist} = [@_] unless defined wantarray;
	$self->{searchlist} = [@_] if scalar @_;
	my @searchlist = @{$self->{searchlist}};
}


sub nameservers {
	my $self = shift;
	$self = $self->_defaults unless ref($self);

	my ( @ipv4, @ipv6 );
	foreach my $ns ( grep defined, @_ ) {
		do { push @ipv6, $ns; next } if _ipv6($ns);
		do { push @ipv4, $ns; next } if _ipv4($ns);

		my $defres = ref($self)->new( debug => $self->{debug} );
		$defres->{persistent} = $self->{persistent};

		my $names  = {};
		my $packet = $defres->search( $ns, 'A' );
		my @iplist = _cname_addr( $packet, $names );

		if (IPv6) {
			$packet = $defres->search( $ns, 'AAAA' );
			push @iplist, _cname_addr( $packet, $names );
		}

		$self->errorstring( $defres->errorstring );

		my %address = map { ( $_ => $_ ) } @iplist;	# tainted
		my @unique = values %address;
		carp "unresolvable name: $ns" unless @unique;
		push @ipv4, grep _ipv4($_), @unique;
		push @ipv6, grep _ipv6($_), @unique;
	}

	unless ( defined wantarray ) {
		$self->{nameserver4} = \@ipv4;
		$self->{nameserver6} = \@ipv6;
		return;
	}

	if ( scalar @_ ) {
		$self->{nameserver4} = \@ipv4;
		$self->{nameserver6} = \@ipv6;
	}

	my @ns4 = $self->force_v6 ? () : @{$self->{nameserver4}};
	my @ns6 = $self->force_v4 ? () : @{$self->{nameserver6}};
	my @returnval = $self->{prefer_v4} ? ( @ns4, @ns6 ) : ( @ns6, @ns4 );

	return @returnval if scalar @returnval;

	my $error = 'no nameservers';
	$error = 'IPv4 transport disabled' if scalar(@ns4) < scalar @{$self->{nameserver4}};
	$error = 'IPv6 transport disabled' if scalar(@ns6) < scalar @{$self->{nameserver6}};
	$self->errorstring($error);
	return @returnval;
}

sub nameserver { &nameservers; }				# uncoverable pod

sub _cname_addr {

	# TODO 20081217
	# This code does not follow CNAME chains, it only looks inside the packet.
	# Out of bailiwick will fail.
	my @null;
	my $packet = shift || return @null;
	my $names = shift;

	map $names->{$_->qname}++, $packet->question;
	map $names->{$_->cname}++, grep $_->can('cname'), $packet->answer;

	my @addr = grep $_->can('address'), $packet->answer;
	map $_->address, grep $names->{$_->name}, @addr;
}


sub answerfrom {
	my $self = shift;
	$self->{answerfrom} = shift if scalar @_;
	return $self->{answerfrom};
}

sub errorstring {
	my $self = shift;
	$self->{errorstring} = shift if scalar @_;
	return $self->{errorstring};
}

sub _reset_errorstring {
	my $self = shift;
	$self->errorstring( $self->_defaults->{errorstring} );
}


sub query {
	my $self = shift;
	my $name = shift || '.';

	# resolve name containing no dots or colons by appending domain
	my @sfix = $self->{defnames} && $name !~ m/[:.]/ ? $self->domain : ();
	my $fqdn = join '.', $name, @sfix;

	$self->_diag( 'query(', $fqdn, @_, ')' );

	my $packet = $self->send( $fqdn, @_ ) || return;

	return $packet->header->ancount ? $packet : undef;
}


sub search {
	my $self = shift;

	return $self->query(@_) unless $self->{dnsrch};

	my $name = shift || '.';
	my @sfix = @{$self->{searchlist}};
	my @list = $name =~ m/[.]/ ? ( undef, @sfix ) : ( @sfix, undef );

	foreach my $suffix ( $name =~ m/:|\.\d*$/ ? undef : @list ) {
		my $fqname = $suffix ? join( '.', $name, $suffix ) : $name;

		$self->_diag( 'search(', $fqname, @_, ')' );

		my $packet = $self->send( $fqname, @_ ) || next;

		return $packet->header->ancount ? $packet : next;
	}

	return undef;
}


sub send {
	my $self	= shift;
	my $packet	= $self->_make_query_packet(@_);
	my $packet_data = $packet->data;

	return $self->_send_tcp( $packet, $packet_data )
			if $self->{usevc} || length $packet_data > $self->_packetsz;

	my $ans = $self->_send_udp( $packet, $packet_data ) || return;

	return $ans if $self->{igntc};
	return $ans unless $ans->header->tc;

	$self->_diag('packet truncated: retrying using TCP');
	$self->_send_tcp( $packet, $packet_data );
}


sub _send_tcp {
	my ( $self, $packet, $packet_data ) = @_;

	my $length = length $packet_data;
	$self->_reset_errorstring;
	my @ns = $self->nameservers();
	my $lastanswer;

	foreach my $ns (@ns) {
		my $socket = $self->_create_tcp_socket($ns) || next;

		$self->_diag( 'tcp send:', $length, 'bytes' );

		$socket->send( pack 'n a*', $length, $packet_data );
		$self->errorstring($!);

		my $sel = IO::Select->new($socket);
		if ( $sel->can_read( $self->{tcp_timeout} ) ) {
			my $buffer = _read_tcp($socket);
			$self->answerfrom($ns);
			$self->_diag( "answer from [$ns]", length($buffer), 'bytes' );

			my $ans = Net::DNS::Packet->new( \$buffer, $self->{debug} );
			$self->errorstring($@);

			if ($ans) {
				next unless $ans->verify($packet);

				$ans->answerfrom($ns);

				my $rcode = $ans->header->rcode;
				return $ans if $rcode eq "NOERROR";
				return $ans if $rcode eq "NXDOMAIN";

				$self->_diag("RCODE: $rcode; try next nameserver");
				$lastanswer = $ans;
			}
		}
	}

	$self->errorstring( $lastanswer->header->rcode ) if $lastanswer;
	$self->_diag( $self->errorstring );
	return $lastanswer;
}


sub _send_udp {
	my ( $self, $packet, $packet_data ) = @_;

	$self->_reset_errorstring;

	# Constructing an array of arrays that contain 3 elements:
	# The socket, IP address and dst_sockaddr
	my $port = $self->{port};
	my $sel	 = IO::Select->new();
	my @ns;

	foreach my $ip ( $self->nameservers ) {
		my $socket = $self->_create_udp_socket($ip) || next;
		my $dst_sockaddr = $self->_create_dst_sockaddr( $ip, $port );
		push @ns, [$socket, $ip, $dst_sockaddr];
	}

	my $retrans = $self->{retrans} || 1;
	my $retry   = $self->{retry}   || 1;
	my $servers = scalar(@ns);
	my $timeout = $servers ? do { no integer; $retrans / $servers } : 0;

	my $lastanswer;

	# Perform each round of retries.
RETRY: for ( 1 .. $retry ) {					# assumed to be a small number

		# Try each nameserver.
NAMESERVER: foreach my $ns (@ns) {
			my ( $socket, $ip, $dst_sockaddr, $failed ) = @$ns;
			next if $failed;

			$self->_diag("udp send [$ip]:$port");

			unless ( $socket->send( $packet_data, 0, $dst_sockaddr ) ) {
				$self->_diag( $ns->[3] = $self->errorstring($!) );
				next;
			}

			# handle failure to detect taint inside socket->send()
			# uncoverable branch true
			die 'Insecure dependency while running with -T switch' if _tainted($dst_sockaddr);

			$sel->add($ns);

			my @ready = $sel->can_read($timeout);
			foreach my $ready (@ready) {
				my ( $socket, $ip ) = @$ready;
				$sel->remove($ready);

				my $peer = $socket->peerhost;
				$self->answerfrom($peer);

				my $buffer = _read_udp( $socket, $self->_packetsz );
				$self->errorstring( $ns->[3] = $! ) unless $buffer;
				$self->_diag( "answer from [$peer]", length($buffer), 'bytes' );

				my $ans = Net::DNS::Packet->new( \$buffer, $self->{debug} );
				$self->errorstring($@);

				if ($ans) {
					my $header = $ans->header;
					next unless $header->qr;
					next unless $header->id == $packet->header->id;

					unless ( $ans->verify($packet) ) {
						$self->errorstring( $ns->[3] = $ans->verifyerr );
						next;
					}

					$ans->answerfrom($peer);

					my $rcode = $header->rcode;
					return $ans if $rcode eq "NOERROR";
					return $ans if $rcode eq "NXDOMAIN";

					my $msg = $ns->[3] = "RCODE: $rcode";
					$self->_diag("$msg; try next nameserver");
					$lastanswer = $ans;
				}
			}					#SELECTOR LOOP
		}						#NAMESERVER LOOP
		no integer;
		$timeout += $timeout;
	}							#RETRY LOOP

	my $error = scalar( $sel->handles ) ? 'query timed out' : $self->errorstring;
	$error = $lastanswer->header->rcode if $lastanswer;
	$self->_diag( $self->errorstring($error) );
	return $lastanswer;
}


sub bgsend {
	my $self	= shift;
	my $packet	= $self->_make_query_packet(@_);
	my $packet_data = $packet->data;

	return $self->_bgsend_tcp( $packet, $packet_data )
			if $self->{usevc} || length $packet_data > $self->_packetsz;

	return $self->_bgsend_udp( $packet, $packet_data );
}


sub _bgsend_tcp {
	my ( $self, $packet, $packet_data ) = @_;

	$self->_reset_errorstring;

	my $port = $self->{port};

	foreach my $ip ( $self->nameservers ) {
		my $socket = $self->_create_tcp_socket($ip) || next;

		$self->_diag( 'bgsend', "[$ip]:$port" );

		my $length = length $packet_data;
		my $tcp_packet = pack 'n a*', $length, $packet_data;

		$socket->send($tcp_packet);
		$self->errorstring($!);

		my $expire = time() + $self->{tcp_timeout};
		${*$socket}{net_dns_bg} = [$expire, 0, $packet->header->id, $ip];
		return $socket;
	}

	$self->_diag( $self->errorstring );
	return undef;
}


sub _bgsend_udp {
	my ( $self, $packet, $packet_data ) = @_;

	$self->_reset_errorstring;

	my $port = $self->{port};

	foreach my $ip ( $self->nameservers ) {
		my $socket = $self->_create_udp_socket($ip) || next;
		my $dst_sockaddr = $self->_create_dst_sockaddr( $ip, $port );

		$self->_diag( 'bgsend', "[$ip]:$port" );

		my $ok = $socket->send( $packet_data, 0, $dst_sockaddr );
		$self->errorstring($!);
		next unless $ok;

		# handle failure to detect taint inside $socket->send()
		# uncoverable branch true
		die 'Insecure dependency while running with -T switch' if _tainted($dst_sockaddr);

		my $expire = time() + $self->{udp_timeout};
		${*$socket}{net_dns_bg} = [$expire, 1, $packet->header->id, $ip];
		return $socket;
	}

	$self->_diag( $self->errorstring );
	return undef;
}


sub bgbusy {
	my $self = shift;
	my ($sock) = @_;
	return unless $sock;

	my $appendix = ${*$sock}{net_dns_bg} || [];
	my ( $expire, $udp ) = ( @$appendix, 0, 1 );
	return if ref($udp);

	unless ( IO::Select->new($sock)->can_read(0) ) {
		my $time = time();
		my ($expire) = ( @$appendix, $time );
		return $time <= $expire;
	}

	return unless $udp;

	my $ans = $self->bgread($sock);
	return unless $ans;

	$$appendix[1] = $ans;
	return unless $ans->header->tc;
	return if $self->{igntc};

	$self->_diag('packet truncated: retrying using TCP');
	my $packet = new Net::DNS::Packet();
	$packet->{question} = $ans->{question};
	my $tcp = $self->_bgsend_tcp( $packet, $packet->data );
	$_[0] = $tcp if $tcp;
	return defined $tcp;
}


sub bgisready {				## historical
	!&bgbusy;						# uncoverable pod
}


sub bgread {
	my $self = shift;
	my $sock = shift || return;

	my $appendix = ${*$sock}{net_dns_bg} || [];
	my ( $x, $udp ) = ( @$appendix, 0, 1 );

	return $udp if ref($udp);

	my $time = time();
	my ( $expire, $u, $qid, $ip ) = ( @$appendix, $time, 1 );

	my $select  = IO::Select->new($sock);
	my $timeout = $expire - $time;
	return undef unless $select->can_read( $timeout > 0 ? $timeout : 0 );

	my $buffer;
	if ($udp) {
		my $peerhost = $sock->peerhost;
		$self->answerfrom($peerhost);
		$buffer = _read_udp( $sock, $self->_packetsz );
		$self->_diag( "answer from [$peerhost]", length($buffer), 'bytes' );

	} else {
		$self->answerfrom($ip);				# $sock->peerhost unreliable
		$buffer = _read_tcp($sock);
		$self->_diag( "answer from [$ip]", length($buffer), 'bytes' );
	}

	my $ans = Net::DNS::Packet->new( \$buffer, $self->{debug} );
	$self->errorstring($@);

	if ($ans) {
		my $header = $ans->header;
		return undef unless $header->qr;
		return undef if defined $qid && ( $header->id != $qid );

		$ans->answerfrom( $self->answerfrom );
	}
	return $ans;
}


sub axfr {				## zone transfer
	my $self = shift;

	my ( $verify, @rr, $soa ) = $self->_axfr_start(@_);	# iterator state

	my $iterator = sub {		## iterate over RRs
		my $rr = shift(@rr);

		if ( ref($rr) eq 'Net::DNS::RR::SOA' ) {
			return $soa = $rr unless $soa;
			croak 'improperly terminated AXFR' if $rr->encode ne $soa->encode;
			return $self->{axfr_sel} = undef;
		}

		return $rr if scalar @rr;

		my $reply;
		( $reply, $verify ) = $self->_axfr_next($verify);
		return $self->{axfr_sel} = undef unless $reply;
		@rr = $reply->answer;
		return $rr;
	};

	$iterator->();						# read initial packet

	return $iterator unless wantarray;

	my @zone;						# assemble whole zone
	while ( my $rr = $iterator->() ) {
		push @zone, $rr, @rr;				# copy RRs en bloc
		@rr = pop(@zone);				# leave last one in @rr
	}
	return @zone;
}


sub axfr_start {			## historical
	my $self = shift;					# uncoverable pod
	my $iter = $self->{axfr_iter} = $self->axfr(@_);
	defined($iter);
}


sub axfr_next {				## historical
	shift->{axfr_iter}->();					# uncoverable pod
}


sub _axfr_start {
	my $self  = shift;
	my $dname = scalar(@_) ? shift : $self->domain;
	my @class = @_;

	my $request = $self->_make_query_packet( $dname, 'AXFR', @class );

	$self->_diag("axfr_start( $dname, @class )");

	foreach my $ns ( $self->nameservers ) {
		my $socket = $self->_create_tcp_socket($ns) || next;

		$self->_diag("axfr_start nameserver [$ns]");

		my $packet_data = $request->data;
		my $TCP_msg = pack 'n a*', length($packet_data), $packet_data;

		$socket->send($TCP_msg);
		$self->errorstring($!);

		$self->{axfr_ns}  = $ns;
		$self->{axfr_sel} = IO::Select->new($socket);

		return $request->sigrr ? $request : undef;
	}

	$self->_diag( $self->errorstring );
	return;
}


sub _axfr_next {
	my ( $self, $verify ) = @_;

	my $select = $self->{axfr_sel} || return;
	my ($sock) = $select->can_read( $self->{tcp_timeout} );
	croak 'improperly terminated AXFR' unless $sock;

	#--------------------------------------------------------------
	# Read the response packet.
	#--------------------------------------------------------------

	my $buffer = _read_tcp($sock);
	$self->_diag( 'received', length($buffer), 'bytes' );

	my $packet = Net::DNS::Packet->new( \$buffer );
	return unless $packet;
	$packet->answerfrom( $self->{axfr_ns} );
	my $rcode = $packet->header->rcode;
	$self->_diag( $self->errorstring("RCODE from server: $rcode") );
	return $packet unless $verify;
	return ( $packet, $verify ) if $verify = $packet->verify($verify);
	croak $packet->verifyerr;
}


#
# Usage:  $data = _read_tcp($socket);
#
sub _read_tcp {
	my $socket = shift;

	my $size_buf = '';
	$socket->recv( $size_buf, INT16SZ );
	my ($unread) = unpack 'n*', $size_buf;

	my $buffer = '';
	while ($unread) {

		# During some of my tests recv() returned undef even
		# though there wasn't an error.	 Checking for the amount
		# of data read appears to work around that problem.

		my $read_buf = '';
		$socket->recv( $read_buf, $unread );

		my $read = length $read_buf;
		last unless $read;

		$buffer .= $read_buf;
		$unread -= $read;
	}

	warn "ERROR: tcp recv failed: $!\n" if $unread;
	return $buffer;
}


#
# Usage:  $data = _read_udp($socket, $length);
#
sub _read_udp {
	my $socket = shift;
	my $length = shift;

	my $buffer = '';
	warn "ERROR: udp recv failed: $!\n" unless $socket->recv( $buffer, $length );
	return $buffer;
}


sub _create_tcp_socket {
	my $self = shift;
	my $ip	 = shift;

	my $sock_key = "TCP[$ip]";
	my $socket;

	if ( $socket = $self->{persistent}{$sock_key} ) {
		$self->_diag( 'using persistent socket', $sock_key );
		return $socket if $socket->connected;
		$self->_diag('socket disconnected (trying to connect)');
	}

	my $dstport = $self->{port};
	my $srcport = $self->{srcport};
	my $timeout = $self->{tcp_timeout};

	if (USE_SOCKET_IP) {
		my $srcaddr = _ipv6($ip) ? $self->{srcaddr6} : $self->{srcaddr4};
		$socket = IO::Socket::IP->new(
			LocalAddr => $srcaddr,
			LocalPort => $srcport,
			PeerAddr  => $ip,
			PeerPort  => $dstport,
			Proto	  => 'tcp',
			Timeout	  => $timeout
			)

	} elsif ( not _ipv6($ip) ) {
		$socket = IO::Socket::INET->new(
			LocalAddr => $self->{srcaddr4},
			LocalPort => ( $srcport || undef ),
			PeerAddr  => $ip,
			PeerPort  => $dstport,
			Proto	  => 'tcp',
			Timeout	  => $timeout
			)

	} elsif (USE_SOCKET_INET6) {
		$socket = IO::Socket::INET6->new(
			LocalAddr => $self->{srcaddr6},
			LocalPort => ( $srcport || undef ),
			PeerAddr  => $ip,
			PeerPort  => $dstport,
			Proto	  => 'tcp',
			Timeout	  => $timeout
			);
	}

	$self->{persistent}{$sock_key} = $self->{persistent_tcp} ? $socket : undef;
	$self->_diag( $self->errorstring("connection failed $sock_key") ) unless $socket;
	return $socket;
}


sub _create_udp_socket {
	my $self = shift;
	my $ip	 = shift;

	my $ip6_addr = IPv6 && _ipv6($ip);
	my $sock_key = IPv6 && $ip6_addr ? 'UDP/IPv6' : 'UDP/IPv4';
	my $socket;
	return $socket if $socket = $self->{persistent}{$sock_key};

	my $srcport = $self->{srcport};

	if (USE_SOCKET_IP) {
		my $srcaddr = $ip6_addr ? $self->{srcaddr6} : $self->{srcaddr4};
		$socket = IO::Socket::IP->new(
			LocalAddr => $srcaddr,
			LocalPort => $srcport,
			Proto	  => 'udp',
			Type	  => SOCK_DGRAM
			)

	} elsif ( not $ip6_addr ) {
		$socket = IO::Socket::INET->new(
			LocalAddr => $self->{srcaddr4},
			LocalPort => ( $srcport || undef ),
			Proto	  => 'udp',
			Type	  => SOCK_DGRAM
			)

	} elsif (USE_SOCKET_INET6) {
		$socket = IO::Socket::INET6->new(
			LocalAddr => $self->{srcaddr6},
			LocalPort => ( $srcport || undef ),
			Proto	  => 'udp',
			Type	  => SOCK_DGRAM
			);
	}

	$self->{persistent}{$sock_key} = $self->{persistent_udp} ? $socket : undef;
	$self->_diag( $self->errorstring("could not get $sock_key socket") ) unless $socket;
	return $socket;
}


sub _create_dst_sockaddr {		## create UDP destination sockaddr structure
	my ( $self, $ip, $port ) = @_;

	no strict;
	unless ( IPv6 && _ipv6($ip) ) {
		return sockaddr_in( $port, inet_aton($ip) )

	} elsif (USE_SOCKET_IP) {
		my $addr = Socket::inet_pton( AF_INET6, $ip );
		return sockaddr_in6( $port, $addr )

	} elsif (USE_SOCKET_INET6) {
		local $^W = 0;					# circumvent perl -w warnings

		my @res = Socket6::getaddrinfo( $ip, $port, AF_INET6, SOCK_DGRAM, 0, AI_NUMERICHOST );
		return $res[3] unless scalar(@res) < 5;

		my ($error) = @res;
		$self->errorstring("send: $ip\t$error");
		return;
	}
}


# Lightweight versions of subroutines from Net::IP module, recoded to fix RT#96812

sub _ipv4 {
	for (shift) {
		return /^[0-9.]+\.[0-9]+$/;			# dotted digits
	}
}

sub _ipv6 {
	for (shift) {
		return 1 if /^[:0-9a-f]+:[0-9a-f]*$/i;		# mixed : and hexdigits
		return 1 if /^[:0-9a-f]+:[0-9.]+$/i;		# prefix + dotted digits
		return /^[:0-9a-f]+:[0-9a-f]*[%].+$/i;		# RFC4007 scoped address
	}
}


sub _make_query_packet {
	my $self = shift;

	my ($packet) = @_;
	if ( ref($packet) ) {
		my $header = $packet->header;
		$header->rd( $self->{recurse} ) if $header->opcode eq 'QUERY';

	} else {
		$packet = Net::DNS::Packet->new(@_);

		my $header = $packet->header;
		$header->ad( $self->{adflag} );			# RFC6840, 5.7
		$header->cd( $self->{cdflag} );			# RFC6840, 5.9
		$header->do(1) if $self->dnssec;
		$header->rd( $self->{recurse} );
	}

	$packet->edns->size( $self->{udppacketsize} );		# advertise UDPsize for local stack

	if ( $self->{tsig_rr} ) {
		$packet->sign_tsig( $self->{tsig_rr} ) unless $packet->sigrr;
	}

	return $packet;
}


sub dnssec {
	my $self = shift;

	return $self->{dnssec} unless scalar @_;

	# increase default udppacket size if flag set
	$self->udppacketsize(2048) if $self->{dnssec} = shift;

	return $self->{dnssec};
}


sub force_v4 {
	my $self = shift;
	return $self->{force_v4} unless scalar @_;
	my $value = shift;
	$self->force_v6(0) if $value;
	$self->{force_v4} = $value ? 1 : 0;
}

sub force_v6 {
	my $self = shift;
	return $self->{force_v6} unless scalar @_;
	my $value = shift;
	$self->force_v4(0) if $value;
	$self->{force_v6} = $value ? 1 : 0;
}

sub prefer_v4 {
	my $self = shift;
	return $self->{prefer_v4} unless scalar @_;
	$self->{prefer_v4} = shift() ? 1 : 0;
}

sub prefer_v6 {
	my $self = shift;
	$self->{prefer_v4} = shift() ? 0 : 1 if scalar @_;
	$self->{prefer_v4} ? 0 : 1;
}


sub srcaddr {
	my $self = shift;
	for (@_) {
		my $hashkey = _ipv6($_) ? 'srcaddr6' : 'srcaddr4';
		$self->{$hashkey} = $_;
	}
	return shift;
}


sub tsig {
	my $self = shift;
	$self->{tsig_rr} = eval {
		local $SIG{__DIE__};
		require Net::DNS::RR::TSIG;
		Net::DNS::RR::TSIG->create(@_);
	};
	croak "${@}unable to create TSIG record" if $@;
}


sub udppacketsize {
	my $self = shift;
	$self->{udppacketsize} = shift if scalar @_;
	return $self->_packetsz;
}

# if ($self->{udppacketsize} > PACKETSZ
# then we use EDNS and $self->{udppacketsize}
# should be taken as the maximum packet_data length
sub _packetsz {
	my $udpsize = shift->{udppacketsize} || 0;
	return $udpsize > PACKETSZ ? $udpsize : PACKETSZ;
}


#
# Keep this method around. Folk depend on it although it is neither documented nor exported.
#
my $warned;

sub make_query_packet {			## historical
	carp 'deprecated method; see RT#37104' unless $warned++;    # uncoverable pod
	&_make_query_packet;
}


sub _diag {				## debug output
	my $self = shift;
	print "\n;; @_\n" if $self->{debug};
}


use vars qw($AUTOLOAD);

sub DESTROY { }				## Avoid tickling AUTOLOAD (in cleanup)

sub AUTOLOAD {				## Default method
	my ($self) = @_;

	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	croak "$name: no such method" unless $public_attr{$name};

	no strict q/refs/;
	*{$AUTOLOAD} = sub {
		my $self = shift;
		$self = $self->_defaults unless ref($self);
		$self->{$name} = shift if scalar @_;
		return $self->{$name};
	};

	goto &{$AUTOLOAD};
}


1;

__END__


=head1 NAME

Net::DNS::Resolver::Base - DNS resolver base class

=head1 SYNOPSIS

    use base qw(Net::DNS::Resolver::Base);

=head1 DESCRIPTION

This class is the common base class for the different platform
sub-classes of L<Net::DNS::Resolver>.

No user serviceable parts inside, see L<Net::DNS::Resolver>
for all your resolving needs.


=head1 METHODS

=head2 new, domain, searchlist, nameservers, print, string, errorstring,

=head2 search, query, send, bgsend, bgbusy, bgread, axfr, answerfrom,

=head2 force_v4, force_v6, prefer_v4, prefer_v6,

=head2 dnssec, srcaddr, tsig, udppacketsize

See L<Net::DNS::Resolver>.


=head1 COPYRIGHT

Copyright (c)2003,2004 Chris Reinhardt.

Portions Copyright (c)2005 Olaf Kolkman.

Portions Copyright (c)2014,2015 Dick Franks.

All rights reserved.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the above copyright notice appear in all copies and that both that
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<perl>, L<Net::DNS>, L<Net::DNS::Resolver>

=cut


# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Dispatcher::Try;
use vars '$VERSION';
$VERSION = '1.15';

use base 'Log::Report::Dispatcher';

use Log::Report 'log-report', syntax => 'SHORT';
use Log::Report::Exception ();
use Log::Report::Util      qw/%reason_code/;


use overload
    bool     => 'failed'
  , '""'     => 'showStatus'
  , fallback => 1;

#-----------------

sub init($)
{   my ($self, $args) = @_;
    defined $self->SUPER::init($args) or return;
    $self->{exceptions} = delete $args->{exceptions} || [];
    $self->{died}       = delete $args->{died};
    $self->hide($args->{hide} // 'NONE');
    $self;
}


sub close()
{   my $self = shift;
    $self->SUPER::close or return;
    $self;
}

#-----------------

sub died(;$)
{   my $self = shift;
    @_ ? ($self->{died} = shift) : $self->{died};
}


sub exceptions() { @{shift->{exceptions}} }


sub hides($)
{   my $h = shift->{hides} or return 0;
    keys %$h ? $h->{(shift)} : 1;
}


sub hide(@)
{   my $self = shift;
    my @h = map { ref $_ eq 'ARRAY' ? @$_ : defined($_) ? $_ : () } @_;

    $self->{hides}
      = @h==0 ? undef
      : @h==1 && $h[0] eq 'ALL'  ? {}    # empty HASH = ALL
      : @h==1 && $h[0] eq 'NONE' ? undef
      :    +{ map +($_ => 1), @h };
}

#-----------------

sub log($$$$)
{   my ($self, $opts, $reason, $message, $domain) = @_;

    unless($opts->{stack})
    {   my $mode = $self->mode;
        $opts->{stack} = $self->collectStack
            if $reason eq 'PANIC'
            || ($mode==2 && $reason_code{$reason} >= $reason_code{ALERT})
            || ($mode==3 && $reason_code{$reason} >= $reason_code{ERROR});
    }

    $opts->{location} ||= '';

    my $e = Log::Report::Exception->new
      ( reason      => $reason
      , report_opts => $opts
      , message     => $message
      );

    push @{$self->{exceptions}}, $e;

    $self->{died} ||=
        exists $opts->{is_fatal} ? $opts->{is_fatal} : $e->isFatal;

    $self;
}


sub reportFatal(@) { $_->throw(@_) for shift->wasFatal   }
sub reportAll(@)   { $_->throw(@_) for shift->exceptions }

#-----------------

sub failed()  {   shift->{died}}
sub success() { ! shift->{died}}


sub wasFatal(@)
{   my ($self, %args) = @_;
    $self->{died} or return ();
    my $ex = $self->{exceptions}[-1];
    (!$args{class} || $ex->inClass($args{class})) ? $ex : ();
}


sub showStatus()
{   my $self  = shift;
    my $fatal = $self->wasFatal or return '';
    __x"try-block stopped with {reason}: {text}"
      , reason => $fatal->reason
      , text   => $self->died;
}

1;

# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Exception;
use vars '$VERSION';
$VERSION = '1.15';


use Log::Report      'log-report';
use Log::Report::Util qw/is_fatal to_html/;
use POSIX             qw/locale_h/;
use Scalar::Util      qw/blessed/;


use overload
    '""'     => 'toString'
  , fallback => 1;


sub new($@)
{   my ($class, %args) = @_;
    $args{report_opts} ||= {};
    bless \%args, $class;
}


sub report_opts() {shift->{report_opts}}


sub reason(;$)
{   my $self = shift;
    @_ ? $self->{reason} = uc(shift) : $self->{reason};
}


sub isFatal() { is_fatal shift->{reason} }


sub message(;$)
{   my $self = shift;
    @_ or return $self->{message};
    my $msg = shift;
    blessed $msg && $msg->isa('Log::Report::Message')
        or panic "message() of exception expects Log::Report::Message";
    $self->{message} = $msg;
}


sub inClass($) { $_[0]->message->inClass($_[1]) }


sub throw(@)
{   my $self    = shift;
    my $opts    = @_ ? { %{$self->{report_opts}}, @_ } : $self->{report_opts};

    my $reason;
    if($reason = delete $opts->{reason})
    {   $self->{reason} = $reason;
        $opts->{is_fatal} = is_fatal $reason
            unless exists $opts->{is_fatal};
    }
    else
    {   $reason = $self->{reason};
    }

    $opts->{stack} ||= Log::Report::Dispatcher->collectStack;
    report $opts, $reason, $self;
}

# where the throw is handled is not interesting
sub PROPAGATE($$) {shift}


sub toString(;$)
{   my ($self, $locale) = @_;
    my $msg  = $self->message;
    lc($self->{reason}).': '.(ref $msg ? $msg->toString($locale) : $msg)."\n";
}


sub toHTML(;$) { to_html($_[0]->toString($_[1])) }


sub print(;$)
{   my $self = shift;
    (shift || *STDERR)->print($self->toString);
}

1;

# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Dispatcher::Log4perl;
use vars '$VERSION';
$VERSION = '1.15';

use base 'Log::Report::Dispatcher';

use Log::Report 'log-report';

use Log::Report::Util qw/@reasons expand_reasons/;
use Log::Log4perl     qw/:levels/;

my %default_reasonToLevel =
 ( TRACE   => $DEBUG
 , ASSERT  => $DEBUG
 , INFO    => $INFO
 , NOTICE  => $INFO
 , WARNING => $WARN
 , MISTAKE => $WARN
 , ERROR   => $ERROR
 , FAULT   => $ERROR
 , ALERT   => $FATAL
 , FAILURE => $FATAL
 , PANIC   => $FATAL
 );

@reasons==keys %default_reasonToLevel
    or panic __"Not all reasons have a default translation";

# Do not show these as source of the error: one or more caller frames up
Log::Log4perl->wrapper_register($_) for qw/
  Log::Report
  Log::Report::Dispatcher
  Log::Report::Dispatcher::Try
/;


sub init($)
{   my ($self, $args) = @_;
    $args->{accept} ||= 'ALL';
    $self->SUPER::init($args);

    my $name   = $self->name;
    my $config = delete $args->{config}
       or error __x"Log4perl back-end {name} requires a 'config' parameter"
            , name => $name;

    $self->{LRDL_levels}  = { %default_reasonToLevel };
    if(my $to_level = delete $args->{to_level})
    {   my @to = @$to_level;
        while(@to)
        {   my ($reasons, $level) = splice @to, 0, 2;
            my @reasons = expand_reasons $reasons;

            $level =~ m/^[0-5]$/
                or error __x "Log4perl level '{level}' must be in 0-5"
                     , level => $level;

            $self->{LRDL_levels}{$_} = $level for @reasons;
        }
    }

    Log::Log4perl->init($config)
        or return;

    $self;
}

#sub close()
#{   my $self = shift;
#    $self->SUPER::close or return;
#    $self;
#}


sub logger(;$)
{   my ($self, $domain) = @_;
    defined $domain
        or return Log::Log4perl->get_logger($self->name);

    # get_logger() creates a logger if that does not exist.  But we
    # want to route it to default
    $Log::Log4perl::LOGGERS_BY_NAME->{$domain}
       ||= Log::Log4perl->get_logger($self->name);
}


sub log($$$$)
{   my ($self, $opts, $reason, $msg, $domain) = @_;
    my $text   = $self->translate($opts, $reason, $msg) or return;
    my $level  = $self->reasonToLevel($reason);

    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 3;

    $text =~ s/\s+$//s;  # log4perl adds own \n
    $self->logger($domain)->log($level, $text);
    $self;
}


sub reasonToLevel($) { $_[0]->{LRDL_levels}{$_[1]} }

1;

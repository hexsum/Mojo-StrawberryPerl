# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package Dancer2::Logger::LogReport;
use vars '$VERSION';
$VERSION = '1.15';

# ABSTRACT: Dancer2 logger engine for Log::Report

use strict;
use warnings;

use Moo;
use Dancer2::Core::Types;
use Scalar::Util qw/blessed/;
use Log::Report  'log-report', syntax => 'REPORT';

our $AUTHORITY = 'cpan:MARKOV';

my %level_dancer2lr =
  ( core  => 'TRACE'
  , debug => 'TRACE'
  );

with 'Dancer2::Core::Role::Logger';

# Set by calling function
has dispatchers =>
  ( is     => 'ro'
  , isa    => Maybe[HashRef]
  );

sub BUILD
{   my $self     = shift;
    my $configs  = $self->dispatchers || {default => undef};
    $self->{use} = [keys %$configs];

    dispatcher 'do-not-reopen';

    foreach my $name (keys %$configs)
    {   my $config = $configs->{$name} || {};
        if(keys %$config)
        {   my $type = delete $config->{type}
                or die "dispatcher configuration $name without type";

            dispatcher $type, $name, %$config;
        }
    }
}

around 'info' => sub {
    my ($orig, $self) = (shift, shift);
    $self->log(info => @_);
};

around 'warning' => sub {
    my ($orig, $self) = (shift, shift);
    $self->log(warning => @_);
};

around 'error' => sub {
    my ($orig, $self) = (shift, shift);
    return if $_[0] =~ /^Route exception/;
    $self->log(error => @_);
};


sub log($$$)
{   my ($self, $level, $msg) = @_;

    # the levels are nearly the same.
    my $reason = $level_dancer2lr{$level} // uc $level;

    report $reason => $msg;
    undef;
}
 
1;

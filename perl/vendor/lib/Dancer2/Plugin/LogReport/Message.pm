# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use strict;
use warnings;

package Dancer2::Plugin::LogReport::Message;
use vars '$VERSION';
$VERSION = '1.15';


use parent 'Log::Report::Message';


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self;
}


sub reason
{   my $self = shift;
    $self->{reason} = $_[0] if exists $_[0];
    $self->{reason};
}

my %reason2color =
    ( TRACE   => 'info'
    , ASSERT  => 'info'
    , INFO    => 'info'
    , NOTICE  => 'info'
    , WARNING => 'warning'
    , MISTAKE => 'warning'
    );


sub bootstrap_color
{  my $self = shift;
   return 'success' if $self->inClass('success');
   $reason2color{$self->reason} || 'danger';
}

1;

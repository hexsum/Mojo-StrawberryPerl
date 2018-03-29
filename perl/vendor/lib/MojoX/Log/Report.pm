# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package MojoX::Log::Report;
use vars '$VERSION';
$VERSION = '1.15';

use Mojo::Base 'Mojo::Log';  # implies use strict etc

use Log::Report 'log-report', import => 'report';


sub new(@) {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    # issue with Mojo, where the base-class registers a function --not
    # a method-- to handle the message.
    $self->unsubscribe('message');    # clean all listeners
    $self->on(message => '_message'); # call it OO
    $self;
}

my %level2reason = qw/
 debug  TRACE
 info   INFO
 warn   WARNING
 error  ERROR
 fatal  ALERT
/;

sub _message($$@)
{   my ($self, $level) = (shift, shift);
 
    report +{is_fatal => 0}    # do not die on errors
      , $level2reason{$level}, join('', @_);
}

1;

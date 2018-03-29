# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use strict;
use warnings;

package Log::Report::DBIC::Profiler;
use vars '$VERSION';
$VERSION = '1.15';

use base 'DBIx::Class::Storage::Statistics';

use Log::Report  'log-report', import => 'trace';
use Time::HiRes  qw(time);


my $start;

sub print($) { trace $_[1] }

sub query_start(@)
{   my $self = shift;
    $self->SUPER::query_start(@_);
    $start   = time;
}

sub query_end(@)
{   my $self = shift;
    $self->SUPER::query_end(@_);
    trace sprintf "execution took %0.4f seconds elapse", time-$start;
}

1;


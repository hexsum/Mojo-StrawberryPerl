# Copyrights 2013-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

use warnings;
use strict;

package Log::Report::Optional;
use vars '$VERSION';
$VERSION = '1.02';

use base 'Exporter';


my ($supported, @used_by);

BEGIN {
   if($INC{'Log/Report.pm'})
   {   $supported  = 'Log::Report';
       my $version = $Log::Report::VERSION;
       die "Log::Report too old for ::Optional, need at least 1.00"
           if $version && $version le '1.00';
   }
   else
   {   require Log::Report::Minimal;
       $supported = 'Log::Report::Minimal';
   }
}

sub import(@)
{   my $class = shift;
    push @used_by, (caller)[0];
    $supported->import('+1', @_);
}


sub usedBy() { @used_by }

1;

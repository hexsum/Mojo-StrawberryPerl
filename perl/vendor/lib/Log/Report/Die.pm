# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Die;
use vars '$VERSION';
$VERSION = '1.15';

use base 'Exporter';

our @EXPORT = qw/die_decode/;

use POSIX  qw/locale_h/;


sub die_decode($)
{   my @text   = split /\n/, $_[0];
    @text or return ();
    chomp $text[-1];

    # Try to catch the error directly, to remove it from the error text
    my %opt    = (errno => $! + 0);
    my $err    = "$!";

    my $dietxt = $text[0];
    if($text[0] =~ s/ at (.+) line (\d+)\.?$// )
    {   $opt{location} = [undef, $1, $2, undef];
    }
    elsif(@text > 1 && $text[1] =~ m/^\s*at (.+) line (\d+)\.?$/ )
    {   # sometimes people carp/confess with \n, folding the line
        $opt{location} = [undef, $1, $2, undef];
        splice @text, 1, 1;
    }

    $text[0] =~ s/\s*[.:;]?\s*$err\s*$//  # the $err is translation sensitive
        or delete $opt{errno};

    my @msg = shift @text;
    length $msg[0] or $msg[0] = 'stopped';

    my @stack;
    foreach (@text)
    {   if(m/^\s*(.*?)\s+called at (.*?) line (\d+)\s*$/)
             { push @stack, [ $1, $2, $3 ] }
        else { push @msg, $_ }
    }
    $opt{stack}   = \@stack;
    $opt{classes} = [ 'perl', (@stack ? 'confess' : 'die') ];

    my $reason
      = @{$opt{stack}} ? ($opt{errno} ? 'ALERT' : 'PANIC')
      :                  ($opt{errno} ? 'FAULT' : 'ERROR');

    ($dietxt, \%opt, $reason, join("\n",@msg));
}

"to die or not to die, that's the question";

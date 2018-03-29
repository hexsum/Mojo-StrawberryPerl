# Copyrights 2013-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Minimal::Domain;
use vars '$VERSION';
$VERSION = '1.02';


use String::Print        'oo';


sub new(@)  { my $class = shift; (bless {}, $class)->init({@_}) }
sub init($)
{   my ($self, $args) = @_;
    $self->{LRMD_name} = $args->{name} or Log::Report::panic();
    $self;
}

#----------------


sub name() {shift->{LRMD_name}}
sub isConfigured() {shift->{LRMD_where}}


sub configure(%)
{   my ($self, %args) = @_;

    my $here = $args{where} || [caller];
    if(my $s = $self->{LRMD_where})
    {   my $domain = $self->name;
        Log::Report::panic("only one package can contain configuration; for $domain already in $s->[0] in file $s->[1] line $s->[2].  Now also found at $here->[1] line $here->[2]");
    }
    my $where = $self->{LRMD_where} = $here;

    # documented in the super-class, the most useful manpage
    my $format = $args{formatter} || 'PRINTI';
    my $sp     = ref $format ? undef : String::Print->new;
    $self->{LRMD_format}
      = $format eq 'PRINTI'   ? sub {$sp->sprinti(@_)}
      : $format eq 'PRINTP'   ? sub {$sp->sprintp(@_)}
      : ref $format eq 'CODE' ? $format
      : error __x"illegal formatter `{name}' at {fn} line {line}"
          , name => $format, fn => $where->[1], line => $where->[2];

    $self;
}

#-------------------

sub interpolate(@)
{   my ($self, $msgid, $args) = @_;
    $args->{_expand} or return $msgid;
    my $f = $self->{LRMD_format} || $self->configure->{LRMD_format};
    $f->($msgid, $args);
}

1;

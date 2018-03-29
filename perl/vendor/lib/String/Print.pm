# Copyrights 2013-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package String::Print;
our $VERSION = '0.15';


#use Log::Report::Optional 'log-report';

use Encode            qw/is_utf8 decode/;
use Unicode::GCString ();

my @default_modifiers   = ( qr/%\S+/ => \&_format_printf );
my %default_serializers =
 ( UNDEF     => sub { 'undef' }
 , ''        => sub { $_[1]   }
 , SCALAR    => sub { ${$_[1]} // shift->{LRF_seri}{UNDEF}->(@_) }
 , ARRAY     =>
     sub { my $v = $_[1]; my $join = $_[2]{_join} // ', ';
           join $join, map +($_ // 'undef'), @$v;
         }
 , HASH      =>
     sub { my $v = $_[1];
           join ', ', map "$_ => ".($v->{$_} // 'undef'), sort keys %$v;
         }
 # CODE value has different purpose
 );


sub new(@) { my $class = shift; (bless {}, $class)->init( {@_} ) }
sub init($)
{   my ($self, $args) = @_;

    my $modif = $self->{LRF_modif} = [ @default_modifiers ];
    if(my $m  = $args->{modifiers})
    {   unshift @$modif, @$m;
    }

    my $s    = $args->{serializers} || {};
    my $seri = $self->{LRF_seri}
      = { %default_serializers, (ref $s eq 'ARRAY' ? @$s : %$s) };

    $self;
}

sub import(@)
{   my $class = shift;
    my ($oo, %func);
    while(@_)
    {   last if $_[0] !~ m/^s?print[ip]$/;
        $func{shift()} = 1;
    }

    if(@_ && $_[0] eq 'oo')   # only object oriented interface
    {   shift @_;
        @_ and die "no options allowed at import with oo interface";
        return;
    }

    my $all   = !keys %func;
    my $f     = $class->new(@_);   # OO encapsulated
    my ($pkg) = caller;
    no strict 'refs';
    *{"$pkg\::printi"}  = sub { $f->printi(@_)  } if $all || $func{printi};
    *{"$pkg\::sprinti"} = sub { $f->sprinti(@_) } if $all || $func{sprinti};
    *{"$pkg\::printp"}  = sub { $f->printp(@_)  } if $all || $func{printp};
    *{"$pkg\::sprintp"} = sub { $f->sprintp(@_) } if $all || $func{sprintp};
    $class;
}

#-------------

sub addModifiers(@) {my $self = shift; unshift @{$self->{LRF_modif}}, @_}

#-------------------

sub sprinti($@)
{   my ($self, $format) = (shift, shift);
    my $args = @_==1 ? shift : {@_};

    $args->{_join} //= ', ';

    my $result = is_utf8($format) ? $format : decode(latin1 => $format);

    # quite hard to check for a bareword :(
    $result    =~ s/\{\s* ( [\pL\p{Pc}\pM]\w* )\s*( [^}]*? )\s*\}/
                    $self->_expand($1,$2,$args)/gxe;

    $result    = $args->{_prepend} . $result if defined $args->{_prepend};
    $result   .= $args->{_append}            if defined $args->{_append};
    $result;
}

sub _expand($$$)
{   my ($self, $key, $modifier, $args) = @_;
    my $value = $args->{$key};

    $value = $value->($self, $key, $args)
        while ref $value eq 'CODE';

    my $mod;
 STACKED:
    while(length $modifier)
    {   my @modif = @{$self->{LRF_modif}};
        while(@modif)
        {   my ($regex, $callback) = (shift @modif, shift @modif);
            $modifier =~ s/^($regex)\s*// or next;

            $value = $callback->($self, $1, $value, $args);
            next STACKED;
        }
        return "{unknown modifier '$modifier'}";
    }

    my $seri = $self->{LRF_seri}{defined $value ? ref $value : 'UNDEF'};
    $seri ? $seri->($self, $value, $args) : "$value";
}

# See dedicated section in explanation in DETAILS
sub _format_printf($$$$)
{   my ($self, $format, $value, $args) = @_;

    # be careful, often $format doesn't eat strings
    defined $value
        or return 'undef';

    use locale;
    if(ref $value eq 'ARRAY')
    {   @$value or return '(none)';
        return [ map $self->_format_print($format, $_, $args), @$value ] ;
    }
    elsif(ref $value eq 'HASH')
    {   keys %$value or return '(none)';
        return { map +($_ => $self->_format_print($format, $value->{$_}, $args))
                   , keys %$value } ;
    }

    $format =~ m/^\%([-+ ]?)([0-9]*)(?:\.([0-9]*))?([sS])$/
        or return sprintf $format, $value;   # simple: not a string

    my ($padding, $width, $max, $u) = ($1, $2, $3, $4);

    # String formats like %10s or %-3.5s count characters, not width.
    # String formats like %10S or %-3.5S are subject to column width.
    # The latter means: minimal 3 chars, max 5, padding right with blanks.
    # All inserted strings are upgraded into utf8.

    my $s = Unicode::GCString->new
      ( is_utf8($value) ? $value : decode(latin1 => $value));

    my $pad;
    if($u eq 'S')
    {   # too large to fit
        return $value if !$max && $width && $width <= $s->columns;

        # wider than max.  Waiting for $s->trim($max) if $max, see
        # https://rt.cpan.org/Public/Bug/Display.html?id=84549
        $s->substr(-1, 1, '')
           while $max && $s->columns > $max;

        $pad = $width ? $width - $s->columns : 0;
    }
    else  # $u eq 's'
    {   return $value if !$max && $width && $width <= length $s;
        $s->substr($max, length($s)-$max, '') if $max && length $s > $max;
        $pad = $width ? $width - length $s : 0;
    }

      $pad==0         ? $s->as_string
    : $padding eq '-' ? $s->as_string . (' ' x $pad)
    :                   (' ' x $pad) . $s->as_string;
}


sub printi($$@)
{   my $self = shift;
    my $fh   = ref $_[0] eq 'GLOB' ? shift : select;
    $fh->print($self->sprinti(@_));
}


sub printp($$@)
{   my $self = shift;
    my $fh   = ref $_[0] eq 'GLOB' ? shift : select;
    $fh->print($self->sprintp(@_));
}


sub _printp_rewrite($)
{   my @params = @{$_[0]};
    my $printp = $params[0];
    my ($printi, @iparam);
    my ($pos, $maxpos) = (1, 1);
    while(length $printp && $printp =~ s/^([^%]+)//s)
    {   $printi .= $1;
        length $printp or last;
        if($printp =~ s/^\%\%//)
        {   $printi .= '%';
            next;
        }
        $printp =~ s/\%(?:([0-9]+)\$)?     # 1=positional
                       ([-+0 \#]*)         # 2=flags
                       ([0-9]*|\*)?        # 3=width
                       (?:\.([0-9]*|\*))?  # 4=precission
                       (?:\{ ([^}]*) \})?  # 5=modifiers
                       (\w)                # 6=conversion
                    //x
            or die "format error at '$printp' in '$params[0]'";

        $pos      = $1 if $1;
        my $width = !defined $3 ? '' : $3 eq '*' ? $params[$pos++] : $3;
        my $prec  = !defined $4 ? '' : $4 eq '*' ? $params[$pos++] : $4;
        my $modif = !defined $5 ? '' : $5;
        my $valpos= $pos++;
        $maxpos   = $pos if $pos > $maxpos;
        push @iparam, "_$valpos" => $params[$valpos];
        my $format= '%'.$2.($width || '').($prec ? ".$prec" : '').$6;
        $format   = '' if $format eq '%s';
        my $sep   = $modif.$format =~ m/^\w/ ? ' ' : '';
        $printi  .= "{_$valpos$sep$modif$format}";
    }
    splice @params, 0, $maxpos, @iparam;
    ($printi, \@params);
}

sub sprintp(@)
{   my $self = shift;
    my ($i, $iparam) = _printp_rewrite \@_;
    $self->sprinti($i, {@$iparam});
}

#-------------------

1;

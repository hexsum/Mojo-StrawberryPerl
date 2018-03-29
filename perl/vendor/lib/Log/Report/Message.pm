# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Message;
use vars '$VERSION';
$VERSION = '1.15';


use Log::Report 'log-report';
use POSIX             qw/locale_h/;
use List::Util        qw/first/;
use Log::Report::Util qw/to_html/;

# Work-around for missing LC_MESSAGES on old Perls and Windows
{ no warnings;
  eval "&LC_MESSAGES";
  *LC_MESSAGES = sub(){5} if $@;
}


use overload
    '""'  => 'toString'
  , '&{}' => sub { my $obj = shift; sub{$obj->clone(@_)} }
  , '.'   => 'concat'
  , fallback => 1;


sub new($@)
{   my ($class, %s) = @_;

    if(ref $s{_count})
    {   my $c        = $s{_count};
        $s{_count}   = ref $c eq 'ARRAY' ? @$c : keys %$c;
    }

    defined $s{_join}
        or $s{_join} = $";

    if($s{_msgid})
    {   $s{_append}  = defined $s{_append} ? $1.$s{_append} : $1
            if $s{_msgid} =~ s/(\s+)$//;

        $s{_prepend}.= $1
            if $s{_msgid} =~ s/^(\s+)//;
    }
    if($s{_plural})
    {   s/\s+$//, s/^\s+// for $s{_plural};
    }

    bless \%s, $class;
}


sub clone(@)
{   my $self = shift;
    (ref $self)->new(%$self, @_);
}


sub fromTemplateToolkit($$;@)
{   my ($class, $domain, $msgid) = splice @_, 0, 3;
    my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
    my $args   = @_ && ref $_[-1] eq 'HASH' ? pop : {};

    my $count;
    if(defined $plural)
    {   @_==1 or $msgid .= " (ERROR: missing count for plural)";
        $count = shift || 0;
        $count = @$count if ref $count eq 'ARRAY';
    }
    else
    {   @_==0 or $msgid .= " (ERROR: only named parameters expected)";
    }

    $class->new
      ( _msgid => $msgid, _plural => $plural, _count => $count
      , %$args, _expand => 1, _domain => $domain);
}

#----------------

sub prepend() {shift->{_prepend}}
sub msgid()   {shift->{_msgid}}
sub append()  {shift->{_append}}
sub domain()  {shift->{_domain}}
sub count()   {shift->{_count}}
sub context() {shift->{_context}}


sub classes()
{   my $class = $_[0]->{_class} || $_[0]->{_classes} || [];
    ref $class ? @$class : split(/[\s,]+/, $class);
}


sub to(;$)
{   my $self = shift;
    @_ ? $self->{_to} = shift : $self->{_to};
}


sub valueOf($) { $_[0]->{$_[1]} }

#--------------

sub inClass($)
{   my @classes = shift->classes;
       ref $_[0] eq 'Regexp'
    ? (first { $_ =~ $_[0] } @classes)
    : (first { $_ eq $_[0] } @classes);
}
    

sub toString(;$)
{   my ($self, $locale) = @_;
    my $count  = $self->{_count} || 0;

    $self->{_msgid}   # no translation, constant string
        or return (defined $self->{_prepend} ? $self->{_prepend} : '')
                . (defined $self->{_append}  ? $self->{_append}  : '');

    # assumed is that switching locales is expensive
    my $oldloc = setlocale(LC_MESSAGES);
    setlocale(LC_MESSAGES, $locale)
        if defined $locale && (!defined $oldloc || $locale ne $oldloc);

    # create a translation
    my $text = (textdomain $self->{_domain})
       ->translate($self, $self->{_lang} || $locale || $oldloc);
  
    defined $text or return ();

    $text  =~ s/\{([^%}]+)(\%[^}]*)?\}/$self->_expand($1,$2)/ge
        if $self->{_expand};

    $text  = "$self->{_prepend}$text"
        if defined $self->{_prepend};

    $text .= "$self->{_append}"
        if defined $self->{_append};

    setlocale(LC_MESSAGES, $oldloc)
        if defined $oldloc && (!defined $locale || $oldloc ne $locale);

    $text;
}

sub _expand($$)
{   my ($self, $key, $format) = @_;
    my $value = $self->{$key} // $self->{_context}{$key};

    $value = $value->($self)
        while ref $value eq 'CODE';

    defined $value
        or return "undef";

    use locale;
    if(ref $value eq 'ARRAY')
    {   my @values = map {defined $_ ? $_ : 'undef'} @$value;
        @values or return '(none)';
        return $format
             ? join($self->{_join}, map sprintf($format, $_), @values)
             : join($self->{_join}, @values);
    }

      $format
    ? sprintf($format, $value)
    : "$value";   # enforce stringification on objects
}


my %tohtml = qw/  > gt   < lt   " quot  & amp /;

sub toHTML(;$) { to_html($_[0]->toString($_[1])) }


sub untranslated()
{  my $self = shift;
     (defined $self->{_prepend} ? $self->{_prepend} : '')
   . (defined $self->{_msgid}   ? $self->{_msgid}   : '')
   . (defined $self->{_append}  ? $self->{_append}  : '');
}


sub concat($;$)
{   my ($self, $what, $reversed) = @_;
    if($reversed)
    {   $what .= $self->{_prepend} if defined $self->{_prepend};
        return ref($self)->new(%$self, _prepend => $what);
    }

    $what = $self->{_append} . $what if defined $self->{_append};
    ref($self)->new(%$self, _append => $what);
}

#----------------

1;

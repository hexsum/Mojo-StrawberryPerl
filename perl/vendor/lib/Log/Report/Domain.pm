# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Domain;
use vars '$VERSION';
$VERSION = '1.15';

use base 'Log::Report::Minimal::Domain';

use Log::Report        'log-report';
use Log::Report::Util  qw/parse_locale/;
use Scalar::Util       qw/blessed/;

use Log::Report::Translator;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->{LRD_ctxt_def} = {};
    $self;
}

#----------------

sub nativeLanguage() {shift->{LRD_native}}
sub translator()     {shift->{LRD_transl}}
sub contextRules()   {shift->{LRD_ctxt_rules}}

#----------------

sub configure(%)
{   my ($self, %args) = @_;

    if(my $config = delete $args{config})
    {   my $set = $self->readConfig($config);
        %args   = (%$set, %args);
    }

    # 'formatter' is handled by the base-class, but documented here.
    $self->SUPER::configure(%args);

    my $transl = $args{translator} || Log::Report::Translator->new;
    $transl    =  Log::Report::Translator->new(%$transl)
        if ref $transl eq 'HASH';

    !blessed $transl || $transl->isa('Log::Report::Translator')
        or panic "translator must be a Log::Report::Translator object";
    $self->{LRD_transl} = $transl;

    my $native = $self->{LRD_native}
      = $args{native_language} || 'en_US';

    my ($lang) = parse_locale $native;
    defined $lang
        or error __x"the native_language '{locale}' is not a valid locale"
            , locale => $native;

    if(my $cr = $args{context_rules})
    {   my $tc = 'Log::Report::Translator::Context';
        eval "require $tc"; panic $@ if $@;
        if(blessed $cr)
        {   $cr->isa($tc) or panic "context_rules must be a $tc" }
        elsif(ref $cr eq 'HASH')
        {   $cr = Log::Report::Translator::Context->new(rules => $cr) }
        else
        {   panic "context_rules expects object or hash, not {have}", have=>$cr;
        }

        $self->{LRD_ctxt_rules} = $cr;
    }

    $self;
}


sub setContext(@)
{   my $self = shift;
    my $cr   = $self->contextRules  # ignore context if no rules given
        or error __x"you need to configure context_rules before setContext";

    $self->{LRD_ctxt_def} = $cr->needDecode(set => @_);
}


sub updateContext(@)
{   my $self = shift;
    my $cr   = $self->contextRules  # ignore context if no rules given
        or return;

    my $rules = $cr->needDecode(update => @_);
    my $r = $self->{LRD_ctxt_def} ||= {};
    @{$r}{keys %$r} = values %$r;
    $r;
}


sub defaultContext() { shift->{LRD_ctxt_def} }


sub readConfig($)
{   my ($self, $fn) = @_;
    my $config;

    if($fn =~ m/\.pl$/i)
    {   $config = do $fn;
    }
    elsif($fn =~ m/\.json$/i)
    {   eval "require JSON"; panic $@ if $@;
        open my($fh), '<:encoding(utf8)', $fn
            or fault __x"cannot open JSON file for context at {fn}"
               , fn => $fn;
        local $/;
        $config = JSON->utf8->decode(<$fh>);
    }
    else
    {   error __x"unsupported context file type for {fn}", fn => $fn;
    }

    $config;
}

#-------------------

sub translate($$)
{   my ($self, $msg, $lang) = @_;

    my ($msgid, $msgctxt);
    if(my $rules = $self->contextRules)
    {   ($msgid, $msgctxt)
           = $rules->ctxtFor($msg, $lang, $self->defaultContext);
    }
    else
    {   $msgid = $msg->msgid;
        1 while $msgid =~
            s/\{([^}]*)\<\w+([^}]*)\}/length "$1$2" ? "{$1$2}" : ''/e;
    }

    # This is ugly, horrible and worse... but I do not want to mutulate
    # the message neither to clone it.  We do need to get rit of {<}
    local $msg->{_msgid} = $msgid;

    my $tr = $self->translator || $self->configure->translator;
    $tr->translate($msg, $lang, $msgctxt) || $msgid;
}

1;

__END__

# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package Log::Report::Translator;
use vars '$VERSION';
$VERSION = '1.15';


use warnings;
use strict;

use Log::Report 'log-report';
use Log::Report::Message;

use File::Spec ();
my %lexicons;

sub _fn_to_lexdir($);


sub new(@)
{   my $class = shift;
    (bless {}, $class)->init( {callerfn => (caller)[1], @_} );
}

sub init($)
{   my ($self, $args) = @_;

    my $lex = delete $args->{lexicons} || delete $args->{lexicon}
     || (ref $self eq __PACKAGE__ ? [] : _fn_to_lexdir $args->{callerfn});

    my @lex;
    foreach my $dir (ref $lex eq 'ARRAY' ? @$lex : $lex)
    {   unless(exists $INC{'Log/Report/Lexicon/Index.pm'})
        {   eval "require Log::Report::Lexicon::Index";
            panic $@ if $@;

            error __x"You have to upgrade Log::Report::Lexicon to at least 1.00"
                if $Log::Report::Lexicon::Index::VERSION < 1.00;
        }

        # lexicon indexes are shared
        my $l = $lexicons{$dir} ||= Log::Report::Lexicon::Index->new($dir);
        $l->index;   # index the files now
        push @lex, $l;
    }
    $self->{lexicons} = \@lex;
    $self->{charset}  = $args->{charset} || 'utf-8';
    $self;
}

sub _fn_to_lexdir($)
{   my $fn = shift;
    $fn =~ s/\.pm$//;
    File::Spec->catdir($fn, 'messages');
}

#------------

sub lexicons() { @{shift->{lexicons}} }


sub charset() {shift->{charset}}

#------------

# this is called as last resort: if a translator cannot find
# any lexicon or has no matching language.
sub translate($$$)
{   my $msg = $_[1];

      defined $msg->{_count} && $msg->{_count} != 1
    ? $msg->{_plural}
    : $msg->{_msgid};
}


sub load($@) { undef }

1;

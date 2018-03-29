# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package Dancer2::Plugin::LogReport;
use vars '$VERSION';
$VERSION = '1.15';


use warnings;
use strict;

use Dancer2::Plugin;
use Dancer2::Plugin::LogReport::Message;
use Log::Report  'log-report', syntax => 'REPORT',
    message_class => 'Dancer2::Plugin::LogReport::Message';

use Scalar::Util qw/blessed/;

my $_dsl;        # XXX How to avoid the global?   Dancer2::Core::DSL
my $_settings;


# "use" import
sub import
{   my $class = shift;
    Log::Report->import('+2', @_, syntax => 'LONG');
}

my %session_messages;
# The default reasons that a message will be displayed to the end user
my @default_reasons = qw/NOTICE WARNING MISTAKE ERROR FAULT ALERT FAILURE PANIC/;
my $hide_real_message; # Used to hide the real message to the end user
my $messages_variable = $_settings->{messages_key} || 'messages';


# Dancer2 import
on_plugin_import
{   my $dsl      = $_dsl      = shift;  # capture global singleton
    my $settings = $_settings = plugin_setting;

    # Need init_error for exceptions and other errors
    $dsl->hook(init_error => sub {
        my $error = shift;
        # Catch other exceptions. This hook is called for all errors
        # not just exceptions (including for example 404s), so check first.
        # If it's an exception then panic it to get Log::Report
        # to handle it nicely. If it's another error such as a 404
        # then exception will not be set.
        report 'PANIC' => $error->{exception}
            if $error->{exception};
    });

    if($settings->{handle_http_errors})
    {   # Need after_error for HTTP errors (eg 404) so as to
        # be able to change the forwarding location
        $dsl->hook(after_error => sub {
            my $error = shift;
            my $msg = __($error->status . ": "
              . Dancer2::Core::HTTP->status_message($error->status));

            # XXX This doesn't work at the moment. The DSL at this point
            # doesn't seem to respond to changes in the session or
            # forward requests
            _forward_home( $_dsl, $msg );
        });
    }

    $dsl->hook(after_layout_render => sub {
        my $session = $_dsl->app->session;
        $session->write($messages_variable => []);
    });

    # Define which messages are saved to the session for later display
    # to the user. This can be configured in the config file, or we
    # choose some sensible defaults.
    my $sm = $settings->{session_messages} // \@default_reasons;
    $session_messages{$_} = 1
        for ref $sm eq 'ARRAY' ? @$sm : $sm;

    # In a production server, we don't want the end user seeing (unexpected)
    # exception messages, for both security and usability. If we detect
    # that this is a production server (show_errors is 0), then we change
    # the specific error to a generic error, when displayed to the user.
    # The message can be customised in the config file.
    my $fatal_error_message = $settings->{fatal_error_message}
       // "An unexpected error has occurred";

    unless($dsl->app->config->{show_errors})
    {   $hide_real_message->{$_} = $fatal_error_message
            for qw/FAULT ALERT FAILURE PANIC/;
    }

    if(my $forward_template = $settings->{forward_template})
    {   # Add a route for the specified template
        $dsl->app->add_route
          ( method => 'get'
          , regexp => qr!^/\Q$forward_template\E$!,
          , code   => sub { shift->app->template($forward_template) }
          );
        # Forward to that new route
        $settings->{forward_url} = $forward_template;
    }

    # This is so that all messages go into the session, to be displayed
    # on the web page (if required)
    dispatcher CALLBACK => 'error_handler'
      , callback => \&_error_handler
      , mode     => 'DEBUG';

    Log::Report::Dispatcher->addSkipStack( sub { $_[0][0] =~
        m/ ^ Dancer2\:\:(?:Plugin|Logger)\:\:LogReport
         | ^ Dancer2\:\:Core\:\:Role\:\:DSL
         /x
    });

};    # ";" required!


sub process($$)
{   my ($dsl, $coderef) = @_;
    try { $coderef->() } hide => 'ALL';
    my $success = $@->died ? 0 : 1;
    $@->reportAll(is_fatal => 0);
    $success;
}

register process => \&process;

sub _message_add($)
{   my $msg = shift;

    return
        if ! $session_messages{$msg->reason}
        || $msg->inClass('no_session');

    my $app = $_dsl->app;
    unless($app->request)
    {   # This happens for HTTP errors
        # XXX the session is not available in the DSL
        report 'ASSERT' => "Unable to write message to session: unable to write cookie";
        return;
    }

    my $r = $msg->reason;
    if(my $newm = $hide_real_message->{$r})
    {   $msg    = __$newm;
        $msg->reason($r);
    }

    my $session = $app->session;
    my $msgs    = $session->read($messages_variable);
    push @$msgs, $msg;
    $session->write($messages_variable => $msgs);
}

#------

sub _forward_home($$)
{   my $dsl = shift;
    _message_add(shift);
    my $page = $_settings->{forward_url} || '/';
    $dsl->redirect($page);
}

sub _error_handler($$$$)
{   my ($disp, $options, $reason, $message) = @_;

    my $fatal_handler = sub {

        # Check whether this fatal message has been caught, in which case we
        # don't want to redirect
        return _message_add($_[0])
            if exists $options->{is_fatal} && !$options->{is_fatal};

        my $req = $_dsl->request
            or return;

        # Don't forward if it's a GET request to the error page, as it will
        # cause a recursive loop. In this case, do nothing, and let dancer
        # handle it.
        # return not needed because of Return::MultiLevel hack, but let's
        # leave it in anyway in hope.
        my $fwd_url = $_settings->{forward_url} || '';
        return _forward_home($_dsl, $_[0])
            if $req->uri ne $fwd_url || !$req->is_get;

        return;
    };

    $message->reason($reason);

    my %handler =
      ( # Default do nothing for the moment (TRACE|ASSERT|INFO)
        default => sub {_message_add $_[0]}

        # A user-created error condition that is not recoverable.
        # This could have already been caught by the process
        # subroutine, in which case we should continue running
        # of the program. In all other cases, we should bail
        # out.
      , ERROR   => $fatal_handler

        # 'FAULT', 'ALERT', 'FAILURE', 'PANIC'
        # All these are fatal errors.
      , FAULT   => $fatal_handler
      , ALERT   => $fatal_handler
      , FAILURE => $fatal_handler
      , PANIC   => $fatal_handler
      );

    my $call = $handler{$reason} || $handler{default};
    $call->($message);
}

sub _report($@) {
    my ($reason, $dsl) = (shift, shift);

    my $msg = (blessed($_[0]) && $_[0]->isa('Log::Report::Message'))
       ? $_[0] : Dancer2::Core::Role::Logger::_serialize(@_);

    if ($reason eq 'SUCCESS')
    {
        $msg = __$msg unless blessed $msg;
        $msg = $msg->clone(_class => 'success');
        $reason = 'NOTICE';
    }
    report uc($reason) => $msg;
}

register trace   => sub { _report(TRACE => @_) };
register assert  => sub { _report(ASSERT => @_) };
register notice  => sub { _report(NOTICE => @_) };
register mistake => sub { _report(MISTAKE => @_) };
register panic   => sub { _report(PANIC => @_) };
register alert   => sub { _report(ALERT => @_) };
register fault   => sub { _report(FAULT => @_) };
register failure => sub { _report(FAILURE => @_) };

register success => sub { _report(SUCCESS => @_) };

register_plugin for_versions => ['2'];

#----------


1;


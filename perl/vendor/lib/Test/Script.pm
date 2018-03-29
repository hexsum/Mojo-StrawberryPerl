package Test::Script;

# ABSTRACT: Basic cross-platform tests for scripts
our $VERSION = '1.12'; # VERSION


use 5.006;
use strict;
use warnings;
use Carp             ();
use Exporter         ();
use File::Spec       ();
use File::Spec::Unix ();
use Probe::Perl      ();
use IPC::Run3        qw( run3 );
use Test::Builder    ();
use File::Temp       ();
use File::Path       ();

our @ISA     = 'Exporter';
our @EXPORT  = qw{
  script_compiles
  script_compiles_ok
  script_runs
  script_stdout_is
  script_stdout_isnt
  script_stdout_like
  script_stdout_unlike
  script_stderr_is
  script_stderr_isnt
  script_stderr_like
  script_stderr_unlike
};

sub import {
  my $self = shift;
  my $pack = caller;
  my $test = Test::Builder->new;
  $test->exported_to($pack);
  $test->plan(@_);
  foreach ( @EXPORT ) {
    $self->export_to_level(1, $self, $_);
  }
}

my $perl = undef;

sub perl () {
  $perl or
  $perl = Probe::Perl->find_perl_interpreter;
}

sub path ($) {
  my $path = shift;
  unless ( defined $path ) {
    Carp::croak("Did not provide a script name");
  }
  if ( File::Spec::Unix->file_name_is_absolute($path) ) {
    Carp::croak("Script name must be relative");
  }
  File::Spec->catfile(
    File::Spec->curdir,
    split /\//, $path
  );
}

## This can and should be removed if/when IPC::Run3 is fixed on MSWin32
## See rt94685, rt46333, rt95308 and IPC-Run3/gh#9"
sub _borked_ipc_run3 () {
  $^O eq 'MSWin32' &&
  ! eval { IPC::Run3::run3 [ perl, -e => 'BEGIN {die}' ], \undef, \undef, \undef; 1 }
}

if(_borked_ipc_run3())
{
  no warnings 'redefine';
  *run3 = sub {
    $! = 0;
    my $r = IPC::Run3::run3(@_, { return_if_system_error => 1 });
    Carp::croak($!) if $! && $! !~ /Inappropriate I\/O control operation/;
    $r;
  };
}

#####################################################################
# Test Functions


sub script_compiles {
  my $args   = _script(shift);
  my $unix   = shift @$args;
  my $path   = path( $unix );
  my @libs   = map { "-I$_" } grep {!ref($_)} @INC;
  my $dir    = _preload_module();
  my $cmd    = [ perl, "-I$dir", '-M__TEST_SCRIPT__', '-c', $path, @$args ];
  my $stdin  = '';
  my $stdout = '';
  my $stderr = '';
  my $rv     = eval { run3( $cmd, \$stdin, \$stdout, \$stderr ) };
  my $error  = $@;
  my $exit   = $? ? ($? >> 8) : 0;
  my $signal = $? ? ($? & 127) : 0;
  my $ok     = !! (
    $error eq '' and $rv and $exit == 0 and $signal == 0 and $stderr =~ /syntax OK\s+\z/si
  );

  File::Path::rmtree($dir);

  my $test = Test::Builder->new;
  $test->ok( $ok, $_[0] || "Script $unix compiles" );
  $test->diag( "$exit - $stderr" ) unless $ok;
  $test->diag( "exception: $error" ) if $error;
  $test->diag( "signal: $signal" ) if $signal;

  return $ok;
}

# this is noticably slower for long @INC lists (sometimes present in cpantesters
# boxes) than the previous implementation, which added a -I for every element in
# @INC.  (also slower for more reasonable @INCs, but not noticably).  But it is
# safer as very long argument lists can break calls to system
sub _preload_module
{
  my $dir = File::Temp::tempdir( CLEANUP => 1 );
  # this is hopefully a pm file that nobody would use
  my $filename = File::Spec->catfile($dir, '__TEST_SCRIPT__.pm');
  my $fh;
  open($fh, ">$filename") 
    || die "unable to open $filename: $!";
  print($fh 'unshift @INC, ',
    join ',', 
    # quotemeta is overkill, but it will make sure that characters
    # like " are quoted
    map { '"' . quotemeta . '"' }
    grep { ! ref } @INC)
      || die "unable to write $filename: $!";
  close($fh) || die "unable to close $filename: $!";;
  $dir;
}


my $stdout;
my $stderr;

sub script_runs {
  my $args   = _script(shift);
  my $opt    = _options(\@_);
  my $unix   = shift @$args;
  my $path   = path( $unix );
  my $dir    = _preload_module();
  my $cmd    = [ perl, "-I$dir", '-M__TEST_SCRIPT__', $path, @$args ];
     $stdout = '';
     $stderr = '';
  my $rv     = eval { run3( $cmd, $opt->{stdin}, $opt->{stdout}, $opt->{stderr} ) };
  my $error  = $@;
  my $exit   = $? ? ($? >> 8) : 0;
  my $signal = $? ? ($? & 127) : 0;
  my $ok     = !! ( $error eq '' and $rv and $exit == $opt->{exit} and $signal == $opt->{signal} );

  File::Path::rmtree($dir);

  my $test = Test::Builder->new;
  $test->ok( $ok, $_[0] || "Script $unix runs" );
  $test->diag( "$exit - $stderr" ) unless $ok;
  $test->diag( "exception: $error" ) if $error;
  $test->diag( "signal: $signal" ) unless $signal == $opt->{signal};

  return $ok;
}

sub _like
{
  my($text, $pattern, $regex, $not, $name) = @_;
  
  my $ok = $regex ? $text =~ $pattern : $text eq $pattern;
  $ok = !$ok if $not;
  
  my $test = Test::Builder->new;
  $test->ok( $ok, $name );
  unless($ok) {
    $test->diag( "The output" );
    $test->diag( "  $_") for split /\n/, $text;
    $test->diag( $not ? "does match" : "does not match" );
    if($regex) {
      $test->diag( "  $pattern" );
    } else {
      $test->diag( "  $_" ) for split /\n/, $pattern;
    }
  }
  
  $ok;
}


sub script_stdout_is
{
  my($pattern, $name) = @_;
  @_ = ($stdout, $pattern, 0, 0, $name || 'stdout matches' );
  goto &_like;
}


sub script_stdout_isnt
{
  my($pattern, $name) = @_;
  @_ = ($stdout, $pattern, 0, 1, $name || 'stdout does not match' );
  goto &_like;
}


sub script_stdout_like
{
  my($pattern, $name) = @_;  
  @_ = ($stdout, $pattern, 1, 0, $name || 'stdout matches' );
  goto &_like;
}


sub script_stdout_unlike
{
  my($pattern, $name) = @_;
  @_ = ($stdout, $pattern, 1, 1, $name || 'stdout does not match' );
  goto &_like;
}


sub script_stderr_is
{
  my($pattern, $name) = @_;
  @_ = ($stderr, $pattern, 0, 0, $name || 'stderr matches' );
  goto &_like;
}


sub script_stderr_isnt
{
  my($pattern, $name) = @_;
  @_ = ($stderr, $pattern, 0, 1, $name || 'stderr does not match' );
  goto &_like;
}


sub script_stderr_like
{
  my($pattern, $name) = @_;  
  @_ = ($stderr, $pattern, 1, 0, $name || 'stderr matches' );
  goto &_like;
}


sub script_stderr_unlike
{
  my($pattern, $name) = @_;
  @_ = ($stderr, $pattern, 1, 1, $name || 'stderr does not match' );
  goto &_like;
}

######################################################################
# Support Functions

# Script params must be either a simple non-null string with the script
# name, or an array reference with one or more non-null strings.
sub _script {
  my $in = shift;
  if ( defined _STRING($in) ) {
    return [ $in ];
  }
  if ( _ARRAY($in) ) {
    unless ( scalar grep { not defined _STRING($_) } @$in ) {
      return $in;     
    }
  }
  Carp::croak("Invalid command parameter");
}

# Inline some basic Params::Util functions

sub _options {
  my %options = ref($_[0]->[0]) eq 'HASH' ? %{ shift @{ $_[0] } }: ();
  
  $options{exit}   = 0        unless defined $options{exit};
  $options{signal} = 0        unless defined $options{signal};
  my $stdin = '';
  $options{stdin}  = \$stdin  unless defined $options{stdin};
  $options{stdout} = \$stdout unless defined $options{stdout};
  $options{stderr} = \$stderr unless defined $options{stderr};

  \%options;
}

sub _ARRAY ($) {
  (ref $_[0] eq 'ARRAY' and @{$_[0]}) ? $_[0] : undef;
}

sub _STRING ($) {
  (defined $_[0] and ! ref $_[0] and length($_[0])) ? $_[0] : undef;
}

BEGIN {
  # Alias to old name
  *script_compiles_ok = *script_compiles;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Script - Basic cross-platform tests for scripts

=head1 VERSION

version 1.12

=head1 SYNOPSIS

 use Test::More tests => 2;
 use Test::Script;
 
 script_compiles('script/myscript.pl');
 script_runs(['script/myscript.pl', '--my-argument']);

=head1 DESCRIPTION

The intent of this module is to provide a series of basic tests for 80%
of the testing you will need to do for scripts in the F<script> (or F<bin>
as is also commonly used) paths of your Perl distribution.

Further, it aims to provide this functionality with perfect
platform-compatibility, and in a way that is as unobtrusive as possible.

That is, if the program works on a platform, then B<Test::Script>
should always work on that platform as well. Anything less than 100% is
considered unacceptable.

In doing so, it is hoped that B<Test::Script> can become a module that
you can safely make a dependency of all your modules, without risking that
your module won't on some platform because of the dependency.

Where a clash exists between wanting more functionality and maintaining
platform safety, this module will err on the side of platform safety.

=head1 FUNCTIONS

=head2 script_compiles

 script_compiles( $script, $test_name );

The L</script_compiles> test calls the script with "perl -c script.pl",
and checks that it returns without error.

The path it should be passed is a relative unix-format script name. This
will be localised when running C<perl -c> and if the test fails the local
name used will be shown in the diagnostic output.

Note also that the test will be run with the same L<perl> interpreter that
is running the test script (and not with the default system perl). This
will also be shown in the diagnostic output on failure.

=head2 script_runs

 script_runs( $script, $test_name );
 script_runs( \@script_and_arguments, $test_name );
 script_runs( $script, \%options, $test_name );
 script_runs( \@script_and_arguments, \%options, $test_name );

The L</script_runs> test executes the script with "perl script.pl" and checks
that it returns success.

The path it should be passed is a relative unix-format script name. This
will be localised when running C<perl -c> and if the test fails the local
name used will be shown in the diagnostic output.

The test will be run with the same L<perl> interpreter that is running the
test script (and not with the default system perl). This will also be shown
in the diagnostic output on failure.

You may pass in options as a hash as the second argument.

=over 4

=item exit

The expected exit value.  The default is to use whatever indicates success
on your platform (usually 0).

=item signal

The expected signal.  The default is 0.  Use with care!  This may not be
portable, and is known not to work on Windows.

=item stdin

The input to be passed into the script via stdin.  The value may be one of

=over 4

=item simple scalar

Is considered to be a filename.

=item scalar reference

In which case the input will be drawn from the data contained in the referenced
scalar.

=back

The behavior for any other types is undefined (the current implementation uses
L<IPC::Run3>, but that may change in the future).

=item stdout

Where to send the standard output to.  If you use this option, then the the
behavior of the C<script_stdout_> functions below are undefined.  The value
may be one of 

=over 4

=item simple scalar

Is considered to be a filename.

=item scalar reference

=back

In which case the standard output will be places into the referenced scalar

The behavior for any other types is undefined (the current implementation uses
L<IPC::Run3>, but that may change in the future).

=item stderr

Same as C<stdout> above, except for stderr.

=back

=head2 script_stdout_is

 script_stdout_is $expected_stdout, $test_name;

Tests if the output to stdout from the previous L</script_runs> matches the 
expected value exactly.

=head2 script_stdout_isnt

 script_stdout_is $expected_stdout, $test_name;

Tests if the output to stdout from the previous L</script_runs> does NOT match the 
expected value exactly.

=head2 script_stdout_like

 script_stdout_like $regex, $test_name;

Tests if the output to stdout from the previous L</script_runs> matches the regular
expression.

=head2 script_stdout_unlike

 script_stdout_unlike $regex, $test_name;

Tests if the output to stdout from the previous L</script_runs> does NOT match the regular
expression.

=head2 script_stderr_is

 script_stderr_is $expected_stderr, $test_name;

Tests if the output to stderr from the previous L</script_runs> matches the 
expected value exactly.

=head2 script_stderr_isnt

 script_stderr_is $expected_stderr, $test_name;

Tests if the output to stderr from the previous L</script_runs> does NOT match the 
expected value exactly.

=head2 script_stderr_like

 script_stderr_like $regex, $test_name;

Tests if the output to stderr from the previous L</script_runs> matches the regular
expression.

=head2 script_stderr_unlike

 script_stderr_unlike $regex, $test_name;

Tests if the output to stderr from the previous L</script_runs> does NOT match the regular
expression.

=head1 CAVEATS

This module is fully supported back to Perl 5.8.1.  It may work on 5.8.0.
It should work on Perl 5.6.x and I may even test on 5.6.2.  I will accept
patches to maintain compatibility for such older Perls, but you may
need to fix it on 5.6.x / 5.8.0 and send me a patch.

This module uses L<IPC::Run3> to compile and run scripts.  There are a number of
outstanding issues with this module, and maintenance for L<IPC::Run3> is not swift.
One of these is that L<IPC::Run3> incorrectly throws an exception on Windows when
you feed it a Perl script with a compile error.  Currently L<Test::Script> probes
for this bug (it checks for the bug, not for a specific version) and applies a
workaround in that case.  I am hoping to remove the work around once the bug is
fixed in L<IPC::Run3>.

=head1 SEE ALSO

L<Test::Script::Run>, L<Test::More>

=head1 AUTHOR

Original author: Adam Kennedy

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

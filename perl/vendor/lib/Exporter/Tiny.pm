package Exporter::Tiny;

use 5.006001;
use strict;
use warnings; no warnings qw(void once uninitialized numeric redefine);

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.042';
our @EXPORT_OK = qw< mkopt mkopt_hash _croak _carp >;

sub _croak ($;@) { require Carp; my $fmt = shift; @_ = sprintf($fmt, @_); goto \&Carp::croak }
sub _carp  ($;@) { require Carp; my $fmt = shift; @_ = sprintf($fmt, @_); goto \&Carp::carp }

my $_process_optlist = sub
{
	my $class = shift;
	my ($global_opts, $opts, $want, $not_want) = @_;
	
	while (@$opts)
	{
		my $opt = shift @{$opts};
		my ($name, $value) = @$opt;
		
		($name =~ m{\A\!(/.+/[msixpodual]+)\z}) ?
			do {
				my @not = $class->_exporter_expand_regexp($1, $value, $global_opts);
				++$not_want->{$_->[0]} for @not;
			} :
		($name =~ m{\A\!(.+)\z}) ?
			(++$not_want->{$1}) :
		($name =~ m{\A[:-](.+)\z}) ?
			push(@$opts, $class->_exporter_expand_tag($1, $value, $global_opts)) :
		($name =~ m{\A/.+/[msixpodual]+\z}) ?
			push(@$opts, $class->_exporter_expand_regexp($name, $value, $global_opts)) :
		# else ?
			push(@$want, $opt);
	}
};

sub import
{
	my $class = shift;
	my $global_opts = +{ @_ && ref($_[0]) eq q(HASH) ? %{+shift} : () };
	$global_opts->{into} = caller unless exists $global_opts->{into};
	
	my @want;
	my %not_want; $global_opts->{not} = \%not_want;
	my @args = do { no strict qw(refs); @_ ? @_ : @{"$class\::EXPORT"} };
	my $opts = mkopt(\@args);
	$class->$_process_optlist($global_opts, $opts, \@want, \%not_want);
	
	my $permitted = $class->_exporter_permitted_regexp($global_opts);
	$class->_exporter_validate_opts($global_opts);
	
	for my $wanted (@want)
	{
		next if $not_want{$wanted->[0]};
		
		my %symbols = $class->_exporter_expand_sub(@$wanted, $global_opts, $permitted);
		$class->_exporter_install_sub($_, $wanted->[1], $global_opts, $symbols{$_})
			for keys %symbols;
	}
}

sub unimport
{
	my $class = shift;
	my $global_opts = +{ @_ && ref($_[0]) eq q(HASH) ? %{+shift} : () };
	$global_opts->{into} = caller unless exists $global_opts->{into};
	$global_opts->{is_unimport} = 1;
	
	my @want;
	my %not_want; $global_opts->{not} = \%not_want;
	my @args = do { our %TRACKED; @_ ? @_ : keys(%{$TRACKED{$class}{$global_opts->{into}}}) };
	my $opts = mkopt(\@args);
	$class->$_process_optlist($global_opts, $opts, \@want, \%not_want);
	
	my $permitted = $class->_exporter_permitted_regexp($global_opts);
	$class->_exporter_validate_unimport_opts($global_opts);
	
	my $expando = $class->can('_exporter_expand_sub');
	$expando = undef if $expando == \&_exporter_expand_sub;
	
	for my $wanted (@want)
	{
		next if $not_want{$wanted->[0]};
		
		if ($wanted->[1])
		{
			_carp("Passing options to unimport '%s' makes no sense", $wanted->[0])
				unless (ref($wanted->[1]) eq 'HASH' and not keys %{$wanted->[1]});
		}
		
		my %symbols = defined($expando)
			? $class->$expando(@$wanted, $global_opts, $permitted)
			: ($wanted->[0] => sub { "dummy" });
		$class->_exporter_uninstall_sub($_, $wanted->[1], $global_opts)
			for keys %symbols;
	}
}

# Called once per import/unimport, passed the "global" import options.
# Expected to validate the options and carp or croak if there are problems.
# Can also take the opportunity to do other stuff if needed.
#
sub _exporter_validate_opts          { 1 }
sub _exporter_validate_unimport_opts { 1 }

# Called after expanding a tag or regexp to merge the tag's options with
# any sub-specific options.
#
sub _exporter_merge_opts
{
	my $class = shift;
	my ($tag_opts, $global_opts, @stuff) = @_;
	
	$tag_opts = {} unless ref($tag_opts) eq q(HASH);
	_croak('Cannot provide an -as option for tags')
		if exists $tag_opts->{-as};
	
	my $optlist = mkopt(\@stuff);
	for my $export (@$optlist)
	{
		next if defined($export->[1]) && ref($export->[1]) ne q(HASH);
		
		my %sub_opts = ( %{ $export->[1] or {} }, %$tag_opts );
		$sub_opts{-prefix} = sprintf('%s%s', $tag_opts->{-prefix}, $export->[1]{-prefix})
			if exists($export->[1]{-prefix}) && exists($tag_opts->{-prefix});
		$sub_opts{-suffix} = sprintf('%s%s', $export->[1]{-suffix}, $tag_opts->{-suffix})
			if exists($export->[1]{-suffix}) && exists($tag_opts->{-suffix});
		$export->[1] = \%sub_opts;
	}
	return @$optlist;
}

# Given a tag name, looks it up in %EXPORT_TAGS and returns the list of
# associated functions. The default implementation magically handles tags
# "all" and "default". The default implementation interprets any undefined
# tags as being global options.
# 
sub _exporter_expand_tag
{
	no strict qw(refs);
	
	my $class = shift;
	my ($name, $value, $globals) = @_;
	my $tags  = \%{"$class\::EXPORT_TAGS"};
	
	return $class->_exporter_merge_opts($value, $globals, $tags->{$name}->($class, @_))
		if ref($tags->{$name}) eq q(CODE);
	
	return $class->_exporter_merge_opts($value, $globals, @{$tags->{$name}})
		if exists $tags->{$name};
	
	return $class->_exporter_merge_opts($value, $globals, @{"$class\::EXPORT"}, @{"$class\::EXPORT_OK"})
		if $name eq 'all';
	
	return $class->_exporter_merge_opts($value, $globals, @{"$class\::EXPORT"})
		if $name eq 'default';
	
	$globals->{$name} = $value || 1;
	return;
}

# Given a regexp-like string, looks it up in @EXPORT_OK and returns the
# list of matching functions.
# 
sub _exporter_expand_regexp
{
	no strict qw(refs);
	our %TRACKED;
	
	my $class = shift;
	my ($name, $value, $globals) = @_;
	my $compiled = eval("qr$name");
	
	my @possible = $globals->{is_unimport}
		? keys( %{$TRACKED{$class}{$globals->{into}}} )
		: @{"$class\::EXPORT_OK"};
	
	$class->_exporter_merge_opts($value, $globals, grep /$compiled/, @possible);
}

# Helper for _exporter_expand_sub. Returns a regexp matching all subs in
# the exporter package which are available for export.
#
sub _exporter_permitted_regexp
{
	no strict qw(refs);
	my $class = shift;
	my $re = join "|", map quotemeta, sort {
		length($b) <=> length($a) or $a cmp $b
	} @{"$class\::EXPORT"}, @{"$class\::EXPORT_OK"};
	qr{^(?:$re)$}ms;
}

# Given a sub name, returns a hash of subs to install (usually just one sub).
# Keys are sub names, values are coderefs.
#
sub _exporter_expand_sub
{
	my $class = shift;
	my ($name, $value, $globals, $permitted) = @_;
	$permitted ||= $class->_exporter_permitted_regexp($globals);
	
	no strict qw(refs);
	
	if ($name =~ $permitted)
	{
		my $generator = $class->can("_generate_$name");
		return $name => $class->$generator($name, $value, $globals) if $generator;
		
		my $sub = $class->can($name);
		return $name => $sub if $sub;
	}
	
	$class->_exporter_fail(@_);
}

# Called by _exporter_expand_sub if it is unable to generate a key-value
# pair for a sub.
#
sub _exporter_fail
{
	my $class = shift;
	my ($name, $value, $globals) = @_;
	return if $globals->{is_unimport};
	_croak("Could not find sub '%s' exported by %s", $name, $class);
}

# Actually performs the installation of the sub into the target package. This
# also handles renaming the sub.
#
sub _exporter_install_sub
{
	my $class = shift;
	my ($name, $value, $globals, $sym) = @_;
	
	my $into      = $globals->{into};
	my $installer = $globals->{installer} || $globals->{exporter};
	
	$name = $value->{-as} || $name;
	unless (ref($name) eq q(SCALAR))
	{
		my ($prefix) = grep defined, $value->{-prefix}, $globals->{prefix}, q();
		my ($suffix) = grep defined, $value->{-suffix}, $globals->{suffix}, q();
		$name = "$prefix$name$suffix";
	}
	
	return ($$name = $sym)                       if ref($name) eq q(SCALAR);
	return ($into->{$name} = $sym)               if ref($into) eq q(HASH);
	
	no strict qw(refs);
	
	if (exists &{"$into\::$name"} and \&{"$into\::$name"} != $sym)
	{
		my ($level) = grep defined, $value->{-replace}, $globals->{replace}, q(0);
		my $action = {
			carp     => \&_carp,
			0        => \&_carp,
			''       => \&_carp,
			warn     => \&_carp,
			nonfatal => \&_carp,
			croak    => \&_croak,
			fatal    => \&_croak,
			die      => \&_croak,
		}->{$level} || sub {};
		
		$action->(
			$action == \&_croak
				? "Refusing to overwrite existing sub '%s::%s' with sub '%s' exported by %s"
				: "Overwriting existing sub '%s::%s' with sub '%s' exported by %s",
			$into,
			$name,
			$_[0],
			$class,
		);
	}
	
	our %TRACKED;
	$TRACKED{$class}{$into}{$name} = $sym;
	
	no warnings qw(prototype);
	$installer
		? $installer->($globals, [$name, $sym])
		: (*{"$into\::$name"} = $sym);
}

sub _exporter_uninstall_sub
{
	our %TRACKED;
	my $class = shift;
	my ($name, $value, $globals, $sym) = @_;
	my $into = $globals->{into};
	ref $into and return;
	
	no strict qw(refs);
	
	# Cowardly refuse to uninstall a sub that differs from the one
	# we installed!
	my $our_coderef = $TRACKED{$class}{$into}{$name};
	my $cur_coderef = exists(&{"$into\::$name"}) ? \&{"$into\::$name"} : -1;
	return unless $our_coderef == $cur_coderef;
	
	my $stash     = \%{"$into\::"};
	my $old       = delete $stash->{$name};
	my $full_name = join('::', $into, $name);
	foreach my $type (qw(SCALAR HASH ARRAY IO)) # everything but the CODE
	{
		next unless defined(*{$old}{$type});
		*$full_name = *{$old}{$type};
	}
	
	delete $TRACKED{$class}{$into}{$name};
}

sub mkopt
{
	my $in = shift or return [];
	my @out;
	
	$in = [map(($_ => ref($in->{$_}) ? $in->{$_} : ()), sort keys %$in)]
		if ref($in) eq q(HASH);
	
	for (my $i = 0; $i < @$in; $i++)
	{
		my $k = $in->[$i];
		my $v;
		
		($i == $#$in)         ? ($v = undef) :
		!defined($in->[$i+1]) ? (++$i, ($v = undef)) :
		!ref($in->[$i+1])     ? ($v = undef) :
		($v = $in->[++$i]);
		
		push @out, [ $k => $v ];
	}
	
	\@out;
}

sub mkopt_hash
{
	my $in  = shift or return;
	my %out = map +($_->[0] => $_->[1]), @{ mkopt($in) };
	\%out;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords frobnicate greps regexps

=head1 NAME

Exporter::Tiny - an exporter with the features of Sub::Exporter but only core dependencies

=head1 SYNOPSIS

   package MyUtils;
   use base "Exporter::Tiny";
   our @EXPORT = qw(frobnicate);
   sub frobnicate { my $n = shift; ... }
   1;

   package MyScript;
   use MyUtils "frobnicate" => { -as => "frob" };
   print frob(42);
   exit;

=head1 DESCRIPTION

Exporter::Tiny supports many of Sub::Exporter's external-facing features
including renaming imported functions with the C<< -as >>, C<< -prefix >> and
C<< -suffix >> options; explicit destinations with the C<< into >> option;
and alternative installers with the C<< installler >> option. But it's written
in only about 40% as many lines of code and with zero non-core dependencies.

Its internal-facing interface is closer to Exporter.pm, with configuration
done through the C<< @EXPORT >>, C<< @EXPORT_OK >> and C<< %EXPORT_TAGS >>
package variables.

Exporter::Tiny performs most of its internal duties (including resolution
of tag names to sub names, resolution of sub names to coderefs, and
installation of coderefs into the target package) as method calls, which
means they can be overridden to provide interesting behaviour.

=head2 Utility Functions

These are really for internal use, but can be exported if you need them.

=over

=item C<< mkopt(\@array) >>

Similar to C<mkopt> from L<Data::OptList>. It doesn't support all the
fancy options that Data::OptList does (C<moniker>, C<require_unique>,
C<must_be> and C<name_test>) but runs about 50% faster.

=item C<< mkopt_hash(\@array) >>

Similar to C<mkopt_hash> from L<Data::OptList>. See also C<mkopt>.

=back

=head1 TIPS AND TRICKS IMPORTING FROM EXPORTER::TINY

For the purposes of this discussion we'll assume we have a module called
C<< MyUtils >> which exports one function, C<< frobnicate >>. C<< MyUtils >>
inherits from Exporter::Tiny.

Many of these tricks may seem familiar from L<Sub::Exporter>. That is
intentional. Exporter::Tiny doesn't attempt to provide every feature of
Sub::Exporter, but where it does it usually uses a fairly similar API.

=head2 Basic importing

   # import "frobnicate" function
   use MyUtils "frobnicate";

   # import all functions that MyUtils offers
   use MyUtils -all;

=head2 Renaming imported functions

   # call it "frob"
   use MyUtils "frobnicate" => { -as => "frob" };

   # call it "my_frobnicate"
   use MyUtils "frobnicate" => { -prefix => "my_" };

   # can set a prefix for *all* functions imported from MyUtils
   # by placing the options hashref *first*.
   use MyUtils { prefix => "my_" }, "frobnicate";
   # (note the lack of hyphen before `prefix`.)

   # call it "frobnicate_util"
   use MyUtils "frobnicate" => { -suffix => "_util" };
   use MyUtils { suffix => "_util" }, "frobnicate";

   # import it twice with two different names
   use MyUtils
      "frobnicate" => { -as => "frob" },
      "frobnicate" => { -as => "frbnct" };

=head2 Lexical subs

   {
      use Sub::Exporter::Lexical lexical_installer => { -as => "lex" };
      use MyUtils { installer => lex }, "frobnicate";
      
      frobnicate(...);  # ok
   }
   
   frobnicate(...);  # not ok

=head2 Import functions into another package

   use MyUtils { into => "OtherPkg" }, "frobnicate";
   
   OtherPkg::frobincate(...);

=head2 Import functions into a scalar

   my $func;
   use MyUtils "frobnicate" => { -as => \$func };
   
   $func->(...);

=head2 Import functions into a hash

OK, Sub::Exporter doesn't do this...

   my %funcs;
   use MyUtils { into => \%funcs }, "frobnicate";
   
   $funcs{frobnicate}->(...);

=head2 DO NOT WANT!

This imports everything except "frobnicate":

   use MyUtils qw( -all !frobnicate );

Negated imports always "win", so the following will not import
"frobnicate", no matter how many times you repeat it...

   use MyUtils qw( !frobnicate frobnicate frobnicate frobnicate );

=head2 Importing by regexp

Here's how you could import all functions beginning with an "f":

   use MyUtils qw( /^F/i );

Or import everything except functions beginning with a "z":

   use MyUtils qw( -all !/^Z/i );

Note that regexps are always supplied as I<strings> starting with
C<< "/" >>, and not as quoted regexp references (C<< qr/.../ >>).

=head2 Unimporting

You can unimport the functions that MyUtils added to your namespace:

   no MyUtils;

Or just specific ones:

   no MyUtils qw(frobnicate);

If you renamed a function when you imported it, you should unimport by
the new name:

   use MyUtils frobnicate => { -as => "frob" };
   ...;
   no MyUtils "frob";

Unimporting using tags and regexps should mostly do what you want.

=head1 TIPS AND TRICKS EXPORTING USING EXPORTER::TINY

Simple configuration works the same as L<Exporter>; inherit from this module,
and use the C<< @EXPORT >>, C<< @EXPORT_OK >> and C<< %EXPORT_TAGS >>
package variables to list subs to export.

=head2 Generators

Exporter::Tiny has always allowed exported subs to be generated (like
L<Sub::Exporter>), but until version 0.025 did not have an especially nice
API for it.

Now, it's easy. If you want to generate a sub C<foo> to export, list it in
C<< @EXPORT >> or C<< @EXPORT_OK >> as usual, and then simply give your
exporter module a class method called C<< _generate_foo >>.

   push @EXPORT_OK, 'foo';
   
   sub _generate_foo {
      my $class = shift;
      my ($name, $args, $globals) = @_;
      
      return sub {
         ...;
      }
   }

You can also generate tags:

   my %constants;
   BEGIN {
      %constants = (FOO => 1, BAR => 2);
   }
   use constant \%constants;
   
   $EXPORT_TAGS{constants} = sub {
      my $class = shift;
      my ($name, $args, $globals) = @_;
      
      return keys(%constants);
   };

=head2 Overriding Internals

An important difference between L<Exporter> and Exporter::Tiny is that
the latter calls all its internal functions as I<< class methods >>. This
means that your subclass can I<< override them >> to alter their behaviour.

The following methods are available to be overridden. Despite being named
with a leading underscore, they are considered public methods. (The underscore
is there to avoid accidentally colliding with any of your own function names.)

=over

=item C<< _exporter_validate_opts($globals) >>

This method is called once each time C<import> is called. It is passed a
reference to the global options hash. (That is, the optional leading hashref
in the C<use> statement, where the C<into> and C<installer> options can be
provided.)

You may use this method to munge the global options, or validate them,
throwing an exception or printing a warning.

The default implementation does nothing interesting.

=item C<< _exporter_validate_unimport_opts($globals) >>

Like C<_exporter_validate_opts>, but called for C<unimport>.

=item C<< _exporter_merge_opts($tag_opts, $globals, @exports) >>

Called to merge options which have been provided for a tag into the
options provided for the exports that the tag expanded to.

=item C<< _exporter_expand_tag($name, $args, $globals) >>

This method is called to expand an import tag (e.g. C<< ":constants" >>).
It is passed the tag name (minus the leading ":"), an optional hashref
of options (like C<< { -prefix => "foo_" } >>), and the global options
hashref.

It is expected to return a list of ($name, $args) arrayref pairs. These
names can be sub names to export, or further tag names (which must have
their ":"). If returning tag names, be careful to avoid creating a tag
expansion loop!

The default implementation uses C<< %EXPORT_TAGS >> to expand tags, and
provides fallbacks for the C<< :default >> and C<< :all >> tags.

=item C<< _exporter_expand_regexp($regexp, $args, $globals) >>

Like C<_exporter_expand_regexp>, but given a regexp-like string instead
of a tag name.

The default implementation greps through C<< @EXPORT_OK >> for imports,
and the list of already-imported functions for exports.

=item C<< _exporter_expand_sub($name, $args, $globals) >>

This method is called to translate a sub name to a hash of name => coderef
pairs for exporting to the caller. In general, this would just be a hash with
one key and one value, but, for example, L<Type::Library> overrides this
method so that C<< "+Foo" >> gets expanded to:

   (
      Foo         => sub { $type },
      is_Foo      => sub { $type->check(@_) },
      to_Foo      => sub { $type->assert_coerce(@_) },
      assert_Foo  => sub { $type->assert_return(@_) },
   )

The default implementation checks that the name is allowed to be exported
(using the C<_exporter_permitted_regexp> method), gets the coderef using
the generator if there is one (or by calling C<< can >> on your exporter
otherwise) and calls C<_exporter_fail> if it's unable to generate or
retrieve a coderef.

=item C<< _exporter_permitted_regexp($globals) >>

This method is called to retrieve a regexp for validating the names of
exportable subs. If a sub doesn't match the regexp, then the default
implementation of C<_exporter_expand_sub> will refuse to export it. (Of
course, you may override the default C<_exporter_expand_sub>.)

The default implementation of this method assembles the regexp from
C<< @EXPORT >> and C<< @EXPORT_OK >>.

=item C<< _exporter_fail($name, $args, $globals) >>

Called by C<_exporter_expand_sub> if it can't find a coderef to export.

The default implementation just throws an exception. But you could emit
a warning instead, or just ignore the failed export.

If you don't throw an exception then you should be aware that this
method is called in list context, and any list it returns will be treated
as an C<_exporter_expand_sub>-style hash of names and coderefs for
export.

=item C<< _exporter_install_sub($name, $args, $globals, $coderef) >>

This method actually installs the exported sub into its new destination.
Its return value is ignored.

The default implementation handles sub renaming (i.e. the C<< -as >>,
C<< -prefix >> and C<< -suffix >> functions. This method does a lot of
stuff; if you need to override it, it's probably a good idea to just
pre-process the arguments and then call the super method rather than
trying to handle all of it yourself.

=item C<< _exporter_uninstall_sub($name, $args, $globals) >>

The opposite of C<_exporter_install_sub>.

=back

=head1 DIAGNOSTICS

=over

=item B<< Overwriting existing sub '%s::%s' with sub '%s' exported by %s >>

A warning issued if Exporter::Tiny is asked to export a symbol which
will result in an existing sub being overwritten. This warning can be
suppressed using either of the following:

   use MyUtils { replace => 1 }, "frobnicate";
   use MyUtils "frobnicate" => { -replace => 1 };

Or can be upgraded to a fatal error:

   use MyUtils { replace => "die" }, "frobnicate";
   use MyUtils "frobnicate" => { -replace => "die" };

=item B<< Refusing to overwrite existing sub '%s::%s' with sub '%s' exported by %s >>

The fatal version of the above warning.

=item B<< Could not find sub '%s' exported by %s >>

You requested to import a sub which the package does not provide.

=item B<< Cannot provide an -as option for tags >>

Because a tag may provide more than one function, it does not make sense
to request a single name for it. Instead use C<< -prefix >> or C<< -suffix >>.

=item B<< Passing options to unimport '%s' makes no sense >>

When you import a sub, it occasionally makes sense to pass some options
for it. However, when unimporting, options do nothing, so this warning
is issued.

=back

=head1 HISTORY

L<Type::Library> had a bunch of custom exporting code which poked coderefs
into its caller's stash. It needed this to be something more powerful than
most exporters so that it could switch between exporting Moose, Mouse and
Moo-compatible objects on request. L<Sub::Exporter> would have been capable,
but had too many dependencies for the Type::Tiny project.

Meanwhile L<Type::Utils>, L<Types::TypeTiny> and L<Test::TypeTiny> each
used the venerable L<Exporter.pm|Exporter>. However, this meant they were
unable to use the features like L<Sub::Exporter>-style function renaming
which I'd built into Type::Library:

   ## import "Str" but rename it to "String".
   use Types::Standard "Str" => { -as => "String" };

And so I decided to factor out code that could be shared by all Type-Tiny's
exporters into a single place: Exporter::TypeTiny.

As of version 0.026, Exporter::TypeTiny was also made available as
L<Exporter::Tiny>, distributed independently on CPAN. CHOCOLATEBOY had
convinced me that it was mature enough to live a life of its own.

As of version 0.030, Type-Tiny depends on Exporter::Tiny and
Exporter::TypeTiny is being phased out.

=head1 OBLIGATORY EXPORTER COMPARISON

Exporting is unlikely to be your application's performance bottleneck, but
nonetheless here are some comparisons.

B<< Comparative sizes according to L<Devel::SizeMe>: >>

   Exporter                     217.1Kb
   Sub::Exporter::Progressive   263.2Kb
   Exporter::Tiny               267.7Kb
   Exporter + Exporter::Heavy   281.5Kb
   Exporter::Renaming           406.2Kb
   Sub::Exporter                701.0Kb

B<< Performance exporting a single sub: >>

              Rate     SubExp    ExpTiny SubExpProg      ExpPM
SubExp      2489/s         --       -56%       -85%       -88%
ExpTiny     5635/s       126%         --       -67%       -72%
SubExpProg 16905/s       579%       200%         --       -16%
ExpPM      20097/s       707%       257%        19%         --

(Exporter::Renaming globally changes the behaviour of Exporter.pm, so could
not be included in the same benchmarks.)

B<< (Non-Core) Dependencies: >>

   Exporter                    -1
   Exporter::Renaming           0
   Exporter::Tiny               0
   Sub::Exporter::Progressive   0
   Sub::Exporter                3

B<< Features: >>

                                      ExpPM   ExpTiny SubExp  SubExpProg
 Can export code symbols............. Yes     Yes     Yes     Yes      
 Can export non-code symbols......... Yes                              
 Groups/tags......................... Yes     Yes     Yes     Yes      
 Export by regexp.................... Yes     Yes                      
 Bang prefix......................... Yes     Yes                      
 Allows renaming of subs.............         Yes     Yes     Maybe    
 Install code into scalar refs.......         Yes     Yes     Maybe    
 Can be passed an "into" parameter...         Yes     Yes     Maybe    
 Can be passed an "installer" sub....         Yes     Yes     Maybe    
 Config avoids package variables.....                 Yes              
 Supports generators.................         Yes     Yes              
 Sane API for generators.............         Yes     Yes              
 Unimport............................         Yes                      

(Certain Sub::Exporter::Progressive features are only available if
Sub::Exporter is installed.)

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Exporter-Tiny>.

=head1 SUPPORT

B<< IRC: >> support is available through in the I<< #moops >> channel
on L<irc.perl.org|http://www.irc.perl.org/channels.html>.

=head1 SEE ALSO

L<Exporter::Shiny>,
L<Sub::Exporter>,
L<Exporter>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


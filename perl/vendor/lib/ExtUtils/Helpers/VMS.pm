package ExtUtils::Helpers::VMS;
$ExtUtils::Helpers::VMS::VERSION = '0.022';
use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable split_like_shell detildefy/;

use ExtUtils::Helpers::Unix qw/split_like_shell/; # Probably very wrong, but whatever
use File::Copy qw/copy/;

sub make_executable {
	my $filename = shift;
	my $batchname = "$filename.com";
	copy($filename, $batchname);
	ExtUtils::Helpers::Unix::make_executable($batchname);
	return;
}

sub detildefy {
	my $arg = shift;

	# Apparently double ~ are not translated.
	return $arg if ($arg =~ /^~~/);

	# Apparently ~ followed by whitespace are not translated.
	return $arg if ($arg =~ /^~ /);

	if ($arg =~ /^~/) {
		my $spec = $arg;

		# Remove the tilde
		$spec =~ s/^~//;

		# Remove any slash following the tilde if present.
		$spec =~ s#^/##;

		# break up the paths for the merge
		my $home = VMS::Filespec::unixify($ENV{HOME});

		# In the default VMS mode, the trailing slash is present.
		# In Unix report mode it is not.  The parsing logic assumes that
		# it is present.
		$home .= '/' unless $home =~ m#/$#;

		# Trivial case of just ~ by it self
		if ($spec eq '') {
			$home =~ s#/$##;
			return $home;
		}

		my ($hvol, $hdir, $hfile) = File::Spec::Unix->splitpath($home);
		if ($hdir eq '') {
			 # Someone has tampered with $ENV{HOME}
			 # So hfile is probably the directory since this should be
			 # a path.
			 $hdir = $hfile;
		}

		my ($vol, $dir, $file) = File::Spec::Unix->splitpath($spec);

		my @hdirs = File::Spec::Unix->splitdir($hdir);
		my @dirs = File::Spec::Unix->splitdir($dir);

		my $newdirs;

		# Two cases of tilde handling
		if ($arg =~ m#^~/#) {

			# Simple case, just merge together
			$newdirs = File::Spec::Unix->catdir(@hdirs, @dirs);

		} else {

			# Complex case, need to add an updir - No delimiters
			my @backup = File::Spec::Unix->splitdir(File::Spec::Unix->updir);

			$newdirs = File::Spec::Unix->catdir(@hdirs, @backup, @dirs);

		}

		# Now put the two cases back together
		$arg = File::Spec::Unix->catpath($hvol, $newdirs, $file);

	}
	return $arg;
}

# ABSTRACT: VMS specific helper bits

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Helpers::VMS - VMS specific helper bits

=head1 VERSION

version 0.022

=for Pod::Coverage make_executable
detildefy

=head1 AUTHORS

=over 4

=item *

Ken Williams <kwilliams@cpan.org>

=item *

Leon Timmermans <leont@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ken Williams, Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

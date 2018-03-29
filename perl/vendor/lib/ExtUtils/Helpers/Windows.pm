package ExtUtils::Helpers::Windows;
$ExtUtils::Helpers::Windows::VERSION = '0.022';
use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable split_like_shell detildefy/;

use Config;
use Carp qw/carp croak/;

sub make_executable {
	my $script = shift;
	if (-T $script && $script !~ / \. (?:bat|cmd) $ /x) {
		_pl2bat(in => $script, update => 1);
	}
	return;
}

# This routine was copied almost verbatim from the 'pl2bat' utility
# distributed with perl. It requires too much voodoo with shell quoting
# differences and shortcomings between the various flavors of Windows
# to reliably shell out
sub _pl2bat {
	my %opts = @_;

	# NOTE: %0 is already enclosed in doublequotes by cmd.exe, as appropriate
	$opts{ntargs}    = '-x -S %0 %*';
	$opts{otherargs} = '-x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9';

	$opts{stripsuffix} = qr/\.plx?/ unless exists $opts{stripsuffix};

	if (not exists $opts{out}) {
		$opts{out} = $opts{in};
		$opts{out} =~ s/$opts{stripsuffix}$//i;
		$opts{out} .= '.bat' unless $opts{in} =~ /\.bat$/i or $opts{in} eq '-';
	}

	my $head = <<"EOT";
	\@rem = '--*-Perl-*--
	\@echo off
	if "%OS%" == "Windows_NT" goto WinNT
	perl $opts{otherargs}
	\@set ErrorLevel=%ErrorLevel%
	goto endofperl
	:WinNT
	perl $opts{ntargs}
	\@set ErrorLevel=%ErrorLevel%
	if NOT "%COMSPEC%" == "%SystemRoot%\\system32\\cmd.exe" goto endofperl
	if %errorlevel% == 9009 echo You do not have Perl in your PATH.
	goto endofperl
	\@rem ';
EOT

	$head =~ s/^\s+//gm;
	my $headlines = 2 + ($head =~ tr/\n/\n/);
	my $tail = <<'EOT';
	__END__
	:endofperl
	@"%COMSPEC%" /c exit /b %ErrorLevel%
EOT
	$tail =~ s/^\s+//gm;

	my $linedone = 0;
	my $taildone = 0;
	my $linenum = 0;
	my $skiplines = 0;

	my $start = $Config{startperl};
	$start = '#!perl' unless $start =~ /^#!.*perl/;

	open my $in, '<', $opts{in} or croak "Can't open $opts{in}: $!";
	my @file = <$in>;
	close $in;

	foreach my $line ( @file ) {
		$linenum++;
		if ( $line =~ /^:endofperl\b/ ) {
			if (!exists $opts{update}) {
				warn "$opts{in} has already been converted to a batch file!\n";
				return;
			}
			$taildone++;
		}
		if ( not $linedone and $line =~ /^#!.*perl/ ) {
			if (exists $opts{update}) {
				$skiplines = $linenum - 1;
				$line .= '#line '.(1+$headlines)."\n";
			} else {
	$line .= '#line '.($linenum+$headlines)."\n";
			}
	$linedone++;
		}
		if ( $line =~ /^#\s*line\b/ and $linenum == 2 + $skiplines ) {
			$line = '';
		}
	}

	open my $out, '>', $opts{out} or croak "Can't open $opts{out}: $!";
	print $out $head;
	print $out $start, ( $opts{usewarnings} ? ' -w' : '' ),
						 "\n#line ", ($headlines+1), "\n" unless $linedone;
	print $out @file[$skiplines..$#file];
	print $out $tail unless $taildone;
	close $out;

	return $opts{out};
}

sub split_like_shell {
	# As it turns out, Windows command-parsing is very different from
	# Unix command-parsing.	Double-quotes mean different things,
	# backslashes don't necessarily mean escapes, and so on.	So we
	# can't use Text::ParseWords::shellwords() to break a command string
	# into words.	The algorithm below was bashed out by Randy and Ken
	# (mostly Randy), and there are a lot of regression tests, so we
	# should feel free to adjust if desired.

	local ($_) = @_;

	my @argv;
	return @argv unless defined && length;

	my $arg = '';
	my ($i, $quote_mode ) = ( 0, 0 );

	while ( $i < length ) {

		my $ch      = substr $_, $i, 1;
		my $next_ch = substr $_, $i+1, 1;

		if ( $ch eq '\\' && $next_ch eq '"' ) {
			$arg .= '"';
			$i++;
		} elsif ( $ch eq '\\' && $next_ch eq '\\' ) {
			$arg .= '\\';
			$i++;
		} elsif ( $ch eq '"' && $next_ch eq '"' && $quote_mode ) {
			$quote_mode = !$quote_mode;
			$arg .= '"';
			$i++;
		} elsif ( $ch eq '"' && $next_ch eq '"' && !$quote_mode &&
				( $i + 2 == length() || substr( $_, $i + 2, 1 ) eq ' ' )
			) { # for cases like: a"" => [ 'a' ]
			push @argv, $arg;
			$arg = '';
			$i += 2;
		} elsif ( $ch eq '"' ) {
			$quote_mode = !$quote_mode;
		} elsif ( $ch =~ /\s/ && !$quote_mode ) {
			push @argv, $arg if $arg;
			$arg = '';
			++$i while substr( $_, $i + 1, 1 ) =~ /\s/;
		} else {
			$arg .= $ch;
		}

		$i++;
	}

	push @argv, $arg if defined $arg && length $arg;
	return @argv;
}

sub detildefy {
	my $value = shift;
	$value =~ s{ ^ ~ (?= [/\\] | $ ) }[$ENV{USERPROFILE}]x if $ENV{USERPROFILE};
	return $value;
}

1;

# ABSTRACT: Windows specific helper bits

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Helpers::Windows - Windows specific helper bits

=head1 VERSION

version 0.022

=for Pod::Coverage make_executable
split_like_shell
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

package List::MoreUtils::XS;

use 5.006;
use strict;
use warnings;

use vars qw{$VERSION @ISA};

BEGIN
{
    $VERSION = '0.415';

    # Load the XS at compile-time so that redefinition warnings will be
    # thrown correctly if the XS versions of part or indexes loaded
    my $ldr = <<EOLDR;
	package List::MoreUtils;

	# PERL_DL_NONLAZY must be false, or any errors in loading will just
	# cause the perl code to be tested
	local \$ENV{PERL_DL_NONLAZY} = 0 if \$ENV{PERL_DL_NONLAZY};

	use XSLoader ();
	XSLoader::load("List::MoreUtils", "$VERSION");

	1;
EOLDR

    eval $ldr unless $ENV{LIST_MOREUTILS_PP};

    # ensure to catch even PP only subs
    my @pp_imp = map { "List::MoreUtils->can(\"$_\") or *$_ = \\&List::MoreUtils::PP::$_;" }
      qw(any all none notall one any_u all_u none_u notall_u one_u true false
      firstidx firstval firstres lastidx lastval lastres onlyidx onlyval onlyres
      insert_after insert_after_string
      apply after after_incl before before_incl
      each_array each_arrayref pairwise
      natatime mesh uniq singleton minmax part indexes bsearch bsearchidx
      sort_by nsort_by _XScompiled);
    my $pp_stuff = join( "\n", "use List::MoreUtils::PP;", "package List::MoreUtils;", @pp_imp );
    eval $pp_stuff;
    die $@ if $@;
}

=pod

=head1 NAME

List::MoreUtils::XS - Provide compiled List::MoreUtils functions

=head1 SYNOPSIS

  BEGIN { delete $ENV{LIST_MOREUTILS_PP}; }
  use List::MoreUtils ...;

=head1 SEE ALSO

L<List::Util>, L<List::AllUtils>

=head1 AUTHOR

Jens Rehsack E<lt>rehsack AT cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Tassilo von Parseval E<lt>tassilo.von.parseval@rwth-aachen.deE<gt>

=head1 COPYRIGHT AND LICENSE

Some parts copyright 2011 Aaron Crane.

Copyright 2004 - 2010 by Tassilo von Parseval

Copyright 2013 - 2016 by Jens Rehsack

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

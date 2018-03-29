#!perl
# Filename     - cvtbdf.pl
# Author       - Geoff Baysinger (gbaysing@HiWAAY.net)
# Purpose      - Allows "simple" installation of additional BDF fonts for GD.pm
# Usage        - "cvtbdf.pl" (no arguments, see instructions)
# License      - Freely given to be distributed with the GD.pm libraries
#                (you may modify this script to your heart's content,
#                 but it may only be distributed by the author or via the GD.pm
#                 package.)
#
# Summary      -
#   Uses "bdftogd", (provided with GD.pm) to convert BDF fonts to GD format.
#   It should makes the edits necessary to the GD.pm source files so that.
#   the "bdftogd" process is automated and all the user needs do is recompile
#   the GD.pm package (only "GD.so" is changed during compilation).
#
# Instructions -
#   1) go to your GD.pm source installation directory
#      note: if you have already installed GD.pm, run a "make clean"
#   2) create a subdirectory called "fonts" (mkdir fonts)
#   3) copy the BDF font files you wish to convert to the "fonts" directory
#      note: The BDF font must be a type that "bdftogd" can convert, hence
#            it must be a standard monospaced character font, not a BDF
#            cursor file. Some monospaced fonts may still not work. Test
#            with "bdftogd" before running this script if you are unsure.
#   4) copy "bdftogd" and "cvtbdf.pl" to the "fonts" directory
#   5) run "cvtbdf.pl"
#   6) go to your GD.pm source installation directory and install the new
#      version via a "make" and "make install"
#
# Notes        -
#   A) Keep the "fonts" subdirectory and all fonts you wish to use in the
#      future. Each time you want to add a font you will need the old ones
#      in the directory, or they will disappear during the next recompile.
#   B) Add new fonts in the future is as easy as copying the .bdf file to
#      the "fonts" directory and running steps #5 and #6 again.
#
# Thanks       -
#   To Lincoln Stein for the use of CGI.pm and GD.pm and to all other
#   contributors of those packages.

# make sure we have the conversion program
if (! -x "bdftogd") { die "OOPS!\n  Can't execute 'bdftogd', is it even there?\n  error: $!\n\n"; }

&badnames;
&saveorig("GD.pm","GD.xs","libgd/Makefile.PL");
&copyorig("GD.pm","GD.xs","libgd/Makefile.PL");

for $i (@files) {
  open(OLDXS,"../GD.xs") || die "OOPS!\n  Can't open '../GD.xs' for reading\n  Make sure you're in a 'fonts' subdirectory\n  error: $!\n\n";
  open(NEWXS,"> ../GD.xs.fonts") || die "OOPS!\n  Can't open '../GD.xs.fonts' for writing\n  Make sure you're in a 'fonts' subdirectory\n  error: $!\n\n";
  open(OLDPM,"../GD.pm") || die "OOPS!\n  Can't open '../GD.pm' for reading\n  Make sure you're in a 'fonts' subdirectory\n  error: $!\n\n";
  open(NEWPM,"> ../GD.pm.fonts") || die "OOPS!\n  Can't open '../GD.pm.fonts' for writing\n  Make sure you're in a 'fonts' subdirectory\n  error: $!\n\n";
  open(OLDMAKE,"../libgd/Makefile.PL") || die "OOPS!\n  Can't open '../libgd/Makefile.PL' for reading\n  Make sure you're in a 'fonts' subdirectory\n  error: $!\n\n";
  open(NEWMAKE,"> ../libgd/Makefile.PL.fonts") || die "OOPS!\n  Can't open '../libgd/Makefile.PL.fonts' for writing\n  Make sure you're in a 'fonts' subdirectory\n  error: $!\n\n";

# some state-keeping variables
  my $extern;
  my $package;
  my $export;
  my $preload;
  my $h;
  my $c;

# figure out our "name"
  my $name = "BDF" . $i;
  $name =~ /(.*)\.bdf/;
  $name = $1;
  print "=> name = $name\n";


# do the actual font conversion:
  open(FONT,"$i");
# usage: bdftogd fontname filename, eg. bdftogd FontLarge gdfontl }
  my $fontname = "Font" . $name;
  my $filename = "font" . $name;
  my $gdname = "gdfont" . $name;
  open(CONVERT,"| bdftogd $fontname $filename");
  while (<FONT>) { print CONVERT; }
  close CONVERT;
# move the font files to "../libgd"
  open(OLD,"${gdname}.h");
  open(NEW,"> ../libgd/${gdname}.h");
  while (<OLD>) { print NEW; }
  close OLD;
  close NEW;
  unlink("${gdname}.h");
  open(OLD,"${gdname}.c");
  open(NEW,"> ../libgd/${gdname}.c");
  while (<OLD>) { print NEW; }
  close OLD;
  close NEW;
  unlink("${gdname}.c");

## Begin editing files
# GD.xs:
  while (<OLDXS>) {
    $data = $_;
    if (! $extern && $data =~ /^extern[\s]{1,}gdFontPtr/) {
      $data = "extern  gdFontPtr       gdFont" . $name . ";\n" . $data;
      $extern = 1;
    } elsif (! $package && $data =~ /^MODULE[\s]*=[\s]*GD[\s]{1,}PACKAGE[\s]*=[\s]*GD::Font[\s]{1,}PREFIX=gd/) {
      $data .= "\nGD::Font\ngd" . $name . "(packname=\"GD::Font\")\n        char *  packname\n        PROTOTYPE: \$\n        CODE:\n        {\n                RETVAL = gdFont" . $name . ";\n        }\n        OUTPUT:\n                RETVAL\n";
      $package = 1;
    }
    print NEWXS $data;
  }

# GD.pm:
  while (<OLDPM>) {
    $data = $_;
    if (! $export && $data =~ /\@EXPORT = qw\(/) {
      $data .= "        gd" . $name . "Font\n";
      $export = "done";
    } elsif (! $preload && $data =~ /^# Preloaded methods go here./) {
      $data .= "sub GD::gd" . $name . "Font {\n    return &GD::Font::" . $name . ";\n}\n";
      $preload = "done";
    }
    print NEWPM $data;
  }

# libgd/Makefile.PL:
  while (<OLDMAKE>) {
    $data = $_;
#        'H'         => [qw(gd.h gdfontl.h gdfonts.h io.h gdfontg.h gdfontmb.h gdfontt.h mtables.h)],
    if (! $h && $data =~ /^([\s]*'H'[\s]*\=\>[\s]*\[qw\(gd\.h[\s])(.*)/) {
      $data = $1 . "${gdname}.h " . $2 . "\n";
      $h = "done";
    } elsif (! $c && $data =~ /^([\s]*'C'[\s]*\=\>[\s]*\[qw\(gdfontg\.c[\s])(.*)/) {
#        'C'         => [qw(gdfontg.c gdfontmb.c gdfontt.c gdfontl.c gdfonts.c libgd.c)],
      $data = $1 . "${gdname}.c " . $2 . "\n";
      $c = "done";
    }
    print NEWMAKE $data;
  }

# close the files
  close OLDXS;
  close NEWXS;
  close OLDPM;
  close NEWPM;
  close OLDMAKE;
  close NEWMAKE;

# copy the files to the proper extension
  open(NEWXS,"../GD.xs.fonts");
  open(OLDXS,"> ../GD.xs");
  open(NEWPM,"../GD.pm.fonts");
  open(OLDPM,"> ../GD.pm");
  open(NEWMAKE,"../libgd/Makefile.PL.fonts");
  open(OLDMAKE,"> ../libgd/Makefile.PL");
  while (<NEWXS>) { print OLDXS; }
  while (<NEWPM>) { print OLDPM; }
  while (<NEWMAKE>) { print OLDMAKE; }
  close NEWXS;
  close OLDXS;
  close NEWPM;
  close OLDPM;
  close NEWMAKE;
  close OLDMAKE;

# unlink the temp files
  unlink "../GD.pm.fonts";
  unlink "../GD.xs.fonts";
  unlink "../libgd/Makefile.PL.fonts";
}

sub saveorig {
  local (@files) = @_;
  for $file (@files) {
    if (! -f "../${file}.orig") {
      open(OLD,"../$file") || die $!;
      open(ORIG,"> ../${file}.orig") || die $!;
      while (<OLD>) { print ORIG; }
      close OLD;
      close ORIG;
    }
  }
}

sub copyorig {
  local(@files) = @_;
  for $file (@files) {
    open(ORIG,"../${file}.orig") || die $!;
    open(NEW,"> ../$file") || die $!;
    while (<ORIG>) { print NEW; }
    close ORIG;
    close NEW;
  }
}

sub badnames {
  @badnames = (<*.BDF>,<*.Bdf>,<*.BDf>,<*.bDf>,<*.bDF>,<*.BdF>);
  for $i (@badnames) {
    my $goodname = $i;
    $goodname =~ tr/A-Z/a-z/;
    open(BAD,"$i");
    open(GOOD,"> $goodname");
    while (<BAD>) { print GOOD; }
    close BAD;
    close GOOD;
    unlink $i;
  }
  @files = <*.bdf>;
}


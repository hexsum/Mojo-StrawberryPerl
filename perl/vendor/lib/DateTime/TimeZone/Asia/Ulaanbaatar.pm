# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/JvovdcV6u5/asia.  Olson data version 2016d
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Asia::Ulaanbaatar;
$DateTime::TimeZone::Asia::Ulaanbaatar::VERSION = '1.98';
use strict;

use Class::Singleton 1.03;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Asia::Ulaanbaatar::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY, #    utc_start
60102751948, #      utc_end 1905-07-31 16:52:28 (Mon)
DateTime::TimeZone::NEG_INFINITY, #  local_start
60102777600, #    local_end 1905-08-01 00:00:00 (Tue)
25652,
0,
'LMT',
    ],
    [
60102751948, #    utc_start 1905-07-31 16:52:28 (Mon)
62388118800, #      utc_end 1977-12-31 17:00:00 (Sat)
60102777148, #  local_start 1905-07-31 23:52:28 (Mon)
62388144000, #    local_end 1978-01-01 00:00:00 (Sun)
25200,
0,
'ULAT',
    ],
    [
62388118800, #    utc_start 1977-12-31 17:00:00 (Sat)
62553657600, #      utc_end 1983-03-31 16:00:00 (Thu)
62388147600, #  local_start 1978-01-01 01:00:00 (Sun)
62553686400, #    local_end 1983-04-01 00:00:00 (Fri)
28800,
0,
'ULAT',
    ],
    [
62553657600, #    utc_start 1983-03-31 16:00:00 (Thu)
62569465200, #      utc_end 1983-09-30 15:00:00 (Fri)
62553690000, #  local_start 1983-04-01 01:00:00 (Fri)
62569497600, #    local_end 1983-10-01 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
62569465200, #    utc_start 1983-09-30 15:00:00 (Fri)
62585280000, #      utc_end 1984-03-31 16:00:00 (Sat)
62569494000, #  local_start 1983-09-30 23:00:00 (Fri)
62585308800, #    local_end 1984-04-01 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62585280000, #    utc_start 1984-03-31 16:00:00 (Sat)
62601001200, #      utc_end 1984-09-29 15:00:00 (Sat)
62585312400, #  local_start 1984-04-01 01:00:00 (Sun)
62601033600, #    local_end 1984-09-30 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62601001200, #    utc_start 1984-09-29 15:00:00 (Sat)
62616729600, #      utc_end 1985-03-30 16:00:00 (Sat)
62601030000, #  local_start 1984-09-29 23:00:00 (Sat)
62616758400, #    local_end 1985-03-31 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62616729600, #    utc_start 1985-03-30 16:00:00 (Sat)
62632450800, #      utc_end 1985-09-28 15:00:00 (Sat)
62616762000, #  local_start 1985-03-31 01:00:00 (Sun)
62632483200, #    local_end 1985-09-29 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62632450800, #    utc_start 1985-09-28 15:00:00 (Sat)
62648179200, #      utc_end 1986-03-29 16:00:00 (Sat)
62632479600, #  local_start 1985-09-28 23:00:00 (Sat)
62648208000, #    local_end 1986-03-30 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62648179200, #    utc_start 1986-03-29 16:00:00 (Sat)
62663900400, #      utc_end 1986-09-27 15:00:00 (Sat)
62648211600, #  local_start 1986-03-30 01:00:00 (Sun)
62663932800, #    local_end 1986-09-28 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62663900400, #    utc_start 1986-09-27 15:00:00 (Sat)
62679628800, #      utc_end 1987-03-28 16:00:00 (Sat)
62663929200, #  local_start 1986-09-27 23:00:00 (Sat)
62679657600, #    local_end 1987-03-29 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62679628800, #    utc_start 1987-03-28 16:00:00 (Sat)
62695350000, #      utc_end 1987-09-26 15:00:00 (Sat)
62679661200, #  local_start 1987-03-29 01:00:00 (Sun)
62695382400, #    local_end 1987-09-27 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62695350000, #    utc_start 1987-09-26 15:00:00 (Sat)
62711078400, #      utc_end 1988-03-26 16:00:00 (Sat)
62695378800, #  local_start 1987-09-26 23:00:00 (Sat)
62711107200, #    local_end 1988-03-27 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62711078400, #    utc_start 1988-03-26 16:00:00 (Sat)
62726799600, #      utc_end 1988-09-24 15:00:00 (Sat)
62711110800, #  local_start 1988-03-27 01:00:00 (Sun)
62726832000, #    local_end 1988-09-25 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62726799600, #    utc_start 1988-09-24 15:00:00 (Sat)
62742528000, #      utc_end 1989-03-25 16:00:00 (Sat)
62726828400, #  local_start 1988-09-24 23:00:00 (Sat)
62742556800, #    local_end 1989-03-26 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62742528000, #    utc_start 1989-03-25 16:00:00 (Sat)
62758249200, #      utc_end 1989-09-23 15:00:00 (Sat)
62742560400, #  local_start 1989-03-26 01:00:00 (Sun)
62758281600, #    local_end 1989-09-24 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62758249200, #    utc_start 1989-09-23 15:00:00 (Sat)
62773977600, #      utc_end 1990-03-24 16:00:00 (Sat)
62758278000, #  local_start 1989-09-23 23:00:00 (Sat)
62774006400, #    local_end 1990-03-25 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62773977600, #    utc_start 1990-03-24 16:00:00 (Sat)
62790303600, #      utc_end 1990-09-29 15:00:00 (Sat)
62774010000, #  local_start 1990-03-25 01:00:00 (Sun)
62790336000, #    local_end 1990-09-30 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62790303600, #    utc_start 1990-09-29 15:00:00 (Sat)
62806032000, #      utc_end 1991-03-30 16:00:00 (Sat)
62790332400, #  local_start 1990-09-29 23:00:00 (Sat)
62806060800, #    local_end 1991-03-31 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62806032000, #    utc_start 1991-03-30 16:00:00 (Sat)
62821753200, #      utc_end 1991-09-28 15:00:00 (Sat)
62806064400, #  local_start 1991-03-31 01:00:00 (Sun)
62821785600, #    local_end 1991-09-29 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62821753200, #    utc_start 1991-09-28 15:00:00 (Sat)
62837481600, #      utc_end 1992-03-28 16:00:00 (Sat)
62821782000, #  local_start 1991-09-28 23:00:00 (Sat)
62837510400, #    local_end 1992-03-29 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62837481600, #    utc_start 1992-03-28 16:00:00 (Sat)
62853202800, #      utc_end 1992-09-26 15:00:00 (Sat)
62837514000, #  local_start 1992-03-29 01:00:00 (Sun)
62853235200, #    local_end 1992-09-27 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62853202800, #    utc_start 1992-09-26 15:00:00 (Sat)
62868931200, #      utc_end 1993-03-27 16:00:00 (Sat)
62853231600, #  local_start 1992-09-26 23:00:00 (Sat)
62868960000, #    local_end 1993-03-28 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62868931200, #    utc_start 1993-03-27 16:00:00 (Sat)
62884652400, #      utc_end 1993-09-25 15:00:00 (Sat)
62868963600, #  local_start 1993-03-28 01:00:00 (Sun)
62884684800, #    local_end 1993-09-26 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62884652400, #    utc_start 1993-09-25 15:00:00 (Sat)
62900380800, #      utc_end 1994-03-26 16:00:00 (Sat)
62884681200, #  local_start 1993-09-25 23:00:00 (Sat)
62900409600, #    local_end 1994-03-27 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62900380800, #    utc_start 1994-03-26 16:00:00 (Sat)
62916102000, #      utc_end 1994-09-24 15:00:00 (Sat)
62900413200, #  local_start 1994-03-27 01:00:00 (Sun)
62916134400, #    local_end 1994-09-25 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62916102000, #    utc_start 1994-09-24 15:00:00 (Sat)
62931830400, #      utc_end 1995-03-25 16:00:00 (Sat)
62916130800, #  local_start 1994-09-24 23:00:00 (Sat)
62931859200, #    local_end 1995-03-26 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62931830400, #    utc_start 1995-03-25 16:00:00 (Sat)
62947551600, #      utc_end 1995-09-23 15:00:00 (Sat)
62931862800, #  local_start 1995-03-26 01:00:00 (Sun)
62947584000, #    local_end 1995-09-24 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62947551600, #    utc_start 1995-09-23 15:00:00 (Sat)
62963884800, #      utc_end 1996-03-30 16:00:00 (Sat)
62947580400, #  local_start 1995-09-23 23:00:00 (Sat)
62963913600, #    local_end 1996-03-31 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62963884800, #    utc_start 1996-03-30 16:00:00 (Sat)
62979606000, #      utc_end 1996-09-28 15:00:00 (Sat)
62963917200, #  local_start 1996-03-31 01:00:00 (Sun)
62979638400, #    local_end 1996-09-29 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
62979606000, #    utc_start 1996-09-28 15:00:00 (Sat)
62995334400, #      utc_end 1997-03-29 16:00:00 (Sat)
62979634800, #  local_start 1996-09-28 23:00:00 (Sat)
62995363200, #    local_end 1997-03-30 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
62995334400, #    utc_start 1997-03-29 16:00:00 (Sat)
63011055600, #      utc_end 1997-09-27 15:00:00 (Sat)
62995366800, #  local_start 1997-03-30 01:00:00 (Sun)
63011088000, #    local_end 1997-09-28 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
63011055600, #    utc_start 1997-09-27 15:00:00 (Sat)
63026784000, #      utc_end 1998-03-28 16:00:00 (Sat)
63011084400, #  local_start 1997-09-27 23:00:00 (Sat)
63026812800, #    local_end 1998-03-29 00:00:00 (Sun)
28800,
0,
'ULAT',
    ],
    [
63026784000, #    utc_start 1998-03-28 16:00:00 (Sat)
63042505200, #      utc_end 1998-09-26 15:00:00 (Sat)
63026816400, #  local_start 1998-03-29 01:00:00 (Sun)
63042537600, #    local_end 1998-09-27 00:00:00 (Sun)
32400,
1,
'ULAST',
    ],
    [
63042505200, #    utc_start 1998-09-26 15:00:00 (Sat)
63124077600, #      utc_end 2001-04-27 18:00:00 (Fri)
63042534000, #  local_start 1998-09-26 23:00:00 (Sat)
63124106400, #    local_end 2001-04-28 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63124077600, #    utc_start 2001-04-27 18:00:00 (Fri)
63137379600, #      utc_end 2001-09-28 17:00:00 (Fri)
63124110000, #  local_start 2001-04-28 03:00:00 (Sat)
63137412000, #    local_end 2001-09-29 02:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63137379600, #    utc_start 2001-09-28 17:00:00 (Fri)
63153108000, #      utc_end 2002-03-29 18:00:00 (Fri)
63137408400, #  local_start 2001-09-29 01:00:00 (Sat)
63153136800, #    local_end 2002-03-30 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63153108000, #    utc_start 2002-03-29 18:00:00 (Fri)
63168829200, #      utc_end 2002-09-27 17:00:00 (Fri)
63153140400, #  local_start 2002-03-30 03:00:00 (Sat)
63168861600, #    local_end 2002-09-28 02:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63168829200, #    utc_start 2002-09-27 17:00:00 (Fri)
63184557600, #      utc_end 2003-03-28 18:00:00 (Fri)
63168858000, #  local_start 2002-09-28 01:00:00 (Sat)
63184586400, #    local_end 2003-03-29 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63184557600, #    utc_start 2003-03-28 18:00:00 (Fri)
63200278800, #      utc_end 2003-09-26 17:00:00 (Fri)
63184590000, #  local_start 2003-03-29 03:00:00 (Sat)
63200311200, #    local_end 2003-09-27 02:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63200278800, #    utc_start 2003-09-26 17:00:00 (Fri)
63216007200, #      utc_end 2004-03-26 18:00:00 (Fri)
63200307600, #  local_start 2003-09-27 01:00:00 (Sat)
63216036000, #    local_end 2004-03-27 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63216007200, #    utc_start 2004-03-26 18:00:00 (Fri)
63231728400, #      utc_end 2004-09-24 17:00:00 (Fri)
63216039600, #  local_start 2004-03-27 03:00:00 (Sat)
63231760800, #    local_end 2004-09-25 02:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63231728400, #    utc_start 2004-09-24 17:00:00 (Fri)
63247456800, #      utc_end 2005-03-25 18:00:00 (Fri)
63231757200, #  local_start 2004-09-25 01:00:00 (Sat)
63247485600, #    local_end 2005-03-26 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63247456800, #    utc_start 2005-03-25 18:00:00 (Fri)
63263178000, #      utc_end 2005-09-23 17:00:00 (Fri)
63247489200, #  local_start 2005-03-26 03:00:00 (Sat)
63263210400, #    local_end 2005-09-24 02:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63263178000, #    utc_start 2005-09-23 17:00:00 (Fri)
63278906400, #      utc_end 2006-03-24 18:00:00 (Fri)
63263206800, #  local_start 2005-09-24 01:00:00 (Sat)
63278935200, #    local_end 2006-03-25 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63278906400, #    utc_start 2006-03-24 18:00:00 (Fri)
63295232400, #      utc_end 2006-09-29 17:00:00 (Fri)
63278938800, #  local_start 2006-03-25 03:00:00 (Sat)
63295264800, #    local_end 2006-09-30 02:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63295232400, #    utc_start 2006-09-29 17:00:00 (Fri)
63563162400, #      utc_end 2015-03-27 18:00:00 (Fri)
63295261200, #  local_start 2006-09-30 01:00:00 (Sat)
63563191200, #    local_end 2015-03-28 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63563162400, #    utc_start 2015-03-27 18:00:00 (Fri)
63578876400, #      utc_end 2015-09-25 15:00:00 (Fri)
63563194800, #  local_start 2015-03-28 03:00:00 (Sat)
63578908800, #    local_end 2015-09-26 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63578876400, #    utc_start 2015-09-25 15:00:00 (Fri)
63594612000, #      utc_end 2016-03-25 18:00:00 (Fri)
63578905200, #  local_start 2015-09-25 23:00:00 (Fri)
63594640800, #    local_end 2016-03-26 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63594612000, #    utc_start 2016-03-25 18:00:00 (Fri)
63610326000, #      utc_end 2016-09-23 15:00:00 (Fri)
63594644400, #  local_start 2016-03-26 03:00:00 (Sat)
63610358400, #    local_end 2016-09-24 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63610326000, #    utc_start 2016-09-23 15:00:00 (Fri)
63626061600, #      utc_end 2017-03-24 18:00:00 (Fri)
63610354800, #  local_start 2016-09-23 23:00:00 (Fri)
63626090400, #    local_end 2017-03-25 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63626061600, #    utc_start 2017-03-24 18:00:00 (Fri)
63642380400, #      utc_end 2017-09-29 15:00:00 (Fri)
63626094000, #  local_start 2017-03-25 03:00:00 (Sat)
63642412800, #    local_end 2017-09-30 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63642380400, #    utc_start 2017-09-29 15:00:00 (Fri)
63658116000, #      utc_end 2018-03-30 18:00:00 (Fri)
63642409200, #  local_start 2017-09-29 23:00:00 (Fri)
63658144800, #    local_end 2018-03-31 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63658116000, #    utc_start 2018-03-30 18:00:00 (Fri)
63673830000, #      utc_end 2018-09-28 15:00:00 (Fri)
63658148400, #  local_start 2018-03-31 03:00:00 (Sat)
63673862400, #    local_end 2018-09-29 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63673830000, #    utc_start 2018-09-28 15:00:00 (Fri)
63689565600, #      utc_end 2019-03-29 18:00:00 (Fri)
63673858800, #  local_start 2018-09-28 23:00:00 (Fri)
63689594400, #    local_end 2019-03-30 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63689565600, #    utc_start 2019-03-29 18:00:00 (Fri)
63705279600, #      utc_end 2019-09-27 15:00:00 (Fri)
63689598000, #  local_start 2019-03-30 03:00:00 (Sat)
63705312000, #    local_end 2019-09-28 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63705279600, #    utc_start 2019-09-27 15:00:00 (Fri)
63721015200, #      utc_end 2020-03-27 18:00:00 (Fri)
63705308400, #  local_start 2019-09-27 23:00:00 (Fri)
63721044000, #    local_end 2020-03-28 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63721015200, #    utc_start 2020-03-27 18:00:00 (Fri)
63736729200, #      utc_end 2020-09-25 15:00:00 (Fri)
63721047600, #  local_start 2020-03-28 03:00:00 (Sat)
63736761600, #    local_end 2020-09-26 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63736729200, #    utc_start 2020-09-25 15:00:00 (Fri)
63752464800, #      utc_end 2021-03-26 18:00:00 (Fri)
63736758000, #  local_start 2020-09-25 23:00:00 (Fri)
63752493600, #    local_end 2021-03-27 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63752464800, #    utc_start 2021-03-26 18:00:00 (Fri)
63768178800, #      utc_end 2021-09-24 15:00:00 (Fri)
63752497200, #  local_start 2021-03-27 03:00:00 (Sat)
63768211200, #    local_end 2021-09-25 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63768178800, #    utc_start 2021-09-24 15:00:00 (Fri)
63783914400, #      utc_end 2022-03-25 18:00:00 (Fri)
63768207600, #  local_start 2021-09-24 23:00:00 (Fri)
63783943200, #    local_end 2022-03-26 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63783914400, #    utc_start 2022-03-25 18:00:00 (Fri)
63799628400, #      utc_end 2022-09-23 15:00:00 (Fri)
63783946800, #  local_start 2022-03-26 03:00:00 (Sat)
63799660800, #    local_end 2022-09-24 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63799628400, #    utc_start 2022-09-23 15:00:00 (Fri)
63815364000, #      utc_end 2023-03-24 18:00:00 (Fri)
63799657200, #  local_start 2022-09-23 23:00:00 (Fri)
63815392800, #    local_end 2023-03-25 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63815364000, #    utc_start 2023-03-24 18:00:00 (Fri)
63831682800, #      utc_end 2023-09-29 15:00:00 (Fri)
63815396400, #  local_start 2023-03-25 03:00:00 (Sat)
63831715200, #    local_end 2023-09-30 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63831682800, #    utc_start 2023-09-29 15:00:00 (Fri)
63847418400, #      utc_end 2024-03-29 18:00:00 (Fri)
63831711600, #  local_start 2023-09-29 23:00:00 (Fri)
63847447200, #    local_end 2024-03-30 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63847418400, #    utc_start 2024-03-29 18:00:00 (Fri)
63863132400, #      utc_end 2024-09-27 15:00:00 (Fri)
63847450800, #  local_start 2024-03-30 03:00:00 (Sat)
63863164800, #    local_end 2024-09-28 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63863132400, #    utc_start 2024-09-27 15:00:00 (Fri)
63878868000, #      utc_end 2025-03-28 18:00:00 (Fri)
63863161200, #  local_start 2024-09-27 23:00:00 (Fri)
63878896800, #    local_end 2025-03-29 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63878868000, #    utc_start 2025-03-28 18:00:00 (Fri)
63894582000, #      utc_end 2025-09-26 15:00:00 (Fri)
63878900400, #  local_start 2025-03-29 03:00:00 (Sat)
63894614400, #    local_end 2025-09-27 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63894582000, #    utc_start 2025-09-26 15:00:00 (Fri)
63910317600, #      utc_end 2026-03-27 18:00:00 (Fri)
63894610800, #  local_start 2025-09-26 23:00:00 (Fri)
63910346400, #    local_end 2026-03-28 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63910317600, #    utc_start 2026-03-27 18:00:00 (Fri)
63926031600, #      utc_end 2026-09-25 15:00:00 (Fri)
63910350000, #  local_start 2026-03-28 03:00:00 (Sat)
63926064000, #    local_end 2026-09-26 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
    [
63926031600, #    utc_start 2026-09-25 15:00:00 (Fri)
63941767200, #      utc_end 2027-03-26 18:00:00 (Fri)
63926060400, #  local_start 2026-09-25 23:00:00 (Fri)
63941796000, #    local_end 2027-03-27 02:00:00 (Sat)
28800,
0,
'ULAT',
    ],
    [
63941767200, #    utc_start 2027-03-26 18:00:00 (Fri)
63957481200, #      utc_end 2027-09-24 15:00:00 (Fri)
63941799600, #  local_start 2027-03-27 03:00:00 (Sat)
63957513600, #    local_end 2027-09-25 00:00:00 (Sat)
32400,
1,
'ULAST',
    ],
];

sub olson_version {'2016d'}

sub has_dst_changes {35}

sub _max_year {2026}

sub _new_instance {
    return shift->_init( @_, spans => $spans );
}

sub _last_offset { 28800 }

my $last_observance = bless( {
  'format' => 'ULA%sT',
  'gmtoff' => '8:00',
  'local_start_datetime' => bless( {
    'formatter' => undef,
    'local_rd_days' => 722085,
    'local_rd_secs' => 3600,
    'offset_modifier' => 0,
    'rd_nanosecs' => 0,
    'tz' => bless( {
      'name' => 'floating',
      'offset' => 0
    }, 'DateTime::TimeZone::Floating' ),
    'utc_rd_days' => 722085,
    'utc_rd_secs' => 3600,
    'utc_year' => 1979
  }, 'DateTime' ),
  'offset_from_std' => 0,
  'offset_from_utc' => 28800,
  'until' => [],
  'utc_start_datetime' => bless( {
    'formatter' => undef,
    'local_rd_days' => 722084,
    'local_rd_secs' => 61200,
    'offset_modifier' => 0,
    'rd_nanosecs' => 0,
    'tz' => bless( {
      'name' => 'floating',
      'offset' => 0
    }, 'DateTime::TimeZone::Floating' ),
    'utc_rd_days' => 722084,
    'utc_rd_secs' => 61200,
    'utc_year' => 1978
  }, 'DateTime' )
}, 'DateTime::TimeZone::OlsonDB::Observance' )
;
sub _last_observance { $last_observance }

my $rules = [
  bless( {
    'at' => '2:00',
    'from' => '2015',
    'in' => 'Mar',
    'letter' => 'S',
    'name' => 'Mongol',
    'offset_from_std' => 3600,
    'on' => 'lastSat',
    'save' => '1:00',
    'to' => 'max',
    'type' => undef
  }, 'DateTime::TimeZone::OlsonDB::Rule' ),
  bless( {
    'at' => '0:00',
    'from' => '2015',
    'in' => 'Sep',
    'letter' => '',
    'name' => 'Mongol',
    'offset_from_std' => 0,
    'on' => 'lastSat',
    'save' => '0',
    'to' => 'max',
    'type' => undef
  }, 'DateTime::TimeZone::OlsonDB::Rule' )
]
;
sub _rules { $rules }


1;

package Time::Moment::Adjusters;
use strict;
use warnings;

use Carp qw[];

BEGIN {
    our $VERSION    = '0.38';
    our @EXPORT_OK  = qw[ NextDayOfWeek
                          NextOrSameDayOfWeek
                          PreviousDayOfWeek
                          PreviousOrSameDayOfWeek
                          FirstDayOfWeekInMonth
                          LastDayOfWeekInMonth
                          NthDayOfWeekInMonth ];

    our %EXPORT_TAGS = (
        all => [ @EXPORT_OK ],
    );

    require Exporter;
    *import = \&Exporter::import;
}

sub NextDayOfWeek {
    @_ == 1 or Carp::croak(q<Usage: NextDayOfWeek(day)>);
    my ($day) = @_;

    ($day >= 1 && $day <= 7)
      or Carp::croak(q<Parameter 'day' is out of the range [1, 7]>);

    return sub {
        my ($tm) = @_;
        return $tm->plus_days(($day - $tm->day_of_week + 6) % 7 + 1);
    };
}

sub NextOrSameDayOfWeek {
    @_ == 1 or Carp::croak(q<Usage: NextOrSameDayOfWeek(day)>);
    my ($day) = @_;

    ($day >= 1 && $day <= 7)
      or Carp::croak(q<Parameter 'day' is out of the range [1, 7]>);

    return sub {
        my ($tm) = @_;
        return $tm->plus_days(($day - $tm->day_of_week) % 7);
    };
}

sub PreviousDayOfWeek {
    @_ == 1 or Carp::croak(q<Usage: PreviousDayOfWeek(day)>);
    my ($day) = @_;

    ($day >= 1 && $day <= 7)
      or Carp::croak(q<Parameter 'day' is out of the range [1, 7]>);

    return sub {
        my ($tm) = @_;
        return $tm->minus_days(($tm->day_of_week - $day + 6) % 7 - 1);
    };
}

sub PreviousOrSameDayOfWeek {
    @_ == 1 or Carp::croak(q<Usage: PreviousOrSameDayOfWeek(day)>);
    my ($day) = @_;

    ($day >= 1 && $day <= 7)
      or Carp::croak(q<Parameter 'day' is out of the range [1, 7]>);

    return sub {
        my ($tm) = @_;
        return $tm->minus_days(($tm->day_of_week - $day) % 7);
    };
}

sub FirstDayOfWeekInMonth {
    @_ == 1 or Carp::croak(q<Usage: FirstDayOfWeekInMonth(day)>);
    my ($day) = @_;

    ($day >= 1 && $day <= 7)
      or Carp::croak(q<Parameter 'day' is out of the range [1, 7]>);

    return sub {
        my ($tm) = @_;
        $tm = $tm->with_day_of_month(1);
        return $tm->plus_days(($day - $tm->day_of_week) % 7);
    };
}

sub LastDayOfWeekInMonth {
    @_ == 1 or Carp::croak(q<Usage: LastDayOfWeekInMonth(day)>);
    my ($day) = @_;

    ($day >= 1 && $day <= 7)
      or Carp::croak(q<Parameter 'day' is out of the range [1, 7]>);

    return sub {
        my ($tm) = @_;
        $tm = $tm->at_last_day_of_month;
        return $tm->minus_days(($tm->day_of_week - $day) % 7);
    };
}

sub NthDayOfWeekInMonth {
    @_ == 2 or Carp::croak(q<Usage: NthDayOfWeekInMonth(ordinal, day)>);
    my ($ordinal, $day) = @_;

    ($ordinal >= -4 && $ordinal <= 4 && $ordinal != 0)
      or Carp::croak(q<Parameter 'ordinal' is out of the range [-4, -1] u [1, 4]>);

    ($day >= 1 && $day <= 7)
      or Carp::croak(q<Parameter 'day' is out of the range [1, 7]>);

    if ($ordinal > 0) {
        my $days = 7 * --$ordinal;
        return sub {
            my ($tm) = @_;
            $tm = $tm->with_day_of_month(1);
            return $tm->plus_days($days + ($day - $tm->day_of_week) % 7);
        };
    }
    else {
        my $days = 7 * ++$ordinal;
        return sub {
            my ($tm) = @_;
            $tm = $tm->at_last_day_of_month;
            return $tm->plus_days($days - ($tm->day_of_week - $day) % 7);
        };
    }
}

1;

// Compute the duration of twilight at a specified latitude and time.
//
// Copyright 2022 Cyrus Rahman
// You may use or modify this source code in any way you find useful, provided
// that you agree that the author(s) have no warranty, obligations or liability.  You
// must determine the suitability of this source code for your use.
//
// Redistributions of this source code must retain this copyright notice.

#include "Twilight.h"
#include "SunRise.h"

#include <math.h>
#include <stdio.h>

#define	DAYSINYEAR  365.2422	// Fractional days in a year.
#define	T0	    2451545.0	// Reference time (in Julian days).
#define	RMA	    0.98564735	// Rate of motion in mean anomoly.
#define	MELL	    280.459	// Mean solar ecliptic longitude at reference time.
#define	OBLIQ	    23.439	// Obliquity of the ecliptic.

#define	M_PI_180    (M_PI/180)
// Degrees the centre of the sun sits below the horizon at rise and set, which is
// refraction plus its semidiameter.  Expressed the way the angle argument is, i.e.
// positive means below the horizon.
#define	SUNRISESET_ANGLE  0.8333

// Determine the length of civil, nautical, or astronomical twilight for the
// mornings or evenings near the the specified time in seconds since the Unix
// epoch (January 1, 1970) and at the specified latitude and longitude in degrees.
// Where there is no twilight at all - a sun that never rises to within the angle
// of the horizon, or one that never sets - the duration is 0.  Where the sun sets
// but never reaches the angle the whole night counts as twilight.
//
// Civil twilight: 6 degrees; Nautical: 12 degrees; Astronomical: 18 degrees
//
// Reference: (from https://en.wikipedia.org/wiki/Twilight, an external link)
//  https://web.archive.org/web/20130122033117/http://www.gandraxa.com/length_of_day.xml 
void
Twilight::calculate(double latitude, double longitude, double angle, time_t t) {
  double z;
  int days;
  time_t daylength;

  initClass();
  queryTime = t;
  angleOfTwilight = angle;
  Twilight::latitude = latitude;
  Twilight::longitude = longitude;

  days = daysSinceWinterEquinox(t);

  /* Position of the sun for the day, as tan(latitude) * tan(declination). */
  z = tan(M_PI_180 * latitude) *
      tan(M_PI_180 * OBLIQ * cos((M_PI / (DAYSINYEAR / 2)) * days));

  /* Duration of daylight.  The longitude decides which local day the rise and the
     set found here belong to, so it has to be the caller's; this used to pass 0 and
     measure the day at Greenwich instead. */
  SunRise sr;
  sr.calculate(latitude, longitude, t);

  if (sr.hasRise && sr.hasSet) {
    /* The two events bracket the query time, and their order says what lies between
       them: a rise and then a set spans the day, a set and then a rise spans the
       night.  isVisible cannot stand in for that test - where the sun is up but its
       short night straddles midnight the set precedes the rise while isVisible is
       still true, and the night was taken for the day: 3013 seconds of daylight at
       70 degrees north on 2026-05-16, against a true figure near 82700.  The
       differences are formed directly rather than through labs(), whose long
       argument is only 32 bit on Windows while time_t is 64 bit. */
    if (sr.riseTime < sr.setTime)
      daylength = sr.setTime - sr.riseTime;
    else
      daylength = 24 * 60 * 60 - (sr.riseTime - sr.setTime);
  } else {
    /* Fewer than two events inside the search window: a polar day or night, or one
       of the two days a year that begin or end one.  riseTime and setTime are still
       the zero left by initClass() here and are not timestamps.  Reading them as
       such used to feed a whole Unix epoch into the subtraction below and return
       twilights of some 28 years.  Fall back on the same model that supplies the
       twilight, so that the two stay comparable. */
    daylength = dayFraction(z, SUNRISESET_ANGLE) * 24 * 60 * 60;
  }

  /* Either event may sit up to a day either side of the query time, so hold the span
     inside one day before it is subtracted below. */
  if (daylength < 0)
    daylength = 0;
  else if (daylength > 24 * 60 * 60)
    daylength = 24 * 60 * 60;

  /* Duration of daylight + twilight, defined by angle. */
  twilightDuration = dayFraction(z, angle) * 24 * 60 * 60;

  if (twilightDuration > daylength)
    twilightDuration -= daylength;  /* Total duration of twilight for the day. */
  else
    twilightDuration = 0;	    /* The sun never crosses the horizon: no twilight. */
  twilightDuration /= 2;	    /* Duration of one period of twilight. */
}

// Fraction of the day the sun spends above -angle degrees, from the same model the
// twilight duration is built on.  acos() is undefined outside [-1, 1]; beyond those
// limits the sun simply never climbs that high, or never drops that low.  The old
// code let acos() return NaN there and read every NaN as "no twilight", which also
// zeroed the nights that are twilit from dusk to dawn, roughly 62 to 65 degrees of
// latitude around the June solstice.
double
Twilight::dayFraction(double z, double angle) {
  double arg = z - tan(M_PI_180 * angle) / cos(M_PI_180 * latitude);

  if (arg >= 1)
    return 0;		/* Below -angle for the whole day. */
  if (arg <= -1)
    return 1;		/* Above -angle for the whole day. */
  return acos(arg) / M_PI;
}

// Return the number of days since the last winter equinox of the requested time
// (specified in seconds since the Unix epoch).  Since this is based upon the mean
// solar ecliptic longitude, it is only accurate to within a couple of days (which is
// adequate for our current purpose).
//
// Reference: https://farside.ph.utexas.edu/books/Syntaxis/Almagest/node36.html
int
Twilight::daysSinceWinterEquinox(time_t t) {
  double julianDaysSinceReference, rotationSinceReference, angleFromWinter;
  int days;

  julianDaysSinceReference = julianDate(t) - T0;  // Days since reference time.
  rotationSinceReference = julianDaysSinceReference * RMA + MELL;

  // Add 90 degrees for winter solstice.
  angleFromWinter = fmod(rotationSinceReference + 90, 360);
  days = angleFromWinter / RMA;			  // Days since winter equinox.

  return (days);
}

// Determine Julian date from Unix time.
// Provides marginally accurate results with Arduino 4-byte double.
double
Twilight::julianDate(time_t t) {
  return (t / 86400.0L + 2440587.5);
}

// Class initialization.
void
Twilight::initClass() {
  queryTime = 0;
  latitude = 0;
  longitude = 0;
  angleOfTwilight = 0;
  twilightDuration = 0;
}

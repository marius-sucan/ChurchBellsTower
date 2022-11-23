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

// Determine the length of civil, nautical, or astronomical twilight for the
// mornings or evenings near the the specified time in seconds since the Unix
// epoch (January 1, 1970) and at the specified latitude in degrees.
// In polar regions, during periods in which there is no or constant twilight,
// the twilight duration is set to 0.
//
// Civil twilight: 6 degrees; Nautical: 12 degrees; Astronomical: 18 degrees
//
// Reference: (from https://en.wikipedia.org/wiki/Twilight, an external link)
//  https://web.archive.org/web/20130122033117/http://www.gandraxa.com/length_of_day.xml 
void
Twilight::calculate(double latitude, double angle, time_t t) {
  double z, e;
  int days;
  time_t daylength;

  initClass();
  queryTime = t;
  angleOfTwilight = angle;
  Twilight::latitude = latitude;

  /* Duration of daylight. */
  SunRise sr;
  sr.calculate(latitude, 0, t);
  daylength = labs(sr.setTime - sr.riseTime);
  if (!sr.isVisible) {
    daylength = 24 * 60 * 60 - daylength;
  }

  days = daysSinceWinterEquinox(t);

  /* Duration of daylight + twilight, defined by angle. */
  z = tan(M_PI_180 * latitude) *
      tan(M_PI_180 * OBLIQ * cos((M_PI / (DAYSINYEAR / 2)) * days));

  e = acos(z - tan(M_PI_180 * angle) / cos(M_PI_180 * latitude)) / M_PI;
  if (isnan(e))
    twilightDuration = 0;
  else
    twilightDuration = e * 24 * 60 * 60;

  if (twilightDuration - daylength > 0)	/* when there is no daylight, this prevents it from returning negative values */
    twilightDuration -= daylength;  /* Total duration of twilight for the day. */
  twilightDuration /= 2;	    /* Duration of one period of twilight. */
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
  angleOfTwilight = 0;
  twilightDuration = 0;
}

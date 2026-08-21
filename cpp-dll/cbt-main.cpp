#include <wchar.h>
#include "math.h"
#include "windows.h"
#include <string>
#include <sstream>
#include <vector>
#include <stack>
#include <map>
#include <array>
#include <numeric>
#include <algorithm>
#include "cbt-main.h"
#include "MoonPhase.h"
#include "MoonPhase.cpp"
#include "SunRise.h"
#include "SunRise.cpp"
#include "Twilight.h"
#include "Twilight.cpp"
#include "SolarCalculator.h"
#include "SolarCalculator.cpp"
#include "MoonELP.h"
#include "MoonELP.cpp"
// #include "moonDiskAngle.h"
// #include "moonDiskAngle.cpp"
// to look into:
// https://github.com/onekiloparsec/SwiftAA
// https://libnova.sourceforge.net/index.html
// https://github.com/buelowp/sunset
// https://github.com/jpb10/SolarCalculator
// https://bitbucket.org/talonsoalbi/sunmooncalculator/src/master/




// Rounded HH:mm format
char * hoursToString(double h, char *str) {
  int m = int(round(h * 60));
  int hr = m / 60;
  int mn = m % 60;

  str[0] = (hr / 10) % 10 + '0';
  str[1] = (hr % 10) + '0';
  str[2] = ':';
  str[3] = (mn / 10) % 10 + '0';
  str[4] = (mn % 10) + '0';
  str[5] = '\0';
  return str;
}

DLL_API int DLL_CALLCONV getSolarCalculatorData(double lat, double lon, int y, int m, int d, float* nrise, float* nsetu, float* ndawn, float* ndusk, float* nnoon) {
  double transit, sunrise, sunset, dawn, dusk;
  int utc_offset = 0;

  // Calculate the times of sunrise, transit, and sunset, in hours (UTC)
  // if (t)
  //    calcSunriseSunset(t, lat, lon, transit, sunrise, sunset, SUNRISESET_STD_ALTITUDE, 2);
  // else
     calcSunriseSunset(y, m, d, lat, lon, transit, sunrise, sunset, SUNRISESET_STD_ALTITUDE, 2);
  if (!isnan(sunrise))
     *nrise = sunrise;
  if (!isnan(sunset))
     *nsetu = sunset;
  if (!isnan(transit))
     *nnoon = transit;

  // Print results
  // char str[6};
  // fnOutputDebug(hoursToString(sunrise, str));
  // fnOutputDebug("c++ rise=" + std::to_string(sunrise));
  // fnOutputDebug(hoursToString(transit + utc_offset, str));
  // fnOutputDebug(hoursToString(sunset + utc_offset, str));
  // fnOutputDebug(std::to_string(sunset + utc_offset));

  calcSunriseSunset(y, m, d, lat, lon, transit, dawn, dusk, CIVIL_DAWNDUSK_STD_ALTITUDE, 2);
  if (!isnan(dawn))
     *ndawn = dawn;
  if (!isnan(dusk))
     *ndusk = dusk;
  // fnOutputDebug("dawn=" + std::to_string(dawn));

  // fnOutputDebug("dawn");
  // fnOutputDebug(hoursToString(dawn + utc_offset, str));
  // fnOutputDebug(std::to_string(dawn + utc_offset));
  // fnOutputDebug("dusk");
  // fnOutputDebug(hoursToString(dusk + utc_offset, str));
  // fnOutputDebug(std::to_string(dusk + utc_offset));

  // sun_altitude = NAUTICAL_DAWNDUSK_STD_ALTITUDE - 0.0353 * sqrt(height);
  // calcSunriseSunset(year, month, day, lat, lon, transit, dawn, dusk, sun_altitude, 2);
  // fnOutputDebug("nautical morning");
  // fnOutputDebug(hoursToString(dawn + utc_offset, str));
  // fnOutputDebug(std::to_string(dawn + utc_offset));
  // fnOutputDebug("nautical evening");
  // fnOutputDebug(hoursToString(dusk + utc_offset, str));
  // fnOutputDebug(std::to_string(dusk + utc_offset));
  return 1;
}

// ============================================================================
//  The moon
//
//  Where the moon is comes from ELP/MPP02, the lunar theory of Chapront and
//  Francou - see MoonELP.cpp.  It replaces the chapter 47 series of Meeus, a
//  60-term truncation of the theory that preceded it, which carried some three
//  arcseconds of error in longitude and eleven at worst; what is used here holds
//  a tenth of an arcsecond, and a third of one at worst, against JPL DE440.
//
//  Everything downstream of the position still follows Jean Meeus, "Astronomical
//  Algorithms" (2nd edition): chapter 22 for nutation and the obliquity of the
//  ecliptic, 12 for sidereal time, 13 for the change of coordinates, 40 for the
//  observer's parallax, 16 for refraction, 48 for the illuminated fraction and
//  49 for the mean instants of the four principal phases - which are then solved
//  properly, against the elongation those phases are defined by.
//
//  The chapter 22 table below was converted from the JS code found on
//  https://www.dannybekaert.be/en/moonposition by Marius Șucan.
// ============================================================================

// Forward declaration: the sun the moon is measured against comes from the
// VSOP87 series further down this file, the same one the equinoxes are solved by.
double sunApparentLongitude(double jde);

// tabelgegevens van tabel 22A voor nutatie en obliquity
static const double dTable22a[63] = { 0, -2, 0, 0, 0, 0, -2, 0, 0,
                      -2, -2, -2, 0, 2, 0, 2, 0, 0,
                      -2, 0, 2, 0, 0, -2, 0, -2, 0,
                      0, 2, -2, 0, -2, 0, 0, 2, 2,
                      0, -2, 0, 2, 2, -2, -2, 2, 2,
                      0, -2, -2, 0, -2, -2, 0, -1, -2,
                      1, 0, 0, -1, 0, 0, 2, 0, 2};

static const double mTable22a[63] = { 0, 0, 0, 0, 1, 0, 1, 0, 0,
                      -1, 0, 0, 0, 0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0, 0, 0, 0, 0,
                      2, 0, 2, 1, 0, -1, 0, 0, 0,
                      1, 1, -1, 0, 0, 0, 0, 0, 0,
                      -1, -1, 0, 0, 0, 1, 0, 0, 1,
                      0, 0, 0, -1, 1, -1, -1, 0, -1};

static const double maTable22a[63] = { 0, 0, 0, 0, 0, 1, 0, 0, 1,
                       0, 1, 0, -1, 0, 1, -1, -1, 1,
                       2, -2, 0, 2, 2, 1, 0, 0, -1,
                       0, -1, 0, 0, 1, 0, 2, -1, 1,
                       0, 1, 0, 0, 1, 2, 1, -2, 0,
                       1, 0, 0, 2, 2, 0, 1, 1, 0,
                       0, 1, -2, 1, 1, 1, -1, 3, 0};

static const double fTable22a[63] = { 0, 2, 2, 0, 0, 0, 2, 2, 2,
                      2, 0, 2, 2, 0, 0, 2, 0, 2,
                      0, 2, 2, 2, 0, 2, 2, 2, 2,
                      0, 0, 2, 0, 0, 0, -2, 2, 2,
                      2, 0, 2, 2, 0, 2, 2, 0, 0,
                      0, 2, 0, 2, 0, 2, -2, 0, 0,
                      0, 2, 2, 0, 0, 2, 2, 2, 2};

static const double oTable22a[63] = { 1, 2, 2, 2, 0, 0, 2, 1, 2,
                        2, 0, 1, 2, 0, 1, 2, 1, 1,
                        0, 1, 2, 2, 0, 2, 0, 0, 1,
                        0, 1, 2, 1, 1, 1, 0, 1, 2,
                        2, 0, 2, 1, 0, 2, 1, 1, 1,
                        0, 1, 1, 1, 1, 1, 0, 0, 0,
                        0, 0, 2, 0, 0, 2, 2, 2, 2};

// Nutation in longitude and in obliquity, in arcseconds - Meeus chapter 22.
// Both series run over the same five arguments, so one pass serves for both.
// The moon's position wants it, and so does the sun's apparent longitude.
void nutationAngles(double T, double &dPsi, double &dEpsilon) {
     double T2 = T*T;
     double T3 = T2*T;

     double fiTable22a[63] = { -171996-174.2*T, -13187-1.6*T, -2274-0.2*T, 2062+0.2*T, 1426-3.4*T, 712+0.1*T, -517+1.2*T, -386-0.4*T, -301,
                              217-0.5*T, -158, 129+0.1*T, 123, 63, 63+0.1*T, -59, -58-0.1*T, 51,
                              48, 46, -38, -31, 29, 29, 26, -22, 21,
                              17-0.1*T, 16, -16+0.1*T, -15, -13, -12, 11, -10, -8,
                              7, -7, -7, -7, 6, 6, 6, -6, -6,
                              5, -5, -5, -5, 4, 4, 4, -4, -4,
                              -4, 3, -3, -3, -3, -3, -3, -3, -3};

     double epsilonTable22a[63] = { 92025+8.9*T, 5736-3.1*T, 977-0.5*T, -895+0.5*T, 54-0.1*T, -7, 224-0.6*T, 200, 129-0.1*T,
                                   -95+0.3*T, 0, -70, -53, 0, -33, 26, 32, 27,
                                   0, -24, 16, 13, 0, -12, 0, 0, -10,
                                   0, -8, 7, 9, 7, 6, 0, 5, 3,
                                   -3, 0, 3, 3, 0, -3, -3, 3, 3,
                                   0, 3, 3, 3, 0, 0, 0, 0, 0,
                                   0, 0, 0, 0, 0, 0, 0, 0, 0};

     double D_CH22  = wrapTo360(297.85036 + 445267.111480*T - 0.0019142*T2 + T3/189474.0);
     double M_CH22  = wrapTo360(357.52772 +  35999.050340*T - 0.0001603*T2 - T3/300000.0);
     double MA_CH22 = wrapTo360(134.96298 + 477198.867398*T + 0.0086972*T2 + T3/56250.0);
     double F_CH22  = wrapTo360( 93.27191 + 483202.017538*T - 0.0036825*T2 + T3/327270.0);

     // Longitude of the ascending node of the mean lunar orbit on the ecliptic,
     // measured from the mean equinox of the date.
     double omega = wrapTo360(125.04452 - 1934.136261*T + 0.0020708*T2 + T3/450000.0);

     dPsi = 0.0;
     dEpsilon = 0.0;
     for (int i=0; i<63; i++)
     {
         double arg = radians(dTable22a[i]*D_CH22 + mTable22a[i]*M_CH22 + maTable22a[i]*MA_CH22
                            + fTable22a[i]*F_CH22 + oTable22a[i]*omega);
         dPsi     += fiTable22a[i] * sin(arg);
         dEpsilon += epsilonTable22a[i] * cos(arg);
     }

     dPsi /= 10000.0;         // the tables are in units of 0.0001 arcseconds
     dEpsilon /= 10000.0;
}

// Mean obliquity of the ecliptic - Laskar's expansion, Meeus chapter 22.
double meanObliquity(double T) {
     double U = T/100.0;
     return (84381.448 + U*(-4680.93 + U*(-1.55 + U*(1999.25 + U*(-51.38
           + U*(-249.67 + U*(-39.05 + U*(7.12 + U*(27.87 + U*(5.79 + U*2.45)))))))))) / 3600.0;
}

// ============================================================================
//  One day of the moon, held as Chebyshev polynomials
//
//  ELP/MPP02 costs twenty-five microseconds a call, a hundred times what the
//  rest of a position costs, and the searches further down ask for a few hundred
//  positions inside the same day: the rise and the set are hunted on a ten
//  minute grid, the highest point by golden section, and the world map draws
//  twenty thousand places at one instant.  Fitting the day once - ten
//  evaluations of the series, laid on Chebyshev points - and reading the fit
//  back for all the rest turns those hundreds of calls into a handful of
//  multiplications each.
//
//  A day is a short interval for a body whose fastest term has a period of
//  several days, so ten points are far more than the fit needs: it reproduces
//  the series it was built from to a hundred-thousandth of an arcsecond, four
//  orders of magnitude below what the series themselves are worth.  The nutation
//  and the obliquity are fitted alongside, being wanted at the same moments and
//  costing a sixty-three term sum of their own otherwise.
// ============================================================================

static const int kMoonBlockN = 10;      // Chebyshev points, and coefficients, per day

struct MoonDayBlock {
    long   day;                         // the block spans [day, day+1] in dynamical time
    bool   filled;
    double lambda[kMoonBlockN];         // geometric longitude, degrees, carried past the turn
    double beta[kMoonBlockN];           // geometric latitude, degrees
    double distance[kMoonBlockN];       // centre to centre, km
    double dPsi[kMoonBlockN];           // nutation in longitude, arcseconds
    double epsilon[kMoonBlockN];        // true obliquity of the ecliptic, degrees
};

// Coefficients of the polynomial through the values at the Chebyshev points.
static void moonBlockFit(const double *f, double *c) {
     for (int j=0; j<kMoonBlockN; j++)
     {
         double sum = 0.0;
         for (int k=0; k<kMoonBlockN; k++)
             sum += f[k] * cos(M_PI*j*(k + 0.5)/kMoonBlockN);

         c[j] = 2.0*sum/kMoonBlockN;
     }

     c[0] *= 0.5;
}

// ... and back again, by Clenshaw's recurrence.  x runs from -1 at the start of
// the day to +1 at its end.
static double moonBlockRead(const double *c, double x) {
     double b1 = 0.0, b2 = 0.0;
     for (int j=kMoonBlockN-1; j>0; j--)
     {
         double t = 2.0*x*b1 - b2 + c[j];
         b2 = b1;
         b1 = t;
     }

     return x*b1 - b2 + c[0];
}

static void moonBlockFill(MoonDayBlock &b, long day) {
     double lambda[kMoonBlockN], beta[kMoonBlockN], distance[kMoonBlockN];
     double dPsi[kMoonBlockN], epsilon[kMoonBlockN];

     double previous = 0.0;
     for (int k=0; k<kMoonBlockN; k++)
     {
         double x = cos(M_PI*(k + 0.5)/kMoonBlockN);
         double T = (day + 0.5 + 0.5*x - 2451545.0) / 36525.0;

         elp::moonPosition(T, lambda[k], beta[k], distance[k]);

         // The longitude runs through the whole turn every month, so some blocks
         // hold the moment it does.  A polynomial cannot follow a jump of 360
         // degrees, so the value is carried on past the turn here and wrapped
         // again when it is read back.
         if (k > 0)
            lambda[k] -= 360.0 * floor((lambda[k] - previous)/360.0 + 0.5);

         previous = lambda[k];

         double dp, de;
         nutationAngles(T, dp, de);
         dPsi[k] = dp;
         epsilon[k] = meanObliquity(T) + de/3600.0;
     }

     moonBlockFit(lambda, b.lambda);
     moonBlockFit(beta, b.beta);
     moonBlockFit(distance, b.distance);
     moonBlockFit(dPsi, b.dPsi);
     moonBlockFit(epsilon, b.epsilon);
     b.day = day;
     b.filled = true;
}

// The blocks in hand, one slot per day of the month.  A search stays inside a day
// or two and a phase is hunted over a few weeks, so nothing here is ever asked to
// hold more than a handful at once; the slot a day lands in is the day itself, so
// neighbouring days never turn each other out.
//
// This is the one piece of state in the file, and it is not guarded: two threads
// calling into the DLL at once could catch a slot half written.  The AutoHotkey
// side calls it from one thread, which is what it was written for.
static const int kMoonBlockCount = 16;
static MoonDayBlock gMoonBlocks[kMoonBlockCount];

static const MoonDayBlock &moonBlockFor(long day) {
     MoonDayBlock &b = gMoonBlocks[(int)(((unsigned long)day) % (unsigned long)kMoonBlockCount)];
     if (!b.filled || b.day != day)
        moonBlockFill(b, day);

     return b;
}

// The moon's geometric geocentric place at an instant of dynamical time, referred
// to the mean ecliptic and equinox of the date, together with the nutation and
// the obliquity of that moment.
//
// What is handed back is where the moon was when the light now arriving left it,
// which is where the almanacs put it.  Over the 1.28 seconds that light is on its
// way the moon moves 0''.7 along its path - eight times what the series
// themselves are worth, so it cannot simply be left out, and it is taken off by
// reading the same fit back a moment earlier rather than by summing the series
// twice.
void moonPlaceAt(double jdTT, double &lambda, double &beta, double &distance,
                 double &dPsi, double &epsilon) {
     long day = (long)floor(jdTT);
     const MoonDayBlock &b = moonBlockFor(day);

     double x = 2.0*(jdTT - (double)day) - 1.0;
     dPsi    = moonBlockRead(b.dPsi, x);
     epsilon = moonBlockRead(b.epsilon, x);

     const double kLightDaysPerKm = 1.0 / (299792.458 * 86400.0);
     double xEmitted = x - 2.0 * moonBlockRead(b.distance, x) * kLightDaysPerKm;

     lambda   = moonBlockRead(b.lambda, xEmitted);
     beta     = moonBlockRead(b.beta, xEmitted);
     distance = moonBlockRead(b.distance, xEmitted);
     lambda  -= 360.0 * floor(lambda/360.0);
}

// Delta T, the gap between dynamical time and the earth's rotation, in seconds.
// Every series taken from Meeus is written in dynamical time, so this is what
// stands between them and a clock: the moon and the sun both come through here.
//
// The moon travels 0.55 arcseconds of longitude in a second of time, so the
// lunar series have to be handed TT rather than UT.  Feeding them UT, as this
// used to, drags the moon 38 arcseconds behind where it is.
//
// Observed values are tabulated below for the years this program is likely to be
// asked about, from the delta T file the US Naval Observatory keeps, read at the
// first of each January.  Ten seconds of error here is worth half a second on a
// moonrise and sixty seconds is worth two and a half, so the table is what
// matters and it should be refreshed every few years.
double deltaTseconds(double jdUT) {
     static const int kFirstYear = 1990;
     static const double kObserved[] = {
         56.86, 57.57, 58.31, 59.12, 59.98, 60.78, 61.63, 62.30, 62.97, 63.47,  // 1990-1999
         63.83, 64.09, 64.30, 64.47, 64.57, 64.69, 64.85, 65.15, 65.46, 65.78,  // 2000-2009
         66.07, 66.32, 66.60, 66.91, 67.28, 67.64, 68.10, 68.59, 68.97, 69.22,  // 2010-2019
         69.36, 69.36, 69.29, 69.20, 69.18, 69.14, 69.11                        // 2020-2026
     };
     static const int kCount = (int)(sizeof(kObserved) / sizeof(kObserved[0]));
     static const int kLastYear = kFirstYear + kCount - 1;

     // Delta T moves by well under a second a year, so a year good to a few days
     // is plenty to look it up by.
     double year = 2000.0 + (jdUT - 2451545.0) / 365.25;
     if (year >= kFirstYear && year < kLastYear)
     {
        int i = (int)floor(year) - kFirstYear;
        double f = year - floor(year);
        return kObserved[i] + f * (kObserved[i+1] - kObserved[i]);
     }

     // Before the table, the historical fit of calcDeltaT(), shifted so that the
     // handover is free of a step.
     if (year < kFirstYear)
        return kObserved[0] + calcDeltaT(year) - calcDeltaT(kFirstYear);

     // After it there is nothing to look up.  Delta T is the earth's rotation and
     // nobody can predict it: the fit Espenak published in 2014, which this used
     // to lean on, has it climbing by a third of a second a year, and instead the
     // earth sped up and it has barely moved since - that fit is two seconds long
     // by 2030 and eleven by 2050.  What is done here is to carry on with the
     // slope of the last ten years the table holds, which is the only trend there
     // is evidence for, and to claim nothing beyond it.  A decade is deliberate:
     // the last six years alone slope downwards, and reading a turn of that
     // length as the shape of the next century is how the old fit went wrong.
     double sumXY = 0.0, sumXX = 0.0;
     const int kFitYears = 10;
     for (int i=0; i<kFitYears; i++)
     {
         double x = i - (kFitYears - 1)/2.0;
         sumXY += x * kObserved[kCount - kFitYears + i];
         sumXX += x*x;
     }

     return kObserved[kCount-1] + (sumXY/sumXX)*(year - kLastYear);
}

// The four principal phases of the moon, a quarter of a lunation apart.
enum MoonPrincipalPhase { MOON_NEW = 0, MOON_FIRST_QUARTER = 1, MOON_FULL = 2, MOON_LAST_QUARTER = 3 };

// Instant of one principal phase of lunation k, as a Julian ephemeris day -
// Meeus chapter 49.  k counts lunations from the new moon of 2000 January 6 and
// runs negative before it; the phase adds its own quarter to it, so that
// (k, MOON_FULL) is the full moon of that same lunation.  Good to some 4 seconds
// against DE421, 13 at worst, over 2020-2030.
double moonPhaseJDE(double lunation, int which) {
     double k = lunation + which*0.25;
     double T = k / 1236.85;
     double T2 = T*T;
     double T3 = T2*T;
     double T4 = T3*T;

     double jde = 2451550.09766 + 29.530588861*k + 0.00015437*T2 - 0.000000150*T3 + 0.00000000073*T4;
     double E   = 1.0 - 0.002516*T - 0.0000074*T2;

     double M  = wrapTo360(  2.5534 +  29.10535670*k - 0.0000014*T2 - 0.00000011*T3);                    // sun's mean anomaly
     double MA = wrapTo360(201.5643 + 385.81693528*k + 0.0107582*T2 + 0.00001238*T3 - 0.000000058*T4);   // moon's mean anomaly
     double F  = wrapTo360(160.7108 + 390.67050284*k - 0.0016118*T2 - 0.00000227*T3 + 0.000000011*T4);   // moon's argument of latitude
     double omega = wrapTo360(124.7746 - 1.56375588*k + 0.0020672*T2 + 0.00000215*T3);

     double Mr = radians(M), MAr = radians(MA), Fr = radians(F), Omr = radians(omega);
     if (which==MOON_NEW || which==MOON_FULL)
     {
        // Meeus prints the new moon and the full moon as two tables, but they part
        // company only in these seven leading coefficients; every term past them is
        // shared, so only the seven are kept apart here.
        static const double leadNew[7]  = { -0.40720, 0.17241, 0.01608, 0.01039, 0.00739, -0.00514, 0.00208 };
        static const double leadFull[7] = { -0.40614, 0.17302, 0.01614, 0.01043, 0.00734, -0.00515, 0.00209 };
        const double *c = (which==MOON_NEW) ? leadNew : leadFull;

        jde += c[0]*sin(MAr)                 + c[1]*E*sin(Mr)
             + c[2]*sin(2*MAr)               + c[3]*sin(2*Fr)
             + c[4]*E*sin(MAr - Mr)          + c[5]*E*sin(MAr + Mr)
             + c[6]*E*E*sin(2*Mr)
             -  0.00111*sin(MAr - 2*Fr)      - 0.00057*sin(MAr + 2*Fr)
             +  0.00056*E*sin(2*MAr + Mr)    - 0.00042*sin(3*MAr)
             +  0.00042*E*sin(Mr + 2*Fr)     + 0.00038*E*sin(Mr - 2*Fr)
             -  0.00024*E*sin(2*MAr - Mr)    - 0.00017*sin(Omr)
             -  0.00007*sin(MAr + 2*Mr)      + 0.00004*sin(2*MAr - 2*Fr)
             +  0.00004*sin(3*Mr)            + 0.00003*sin(MAr + Mr - 2*Fr)
             +  0.00003*sin(2*MAr + 2*Fr)    - 0.00003*sin(MAr + Mr + 2*Fr)
             +  0.00003*sin(MAr - Mr + 2*Fr) - 0.00002*sin(MAr - Mr - 2*Fr)
             -  0.00002*sin(3*MAr + Mr)      + 0.00002*sin(4*MAr);
     } else
     {
        jde += -0.62801*sin(MAr)              + 0.17172*E*sin(Mr)
             -  0.01183*E*sin(MAr + Mr)       + 0.00862*sin(2*MAr)
             +  0.00804*sin(2*Fr)             + 0.00454*E*sin(MAr - Mr)
             +  0.00204*E*E*sin(2*Mr)         - 0.00180*sin(MAr - 2*Fr)
             -  0.00070*sin(MAr + 2*Fr)       - 0.00040*sin(3*MAr)
             -  0.00034*E*sin(2*MAr - Mr)     + 0.00032*E*sin(Mr + 2*Fr)
             +  0.00032*E*sin(Mr - 2*Fr)      - 0.00028*E*E*sin(MAr + 2*Mr)
             +  0.00027*E*sin(2*MAr + Mr)     - 0.00017*sin(Omr)
             -  0.00005*sin(MAr - Mr - 2*Fr)  + 0.00004*sin(2*MAr + 2*Fr)
             -  0.00004*sin(MAr + Mr + 2*Fr)  + 0.00004*sin(MAr - 2*Mr)
             +  0.00003*sin(MAr + Mr - 2*Fr)  + 0.00003*sin(3*Mr)
             +  0.00002*sin(2*MAr - 2*Fr)     + 0.00002*sin(MAr - Mr + 2*Fr)
             -  0.00002*sin(3*MAr + Mr);

        // The quarters lean to one side of the mean instant and the other.
        double W = 0.00306 - 0.00038*E*cos(Mr) + 0.00026*cos(MAr) - 0.00002*cos(MAr - Mr)
                 + 0.00002*cos(MAr + Mr) + 0.00002*cos(2*Fr);
        jde += (which==MOON_FIRST_QUARTER) ? W : -W;
     }

     // Planetary arguments.  Small - a minute and a half between them at most -
     // but they are the difference between four seconds of error and a hundred.
     static const double aBase[14] = { 299.77, 251.88, 251.83, 349.42,  84.66, 141.74, 207.14,
                                       154.84,  34.52, 207.19, 291.34, 161.72, 239.56, 331.55 };
     static const double aRate[14] = {   0.107408,  0.016321, 26.651886, 36.412478, 18.206239,
                                        53.303771,  2.453732,  7.306860, 27.261239,  0.121824,
                                         1.844379, 24.198154, 25.513099,  3.592518 };
     static const double aCoef[14] = { 0.000325, 0.000165, 0.000164, 0.000126, 0.000110,
                                       0.000062, 0.000060, 0.000056, 0.000047, 0.000042,
                                       0.000040, 0.000037, 0.000035, 0.000023 };
     for (int i=0; i<14; i++)
     {
         double a = aBase[i] + aRate[i]*k;
         if (i==0)
            a -= 0.009173*T2;
         jde += aCoef[i] * sin(radians(wrapTo360(a)));
     }

     return jde;
}

// Lunation number whose mean new moon last preceded the given instant.
double moonLunationNumber(double jdTT) {
     return floor((jdTT - 2451550.09766) / 29.530588861);
}

// Apparent geocentric elongation of the moon from the sun, measured in longitude
// alone: 0 at the new moon, 90 at the first quarter, 180 at the full.  This is
// the angle the four principal phases are defined by, so it is what they are
// solved against here.
double moonElongationInLongitude(double jdTT) {
     double lambda, beta, distance, dPsi, epsilon;
     moonPlaceAt(jdTT, lambda, beta, distance, dPsi, epsilon);

     // The nutation is common to both bodies and cancels in the difference, but
     // it costs nothing to leave it on and it keeps the two longitudes the same
     // ones the rest of this file reports.
     return wrapTo360(lambda + dPsi/3600.0 - sunApparentLongitude(jdTT));
}

// Instant of one principal phase of lunation k, as a Julian ephemeris day.
//
// Chapter 49 places it within some five seconds, eighteen at worst, and that is
// as good as a series in k alone can be: it carries a lunar theory of its own,
// fitted decades ago, and there is no dial on it to turn.  The elongation the
// phase is defined by can simply be solved instead, and the moon and the sun
// this file already has are worth 0''.09 and 0''.13 - a hundredth of a second of
// time between them.  The mean instant is where the search starts, so it is
// never more than a few Newton steps away; the elongation opens at a bit over
// twelve degrees a day, and dividing the gap by that rate converges in three
// passes from twenty seconds out.
double moonPhaseInstant(double lunation, int which) {
     double jde = moonPhaseJDE(lunation, which);
     double target = which * 90.0;

     for (int pass=0; pass<6; pass++)
     {
         double gap = moonElongationInLongitude(jde) - target;
         gap -= 360.0 * floor(gap/360.0 + 0.5);      // to the nearer side of the turn

         double step = -gap / 12.19;
         jde += step;
         if (fabs(step) < 1.0e-7)                    // ten milliseconds
            break;
     }

     return jde;
}

// Everything one call can say about the moon.  Angles are in degrees, distances
// in kilometres, times in days.
struct MoonState {
    double jdUT;          // Julian day, universal time
    double jdTT;          // ... and dynamical time, which the series want
    double lambda;        // apparent geocentric ecliptic longitude
    double beta;          // apparent geocentric ecliptic latitude
    double distance;      // centre to centre, km
    double parallax;      // equatorial horizontal parallax
    double ra, dec;       // apparent geocentric right ascension and declination
    double raTopo;        // ... as seen from the observer's place on the surface
    double decTopo;
    double hourAngle;     // topocentric local hour angle
    double azimuth;       // degrees east of north
    double altitude;      // topocentric altitude, geometric
    double altitudeApp;   // ... as refraction leaves it
    double sunLambda;     // sun's apparent geocentric longitude
    double sunRadius;     // sun's distance, astronomical units
    double elongation;    // geocentric moon-sun angle, 0 to 180
    double phaseAngle;    // sun-moon-earth angle
    double illumination;  // lit fraction of the disk, per cent
    double phase;         // place in the lunation: 0 new, 0.25 first quarter, 0.5 full
    double age;           // days since the new moon that actually happened
    int    phaseID;       // 0-7, an eighth of the lunation each
};

// How much of the state a caller needs.  The hunt for the moon's highest point
// asks for an altitude a few dozen times per call and has no use for the rest.
enum MoonDetail { MOON_DETAIL_PLACE = 0,   // where the moon is in the sky
                  MOON_DETAIL_ALL   = 1 }; // ... and how lit and how old it is

void moonComputeState(double timeUTC, double obslatitude, double obslongitude,
                      MoonState &s, MoonDetail detail) {
     s.jdUT = timeUTC / 86400.0 + 2440587.5;
     s.jdTT = s.jdUT + deltaTseconds(s.jdUT) / 86400.0;

     double T = (s.jdTT - 2451545.0) / 36525.0;

     // Where the moon is, read off the day's fit of ELP/MPP02, with the nutation
     // and the true obliquity of the ecliptic that were fitted alongside it.
     double lambdaGeometric, dPsi, epsilon;
     moonPlaceAt(s.jdTT, lambdaGeometric, s.beta, s.distance, dPsi, epsilon);
     s.parallax = degrees(asin(6378.14 / s.distance));

     // Apparent longitude, which is the geometric one carried forward by the
     // nutation.  The light time is already off it: moonPlaceAt() reads the fit
     // back at the moment the light left the moon.
     s.lambda = wrapTo360(lambdaGeometric + dPsi/3600.0);

     // Right ascension and declination - Meeus chapter 13.  Read straight off
     // the ecliptic coordinates: the half-angle detour this replaces rounded the
     // declination to whole arcseconds on its way through a degrees-minutes-
     // seconds decomposition it then undid again.
     double bR = radians(s.beta), lR = radians(s.lambda), eR = radians(epsilon);
     s.ra  = wrapTo360(degrees(atan2(sin(lR)*cos(eR) - tan(bR)*sin(eR), cos(lR))));
     s.dec = degrees(asin(sin(bR)*cos(eR) + cos(bR)*sin(eR)*sin(lR)));

     // Apparent sidereal time at Greenwich - Meeus chapter 12.  This one measures
     // the earth's rotation, so it is a function of UT and not of TT.
     double Tu = (s.jdUT - 2451545.0) / 36525.0;
     double gmst = wrapTo360(280.46061837 + 360.98564736629*(s.jdUT - 2451545.0)
                            + 0.000387933*Tu*Tu - Tu*Tu*Tu/38710000.0);
     double gast = gmst + (dPsi/3600.0) * cos(radians(epsilon));

     // Local hour angle, still geocentric.  Longitude counts positive east.
     double H = wrapTo360(gast + obslongitude - s.ra);

     // The observer stands on the surface, not at the centre, and for the moon
     // that is worth up to a degree - Meeus chapter 40.  Taking the parallax out
     // in the equatorial frame carries the earth's flattening with it and leaves
     // a declination and an hour angle that the azimuth can be read from too,
     // rather than only shifting the altitude.
     double latR = radians(obslatitude);
     double u = atan2(0.99664719*sin(latR), cos(latR));
     double rhoSinPhi = 0.99664719*sin(u);
     double rhoCosPhi = cos(u);

     double sinPi = sin(radians(s.parallax));
     double decR = radians(s.dec), HR = radians(H);
     double denom = cos(decR) - rhoCosPhi*sinPi*cos(HR);
     double dRA = atan2(-rhoCosPhi*sinPi*sin(HR), denom);

     s.raTopo    = wrapTo360(s.ra + degrees(dRA));
     s.decTopo   = degrees(atan2((sin(decR) - rhoSinPhi*sinPi)*cos(dRA), denom));
     s.hourAngle = wrapTo360(H - degrees(dRA));

     // Horizontal coordinates - Meeus chapter 13.  Meeus reckons the azimuth
     // west from the south; the half turn puts it east from the north.
     double dtR = radians(s.decTopo), htR = radians(s.hourAngle);
     double sinLat = sin(latR), cosLat = cos(latR);
     s.altitude = degrees(asin(sinLat*sin(dtR) + cosLat*cos(dtR)*cos(htR)));
     s.azimuth  = wrapTo360(180.0 + degrees(atan2(cos(dtR)*sin(htR),
                            cos(dtR)*cos(htR)*sinLat - sin(dtR)*cosLat)));

     // Refraction lifts the moon by half a degree at the horizon, and it has to
     // be read off the altitude the moon is actually at - the one parallax has
     // already pushed down.  Reading it off the geocentric altitude instead, as
     // this used to, is a third of a degree out around rise and set, where the
     // curve is at its steepest and where it matters most.
     s.altitudeApp = s.altitude + calcRefraction(s.altitude);

     if (detail == MOON_DETAIL_PLACE)
        return;

     // The sun, from the same VSOP87 series the equinoxes and the solstices are
     // solved against - 0''.13, where the chapter 25 shortcut this replaces is
     // 36''.  The elongation is a difference of two longitudes, so whatever the
     // sun is out by lands on it whole: 36'' of it is a minute and a quarter on
     // the instant of a phase, against the hundredth of a second the two
     // longitudes are worth between them now.
     s.sunLambda = sunApparentLongitude(s.jdTT);
     s.sunRadius = calcSunRadVector(T);

     // Elongation, phase angle and the lit fraction of the disk - Meeus chapter
     // 48.  Only the rigorous 48.3 is used now.  The two-term approximation of
     // 48.4 that this used to average it with is a tenth of a per cent adrift,
     // and averaging a good figure with a worse one only spoils the good one.
     double elongInLongitude = wrapTo360(s.lambda - s.sunLambda);   // 0 at new, 180 at full
     s.elongation = degrees(acos(cos(radians(s.beta)) * cos(radians(elongInLongitude))));

     double sunKm = s.sunRadius * 149597870.7;
     s.phaseAngle = degrees(atan2(sunKm * sin(radians(s.elongation)),
                                  s.distance - sunKm * cos(radians(s.elongation))));
     s.illumination = 100.0 * (1.0 + cos(radians(s.phaseAngle))) / 2.0;

     // Where the moon stands in the lunation.  New moon, first quarter, full and
     // last quarter are defined by the elongation - 0, 90, 180, 270 degrees - so
     // that is what names the phase here.  The mean cycle this replaces ran up to
     // half a day fast or slow and put the name outright wrong about one day in
     // eleven, which is what the corrections on the AutoHotkey side were for.
     s.phase   = elongInLongitude / 360.0;
     s.phaseID = ((int)floor(s.phase * 8.0 + 0.5)) % 8;

     // Age is a length of time, so it is counted from the new moon that really
     // happened rather than from a mean one.  The mean series of chapter 49 is
     // never more than about 0.6 days out, so the walk below settles the lunation
     // in a step or two, and only the one it settles on is worth solving properly.
     double k = moonLunationNumber(s.jdTT);
     while (moonPhaseJDE(k, MOON_NEW) > s.jdTT)
           k -= 1.0;

     while (moonPhaseJDE(k + 1.0, MOON_NEW) <= s.jdTT)
           k += 1.0;

     double prevNew = moonPhaseInstant(k, MOON_NEW);
     if (prevNew > s.jdTT)      // the given moment falls inside the mean series' own error
        prevNew = moonPhaseInstant(k - 1.0, MOON_NEW);

     s.age = s.jdTT - prevNew;
}


DLL_API int DLL_CALLCONV getMoonPhase(double timeUTC, double obsLat, double obsLon, double* p, int* IDp, double* a, double* f, double* latu, double* lon, double* azi, double* eleva) {
   MoonState s;
   moonComputeState(timeUTC, obsLat, obsLon, s, MOON_DETAIL_ALL);

   *p     = s.phase;
   *IDp   = s.phaseID;
   *a     = s.age;
   *f     = s.illumination;    // per cent
   *latu  = s.beta;
   *lon   = s.lambda;
   *azi   = s.azimuth;
   *eleva = s.altitudeApp;
   return 1;
}

// Kept for the callers that want the zodiac sign, which the call above does not
// report.  It used to run the Schaefer approximation of MoonPhase.cpp, whose
// longitude wanders by several degrees and put the sign on the wrong side of a
// boundary often enough to notice; the numbers now come from the same place as
// everything else.  Note that this one hands back the lit fraction from 0 to 1,
// where getMoonPhase() hands back a percentage - the two callers on the
// AutoHotkey side differ that way and always have.
DLL_API int DLL_CALLCONV oldgetMoonPhase(double timeus, int timeGiven, double* p, int* IDp, double* a, double* f, double* latu, double* lon, int* z) {
  double timeUTC = (timeGiven==1) ? timeus : (double)time(NULL);

  // Nothing this one reports depends on where the observer stands, so the place
  // handed to the core is immaterial.
  MoonState s;
  moonComputeState(timeUTC, 0.0, 0.0, s, MOON_DETAIL_ALL);

  *p = s.phase;
  *IDp = s.phaseID;
  *a = s.age;
  *f = s.illumination / 100.0;
  *latu = s.beta;
  *lon = s.lambda;

  // Ecliptic bounds of the zodiacal constellations, as MoonPhase.cpp lists them.
  int zodiacID = 0;
  for (int i = 0; i < (int)(sizeof(zodiacAngles) / sizeof(float)); i++)
  {
      if (s.lambda < zodiacAngles[i])
      {
         zodiacID = i;
         break;
      }
  }
  *z = zodiacID;
  return 1;
}

// How long from timeUTC until each of the four principal phases next comes round,
// in seconds.  Meeus chapter 49 gives the instants outright, so there is nothing
// here to search for: the caller no longer has to walk the phase forward in ten
// minute steps and watch for the name to turn over, which took a couple of
// thousand calls to land on a boundary it could only ever resolve to the width of
// a step - and which named the moment the moon entered the new or full eighth of
// the cycle, nearly two days before the phase itself.
//
// The four are handed back as offsets rather than as absolute times, the way
// getMoonNoon() and getSunMoonRiseSet() do, so the caller can add them straight
// onto the timestamp it asked about.  An offset is also a difference of two
// dynamical times, which leaves delta T out of it entirely.
DLL_API int DLL_CALLCONV getNextMoonPhases(double timeUTC, double* toNew, double* toFirstQuarter, double* toFull, double* toLastQuarter) {
     double jdUT = timeUTC / 86400.0 + 2440587.5;
     double jdTT = jdUT + deltaTseconds(jdUT) / 86400.0;

     double* out[4] = { toNew, toFirstQuarter, toFull, toLastQuarter };
     for (int which = 0; which < 4; which++)
     {
         // Two lunations back is far enough that every phase of the four starts
         // out behind the given moment, whichever quarter of the cycle it sits in.
         double k = moonLunationNumber(jdTT) - 2.0;
         double jde = moonPhaseJDE(k, which);
         for (int step = 0; step < 8 && jde <= jdTT; step++)
         {
             k += 1.0;
             jde = moonPhaseJDE(k, which);
         }

         // The mean series only settles which lunation the phase belongs to;
         // where it falls inside that lunation is then solved against the
         // elongation, which is worth some five seconds.
         double instant = moonPhaseInstant(k, which);
         if (instant <= jdTT)
            instant = moonPhaseInstant(k + 1.0, which);

         *out[which] = (instant - jdTT) * 86400.0;
     }

     return 1;
}

DLL_API int DLL_CALLCONV getMoonElevation(double timeUTC, double obslatitude, double obslongitude, double *azimuth, double *eleva) {
     MoonState s;
     moonComputeState(timeUTC, obslatitude, obslongitude, s, MOON_DETAIL_PLACE);
     *azimuth = s.azimuth;
     *eleva   = s.altitudeApp;
     return 1;
}

double moonAltitudeAt(double timeUTC, double obslatitude, double obslongitude) {
     MoonState s;
     moonComputeState(timeUTC, obslatitude, obslongitude, s, MOON_DETAIL_PLACE);
     return s.altitudeApp;
}

// Golden-section search for the moon's highest or lowest point inside a bracket
// known to hold it.  Twenty-five or so evaluations bring an hour-wide bracket
// down to a twentieth of a second, where the altitude curve is flat to far
// under a thousandth of a degree.  The minute-by-minute walk this replaces cost
// five times as many evaluations of the full series and still left the transit
// quantised to whole minutes.
void moonFindExtremum(double loTime, double hiTime, double obslatitude, double obslongitude,
                      int wantMax, double &bestTime, double &bestAlt) {
     const double invPhi = 0.6180339887498949;
     double sign = wantMax ? 1.0 : -1.0;

     double a = loTime, b = hiTime;
     double c = b - invPhi*(b - a);
     double d = a + invPhi*(b - a);
     double fc = sign * moonAltitudeAt(c, obslatitude, obslongitude);
     double fd = sign * moonAltitudeAt(d, obslatitude, obslongitude);

     while (b - a > 0.05)
     {
         if (fc > fd)
         {
            b = d;  d = c;  fd = fc;
            c = b - invPhi*(b - a);
            fc = sign * moonAltitudeAt(c, obslatitude, obslongitude);
         } else
         {
            a = c;  c = d;  fc = fd;
            d = a + invPhi*(b - a);
            fd = sign * moonAltitudeAt(d, obslatitude, obslongitude);
         }
     }

     bestTime = (a + b) / 2.0;
     bestAlt  = moonAltitudeAt(bestTime, obslatitude, obslongitude);
}

// Highest point the moon reaches in the twenty-four hours from timeUTC, and
// optionally its lowest.  hmax and hmin come back as minutes from timeUTC, now
// with the fraction on them - the caller should carry them over in seconds.
DLL_API int DLL_CALLCONV getMoonNoon(double timeUTC, double obslatitude, double obslongitude, int doMinu, double *hmax, double *hmin, double *fmax, double *fmin) {
     // Hour 24 belongs in the grid as well: without it a peak inside the closing
     // hour of the day is only ever sampled up to an hour before it, and a lower
     // interior peak elsewhere in the day can win the comparison, leaving the moon's
     // highest point out by as much as five degrees on a handful of days a year.
     const int kHours = 24;
     double alt[kHours + 1];
     int iMax = 0, iMin = 0;
     for (int i = 0; i <= kHours; ++i)
     {
         alt[i] = moonAltitudeAt(timeUTC + i*3600.0, obslatitude, obslongitude);
         if (alt[i] > alt[iMax])
            iMax = i;

         if (alt[i] < alt[iMin])
            iMin = i;
     }

     // The winning sample has both its neighbours below it, so the turning point
     // lies between them.  At the ends of the day there is no neighbour to lean
     // on and the bracket stops at the edge, which keeps the answer inside the
     // day it was asked about.
     double peakTime, peakAlt;
     double lo = timeUTC + (iMax > 0 ? iMax - 1 : 0) * 3600.0;
     double hi = timeUTC + (iMax < kHours ? iMax + 1 : kHours) * 3600.0;
     moonFindExtremum(lo, hi, obslatitude, obslongitude, 1, peakTime, peakAlt);
     *hmax = (peakTime - timeUTC) / 60.0;
     *fmax = peakAlt;

     if (doMinu==1)
     {
        lo = timeUTC + (iMin > 0 ? iMin - 1 : 0) * 3600.0;
        hi = timeUTC + (iMin < kHours ? iMin + 1 : kHours) * 3600.0;
        moonFindExtremum(lo, hi, obslatitude, obslongitude, 0, peakTime, peakAlt);
        *hmin = (peakTime - timeUTC) / 60.0;
        *fmin = peakAlt;
     }

     return 1;
}

// ============================================================================
//  Moonrise and moonset
//
//  An event is the instant the moon's upper limb meets the horizon, with the
//  standard 34 arcminutes of refraction allowed for.  Written against the
//  topocentric altitude of the centre - which is what moonComputeState already
//  works out, the observer's parallax and the earth's flattening included - the
//  criterion is
//
//      altitude + semidiameter + 34' + dip = 0
//
//  and the moon is up while that is positive.  The semidiameter is 0.2725 of the
//  horizontal parallax, so the threshold moves with the moon's distance, by some
//  four minutes of time between perigee and apogee.
//
//  The dip is how far the horizon falls away for an observer standing above the
//  ground around them: 1.76 arcminutes for the square root of every metre.  A
//  hundred metres up that is a minute and a half of time, five hundred metres up
//  four minutes and a half.  The AutoHotkey side used to add Altitude/1453
//  minutes for this, which is a twentieth of what it should be.
//
//  This replaces MoonRise.cpp, which computed the moon's place three times a day
//  from a 34-term series published in Sky & Telescope in 1989, interpolated
//  between them with a parabola, and handed the series universal time where it
//  wanted dynamical time.  Measured against JPL DE440 over twelve places and ten
//  years it was 42 seconds out at the root mean square and 294 at worst; what is
//  below is 0.05 seconds and 0.2, and the whole of that is the tenth of an
//  arcsecond in the theory underneath it.
// ============================================================================

// How far the moon stands above its own rising, in degrees: zero at the event.
static double moonHorizonGap(double timeUTC, double obslatitude, double obslongitude,
                             double dip, double *azimuth) {
     MoonState s;
     moonComputeState(timeUTC, obslatitude, obslongitude, s, MOON_DETAIL_PLACE);
     if (azimuth)
        *azimuth = s.azimuth;

     return s.altitude + 0.2725*s.parallax + 0.5667 + dip;
}

// The instant inside a bracket at which it changes sign.  False position with the
// bracket kept around the root: over ten minutes the altitude is so nearly
// straight that three or four passes settle it, and the bisection the guard falls
// back on cannot fail to.
static double moonHorizonCrossing(double loTime, double loGap, double hiTime, double hiGap,
                                  double obslatitude, double obslongitude, double dip) {
     for (int pass=0; pass<40 && (hiTime - loTime) > 0.02; pass++)
     {
         double t = loTime + (hiTime - loTime)*loGap/(loGap - hiGap);
         double guard = 0.05*(hiTime - loTime);
         if (t < loTime + guard)
            t = loTime + guard;
         if (t > hiTime - guard)
            t = hiTime - guard;

         double gap = moonHorizonGap(t, obslatitude, obslongitude, dip, 0);
         if ((gap < 0.0) == (loGap < 0.0))
         {
            loTime = t;  loGap = gap;
         } else
         {
            hiTime = t;  hiGap = gap;
         }
     }

     return (loTime + hiTime) / 2.0;
}

// The moon's rise and its set inside a span of time, as seconds from its start,
// or -1 for an event that does not fall inside it.  The moon crosses the horizon
// at most once each way in a day, so at most one of each is ever found.
//
// The span is walked in ten minute steps looking for a change of sign.  A pass
// above the horizon shorter than one step would be missed, which can happen near
// the poles on the day the moon first clears it; the hour the old code stepped in
// missed rather more of them, and an event that brief is not one a clock has any
// business naming to the minute anyway.
void moonRiseSetInSpan(double startUTC, double spanSeconds, double obslatitude,
                       double obslongitude, double obsHeight,
                       double &riseSeconds, double &setSeconds,
                       double &riseAzimuth, double &setAzimuth) {
     const double kStepSeconds = 600.0;

     double dip = (obsHeight > 0.0) ? 0.029333*sqrt(obsHeight) : 0.0;
     riseSeconds = setSeconds = -1.0;
     riseAzimuth = setAzimuth = 0.0;

     int steps = (int)ceil(spanSeconds/kStepSeconds);
     if (steps < 1)
        steps = 1;

     double loTime = startUTC;
     double loGap  = moonHorizonGap(loTime, obslatitude, obslongitude, dip, 0);
     for (int i=1; i<=steps; i++)
     {
         double hiTime = (i < steps) ? startUTC + i*kStepSeconds : startUTC + spanSeconds;
         double hiGap  = moonHorizonGap(hiTime, obslatitude, obslongitude, dip, 0);

         if ((loGap < 0.0) != (hiGap < 0.0))
         {
            double t = moonHorizonCrossing(loTime, loGap, hiTime, hiGap,
                                           obslatitude, obslongitude, dip);
            double azimuth;
            moonHorizonGap(t, obslatitude, obslongitude, dip, &azimuth);

            if (hiGap > loGap)
            {
               if (riseSeconds < 0.0)
               {
                  riseSeconds = t - startUTC;
                  riseAzimuth = azimuth;
               }
            } else if (setSeconds < 0.0)
            {
               setSeconds = t - startUTC;
               setAzimuth = azimuth;
            }
         }

         loTime = hiTime;
         loGap  = hiGap;
     }
}

// The moon's rise and set over one civil day, for a caller that knows where its
// day begins and how long it is - the length is given rather than assumed, so
// that the day a clock changes is 23 or 25 hours here as it is on the wall.
//
// dayStartUTC is that day's first moment, in seconds since the Unix epoch, and
// what comes back are seconds from it, or -1 where the event does not fall inside
// the day.  obsHeight is how far the observer stands above the ground around
// them, in metres, which lowers their horizon and so brings the rise forward and
// puts the set back.
DLL_API int DLL_CALLCONV getMoonRiseSetDay(double dayStartUTC, double spanSeconds,
                                           double lat, double lon, double obsHeight,
                                           double* riseSeconds, double* setSeconds,
                                           double* riseAzimuth, double* setAzimuth) {
     double rise, setu, riseAz, setAz;
     moonRiseSetInSpan(dayStartUTC, spanSeconds, lat, lon, obsHeight,
                       rise, setu, riseAz, setAz);

     *riseSeconds = rise;
     *setSeconds  = setu;
     *riseAzimuth = riseAz;
     *setAzimuth  = setAz;
     return 1;
}


DLL_API int DLL_CALLCONV getTwilightDuration(double t, double lat, double lon, double degs, double* twDur) {
  // Find duration of today's twilight.
  Twilight tw;
  tw.calculate(lat, lon, degs, t);
  time_t duration = tw.twilightDuration;
  // Duration in seconds of twilight. [morning or evening, both are considered to be equal]
  *twDur = duration;
  // fnOutputDebug(std::to_string(duration));
  // fnOutputDebug(std::to_string(lat));
  // fnOutputDebug(std::to_string(t));
  // fnOutputDebug(std::to_string(degs));
  // fnOutputDebug(std::to_string(t));

  return 1;
}


DLL_API int DLL_CALLCONV getSunAzimuthElevation(double t, int y, int m, int d, int hh, int mm, double lat, double lon, double* azi, double* elev) {
  double azimuth, elevation;

  // calcHorizontalCoordinates(t, lat, lon, azimuth, elevation);
  calcHorizontalCoordinates(y,m,d,hh,mm, 30, lat, lon, azimuth, elevation);
  *azi = azimuth;
  *elev = elevation;
  // fnOutputDebug("elev=" + std::to_string(elevation) + "lat=" + std::to_string(lat) + "lon=" + std::to_string(lon));
  // fnOutputDebug(std::to_string(t) + "date=" + std::to_string(y) + std::to_string(m) + std::to_string(d) + std::to_string(hh) + std::to_string(mm));
  return 1;
}

DLL_API int DLL_CALLCONV getSunMoonRiseSet(double t, double rt, double lat, double lon, int obju, double* riseu, double* setu, double* twDur) {

  // Calculate sun related information.
  if (obju==1)
  {
     SunRise sr;
     sr.calculate(lat, lon, t);
     if (sr.hasRise)
        *riseu = -1*(rt - sr.riseTime)/3600;
     else
        *riseu = 999999;

     if (sr.hasSet)
        *setu = -1*(rt - sr.setTime)/3600;
     else
        *setu = 999999;

     // Find duration of today's twilight.
     Twilight tw;
     tw.calculate(lat, lon, 6.1, t);
     *twDur = tw.twilightDuration;  // Duration in seconds of twilight.
  } else
  {
     // The moon.  The window is the day either side of the moment asked about,
     // which is what MoonRise.cpp searched and what the callers still expect;
     // getMoonRiseSetDay() answers for a named day instead and is the better way
     // in for anything that knows which day it wants.
     double riseAt, setAt, riseAz, setAz;
     double windowStart = t - 12*3600.0;
     moonRiseSetInSpan(windowStart, 24*3600.0, lat, lon, 0.0, riseAt, setAt, riseAz, setAz);

     *riseu = (riseAt >= 0.0) ? (windowStart + riseAt - rt)/3600.0 : 999999;
     *setu  = (setAt  >= 0.0) ? (windowStart + setAt  - rt)/3600.0 : 999999;
  }

  return 1;
}

// Equinoxes and solstices, out of Astronomical Algorithms, second edition, by Jean
// Meeus, (c)1998, published by Willmann-Bell, Inc., Richmond, VA, ISBN 0-943396-61-1:
// chapter 27 for the events, chapter 25 for the Sun's position they are defined by.
// This began as a port of the JavaScript behind https://stellafane.org/misc/equinox.html
// by its author Ken Slater, converted to C++ by Marius Șucan in 2022.  What is left of
// that port is table 27.B below.  The 24 term shortcut it used in place of a real solar
// theory is gone, and so is the dynamical time it handed back as though it were UTC.

double calcJDEzEquiSols(int k, int year) {
// Mean equinox or solstice of a given year, as a Julian ephemeris day - Meeus
// chapter 27, table 27.B, valid for the years 1000 to 3000.  This is only where
// the search starts: the true instant lies up to some twenty minutes away from
// it and equiSolsJDE() walks the rest of the way.
// k: 0 = March equinox, 1 = June solstice, 2 = September equinox, 3 = December solstice.

   double JDEzero = 0.0;
   double Y = (year - 2000.0) / 1000.0;
   if (k==0)
      JDEzero = 2451623.80984 + 365242.37404*Y + 0.05169*pow(Y, 2) - 0.00411*pow(Y, 3) - 0.00057*pow(Y, 4);
   else if (k==1)
      JDEzero = 2451716.56767 + 365241.62603*Y + 0.00325*pow(Y, 2) + 0.00888*pow(Y, 3) - 0.00030*pow(Y, 4);
   else if (k==2)
      JDEzero = 2451810.21715 + 365242.01767*Y - 0.11575*pow(Y, 2) + 0.00337*pow(Y, 3) + 0.00078*pow(Y, 4);
   else if (k==3)
      JDEzero = 2451900.05952 + 365242.74049*Y - 0.06223*pow(Y, 2) - 0.00823*pow(Y, 3) + 0.00032*pow(Y, 4);

   return JDEzero;
}

// Earth's heliocentric longitude, as the periodic terms of VSOP87D - amplitude in
// radians, phase in radians, frequency in radians per Julian millennium - grouped
// by the power of time they belong to.  The series is the one distributed as
// VSOP87D.ear (Bureau des Longitudes, Bretagnon & Francou 1988), cut to the terms
// of at least 3e-8 radian; the 858 terms left out of the longitude move it by no
// more than 0''.13, which is three seconds of time, anywhere in 1000-3000.
//
// Meeus prints a shorter version of the same series in his Appendix III.  It is
// three times coarser - 0''.74, eighteen seconds of time - which is most of what
// the answer would be worth, so the fuller cut is used here instead.
static const int vsopEarthLterms[5] = {152, 50, 15, 3, 2};
static const double vsopEarthL[222*3] = {
     // T^0, 152 terms
     1.75347045673, 0.00000000,     0.00000000, 0.03341656456, 4.66925680,  6283.07584999,
     0.00034894275, 4.62610242, 12566.15169998, 0.00003417571, 2.82886580,     3.52311835,
     0.00003497056, 2.74411801,  5753.38488490, 0.00003135896, 3.62767042, 77713.77146812,
     0.00002676218, 4.41808351,  7860.41939244, 0.00002342687, 6.13516238,  3930.20969622,
     0.00001273166, 2.03709656,   529.69096509, 0.00001324292, 0.74246356, 11506.76976979,
     0.00000901855, 2.04505444,    26.29831980, 0.00001199167, 1.10962944,  1577.34354245,
     0.00000857223, 3.50849157,   398.14900341, 0.00000779786, 1.17882652,  5223.69391980,
     0.00000990250, 5.23268130,  5884.92684658, 0.00000753141, 2.53339054,  5507.55323867,
     0.00000505264, 4.58292563, 18849.22754997, 0.00000492379, 4.20506640,   775.52261132,
     0.00000356655, 2.91954117,     0.06731030, 0.00000284125, 1.89869034,   796.29800682,
     0.00000242810, 0.34481141,  5486.77784318, 0.00000317087, 5.84901952, 11790.62908866,
     0.00000271039, 0.31488608, 10977.07880470, 0.00000206160, 4.80646606,  2544.31441988,
     0.00000205385, 1.86947814,  5573.14280143, 0.00000202261, 2.45767795,  6069.77675455,
     0.00000126184, 1.08302630,    20.77539549, 0.00000155516, 0.83306074,   213.29909544,
     0.00000115132, 0.64544912,     0.98032107, 0.00000102851, 0.63599847,  4694.00295471,
     0.00000101724, 4.26679821,     7.11354700, 0.00000099206, 6.20992940,  2146.16541648,
     0.00000132212, 3.41118276,  2942.46342329, 0.00000097607, 0.68101272,   155.42039943,
     0.00000085128, 1.29870743,  6275.96230299, 0.00000074651, 1.75508916,  5088.62883977,
     0.00000101895, 0.97569222, 15720.83878488, 0.00000084711, 3.67080093, 71430.69561813,
     0.00000073547, 4.67926565,   801.82093112, 0.00000073874, 3.50319443,  3154.68708490,
     0.00000078756, 3.03698313, 12036.46073489, 0.00000079637, 1.80791331, 17260.15465469,
     0.00000085803, 5.98322631, 161000.68573767, 0.00000056963, 2.78430398,  6286.59896834,
     0.00000061148, 1.81839811,  7084.89678112, 0.00000069627, 0.83297597,  9437.76293489,
     0.00000056116, 4.38694881, 14143.49524243, 0.00000062449, 3.97763881,  8827.39026987,
     0.00000051145, 0.28306865,  5856.47765912, 0.00000055577, 3.47006009,  6279.55273164,
     0.00000041036, 5.36817351,  8429.24126647, 0.00000051605, 1.33282747,  1748.01641307,
     0.00000051992, 0.18914946, 12139.55350911, 0.00000049000, 0.48735065,  1194.44701022,
     0.00000039200, 6.16832995, 10447.38783960, 0.00000035566, 1.77597315,  6812.76681509,
     0.00000036770, 6.04133859, 10213.28554621, 0.00000036596, 2.56955239,  1059.38193019,
     0.00000033291, 0.59309499, 17789.84561978, 0.00000035954, 1.70876112,  2352.86615377,
     0.00000040938, 2.39850882, 19651.04848110, 0.00000030047, 2.73975124,  1349.86740966,
     0.00000030412, 0.44294464, 83996.84731811, 0.00000023663, 0.48473568,  8031.09226306,
     0.00000023574, 2.06527720,  3340.61242670, 0.00000021089, 4.14825464,   951.71840625,
     0.00000024738, 0.21484762,     3.59042865, 0.00000025352, 3.16470953,  4690.47983636,
     0.00000022820, 5.22197888,  4705.73230754, 0.00000021419, 1.42563736, 16730.46368960,
     0.00000021891, 5.55594303,   553.56940284, 0.00000017481, 4.56052900,   135.06508004,
     0.00000019925, 5.22208471, 12168.00269657, 0.00000019860, 5.77470168,  6309.37416979,
     0.00000020300, 0.37133793,   283.85931887, 0.00000014421, 4.19315333,   242.72860397,
     0.00000016225, 5.98837723, 11769.85369317, 0.00000015077, 4.19567181,  6256.77753019,
     0.00000019124, 3.82219997, 23581.25817732, 0.00000018888, 5.38626881, 149854.40013481,
     0.00000014346, 3.72355084,    38.02767264, 0.00000017898, 2.21490736, 13367.97263111,
     0.00000012054, 2.62229588,   955.59974161, 0.00000011287, 0.17739328,  4164.31198961,
     0.00000013971, 4.40138140,  6681.22485340, 0.00000013621, 1.88934471,  7632.94325965,
     0.00000012503, 1.13052412,     5.52292431, 0.00000010498, 5.35909519,  1592.59601363,
     0.00000009803, 0.99947479, 11371.70468976, 0.00000009220, 4.57138610,  4292.33083295,
     0.00000010327, 6.19982566,  6438.49624943, 0.00000012003, 1.00351457,   632.78373931,
     0.00000010827, 0.32734520,   103.09277422, 0.00000008356, 4.53902686, 25132.30339997,
     0.00000010005, 6.02914963,  5746.27133790, 0.00000008409, 3.29946744,  7234.79425624,
     0.00000008006, 5.82145272,    28.44918747, 0.00000010523, 0.93871806, 11926.25441367,
     0.00000007686, 3.12142363,  7238.67559160, 0.00000009378, 2.62414241,  5760.49843190,
     0.00000008127, 6.11228002,  4732.03062734, 0.00000009232, 0.48343969,   522.57741809,
     0.00000009802, 5.24413991, 27511.46787354, 0.00000007871, 0.99590178,  5643.17856368,
     0.00000008123, 6.27053014,   426.59819088, 0.00000009048, 5.33686336,  6386.16862421,
     0.00000008620, 4.16538211,  7058.59846132, 0.00000006297, 4.71724819,  6836.64525283,
     0.00000007575, 3.97382859, 11499.65622279, 0.00000007756, 2.95729057, 23013.53953959,
     0.00000007314, 0.60652506, 11513.88331679, 0.00000005955, 2.87641048,  6283.14316029,
     0.00000006534, 5.79072926, 18073.70493865, 0.00000007188, 3.99831509,    74.78159857,
     0.00000007346, 4.38582365,   316.39186966, 0.00000005413, 5.39199025,   419.48464388,
     0.00000005127, 2.36062849, 10973.55568635, 0.00000007056, 0.32258442,   263.08392337,
     0.00000006625, 3.66475159, 17298.18232733, 0.00000006762, 5.91132536, 90955.55169450,
     0.00000004938, 5.73672166,  9917.69687451, 0.00000005547, 2.45152598, 12352.85260454,
     0.00000005958, 3.32051345,  6283.00853969, 0.00000004471, 2.06386000,  7079.37385681,
     0.00000006153, 1.45823331, 233141.31440436, 0.00000004348, 4.42342175,  5216.58037280,
     0.00000006123, 1.07494905, 19804.82729158, 0.00000004488, 3.65285037,   206.18554844,
     0.00000004020, 0.83995823,    20.35531940, 0.00000005188, 4.06503864,  6208.29425142,
     0.00000005307, 0.38217636, 31441.67756976, 0.00000003785, 2.34369214,     3.88133536,
     0.00000004497, 3.27230797, 11015.10647733, 0.00000004132, 0.92128916,  3738.76143011,
     0.00000003521, 5.97844807,  3894.18182954, 0.00000004215, 1.90601121,   245.83164623,
     0.00000003701, 5.03069398,   536.80451210, 0.00000003865, 1.82634361, 11856.21865142,
     0.00000003652, 1.01838585, 16200.77272450, 0.00000003390, 0.97785124,  8635.94200376,
     0.00000003737, 2.95380108,  3128.38876510, 0.00000003507, 3.71291946,  6290.18939699,
     0.00000003086, 3.64646922,    10.63666535, 0.00000003397, 1.10590684, 14712.31711646,
     0.00000003334, 0.83684925,  6496.37494543, 0.00000003650, 1.08344143, 88860.05707099,
     0.00000003388, 3.20185096,  5120.60114558, 0.00000003252, 3.47859752,  6133.51265286,
     0.00000003520, 2.05559693, 244287.60000723, 0.00000003161, 1.32798718, 10873.98603048,
     0.00000003163, 5.08946465, 21228.39202355, 0.00000003030, 1.80209931, 35371.88726598,
     // T^1, 50 terms
     6283.31966747491, 0.00000000,     0.00000000, 0.00206058863, 2.67823456,  6283.07584999,
     0.00004303430, 2.63512650, 12566.15169998, 0.00000425264, 1.59046981,     3.52311835,
     0.00000108977, 2.96618002,  1577.34354245, 0.00000093478, 2.59212835, 18849.22754997,
     0.00000119261, 5.79557488,    26.29831980, 0.00000072122, 1.13846158,   529.69096509,
     0.00000067768, 1.87472305,   398.14900341, 0.00000067327, 4.40918235,  5507.55323867,
     0.00000059027, 2.88797038,  5223.69391980, 0.00000055976, 2.17471680,   155.42039943,
     0.00000045407, 0.39803080,   796.29800682, 0.00000036369, 0.46624740,   775.52261132,
     0.00000028958, 2.64707384,     7.11354700, 0.00000019097, 1.84628333,  5486.77784318,
     0.00000020844, 5.34138275,     0.98032107, 0.00000018508, 4.96855125,   213.29909544,
     0.00000016233, 0.03216483,  2544.31441988, 0.00000017293, 2.99116865,  6275.96230299,
     0.00000015832, 1.43049285,  2146.16541648, 0.00000014615, 1.20532366, 10977.07880470,
     0.00000011877, 3.25804816,  5088.62883977, 0.00000011514, 2.07502418,  4694.00295471,
     0.00000009721, 4.23925472,  1349.86740966, 0.00000009969, 1.30262991,  6286.59896834,
     0.00000009452, 2.69957063,   242.72860397, 0.00000012461, 2.83432286,  1748.01641307,
     0.00000011808, 5.27379790,  1194.44701022, 0.00000008577, 5.64475868,   951.71840625,
     0.00000010641, 0.76614199,   553.56940284, 0.00000007576, 5.30062665,  2352.86615377,
     0.00000005834, 1.76649918,  1059.38193019, 0.00000006385, 2.65033985,  9437.76293489,
     0.00000005223, 5.66135768, 71430.69561813, 0.00000005305, 0.90857522,  3154.68708490,
     0.00000006101, 4.66632584,  4690.47983636, 0.00000004330, 0.24102555,  6812.76681509,
     0.00000005041, 1.42490104,  6438.49624943, 0.00000004259, 0.77355901, 10447.38783960,
     0.00000005198, 1.85353197,   801.82093112, 0.00000003744, 2.00119516,  8031.09226306,
     0.00000003558, 2.42901553, 14143.49524243, 0.00000003372, 3.86210700,  1592.59601363,
     0.00000003374, 0.88776220, 12036.46073489, 0.00000003175, 3.18785711,  4705.73230754,
     0.00000003221, 0.61599835,  8429.24126647, 0.00000004132, 5.23992860,  7084.89678112,
     0.00000003504, 4.79975694,  6279.55273164, 0.00000003250, 3.39954640,  7632.94325965,
     // T^2, 15 terms
     0.00052918870, 0.00000000,     0.00000000, 0.00008719837, 1.07209665,  6283.07584999,
     0.00000309125, 0.86728819, 12566.15169998, 0.00000027339, 0.05297872,     3.52311835,
     0.00000016334, 5.18826691,    26.29831980, 0.00000015752, 3.68457889,   155.42039943,
     0.00000009541, 0.75742298, 18849.22754997, 0.00000008937, 2.05705419, 77713.77146812,
     0.00000006952, 0.82673305,   775.52261132, 0.00000005064, 4.66284525,  1577.34354245,
     0.00000004061, 1.03057163,     7.11354700, 0.00000003463, 5.14074633,   796.29800682,
     0.00000003169, 6.05291851,  5507.55323867, 0.00000003020, 1.19246506,   242.72860397,
     0.00000003810, 3.44050803,  5573.14280143,
     // T^3, 3 terms
     0.00000289226, 5.84384199,  6283.07584999, 0.00000034955, 0.00000000,     0.00000000,
     0.00000016819, 5.48766912, 12566.15169998,
     // T^4, 2 terms
     0.00000114084, 3.14159265,     0.00000000, 0.00000007717, 4.13446589,  6283.07584999
};

// Earth's heliocentric longitude in radians, referred to the mean dynamical
// ecliptic and equinox of the date.  tau counts Julian millennia from J2000.
double earthHelioLongitude(double tau) {
     const double *t = vsopEarthL;
     double L = 0.0, power = 1.0;
     for (int p=0; p<5; p++)
     {
         double sum = 0.0;
         for (int i=0; i<vsopEarthLterms[p]; i++, t+=3)
             sum += t[0] * cos(t[1] + t[2]*tau);

         L += sum * power;
         power *= tau;
     }

     return L;
}

// The Sun's apparent geocentric longitude in degrees, referred to the true equinox
// of the date - Meeus chapter 25.  It is what the equinoxes and the solstices are
// defined by: the four events are the instants at which this angle is an exact
// multiple of 90 degrees.  jde is a Julian ephemeris day, in dynamical time.
double sunApparentLongitude(double jde) {
     double tau = (jde - 2451545.0) / 365250.0;
     double T = tau * 10.0;

     // seen from the Earth the Sun sits opposite where the Earth sits seen from the Sun
     double theta = wrapTo360(degrees(earthHelioLongitude(tau)) + 180.0);

     double dPsi, dEpsilon;
     nutationAngles(T, dPsi, dEpsilon);

     // -0''.09033 carries VSOP87's own dynamical frame over to the FK5 one (25.9).
     //   The rest of that correction is proportional to the Sun's ecliptic latitude,
     //   which never reaches 1'', and dies below a millionth of an arcsecond.
     // dPsi is the nutation in longitude, which is what makes the longitude apparent
     //   rather than referred to the mean equinox; it swings over some 35''.
     // -20''.4898/R is the annual aberration (25.11 in its constant form).  R only
     //   enters through it, so the radius vector of chapter 25 is close enough: its
     //   error of 5e-4 AU is worth a quarter of a second of time at the very edges
     //   of the range, and a twentieth of one over 1900-2100.
     // -0''.29965 per century is the correction the IAU adopted in 2000 for the IAU
     //   1976 precession in longitude that VSOP87 was built on.  Left out, it tilts
     //   the whole answer by seven seconds of time per century away from J2000.
     double R = calcSunRadVector(T);
     double corrections = -0.09033 + dPsi - 20.4898/R - 0.29965*T;

     return wrapTo360(theta + corrections/3600.0);
}

// Instant of one equinox or solstice, as a Julian ephemeris day - Meeus chapter 27.
// The mean event of table 27.B is the first guess, and each pass moves it by the
// longitude still missing, 58 days to the radian (27.1).  The Sun's longitude is so
// nearly linear in time that the gap shrinks about thirtyfold a pass, so five or six
// of them land well inside a hundredth of a second.
//
// Chapter 27 also carries a table of 24 periodic terms that answers in one step
// instead, which is what this used to use.  That shortcut is good to 51 seconds
// only; measured against JPL DE440 over 1900-2100 it strays by up to 55 seconds,
// where the route below stays within 2.5 - and the day either lands on is a coin
// toss whenever an event falls within a minute of local midnight.
double equiSolsJDE(int k, int year) {
     double jde = calcJDEzEquiSols(k, year);
     double target = k * 90.0;
     for (int pass=0; pass<10; pass++)
     {
         double correction = 58.0 * sin(radians(target - sunApparentLongitude(jde)));
         jde += correction;
         if (fabs(correction) < 0.0000001)   // a hundredth of a second of time
            break;
     }

     return jde;
}

// Julian day to a UTC calendar date - Meeus chapter 7.  The seconds are rounded
// before the date is taken apart, so that an instant a fraction short of midnight
// is carried into the next day rather than reported as 23:59:60.
void fromJDtoUTC( double JD, int* monu, int* dayu, int* hour, int* minu, int* secu ) {
    double totalSeconds = floor((JD + 0.5)*86400.0 + 0.5);
    double Z = floor(totalSeconds / 86400.0);         // integer JD's
    int daySeconds = (int)(totalSeconds - Z*86400.0); // seconds elapsed since 0h UT
    double A = 0.0;
    if (Z < 2299161)
    {
       A = Z;
    } else
    {
       double alpha = floor( (Z - 1867216.25) / 36524.25 );
       A = Z + 1 + alpha - floor( alpha / 4.0 );
    }

    double B = A + 1524.0;
    double C = floor( (B - 122.1) / 365.25 );
    double D = floor( 365.25*C );
    double E = floor( ( B - D ) / 30.6001 );

    *dayu = (int)(B - D - floor(30.6001 * E));
    *monu = (int)(E - ((E < 13.5) ? 1.0 : 13.0));
    *hour = daySeconds / 3600;
    *minu = (daySeconds / 60) % 60;
    *secu = daySeconds % 60;
    // the year is C - 4716 or C - 4715 and the caller already knows it: an equinox
    // or a solstice never leaves the month it is named after, let alone the year.
}

DLL_API int DLL_CALLCONV calculateEquiSols(int k, int year, int* mm, int* d, int* hh, int* m, int* s) {
// One equinox or solstice of one year, as a UTC date.
// k: 0 = March equinox, 1 = June solstice, 2 = September equinox, 3 = December solstice.
//
// The instant chapter 27 arrives at is in dynamical time, which the earth's rotation
// has been running a good minute behind for the last twenty years.  The JavaScript
// this was ported from - the stellafane.org equinox page by Ken Slater - subtracts
// that gap before it prints a civil time; the port did not, and every event has been
// coming out about 69 seconds late ever since.
   if (k < 0 || k > 3)
      return 0;

   double jdTT = equiSolsJDE(k, year);
   double jdUT = jdTT - deltaTseconds(jdTT) / 86400.0;

   int month, day, hour, mins, secs;
   fromJDtoUTC(jdUT, &month, &day, &hour, &mins, &secs);
   *mm = month;   *d = day;
   *hh = hour;    *m = mins;   *s = secs;

   // fnOutputDebug("k(" + std::to_string(k) + ") " + std::to_string(year) + "/" + std::to_string(month) + "/" + std::to_string(day) + "|" + std::to_string(hour) + ":" + std::to_string(mins));
   return 1;
}


/*
DLL_API double DLL_CALLCONV getMoonLitAngle(double timeUTC, int year, int month, int day, int hour, int minute, double obsLat, double obsLon, int obsAlt) {
// this is the worst function I could write
// the setup is bonkers stupid
// it does not seem to yield good values

   wrapSetUTdate(year, month, day, hour, minute, obsLat, obsLon, obsAlt);
   double sunRA, sunDEC, sunRV;

   JulianDay jd(year, month, day, hour, minute, 35);
   calcEquatorialCoordinates(jd, sunRA, sunDEC, sunRV);

   MoonState s;
   moonComputeState(timeUTC, obsLat, obsLon, s, MOON_DETAIL_ALL);

   double angle = getMoonDiskOrientationAngles(s.beta, s.lambda, s.ra, s.dec, sunRA, sunDEC, obsLat, obsLon);
   fnOutputDebug("moon angle = " + std::to_string(angle));
   fnOutputDebug("moon lat/lon = " + std::to_string(s.beta) + "/" + std::to_string(s.lambda));
   fnOutputDebug("moon ra/dec = " + std::to_string(s.ra) + "/" + std::to_string(s.dec));
   fnOutputDebug("sun ra/dec = " + std::to_string(sunRA) + "/" + std::to_string(sunDEC));
   return angle;
}
*/


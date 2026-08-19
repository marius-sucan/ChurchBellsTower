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
#include "MoonRise.h"
#include "MoonRise.cpp"
#include "Twilight.h"
#include "Twilight.cpp"
#include "SolarCalculator.h"
#include "SolarCalculator.cpp"
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
//  Positions follow Jean Meeus, "Astronomical Algorithms" (2nd edition):
//  chapter 47 for the lunar series, 22 for nutation and the obliquity of the
//  ecliptic, 12 for sidereal time, 13 for the change of coordinates, 40 for the
//  observer's parallax, 16 for refraction, 48 for the illuminated fraction and
//  49 for the instants of new moon.  The chapter 47 series is a truncation of
//  ELP-2000/82 and carries some 10 arcseconds of error in longitude on its own.
//  That is the floor this code works towards; every other step is kept well
//  under it, so that what comes out is within a few arcseconds of DE421.
//
//  The chapter 47 and 22 tables were converted from the JS code found on
//  https://www.dannybekaert.be/en/moonposition by Marius Șucan.
// ============================================================================

// tabelgegevens van tabel 47A voor lengtegraad van de maan en afstand tot de maan
static const double dTable47a[60] = { 0, 2, 2, 0, 0, 0, 2, 2, 2, 2, 0, 1,
                      0, 2, 0, 0, 4, 0, 4, 2, 2, 1, 1, 2,
                      2, 4, 2, 0, 2, 2, 1, 2, 0, 0, 2, 2,
                      2, 4, 0, 3, 2, 4, 0, 2, 2, 2, 4, 0,
                      4, 1, 2, 0, 1, 3, 4, 2, 0, 1, 2, 2};

static const double mTable47a[60] = { 0, 0, 0, 0, 1, 0, 0, -1, 0, -1, 1, 0,
                      1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, -1,
                      0, 0, 0, 1, 0, -1, 0, -2, 1, 2, -2, 0,
                      0, -1, 0, 0, 1, -1, 2, 2, 1, -1, 0, 0,
                      -1, 0, 1, 0, 1, 0, 0, -1, 2, 1, 0, 0};

static const double maTable47a[60] = { 1, -1, 0, 2, 0, 0, -2, -1, 1, 0, -1, 0,
                       1, 0, 1, 1, -1, 3, -2, -1, 0, -1, 0, 1,
                       2, 0, -3, -2, -1, -2, 1, 0, 2, 0, -1, 1,
                       0, -1, 2, -1, 1, -2, -1, -1, -2, 0, 1, 4,
                       0, -2, 0, 2, 1, -2, -3, 2, 1, -1, 3, -1};

static const double fTable47a[60] = { 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0,
                      0, -2, 2, -2, 0, 0, 0, 0, 0, 0, 0, 0,
                      0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, -2,
                      2, 0, 2, 0, 0, 0, 0, 0, 0, -2, 0, 0,
                      0, 0, -2, -2, 0, 0, 0, 0, 0, 0, 0, -2};

static const double lTable47a[60] = { 6288774, 1274027, 658314, 213618, -185116, -114332, 58793, 57066, 53322, 45758, -40923, -34720,
                         -30383, 15327, -12528, 10980, 10675, 10034, 8548, -7888, -6766, -5163, 4987, 4036,
                         3994, 3861, 3665, -2689, -2602, 2390, -2348, 2236, -2120, -2069, 2048, -1773,
                         -1595, 1215, -1110, -892, -810, 759, -713, -700, 691, 596, 549, 537,
                         520, -487, -399, -381, 351, -340, 330, 327, -323, 299, 294, 0};

static const double rTable47a[60] = { -20905355, -3699111, -2955968, -569925, 48888, -3149, 246158, -152138, -170733, -204586, -129620, 108743,
                         104755, 10321, 0, 79661, -34782, -23210, -21636, 24208, 30824, -8379, -16675, -12831,
                         -10445, -11650, 14403, -7003, 0, 10056, 6322, -9884, 5751, 0, -4950, 4130,
                         0, -3958, 0, 3258, 2616, -1897, -2117, 2354, 0, 0, -1423, -1117,
                         -1571, -1739, 0, -4421, 0, 0, 0, 0, 1165, 0, 0, 8752};

// tabelgegevens van tabel 47B voor de breedtegraad van de maan
static const double dTable47b[60] = { 0, 0, 0, 2, 2, 2, 2, 0, 2, 0, 2, 2,
                      2, 2, 2, 2, 2, 0, 4, 0, 0, 0, 1, 0,
                      0, 0, 1, 0, 4, 4, 0, 4, 2, 2, 2, 2,
                      0, 2, 2, 2, 2, 4, 2, 2, 0, 2, 1, 1,
                      0, 2, 1, 2, 0, 4, 4, 1, 4, 1, 4, 2};

static const double mTable47b[60] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0,
                      0, 1, -1, -1, -1, 1, 0, 1, 0, 1, 0, 1,
                      1, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0,
                      0, 0, 0, 1, 1, 0, -1, -2, 0, 1, 1, 1,
                      1, 1, 0, -1, 1, 0, -1, 0, 0, 0, -1, -2};

static const double maTable47b[60] = { 0, 1, 1, 0, -1, -1, 0, 2, 1, 2, 0, -2,
                       1, 0, -1, 0, -1, -1, -1, 0, 0, -1, 0, 1,
                       1, 0, 0, 3, 0, -1, 1, -2, 0, 2, 1, -2,
                       3, 2, -3, -1, 0, 0, 1, 0, 1, 1, 0, 0,
                       -2, -1, 1, -2, 2, -2, -1, 1, 1, -1, 0, 0};

static const double fTable47b[60] = { 1, 1, -1, -1, 1, -1, 1, 1, -1, -1, -1, -1,
                      1, -1, 1, 1, -1, -1, -1, 1, 3, 1, 1, 1,
                      -1, -1, -1, 1, -1, 1, -3, 1, -3, -1, -1, 1,
                      -1, 1, -1, 1, 1, 1, 1, -1, 3, -1, -1, 1,
                      -1, -1, 1, -1, 1, -1, -1, -1, -1, -1, -1, 1};

static const double bTable47b[60] = { 5128122, 280602, 277693, 173237, 55413, 46271, 32573, 17198, 9266, 8822, 8216, 4324,
                         4200, -3359, 2463, 2211, 2065, -1870, 1828, -1794, -1749, -1565, -1491, -1475,
                         -1410, -1344, -1335, 1107, 1021, 833, 777, 671, 607, 596, 491, -451,
                         439, 422, 421, -366, -351, 331, 315, 302, -283, -229, 223, 223,
                         -220, -220, -185, 181, -177, 176, 166, -164, 132, -119, 115, 107 };

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
void moonNutation(double T, double &dPsi, double &dEpsilon) {
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

// Delta T, the gap between dynamical time and the earth's rotation, in seconds.
//
// The moon travels 0.55 arcseconds of longitude in a second of time, so the
// chapter 47 series - which are written in dynamical time - have to be handed
// TT rather than UT.  Feeding them UT, as this used to, drags the moon 38
// arcseconds behind where it is, nearly four times the error of the series
// themselves.  Observed values are tabulated for the years this program is
// likely to be asked about; beyond either end of the table the polynomial fits
// of calcDeltaT() take over, shifted so the handover is free of a step.
double moonDeltaTseconds(double jdUT) {
     static const int kFirstYear = 1990;
     static const double kObserved[] = {
         56.86, 57.57, 58.31, 59.12, 59.98, 60.78, 61.63, 62.30, 62.97, 63.47,  // 1990-1999
         63.83, 64.09, 64.30, 64.47, 64.57, 64.69, 64.85, 65.15, 65.46, 65.78,  // 2000-2009
         66.07, 66.32, 66.60, 66.91, 67.28, 67.64, 68.10, 68.59, 68.97, 69.22,  // 2010-2019
         69.36, 69.36, 69.29, 69.22, 69.18, 69.19, 69.25                        // 2020-2026
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

     int edgeYear = (year < kFirstYear) ? kFirstYear : kLastYear;
     return kObserved[edgeYear - kFirstYear] + calcDeltaT(year) - calcDeltaT(edgeYear);
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
     s.jdTT = s.jdUT + moonDeltaTseconds(s.jdUT) / 86400.0;

     double T  = (s.jdTT - 2451545.0) / 36525.0;
     double T2 = T*T;
     double T3 = T2*T;
     double T4 = T3*T;

     // Mean elements of the moon and of the sun - Meeus chapter 47.
     double LA = wrapTo360(218.3164477 + 481267.88123421*T - 0.0015786*T2 + T3/538841.0 - T4/65194000.0);   // mean longitude
     double D  = wrapTo360(297.8501921 + 445267.1114034*T  - 0.0018819*T2 + T3/545868.0 - T4/113065000.0);  // mean elongation
     double M  = wrapTo360(357.5291092 +  35999.0502909*T  - 0.0001536*T2 + T3/24490000.0);                 // sun's mean anomaly
     double MA = wrapTo360(134.9633964 + 477198.8675055*T  + 0.0087414*T2 + T3/69699.0  - T4/14712000.0);   // moon's mean anomaly
     double F  = wrapTo360( 93.2720950 + 483202.0175233*T  - 0.0036539*T2 - T3/3526000.0 + T4/863310000.0); // argument of latitude

     double A1 = wrapTo360(119.75 +    131.849*T);
     double A2 = wrapTo360( 53.09 + 479264.290*T);
     double A3 = wrapTo360(313.45 + 481266.484*T);

     // Eccentricity of the earth's orbit round the sun, which damps the terms
     // that carry the sun's anomaly.
     double E  = 1.0 - 0.002516*T - 0.0000074*T2;
     double E2 = E*E;

     double Sl = 0.0, Sr = 0.0, Sb = 0.0;
     for (int i=0; i<60; i++)
     {
        double eTerm = 1.0;
        if (fabs(mTable47a[i])==1.0)
           eTerm = E;
        else if (fabs(mTable47a[i])==2.0)
           eTerm = E2;

        double arg = radians(dTable47a[i]*D + mTable47a[i]*M + maTable47a[i]*MA + fTable47a[i]*F);
        Sl += lTable47a[i] * eTerm * sin(arg);
        Sr += rTable47a[i] * eTerm * cos(arg);

        eTerm = 1.0;
        if (fabs(mTable47b[i])==1.0)
           eTerm = E;
        else if (fabs(mTable47b[i])==2.0)
           eTerm = E2;

        arg = radians(dTable47b[i]*D + mTable47b[i]*M + maTable47b[i]*MA + fTable47b[i]*F);
        Sb += bTable47b[i] * eTerm * sin(arg);
     }

     // Additive terms for Venus, Jupiter and the flattening of the earth.
     Sl += 3958.0*sin(radians(A1)) + 1962.0*sin(radians(LA - F)) + 318.0*sin(radians(A2));
     Sb += -2235.0*sin(radians(LA)) + 382.0*sin(radians(A3))
         +   175.0*sin(radians(A1 - F)) + 175.0*sin(radians(A1 + F))
         +   127.0*sin(radians(LA - MA)) - 115.0*sin(radians(LA + MA));

     double lambda = LA + Sl/1000000.0;      // geometric, mean equinox of the date
     s.beta        = Sb/1000000.0;
     s.distance    = 385000.56 + Sr/1000.0;
     s.parallax    = degrees(asin(6378.14 / s.distance));

     double dPsi, dEpsilon;
     moonNutation(T, dPsi, dEpsilon);

     // Mean obliquity of the ecliptic - Laskar's expansion, Meeus chapter 22.
     double U = T/100.0;
     double epsilonZeroSeconds = 84381.448 + U*(-4680.93 + U*(-1.55 + U*(1999.25 + U*(-51.38
                              + U*(-249.67 + U*(-39.05 + U*(7.12 + U*(27.87 + U*(5.79 + U*2.45)))))))));
     double epsilon = (epsilonZeroSeconds + dEpsilon) / 3600.0;

     // Apparent longitude.  Only nutation is added: the 0.7 arcseconds the moon
     // slips back over the 1.28 seconds its light takes to reach us is already
     // carried by the chapter 47 series.  Subtracting it a second time leaves a
     // measurable 0.8 arcsecond bias against DE421, where leaving it alone
     // leaves none.
     s.lambda = wrapTo360(lambda + dPsi/3600.0);

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

     // The sun, to the hundredth of a degree of Meeus chapter 25 - enough for an
     // elongation whose other half is only good to 10 arcseconds anyway.
     double L0sun = wrapTo360(280.46646 + 36000.76983*T + 0.0003032*T2);
     double Msun  = wrapTo360(357.52911 + 35999.05029*T - 0.0001537*T2);
     double Csun  = (1.914602 - 0.004817*T - 0.000014*T2) * sin(radians(Msun))
                  + (0.019993 - 0.000101*T) * sin(radians(2.0*Msun))
                  +  0.000289 * sin(radians(3.0*Msun));
     double eSun  = 0.016708634 - 0.000042037*T - 0.0000001267*T2;
     double vSun  = Msun + Csun;                     // true anomaly

     s.sunRadius = (1.000001018 * (1.0 - eSun*eSun)) / (1.0 + eSun*cos(radians(vSun)));
     s.sunLambda = wrapTo360(L0sun + Csun - 0.00569 - 0.00478*sin(radians(125.04 - 1934.136*T)));

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
     // happened rather than from a mean one - chapter 49 places those to within
     // a few seconds.  The starting guess is the mean lunation, which is never
     // more than about 0.6 days out, so at most one step is needed either way.
     double k = moonLunationNumber(s.jdTT);
     double prevNew = moonPhaseJDE(k, MOON_NEW);
     while (prevNew > s.jdTT)
     {
        k -= 1.0;
        prevNew = moonPhaseJDE(k, MOON_NEW);
     }
     for (;;)
     {
        double nextNew = moonPhaseJDE(k + 1.0, MOON_NEW);
        if (nextNew > s.jdTT)
           break;
        k += 1.0;
        prevNew = nextNew;
     }
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
     double jdTT = jdUT + moonDeltaTseconds(jdUT) / 86400.0;

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

         *out[which] = (jde - jdTT) * 86400.0;
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
     MoonRise mr;
     mr.calculate(lat, lon, t);
     if (mr.hasRise)
        *riseu = -1*(rt - mr.riseTime)/3600;
     else
        *riseu = 999999;

  // double re = (rt - mr.setTime)/3600;
  // struct tm *ptmu;
  // ptmu = gmtime(&mr.setTime);
  // int hu = ptmu->tm_hour;
  // char* k = ctime(&mr.setTime);
  // string ks = k;
  // fnOutputDebug(std::to_string(re) + "//" + std::to_string(hu) + " timeu: " + ks);

     if (mr.hasSet)
        *setu = -1*(rt - mr.setTime)/3600;
     else
        *setu = 999999;
  }

  return 1;
}

double calcJDEzEquiSols(int k, int year) {
// Equinox & Solstice Calculator
//  The algorithms and correction tables for this computation come directly from the book Astronomical
//  Algorithms Second Edition by Jean Meeus, ©1998, published by Willmann-Bell, Inc., Richmond, VA,
//  ISBN 0-943396-61-1. They were coded in JavaScript and built into the
//  https://stellafane.org/misc/equinox.html web page by its author, Ken Slater.
// JS code converted to C++ by Marius Șucan in 2022

// Function valid for years between 1000 and 3000.
// Calculate an initial guess as the JD of the Equinox or Solstice of a Given Year.
// Meeus Astronomical Algorithms Chapter 27.

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

double COSdeg(double deg) {
   const double PI = 3.14159265358979323846;
   return cos( (deg * PI)/180.0 );
}

double periodic24(double T) {
// Calculate 24 Periodic Terms.
// Meeus Astronomical Algorithms Chapter 27.
   double A[24] = {485, 203, 199, 182, 156, 136, 77, 74, 70, 58, 52, 50, 45, 44, 29, 18, 17, 16, 14, 12, 12, 12, 9, 8};
   double B[24] = {324.96,337.23,342.08,27.85,73.14,171.52,222.54,296.72,243.58,119.81,297.17,21.02,247.54,325.15,60.93,155.12,288.79,198.04,199.76,95.39,287.11,320.81,227.73,15.45};
   double C[24] = {1934.136,32964.467,20.186,445267.112,45036.886,22518.443, 65928.934,3034.906,9037.513,33718.147,150.678,2281.226,
                   29929.562,31555.956,4443.417,67555.328,4562.452,62894.029,31436.921,14577.848,31931.756,34777.259,1222.114,16859.074};
   double S = 0.0;
   for (int i=0; i<24; i++ )
   {
       S += A[i] * COSdeg( B[i] + (C[i]*T) );
   };

   return S;
}

void fromJDtoUTC( double JD, int* monu, int* dayu, int* hour, int* minu ) {
// Julian Date to UTC date
// Meeus Astronomical Algorithms Chapter 7
    double Z = floor(JD + 0.5);    // Integer JD's
    double F = (JD + 0.5) - Z;     // Fractional JD's
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
    double DT = B - D - floor(30.6001 * E) + F;   // Day of Month with decimals for time

    double G = (E < 13.5) ? 1.0 : 13.0;
    double Month = E - G;
    *monu = Month;
    G = (Month > 2.5) ? 4716.0 : 4715.0;
    // double Yr = C - G;
    int dayum = floor(DT);
    *dayu = dayum;
    double H = 24 * (DT - dayum);
    int Hr = floor(H);
    *hour = Hr;
    double M = 60 * (H - Hr);
    *minu = floor(M);
    // Sec = floor( 60 * (M - Min) );

    // theDate := Yr "-" Mon "-" Day "-" Hr "-" Min "-" Sec
    // theDate := Yr Format("{:02}", Mon) Format("{:02}", Day) Format("{:02}", Hr) Format("{:02}", Min) Format("{:02}", Sec)
    // return theDate
}


DLL_API int DLL_CALLCONV calculateEquiSols(int k, int year, int* mm, int* d, int* hh, int* m) {
// source https://stellafane.org/misc/equinox.html web page by its author, Ken Slater.
// JS code converted to C++ by Marius Șucan in 2022
// Calculate and Display a single event for a single year (an equinox or solstice)
// Meeus Astronomical Algorithms Chapter 27
// 4 events for param i: 0=AE, 1=SS, 2-VE, 3=WS

   double JDEzero = calcJDEzEquiSols(k, year);           // Initial estimate of date of event
   double T = (JDEzero - 2451545.0) / 36525.0;
   double W = (35999.373 * T) -2.47;
   double dL = 1 + 0.0334 * COSdeg(W) + 0.0007 * COSdeg(2*W);
   double S = periodic24(T);
   // fnOutputDebug("S=" S)
   double JDE = JDEzero + ( (0.00001*S) / dL );             // This is the answer in Julian Emphemeris Days
   int month, day, hour, mins;
   fromJDtoUTC(JDE, &month, &day, &hour, &mins);    // Convert Julian Days to TDT in a Date Object
   *mm = month;   *d = day;
   *hh = hour;    *m = mins;

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


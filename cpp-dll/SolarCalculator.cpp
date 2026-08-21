//======================================================================================================================
// SolarCalculator Library for Arduino
//
// This library provides functions to calculate the times of sunrise, sunset, solar noon, twilight (dawn and dusk),
// Sun's apparent position in the sky, equation of time, etc.
//
// Most formulae are taken from Astronomical Algorithms by Jean Meeus and optimized for 8-bit AVR platform.
// source https://github.com/jpb10/SolarCalculator
//======================================================================================================================

// #ifndef ARDUINO
#include <cmath>
// #endif

#include "SolarCalculator.h"

//namespace solarcalculator {

JulianDay::JulianDay(unsigned long utc)
{
    JD = static_cast<unsigned long>(utc / 86400) + 2440587.5;
    m = (utc % 86400) / 86400.0;
}

JulianDay::JulianDay(int year, int month, int day, int hour, int minute, int second)
{
    JD = calcJulianDay(year, month, day);
    m = fractionalDay(hour, minute, second);
}

//======================================================================================================================
// Intermediate calculations
//
// Time T is measured in Julian centuries (36525 ephemeris days from the epoch J2000.0)
//======================================================================================================================

#ifndef ARDUINO
double radians(double deg)
{
    return deg * M_PI / 180;
}

double degrees(double rad)
{
    return rad * 180 / M_PI;
}
#endif

double wrapTo360(double angle)
{
    angle = fmod(angle, 360);
    if (angle < 0) angle += 360;
    return angle;  // [0, 360)
}

double wrapTo180(double angle)
{
    angle = wrapTo360(angle + 180);
    return angle - 180;  // [-180, 180)
}

// Interpolation of three tabular values, valid for n between -1 and +1
double interpolateCoordinates(double n, double y1, double y2, double y3)
{
    if (fabs(y2 - y1) > 180)  // if coordinate is discontinuous
    {                         // add or subtract 360 degrees
        if (y1 < 0) y1 += 360;
        else if (y2 < 0) y1 -= 360;
    }
    else if (fabs(y3 - y2) > 180)
    {
        if (y3 < 0) y3 += 360;
        else if (y2 < 0) y3 -= 360;
    }

    double a = y2 - y1;
    double b = y3 - y2;
    double c = b - a;
    return y2 + n * (a + b + n * c) / 2;
}

double fractionalDay(int hour, int minute, int second)
{
    return (hour + minute / 60.0 + second / 3600.0) / 24;
}

// Gregorian calendar date to the Julian day at 0h UT.  Meeus, Astronomical Algorithms,
// chapter 7, valid for any date of the Gregorian calendar (proleptic before 1582).
// It replaces the Van Flandern & Pulkkinen form, which only knew the Julian four year
// leap rule and so drifted a whole day outside 1900-03-01 .. 2100-02-28: every date
// from 2100-03-01 on came out one day late, and 1899 one day early.
double calcJulianDay(int year, int month, int day)
{
    if (month <= 2)  // January and February count as months 13 and 14 of the year before
    {
        year -= 1;
        month += 12;
    }
    int a = year / 100;
    int b = 2 - a + a / 4;  // the Gregorian century correction the old formula lacked

    return static_cast<int>(365.25 * (year + 4716)) + static_cast<int>(30.6001 * (month + 1)) +
           day + b - 1524.5;
}

double calcJulianCent(JulianDay jd)
{
    return (jd.JD - 2451545 + jd.m) / 36525;
}

double calcGeomMeanLongSun(double T)
{
    return wrapTo360(280.46646 + T * 36000.76983);  // in degrees
}

double calcGeomMeanAnomalySun(double T)
{
    return wrapTo360(357.52911 + T * 35999.05029);  // in degrees
}

double calcSunEqOfCenter(double T)
{
    double M = calcGeomMeanAnomalySun(T);
    return sin(radians(M)) * 1.914602 + sin(2 * radians(M)) * 0.019993;  // in degrees
}

double calcSunRadVector(double T)
{
    double M = calcGeomMeanAnomalySun(T);
    return 1.00014 - 0.01671 * cos(radians(M)) - 0.00014 * cos(2 * radians(M));  // in AUs
}

double calcMeanObliquityOfEcliptic(double T)
{
    return 23.4392911 - T * 0.0130042;  // in degrees
}

// Mean geocentric equatorial coordinates, accurate to ~0.01 degree
void calcSolarCoordinates(double T, double &ra, double &dec)
{
    double L0 = calcGeomMeanLongSun(T);
    double C = calcSunEqOfCenter(T);
    double L = L0 + C - 0.00569;  // corrected for aberration

    double eps = calcMeanObliquityOfEcliptic(T);
    ra = degrees(atan2(cos(radians(eps)) * sin(radians(L)), cos(radians(L))));  // [-180, 180)
    dec = degrees(asin(sin(radians(eps)) * sin(radians(L))));
}

double calcGrMeanSiderealTime(JulianDay jd)
{
    double GMST = wrapTo360(100.46061837 + 0.98564736629 * (jd.JD - 2451545));
    return wrapTo360(GMST + 360.985647 * jd.m);  // in degrees
}

void equatorial2horizontal(double H, double dec, double lat, double &az, double &el)
{
    az = degrees(atan2(sin(radians(H)), cos(radians(H)) * sin(radians(lat)) -
                 tan(radians(dec)) * cos(radians(lat))));
    el = degrees(asin(sin(radians(lat)) * sin(radians(dec)) +
                 cos(radians(lat)) * cos(radians(dec)) * cos(radians(H))));
}

// Approximate atmospheric refraction correction, in degrees
double calcRefraction(double elev)
{
    if (elev < -0.575)
        return -20.774 / tan(radians(elev)) / 3600;  // Zimmerman (1981)
    else
        return 1.02 / tan(radians(elev + 10.3 / (elev + 5.11))) / 60;  // Sæmundsson (1986)
}

// Equation of ephemeris time by Smart (1978)
double equationOfTimeSmart(double T)
{
    double L0 = calcGeomMeanLongSun(T);
    double M = calcGeomMeanAnomalySun(T);

    // Using numerical values for the eccentricity and obliquity in 2025
    return 2.465 * sin(2 * radians(L0)) - 1.913 * sin(radians(M)) +
           0.165 * sin(radians(M)) * cos(2 * radians(L0)) -
           0.053 * sin(4 * radians(L0)) - 0.02 * sin(2 * radians(M));  // in degrees
}

// Delta T, the gap between dynamical time and the earth's rotation, in seconds.
//
// The polynomials for the years up to 1997 are the ones Fred Espenak and Jean
// Meeus fitted to the historical record for the NASA eclipse pages, each piece
// good to about a second over the span it covers.  They replace a single
// parabola that was ten seconds out by 1900 and worse before it.
//
// deltaTseconds() in cbt-main.cpp is what the moon and the sun actually go
// through: it tabulates observed values from 1990 onwards and only leans on this
// for the years before them, so the branch past 1997 is the least of it.
double calcDeltaT(double year)
{
    double t;
    if (year > 1997)
    {
        t = year - 2015;
        return 67.62 + t * (0.3645 + 0.0039755 * t);  // Fred Espenak (2014)
    }

    if (year >= 1986)
    {
        t = year - 2000;
        return 63.86 + t*(0.3345 + t*(-0.060374 + t*(0.0017275 + t*(0.000651814 + t*0.00002373599))));
    }

    if (year >= 1961)
    {
        t = year - 1975;
        return 45.45 + t*(1.067 + t*(-1.0/260.0 - t/718.0));
    }

    if (year >= 1941)
    {
        t = year - 1950;
        return 29.07 + t*(0.407 + t*(-1.0/233.0 + t/2547.0));
    }

    if (year >= 1920)
    {
        t = year - 1920;
        return 21.20 + t*(0.84493 + t*(-0.076100 + t*0.0020936));
    }

    if (year >= 1900)
    {
        t = year - 1900;
        return -2.79 + t*(1.494119 + t*(-0.0598939 + t*(0.0061966 - t*0.000197)));
    }

    if (year >= 1860)
    {
        t = year - 1860;
        return 7.62 + t*(0.5737 + t*(-0.251754 + t*(0.01680668 + t*(-0.0004473624 + t/233174.0))));
    }

    if (year >= 1800)
    {
        t = year - 1800;
        return 13.72 + t*(-0.332447 + t*(0.0068612 + t*(0.0041116 + t*(-0.00037436
             + t*(0.0000121272 + t*(-0.0000001699 + t*0.000000000875))))));
    }

    if (year >= 1700)
    {
        t = year - 1700;
        return 8.83 + t*(0.1603 + t*(-0.0059285 + t*(0.00013336 - t/1174000.0)));
    }

    if (year >= 1600)
    {
        t = year - 1600;
        return 120.0 + t*(-0.9808 + t*(-0.01532 + t/7129.0));
    }

    // Before 1600 the record thins out and this is only the shape of it.
    double u = (year - 1820) / 100.0;
    return -20.0 + 32.0*u*u;
}

//======================================================================================================================
// Solar calculator
//
// All calculations assume time inputs in Coordinated Universal Time (UTC)
//======================================================================================================================

// Equation of time, in minutes of time
void calcEquationOfTime(JulianDay jd, double &E)
{
    double T = calcJulianCent(jd);
    E = 4 * equationOfTimeSmart(T);
}

// Sun's geocentric (as seen from the center of the Earth) equatorial coordinates, in degrees and AUs
void calcEquatorialCoordinates(JulianDay jd, double &rt_ascension, double &declination, double &radius_vector)
{
    double T = calcJulianCent(jd);
    calcSolarCoordinates(T, rt_ascension, declination);

    rt_ascension = wrapTo360(rt_ascension);
    radius_vector = calcSunRadVector(T);
}

// Sun's topocentric (as seen from the observer's place on the Earth's surface) horizontal coordinates, in degrees
void calcHorizontalCoordinates(JulianDay jd, double latitude, double longitude, double &azimuth, double &elevation)
{
    double T = calcJulianCent(jd);
    double GMST = calcGrMeanSiderealTime(jd);

    double ra, dec;
    calcSolarCoordinates(T, ra, dec);

    double H = GMST + longitude - ra;
    equatorial2horizontal(H, dec, latitude, azimuth, elevation);

    azimuth += 180;  // measured from the North
    //  elevation -= 8.794 * cos(radians(elevation)) / 3600;  // parallax in altitude, always < 0.0025 degrees
    elevation += calcRefraction(elevation);
}

// Helper function
void calcRiseSetTimes(double (&m)[3], JulianDay jd, double latitude, double longitude, double h0)
{
    double T = calcJulianCent(jd);
    double GMST = calcGrMeanSiderealTime(jd);

    double ra, dec;
    calcSolarCoordinates(T, ra, dec);

    // Local hour angle at sunrise or sunset (±NaN if body is circumpolar)
    double H0 = degrees(acos((sin(radians(h0)) - sin(radians(latitude)) * sin(radians(dec))) /
                        (cos(radians(latitude)) * cos(radians(dec)))));

    m[0] = jd.m + wrapTo180(ra - longitude - GMST) / 360;
    m[1] = m[0] - H0 / 360;
    m[2] = m[0] + H0 / 360;
}

// Find the times of sunrise, transit, and sunset, in hours
void calcSunriseSunset(JulianDay jd, double latitude, double longitude,
                       double &transit, double &sunrise, double &sunset, double altitude, int iterations)
{
    double m[3], times[3];
    m[0] = 0.5 - longitude / 360;

    for (int i = 0; i <= iterations; i++)
    {
        for (int event = 0; event < 3; event++)
        {
            jd.m = m[event];
            calcRiseSetTimes(times, jd, latitude, longitude, altitude);
            m[event] = times[event];

            // First iteration, approximate rise and set times
            if (i == 0)
            {
                m[1] = times[1]; m[2] = times[2];
                break;
            }
        }
    }

    transit = m[0] * 24;
    sunrise = m[1] * 24;
    sunset = m[2] * 24;
}

//======================================================================================================================
// Wrapper functions
//
// All calculations assume time inputs in Coordinated Universal Time (UTC)
//======================================================================================================================

void calcEquationOfTime(unsigned long utc, double &E)
{
    JulianDay jd(utc);
    calcEquationOfTime(jd, E);
}

void calcEquationOfTime(int year, int month, int day, int hour, int minute, int second, double &E)
{
    JulianDay jd(year, month, day, hour, minute, second);
    calcEquationOfTime(jd, E);
}

void calcEquatorialCoordinates(unsigned long utc, double &rt_ascension, double &declination, double &radius_vector)
{
    JulianDay jd(utc);
    calcEquatorialCoordinates(jd, rt_ascension, declination, radius_vector);
}

void calcEquatorialCoordinates(int year, int month, int day, int hour, int minute, int second,
                               double &rt_ascension, double &declination, double &radius_vector)
{
    JulianDay jd(year, month, day, hour, minute, second);
    calcEquatorialCoordinates(jd, rt_ascension, declination, radius_vector);
}

void calcHorizontalCoordinates(unsigned long utc, double latitude, double longitude,
                               double &azimuth, double &elevation)
{
    JulianDay jd(utc);
    calcHorizontalCoordinates(jd, latitude, longitude, azimuth, elevation);
}

void calcHorizontalCoordinates(int year, int month, int day, int hour, int minute, int second,
                               double latitude, double longitude, double &azimuth, double &elevation)
{
    JulianDay jd(year, month, day, hour, minute, second);
    calcHorizontalCoordinates(jd, latitude, longitude, azimuth, elevation);
}

void calcSunriseSunset(unsigned long utc, double latitude, double longitude,
                       double &transit, double &sunrise, double &sunset, double altitude, int iterations)
{
    JulianDay jd(utc);
    calcSunriseSunset(jd, latitude, longitude, transit, sunrise, sunset, altitude, iterations);
}

void calcSunriseSunset(int year, int month, int day, double latitude, double longitude,
                       double &transit, double &sunrise, double &sunset, double altitude, int iterations)
{
    JulianDay jd(year, month, day);
    calcSunriseSunset(jd, latitude, longitude, transit, sunrise, sunset, altitude, iterations);
}

void calcCivilDawnDusk(unsigned long utc, double latitude, double longitude,
                       double &transit, double &dawn, double &dusk)
{
    calcSunriseSunset(utc, latitude, longitude, transit, dawn, dusk, CIVIL_DAWNDUSK_STD_ALTITUDE);
}

void calcCivilDawnDusk(int year, int month, int day, double latitude, double longitude,
                       double &transit, double &dawn, double &dusk)
{
    calcSunriseSunset(year, month, day, latitude, longitude, transit, dawn, dusk, CIVIL_DAWNDUSK_STD_ALTITUDE);
}

void calcNauticalDawnDusk(unsigned long utc, double latitude, double longitude,
                          double &transit, double &dawn, double &dusk)
{
    calcSunriseSunset(utc, latitude, longitude, transit, dawn, dusk, NAUTICAL_DAWNDUSK_STD_ALTITUDE);
}

void calcNauticalDawnDusk(int year, int month, int day, double latitude, double longitude,
                          double &transit, double &dawn, double &dusk)
{
    calcSunriseSunset(year, month, day, latitude, longitude, transit, dawn, dusk, NAUTICAL_DAWNDUSK_STD_ALTITUDE);
}

void calcAstronomicalDawnDusk(unsigned long utc, double latitude, double longitude,
                              double &transit, double &dawn, double &dusk)
{
    calcSunriseSunset(utc, latitude, longitude, transit, dawn, dusk, ASTRONOMICAL_DAWNDUSK_STD_ALTITUDE);
}

void calcAstronomicalDawnDusk(int year, int month, int day, double latitude, double longitude,
                              double &transit, double &dawn, double &dusk)
{
    calcSunriseSunset(year, month, day, latitude, longitude, transit, dawn, dusk, ASTRONOMICAL_DAWNDUSK_STD_ALTITUDE);
}

//}  // namespace


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


DLL_API int DLL_CALLCONV oldgetMoonPhase(double timeus, int timeGiven, double* p, int* IDp, double* a, double* f, double* latu, double* lon, int* z) {
  // Default to the current time.
  time_t t = time(NULL);

  // Look for an argument.
  if (timeGiven==1)
     t = timeus;
     // t = atol(timeus);

  // Calculate the moon phase and related information.
  MoonPhase m;
  m.calculate(t);

  *p = m.phase;
  *IDp = m.phaseID;
  *a = m.age;
  *f = m.fraction;
  *latu = m.latitude;
  *lon = m.longitude;
  *z = m.zodiacID;
/*
  string pn = m.zodiacName;
  fnOutputDebug("moon phase=" + std::to_string(m.longitude) + pn + std::to_string(m.zodiacID));
  char* k = ctime(&t);
  string ks = k;
  string pn = m.phaseName;
  fnOutputDebug("Time: " + ks);
  fnOutputDebug("Julian Day: " + std::to_string(m.jDate));
  fnOutputDebug("Phase: " + std::to_string(m.phase));
  fnOutputDebug("Fraction: " + std::to_string(m.fraction));
  fnOutputDebug("Phase name: " + pn);
*/
  return 1;
}


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

double atan2d(double y, double x) {
   int p = (x<0) ? 1 : 0;
   return 180.0 / M_PI * atan(y/x) - 180.0*p;
}

void moonCalcPosition(double timeUTC, double obslatitude, double obslongitude, double* results, int onlyElevation=0) {
// based on the JS code found on https://www.dannybekaert.be/en/moonposition
// converted to C++ by Marius Șucan
    const double PIdiv180 = M_PI/180;
    const double c180divPI = 180.0 / M_PI;

    // tabelgegevens van tabel 47A voor lengtegraad van de maan en afstand tot de maan
    const double dTable47a[60] = { 0, 2, 2, 0, 0, 0, 2, 2, 2, 2, 0, 1,
                          0, 2, 0, 0, 4, 0, 4, 2, 2, 1, 1, 2,
                          2, 4, 2, 0, 2, 2, 1, 2, 0, 0, 2, 2,
                          2, 4, 0, 3, 2, 4, 0, 2, 2, 2, 4, 0,
                          4, 1, 2, 0, 1, 3, 4, 2, 0, 1, 2, 2};

    const double mTable47a[60] = { 0, 0, 0, 0, 1, 0, 0, -1, 0, -1, 1, 0,
                          1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, -1,
                          0, 0, 0, 1, 0, -1, 0, -2, 1, 2, -2, 0,
                          0, -1, 0, 0, 1, -1, 2, 2, 1, -1, 0, 0,
                          -1, 0, 1, 0, 1, 0, 0, -1, 2, 1, 0, 0};
                  
    const double maTable47a[60] = { 1, -1, 0, 2, 0, 0, -2, -1, 1, 0, -1, 0,
                           1, 0, 1, 1, -1, 3, -2, -1, 0, -1, 0, 1,
                           2, 0, -3, -2, -1, -2, 1, 0, 2, 0, -1, 1,
                           0, -1, 2, -1, 1, -2, -1, -1, -2, 0, 1, 4,
                           0, -2, 0, 2, 1, -2, -3, 2, 1, -1, 3, -1};
                   
    const double fTable47a[60] = { 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0,
                          0, -2, 2, -2, 0, 0, 0, 0, 0, 0, 0, 0,
                          0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, -2,
                          2, 0, 2, 0, 0, 0, 0, 0, 0, -2, 0, 0, 
                          0, 0, -2, -2, 0, 0, 0, 0, 0, 0, 0, -2};
                          
    const double lTable47a[60] = { 6288774, 1274027, 658314, 213618, -185116, -114332, 58793, 57066, 53322, 45758, -40923, -34720,
                             -30383, 15327, -12528, 10980, 10675, 10034, 8548, -7888, -6766, -5163, 4987, 4036,
                             3994, 3861, 3665, -2689, -2602, 2390, -2348, 2236, -2120, -2069, 2048, -1773,
                             -1595, 1215, -1110, -892, -810, 759, -713, -700, 691, 596, 549, 537,
                             520, -487, -399, -381, 351, -340, 330, 327, -323, 299, 294, 0};
                             
    const double rTable47a[60] = { -20905355, -3699111, -2955968, -569925, 48888, -3149, 246158, -152138, -170733, -204586, -129620, 108743,
                             104755, 10321, 0, 79661, -34782, -23210, -21636, 24208, 30824, -8379, -16675, -12831,
                             -10445, -11650, 14403, -7003, 0, 10056, 6322, -9884, 5751, 0, -4950, 4130,
                             0, -3958, 0, 3258, 2616, -1897, -2117, 2354, 0, 0, -1423, -1117,
                             -1571, -1739, 0, -4421, 0, 0, 0, 0, 1165, 0, 0, 8752};

    // tabelgegevens van tabel 47B voor de breedtegraad van de maan  
    const double dTable47b[60] = { 0, 0, 0, 2, 2, 2, 2, 0, 2, 0, 2, 2, 
                          2, 2, 2, 2, 2, 0, 4, 0, 0, 0, 1, 0,
                          0, 0, 1, 0, 4, 4, 0, 4, 2, 2, 2, 2,
                          0, 2, 2, 2, 2, 4, 2, 2, 0, 2, 1, 1,
                          0, 2, 1, 2, 0, 4, 4, 1, 4, 1, 4, 2};
                           
    const double mTable47b[60] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0,
                          0, 1, -1, -1, -1, 1, 0, 1, 0, 1, 0, 1,
                          1, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0,
                          0, 0, 0, 1, 1, 0, -1, -2, 0, 1, 1, 1,
                          1, 1, 0, -1, 1, 0, -1, 0, 0, 0, -1, -2};
                   
    const double maTable47b[60] = { 0, 1, 1, 0, -1, -1, 0, 2, 1, 2, 0, -2,
                           1, 0, -1, 0, -1, -1, -1, 0, 0, -1, 0, 1,
                           1, 0, 0, 3, 0, -1, 1, -2, 0, 2, 1, -2, 
                           3, 2, -3, -1, 0, 0, 1, 0, 1, 1, 0, 0,
                           -2, -1, 1, -2, 2, -2, -1, 1, 1, -1, 0, 0};
                      
    const double fTable47b[60] = { 1, 1, -1, -1, 1, -1, 1, 1, -1, -1, -1, -1,
                          1, -1, 1, 1, -1, -1, -1, 1, 3, 1, 1, 1,
                          -1, -1, -1, 1, -1, 1, -3, 1, -3, -1, -1, 1,
                          -1, 1, -1, 1, 1, 1, 1, -1, 3, -1, -1, 1,
                          -1, -1, 1, -1, 1, -1, -1, -1, -1, -1, -1, 1};
                   
    const double bTable47b[60] = { 5128122, 280602, 277693, 173237, 55413, 46271, 32573, 17198, 9266, 8822, 8216, 4324,
                             4200, -3359, 2463, 2211, 2065, -1870, 1828, -1794, -1749, -1565, -1491, -1475,
                             -1410, -1344, -1335, 1107, 1021, 833, 777, 671, 607, 596, 491, -451,
                             439, 422, 421, -366, -351, 331, 315, 302, -283, -229, 223, 223,
                             -220, -220, -185, 181, -177, 176, 166, -164, 132, -119, 115, 107 };

    // tabelgegevens van tabel 22A voor nutatie en obliquity
    const double dTable22a[63] = { 0, -2, 0, 0, 0, 0, -2, 0, 0,
                          -2, -2, -2, 0, 2, 0, 2, 0, 0,
                          -2, 0, 2, 0, 0, -2, 0, -2, 0,
                          0, 2, -2, 0, -2, 0, 0, 2, 2,
                          0, -2, 0, 2, 2, -2, -2, 2, 2, 
                          0, -2, -2, 0, -2, -2, 0, -1, -2,
                          1, 0, 0, -1, 0, 0, 2, 0, 2};
                      
    const double mTable22a[63] = { 0, 0, 0, 0, 1, 0, 1, 0, 0,
                          -1, 0, 0, 0, 0, 0, 0, 0, 0,
                          0, 0, 0, 0, 0, 0, 0, 0, 0,
                          2, 0, 2, 1, 0, -1, 0, 0, 0,
                          1, 1, -1, 0, 0, 0, 0, 0, 0,
                          -1, -1, 0, 0, 0, 1, 0, 0, 1,
                          0, 0, 0, -1, 1, -1, -1, 0, -1};
                        
    const double maTable22a[63] = { 0, 0, 0, 0, 0, 1, 0, 0, 1,
                           0, 1, 0, -1, 0, 1, -1, -1, 1,
                           2, -2, 0, 2, 2, 1, 0, 0, -1,
                           0, -1, 0, 0, 1, 0, 2, -1, 1,
                           0, 1, 0, 0, 1, 2, 1, -2, 0,
                           1, 0, 0, 2, 2, 0, 1, 1, 0,
                           0, 1, -2, 1, 1, 1, -1, 3, 0};
                              
    const double fTable22a[63] = { 0, 2, 2, 0, 0, 0, 2, 2, 2,
                          2, 0, 2, 2, 0, 0, 2, 0, 2,
                          0, 2, 2, 2, 0, 2, 2, 2, 2,
                          0, 0, 2, 0, 0, 0, -2, 2, 2,
                          2, 0, 2, 2, 0, 2, 2, 0, 0,
                          0, 2, 0, 2, 0, 2, -2, 0, 0,
                          0, 2, 2, 0, 0, 2, 2, 2, 2};
                          
    const double oTable22a[63] = { 1, 2, 2, 2, 0, 0, 2, 1, 2,
                            2, 0, 1, 2, 0, 1, 2, 1, 1,
                            0, 1, 2, 2, 0, 2, 0, 0, 1,
                            0, 1, 2, 1, 1, 1, 0, 1, 2,
                            2, 0, 2, 1, 0, 2, 1, 1, 1,
                            0, 1, 1, 1, 1, 1, 0, 0, 0,
                            0, 0, 2, 0, 0, 2, 2, 2, 2};

    double JDE = ((timeUTC - 86400) / 86400.0L + 2440588.5L);  // julian date

    // juliaanse eeuw en zijn machtsverheffingen
    double T = (JDE - 2451545.0L) / 36525.0L;
    double T2 = pow(T, 2);
    double T3 = pow(T, 3);
    double T4 = pow(T, 4);

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

     // gemiddelde sterrentijd te Greenwich - hoofdstuk 12 - formule 12.4
     double tetaNul = 280.46061837 + 360.98564736629 * (JDE - 2451545.0) + 0.000387933*T2 - T3/38710000.0;
     if (tetaNul>0)
        tetaNul -= floor(tetaNul/360.0)*360.0;
     else
        tetaNul += (1.0 + floor(abs(tetaNul)/360.0))*360.0;

     double tetaNulHour = floor(tetaNul/15.0);
     double tetaNulMinute = floor((tetaNul/15.0 - tetaNulHour)*60.0);
     double tetaNulSecond = (tetaNul/15.0 - tetaNulHour - tetaNulMinute/60.0)*3600.0;
     double tetaNulTotalSeconds = tetaNulHour*3600.0 + tetaNulMinute*60.0 + tetaNulSecond;
  
     // gemiddelde lengtegraad van de maan
     double LA = 218.3164477 + 481267.88123421*T - 0.0015786*T2 + T3/538841.0 - T4/65194000.0;
     LA -= floor(LA/360.0)*360.0;

     // gemiddelde verlenging van de maan
     double D = 297.8501921 + 445267.1114034*T - 0.0018819*T2 + T3/545868.0 - T4/113065000.0;
     D -= floor(D/360.0)*360.0;

     // gemiddelde anomalie van de zon
     double M = 357.5291092 + 35999.0502909*T - 0.0001536*T2 + T3/24490000.0;
     M -= floor(M/360.0)*360.0;

     // gemiddelde anomalie van de maan
     double MA = 134.9633964 + 477198.8675055*T + 0.0087414*T2 + T3/69699.0 - T4/14712000.0;
     MA -= floor(MA/360.0)*360.0;

     // breedtegraad argument van de maan
     double F = 93.2720950 + 483202.0175233*T - 0.0036539*T2 - T3/3526000.0 + T4/863310000.0;
     F -= floor(F/360.0)*360.0;

     // nog drie bijkomende argumenten
     double A1 = 119.75 + 131.849*T;
     A1 -= floor(A1/360.0)*360.0;
     double A2 = 53.09 + 479264.290*T;
     A2 -= floor(A2/360.0)*360.0;
     double A3 = 313.45+481266.484*T;
     A3 -= floor(A3/360.0)*360.0;

     // eccentriciteit van de baan van de aarde rond de zon
     double E = 1.0 - 0.002516*T - 0.0000074*T2;

     // bepaling van de periodieke termen
     double Sl = 0.0;
     double Sr = 0.0;

     double eTerm = 1.0;
     for (int i=0; i<60; i++)
     {
        if (abs(mTable47a[i])==1)
           eTerm = E; 
        else if (abs(mTable47a[i])==2)
           eTerm = pow(E, 2);
        else
           eTerm = 1.0;

        double pp = (dTable47a[i]*D + mTable47a[i]*M + maTable47a[i]*MA + fTable47a[i]*F)*M_PI / 180.0;
        Sl += lTable47a[i] * eTerm * sin(pp);
        Sr += rTable47a[i] * eTerm * cos(pp);
     }

     eTerm = 1.0;
     double Sb = 0.0;
     for (int i=0; i<60; i++)
     {
        if (abs(mTable47b[i])==1)
           eTerm = E; 
        else if (abs(mTable47b[i])==2)
           eTerm = pow(E, 2);
        else
           eTerm = 1.0;

        Sb += bTable47b[i] * eTerm * sin((dTable47b[i]*D + mTable47b[i]*M + maTable47b[i]*MA + fTable47b[i]*F) * PIdiv180);
     }

     // additionele termen voor sigma l en sigma b
     double addSigmal = 3958.0*sin(A1 * PIdiv180) + 1962.0*sin((LA - F) * PIdiv180) + 318.0*sin(A2 * PIdiv180);
     double addSigmab = -2235.0*sin(LA * PIdiv180) + 382.0*sin(A3 * PIdiv180) + 175.0*sin((A1 - F) * PIdiv180) + 175.0*sin((A1 + F) * PIdiv180) + 127.0*sin((LA - MA) * PIdiv180) - 115.0*sin((LA + MA) * PIdiv180);
     Sl += addSigmal;
     Sb += addSigmab;

     // maan coordinaten
     // lengtegraad van de maan [ right ascension ]
     double lambda = LA + (Sl/1000000.0);

     // breedtegraad van de maan
     double beta = Sb/1000000.0;
     if (beta>180.0)
        beta -= 360.0;

     // afstand tot de maan
     double distance = 385000.56 + (Sr/1000.0);

     // equatoriale horizontale parallax van de maan
     double pi = asin(6378.14/distance) * c180divPI;
     // tabelgegevens van tabel 22A voor nutatie en obliquity

     // HS22 gemiddelde verlenging voor de maan vanaf de zon 
     double D_CH22 = 297.85036 + 445267.111480*T - 0.0019142*T2 + T3/189474.0;
     D_CH22 -= floor(D_CH22/360.0)*360.0;
     
     // HS22 gemiddelde anomalie van de zon (aarde)
     double M_CH22 = 357.52772 + 35999.050340*T - 0.0001603*T2 - T3/300000.0;
     M_CH22 -= floor(M_CH22/360.0)*360.0;

     // HS22 gemiddelde anomalie van de maan
     double MA_CH22 = 134.96298 + 477198.867398*T + 0.0086972*T2 + T3/56250.0;
     MA_CH22 -= floor(MA_CH22/360.0)*360.0;

     // HS22 breedtegraad argument van de maan
     double F_CH22 = 93.27191 + 483202.017538*T - 0.0036825*T2 + T3/327270.0;
     F_CH22 -= floor(F_CH22/360.0)*360.0;

     // lengtegraad van de stijgende knoop van de gemiddelde maanbaan op het ecliptisch vlak gemeten vanaf de gemiddelde equinox van de datum
     double omega = 125.04452 - 1934.136261*T + 0.0020708*T2 + T3/450000.0;
     omega -= floor(omega/360.0)*360.0;

     double dFi = 0.0;
     for (int i=0; i<63; i++) {
         dFi += fiTable22a[i] * sin((dTable22a[i]*D_CH22 + mTable22a[i]*M_CH22 + maTable22a[i]*MA_CH22 + fTable22a[i]*F_CH22 + oTable22a[i]*omega)*PIdiv180);
     }

     double dEpsilon = 0.0;
     for (int i=0; i<63; i++) {
         dEpsilon += epsilonTable22a[i] * cos((dTable22a[i]*D_CH22 + mTable22a[i]*M_CH22 + maTable22a[i]*MA_CH22 + fTable22a[i]*F_CH22 + oTable22a[i]*omega)*PIdiv180);
     } 

     dFi /= 10000.0;
     dEpsilon /= 10000.0;

     // gecorrigeerde lambda       
     lambda += dFi/3600.0;
     lambda -= floor(lambda/360.0)*360.0;

     // bepalen van epsilonzero
     double U_CH22 = (double)T/100.0;
     double U2_CH22 = U_CH22 * U_CH22;
     double U3_CH22 = U2_CH22 * U_CH22;
     double U4_CH22 = U3_CH22 * U_CH22;
     double U5_CH22 = U4_CH22 * U_CH22;
     double U6_CH22 = U5_CH22 * U_CH22;
     double U7_CH22 = U6_CH22 * U_CH22;
     double U8_CH22 = U7_CH22 * U_CH22;
     double U9_CH22 = U8_CH22 * U_CH22;
     double U10_CH22 = U9_CH22 * U_CH22;

     double epsilonZeroSeconds = 84381.448 - 4680.93*U_CH22 - 1.55*U2_CH22 + 1999.25*U3_CH22 - 51.38*U4_CH22 - 249.67*U5_CH22 - 39.05*U6_CH22 + 7.12*U7_CH22 + 27.87*U8_CH22 + 5.79*U9_CH22 + 2.45*U10_CH22;
     double epsilonSeconds = epsilonZeroSeconds + dEpsilon;
     double epsilonDegrees = epsilonSeconds/3600.0;

     // bepalen van de apparente sterrentijd te Greenwich
     double appTetaNulTotalSeconds = tetaNulTotalSeconds + (dFi/15.0) * cos(epsilonDegrees*PIdiv180);

     // bepalen van alfa (rechte klimming) en delta (declinatie) van de maan
     double bPI = beta*PIdiv180; double lPI = lambda*PIdiv180; double ePI = epsilonDegrees*PIdiv180;

     double X = cos(bPI) * cos(lPI);
     double Y = cos(ePI) * cos(bPI) * sin(lPI) - sin(ePI) * sin(bPI);
     double Z = sin(ePI) * cos(bPI) * sin(lPI) + cos(ePI) * sin(bPI);
     double R = sqrt(1.0 - pow(Z, 2));
     // fnOutputDebug("epsilonDegrees / epsilonSeconds = " + std::to_string(epsilonDegrees) + "/" + std::to_string(epsilonSeconds));
     // fnOutputDebug("z / r = " + std::to_string(Z) + "/" + std::to_string(R));

     double delta = c180divPI * atan(Z/R);
     double alfa = (24.0/M_PI) * atan(Y/(X + R));
                      
     double alfaUur = floor(alfa);
     double alfaMinuut = floor((alfa - alfaUur)*60.0);
     double alfaSeconde = (alfa - alfaUur - (alfaMinuut/60.0))*3600.0;
     double deltaGraden = floor(delta);
     double deltaMinuten = floor((delta - deltaGraden)*60.0);
     double deltaSeconden = floor((delta - deltaGraden - (deltaMinuten/60))*3600.0);
     double deltaGradenDecimaal = deltaGraden + (deltaMinuten/60.0) + (deltaSeconden/3600.0);

     // bepalen van de uurhoek H
     double alfaTotalSeconds = alfaUur*3600.0 + alfaMinuut*60.0 + alfaSeconde;
     double hourAngleTotalSeconds = appTetaNulTotalSeconds + obslongitude*3600.0/15.0 - alfaTotalSeconds;
     double hourAngle = hourAngleTotalSeconds/3600.0;
     double hourAngleDegrees = hourAngle*15.0;

     if (hourAngleDegrees<0)
        hourAngleDegrees += 360.0;

     // bepalen van de hoogte h
     double altitudeh = asin(sin(obslatitude * PIdiv180) * sin(deltaGradenDecimaal * PIdiv180) + cos(obslatitude * PIdiv180)* cos(deltaGradenDecimaal * PIdiv180) * cos(hourAngleDegrees * PIdiv180));
     altitudeh *= c180divPI;

     // bepalen van de refractie
     double refractieArgument = altitudeh + (10.3 / (altitudeh + 5.11));
     double refractieR = 1.02/(tan(refractieArgument * PIdiv180));
     refractieR /= 60.0;

     // bepalen van de parallax in horizontale coordinaten
     double parallaxh = asin(sin(pi * PIdiv180) * cos(altitudeh * PIdiv180)) * c180divPI;

     // correctie van de altitude met de parallax 
     double corraltitudeh = altitudeh + refractieR - parallaxh;
     if (onlyElevation==1)
     {
        results[1] = corraltitudeh;
        return;
     }

     // bepalen van de azimuth A
     double teller = sin(hourAngleDegrees * PIdiv180);
     double noemer = cos(hourAngleDegrees * PIdiv180) * sin(obslatitude * PIdiv180) - tan(deltaGradenDecimaal * PIdiv180) * cos(obslatitude * PIdiv180);
     double azimuth = atan2d(teller, noemer);
     azimuth += 180.0;
     if (azimuth<0)
        azimuth += 360.0;

     // bepalen van de verlichte fractie van de maanschijf
     double angleI = 180.0 - D - 6.289*sin(MA*PIdiv180) + 2.1*sin(M*PIdiv180) - 1.274*sin((2.0*D - MA)*PIdiv180) - 0.658*sin(2.0*D*PIdiv180) - 0.214*sin(2.0*MA*PIdiv180) - 0.110*sin(D*PIdiv180);
     double illumFractionK = 100.0 * ((1.0 + cos(angleI*PIdiv180))/2.0);

     // zonnecoordinaten
     double LnulSun = 280.46646 + 36000.76983*T + 0.0003032*T2;
     LnulSun -= floor(LnulSun/360.0)*360.0;
     if (LnulSun < 0)
        LnulSun += 360.0;

     double Msun = 357.52911+35999.05029*T - 0.0001537*T2;
     Msun -= floor(Msun/360.0)*360.0;
     if (Msun < 0)
        Msun += 360.0;

     double eSun = 0.016708634 - 0.000042037*T - 0.0000001267*T2;
     double Csun = (1.914602 - 0.004817*T - 0.000014*T2) * sin(Msun*PIdiv180) + (0.019993 - 0.000101*T) * sin(2.0*Msun*PIdiv180) + 0.000289*sin(3.0*Msun*PIdiv180);
     double eiSun = LnulSun + Csun;
     double vSun = Msun + Csun;
     double Rsun =  (1.000001018 * (1.0 - eSun*eSun)) / (1.0 + eSun*cos(vSun*PIdiv180));
     double omegaSun = 125.04 - 1934.136*T;
     double lambdaSun = eiSun - 0.00569 - 0.00478*sin(omegaSun*PIdiv180);
     double fiMoon = acos(cos(beta*PIdiv180) * cos((lambda - lambdaSun)*PIdiv180)) * c180divPI;
     double y = Rsun * 149597871.0 * sin(fiMoon*PIdiv180);
     double x = distance - Rsun * 149597871.0 * cos(fiMoon*PIdiv180);
     double iMoon = 0.0;
     if (x>0)
        iMoon = atan(y/x)*c180divPI;

     if (x<0 && y>=0)
        iMoon = (atan(y/x) + M_PI) * c180divPI;

     if (x<0 && y<0)
        iMoon = (atan(y/x) - M_PI) * c180divPI;

     if (x==0 && y>0)
        iMoon = M_PI / 2.0*c180divPI;

     if (x==0 && y<0)
        iMoon = -M_PI / 2.0*c180divPI;
 
     double illumFractionDetail = 100*((1.0 + cos(iMoon*PIdiv180)) / 2.0);
     double phase = (JDE - 2451550.26L) / 29.530588853L;
     phase -= floor(phase);
     double age = phase * 29.530588853L;
     int phaseID = (int)(phase * 8 + 0.5) % 8;

     results[0] = (illumFractionDetail + illumFractionK)/2.0;
     results[1] = corraltitudeh;// elevation
     results[2] = azimuth;
     results[3] = lambda;       // right ascension / longitude
     results[4] = delta;        // declination
     results[5] = age;
     results[6] = phase;
     results[7] = phaseID;
     results[8] = beta;         // latitude

     // fnOutputDebug("rerun = " + std::to_string(JDE));
     // fnOutputDebug("illumFractionDetail = " + std::to_string(illumFractionDetail));
     // fnOutputDebug("illumFractionK = " + std::to_string(illumFractionK));
     // fnOutputDebug("altitude/elev = " + std::to_string(corraltitudeh));
     // fnOutputDebug("azimuth = " + std::to_string(azimuth));
     // fnOutputDebug("RA / lambda = " + std::to_string(lambda));
     // fnOutputDebug("declination / delta = " + std::to_string(delta));
     // fnOutputDebug("age = " + std::to_string(age));
     // return 1;
}


DLL_API int DLL_CALLCONV getMoonPhase(double timeUTC, double obsLat, double obsLon, double* p, int* IDp, double* a, double* f, double* latu, double* lon, double* azi, double* eleva) {
   double res[9];
   moonCalcPosition(timeUTC, obsLat, obsLon, res);

   double frac = res[0];
   double altitudeh = res[1];
   double azimuth = res[2];
   double lambda = res[3];
   double delta = res[4];
   double age = res[5];
   double phase = res[6];
   double phaseID = res[7];
   double beta = res[8];

   *p = phase;
   *IDp = phaseID;
   *a = age;
   *f = frac;
   *latu = beta;
   *lon = lambda;
   *azi = azimuth;
   *eleva = altitudeh;
   return 1;
}

DLL_API int DLL_CALLCONV getMoonElevation(double timeUTC, double obslatitude, double obslongitude, double *azimuth, double *eleva) {
     double res[9];
     moonCalcPosition(timeUTC, obslatitude, obslongitude, res);
     // fnOutputDebug("res[1] = " + std::to_string(res[1]));
     double el = res[1];
     *eleva = el;
     double azi = res[2];
     *azimuth = azi;
     return 1;
}

DLL_API int DLL_CALLCONV getMoonNoon(double timeUTC, double obslatitude, double obslongitude, int doMinu, double *hmax, double *hmin, double *fmax, double *fmin) {

     double res[9];
     double maxu = -91;     double minu = 91;
     double maxuZeit = 0;   int maxuIndexZeit = 0;
     double minuZeit = 0;   int minuIndexZeit = 0;

     for (int i = 0; i < 24; ++i)
     {
         double b = timeUTC + i * 3600;
         moonCalcPosition(b, obslatitude, obslongitude, res, 1);
         // fnOutputDebug("res[1] = " + std::to_string(res[1]));
         if (res[1]>maxu)
         {
            maxuIndexZeit = i;
            maxuZeit = b;
            maxu = res[1];
         }

         if (res[1]<minu)
         {
            minuIndexZeit = i;
            minuZeit = b;
            minu = res[1];
         }
     }

     int extraLoops = 0;   int outerLoops = 0;
     for (int i = -30; i < 90; ++i)
     {
         double b = maxuZeit + i * 60;
         moonCalcPosition(b, obslatitude, obslongitude, res, 1);
         // fnOutputDebug("res[1] = " + std::to_string(res[1]));
         if (res[1]>maxu)
         {
            maxuIndexZeit = i;
            maxuZeit = b;
            maxu = res[1];
            extraLoops++;
         } else if (i>0)
            break;
         outerLoops++;
     }

     // fnOutputDebug("loops = " + std::to_string(extraLoops) + " / " + std::to_string(outerLoops) );
     // outerLoops = 0; extraLoops = 0;
     if (doMinu==1)
     {
         for (int i = -30; i < 90; ++i)
         {
             double b = minuZeit + i * 60;
             moonCalcPosition(b, obslatitude, obslongitude, res, 1);
             // fnOutputDebug("res[1] = " + std::to_string(res[1]));
             if (res[1]<minu)
             {
                minuIndexZeit = i;
                minuZeit = b;
                minu = res[1];
                extraLoops++;
             } else if (i>0)
                break;
             outerLoops++;
         }
         *hmin = (minuZeit - timeUTC)/60;
         *fmin = minu;
     }

     // fnOutputDebug("loops = " + std::to_string(extraLoops) + " / " + std::to_string(outerLoops) );
     *hmax = (maxuZeit - timeUTC)/60;
     *fmax = maxu;
     // fnOutputDebug("maxu = " + std::to_string(maxu) + " // " + std::to_string(maxuZeit) );
     // fnOutputDebug("hm = " + std::to_string(hmax) + " // " + std::to_string(hmin) + " // " + std::to_string(extraLoops) + " // " + std::to_string(outerLoops) );
     // fnOutputDebug("minu = " + std::to_string(minu) + " // " + std::to_string(minuZeit) );
     return 1;
}

DLL_API int DLL_CALLCONV getTwilightDuration(double t, double lat, double lon, double degs, double* twDur) {
  // Find duration of today's twilight.
  Twilight tw;
  tw.calculate(lat, degs, t);
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
     tw.calculate(lat, 6.1, t);
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

   double res[9];
   moonCalcPosition(timeUTC, obsLat, obsLon, res);

   double moonRA = res[3];
   double moonDEC = res[4];
   double moonLatu = res[8];

   MoonPhase m;
   m.calculate(timeUTC);
   double moonLat = m.latitude;
   double moonLon = m.longitude;
   double angle = getMoonDiskOrientationAngles(moonLat, moonLon, moonRA, moonDEC, sunRA, sunDEC, obsLat, obsLon);
   fnOutputDebug("moon angle = " + std::to_string(angle));
   fnOutputDebug("moon lat/lon = " + std::to_string(moonLat) + "/" + std::to_string(moonLon));
   fnOutputDebug("2moon lat/lon = " + std::to_string(moonLatu) + "/" + std::to_string(moonRA));
   fnOutputDebug("moon ra/dec = " + std::to_string(moonRA) + "/" + std::to_string(moonDEC));
   fnOutputDebug("sun ra/dec = " + std::to_string(sunRA) + "/" + std::to_string(sunDEC));
   return angle;
}
*/


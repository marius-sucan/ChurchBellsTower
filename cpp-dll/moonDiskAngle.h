double kp_jd_UT = 0;
double kp_t = 0;
double kp_nutLon = 0, kp_nutObl = 0;
double kp_meanObliquity = 0;
double kp_TTminusUT = 0;
double kp_lst = 0;

   /** Radians to degrees. */
double RAD_TO_DEG = 180.0 / M_PI;

   /** Degrees to radians. */
double DEG_TO_RAD = 1.0 / RAD_TO_DEG;

   /* Arcseconds to radians */
double ARCSEC_TO_RAD = (DEG_TO_RAD / 3600.0);

   /** Astronomical Unit in km. As defined by JPL. */
double AU = 149597870.691;

   /** Earth equatorial radius in km. IERS 2003 Conventions. */
double EARTH_RADIUS = 6378.1366;

   /** Two times Pi. */
double TWO_PI = 2.0 * M_PI;

   /** Pi divided by two. */
double PI_OVER_TWO = M_PI / 2.0;

   /** Julian century conversion constant = 100 * days per year. */
double JULIAN_DAYS_PER_CENTURY = 36525.0;

   /** Seconds in one day. */
double SECONDS_PER_DAY = 86400;

   /** Light time in days for 1 AU. DE405 definition. */
double LIGHT_TIME_DAYS_PER_AU = 0.00577551833109;

   /** Our default epoch. The Julian Day which represents noon on 2000-01-01. */
double J2000 = 2451545.0;



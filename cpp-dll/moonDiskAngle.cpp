 
 // Extracted code from java source by:
 // Tomás Alonso Albi / SunMoonCalculator
 // https://bitbucket.org/talonsoalbi/sunmooncalculator/src/master/
 // converted [poorly?] to c++ by Marius Șucan
 // this work is not done yet

   /**
    * Reduce an angle in radians to the range (0 - 2 Pi).
    * @param r Value in radians.
    * @return The reduced radians value.
    */
   double normalizeRadians(double r) {
      if (r < 0 && r >= -TWO_PI)
         return r + TWO_PI;
      if (r >= TWO_PI && r < 2*TWO_PI)
         return r - TWO_PI;
      if (r >= 0 && r < TWO_PI)
         return r;

      r -= TWO_PI * floor(r / TWO_PI);
      if (r < 0.)
         r += TWO_PI;

      return r;
   }

   void setUTDate(double jd, double obsLon) {
      kp_jd_UT = jd;
      kp_t = (jd + kp_TTminusUT / SECONDS_PER_DAY - J2000) / JULIAN_DAYS_PER_CENTURY;
      double t = kp_t;
      // Compute nutation
      double M1 = (124.90 - 1934.134 * t + 0.002063 * t * t) * DEG_TO_RAD;
      double M2 = (201.11 + 72001.5377 * t + 0.00057 * t * t) * DEG_TO_RAD;
      kp_nutLon = (-(17.2026 + 0.01737 * t) * sin(M1) + (-1.32012 + 0.00013 * t) * sin(M2) + 0.2088 * sin(2 * M1)) * ARCSEC_TO_RAD;
      kp_nutObl = ((9.2088 + 0.00091 * t) * cos(M1) + (0.552204 - 0.00029 * t) * cos(M2) - 0.0904 * cos(2 * M1)) * ARCSEC_TO_RAD;

      // Compute mean obliquity
      double t2 = kp_t / 100.0;
      double tmp = t2 * (27.87 + t2 * (5.79 + t2 * 2.45));
      tmp = t2 * (-249.67 + t2 * (-39.05 + t2 * (7.12 + tmp)));
      tmp = t2 * (-1.55 + t2 * (1999.25 + t2 * (-51.38 + tmp)));
      tmp = (t2 * (-4680.93 + tmp)) / 3600.0;
      kp_meanObliquity = (23.4392911111111 + tmp) * DEG_TO_RAD;

      // Obtain local apparent sidereal time
      double jd0 = floor(kp_jd_UT - 0.5) + 0.5;
      double T0Z = (jd0 - J2000) / JULIAN_DAYS_PER_CENTURY;
      double secs = (kp_jd_UT - jd0) * SECONDS_PER_DAY;
      double gmst = (((((-6.2e-6 * T0Z) + 9.3104e-2) * T0Z) + 8640184.812866) * T0Z) + 24110.54841;
      double msday = 1.0 + (((((-1.86e-5 * T0Z) + 0.186208) * T0Z) + 8640184.812866) / (SECONDS_PER_DAY * JULIAN_DAYS_PER_CENTURY));
      gmst = (gmst + msday * secs) * (15.0 / 3600.0) * DEG_TO_RAD;
      kp_lst = normalizeRadians(gmst + obsLon + kp_nutLon * cos(kp_meanObliquity + kp_nutObl));
   }

   /**
    * Returns the orientation angles of the lunar disk figure. Illumination fraction 
    * is returned in the main program. Simplification of the method presented by 
    * Eckhardt, D. H., "Theory of the Libration of the Moon", Moon and planets 25, 3 
    * (1981), without the physical librations of the Moon. Accuracy around 0.5 deg 
    * for each value. 
    * Moon and Sun positions must be computed before calling this method.
    * @return Optical libration in longitude, latitude, position angle of 
    * axis, bright limb angle, and paralactic angle.
    */
   double getMoonDiskOrientationAngles(double moonLat, double moonLon, double moonRA, double moonDEC, double sunRA, double sunDEC, double obsLat, double obsLon) {
      // double moonLon = moon.eclipticLongitude, moonLat = moon.eclipticLatitude, 
      //        moonRA  = moon.rightAscension,    moonDEC = moon.declination;
      // double sunRA   = sun.rightAscension,      sunDEC = sun.declination;
    
      // Obliquity of ecliptic
      double eps = kp_meanObliquity + kp_nutObl;
      double t = kp_t;
      // Moon's argument of latitude
      double F = (93.2720993 + 483202.0175273 * t - 0.0034029 * t * t - t * t * t / 3526000.0 + t * t * t * t / 863310000.0) * DEG_TO_RAD;
      // Moon's inclination
      double I = 1.54242 * DEG_TO_RAD;
      // Moon's mean ascending node longitude
      double omega = (125.0445550 - 1934.1361849 * t + 0.0020762 * t * t + t * t * t / 467410.0 - t * t * t * t / 18999000.0) * DEG_TO_RAD;

      double cosI = cos(I), sinI = sin(I);
      double cosMoonLat = cos(moonLat), sinMoonLat = sin(moonLat);
      double cosMoonDec = cos(moonDEC), sinMoonDec = sin(moonDEC);

      // Obtain optical librations lp and bp
      double W = moonLon - omega;
      double sinA = sin(W) * cosMoonLat * cosI - sinMoonLat * sinI;
      double cosA = cos(W) * cosMoonLat;
      double A = atan2(sinA, cosA);
      double lp = normalizeRadians(A - F);
      double sinbp = -sin(W) * cosMoonLat * sinI - sinMoonLat * cosI;
      double bp = asin(sinbp);
    
      // Obtain position angle of axis p
      double x = sinI * sin(omega);
      double y = sinI * cos(omega) * cos(eps) - cosI * sin(eps);
      double w = atan2(x, y);
      double sinp = hypot(x, y) * cos(moonRA - w) / cos(bp);
      double p = asin(sinp);
    
      // Compute bright limb angle bl
      double bl = (M_PI + atan2(cos(sunDEC) * sin(moonRA - sunRA), cos(sunDEC) * 
            sinMoonDec * cos(moonRA - sunRA) - sin(sunDEC) * cosMoonDec));
    
      // Paralactic angle par
      y = sin(kp_lst - moonRA);
      x = tan(obsLat) * cosMoonDec - sinMoonDec * cos(kp_lst - moonRA);
      double par = 0.0;
      if (x != 0.0) {
         par = atan2(y, x);
      } else {
         par = (y / abs(y)) * PI_OVER_TWO;
      }
      fnOutputDebug("p/bl/par = " + std::to_string(bp) + "/" + std::to_string(bl) + "/" + std::to_string(par));
      // return new double[] {lp, bp, p, bl, par};
      return bl;
   }


   /**
    * Transforms a common date into a Julian day number (counting days from Jan 1, 4713 B.C. at noon).
    * Dates before October, 15, 1582 are assumed to be in the Julian calendar, after that the Gregorian one is used.
    * @return Julian day number.
    */
   double toJulianDay(int year, int month, int day, int h, int m, int s) {
      // The conversion formulas are from Meeus, chapter 7.
      boolean julian = false; // Use Gregorian calendar
      if (year < 1582 || (year == 1582 && month < 10) || (year == 1582 && month == 10 && day < 15))
         julian = true;

      int D = day;
      int M = month;
      int Y = year;
      if (M < 3)
      {
         Y--;
         M += 12;
      }
      int A = Y / 100;
      int B = julian ? 0 : 2 - A + A / 4;

      double dayFraction = (h + (m + (s / 60.0)) / 60.0) / 24.0;
      double jd = dayFraction + (int) (365.25D * (Y + 4716)) + (int) (30.6001 * (M + 1)) + D + B - 1524.5;
      return jd;
   }


   void wrapSetUTdate(int year, int month, int day, int h, int m, double obsLat, double obsLon, int obsAlt) {
      double jd = toJulianDay(year, month, day, h, m, 25);
      double ndot = -25.858, c0 = 0.91072 * (ndot + 26.0);

      if (year < -500 || year >= 2200)
      {
         double u = (jd - 2385800.5) / 36525.0; // centuries since J1820
         kp_TTminusUT = -20 + 32.0 * u * u;
      } else
      {
         double x = year + (month - 1 + (day - 1) / 30.0) / 12.0;
         double x2 = x * x, x3 = x2 * x, x4 = x3 * x;
         if (year < 1600)
         {
            kp_TTminusUT = 10535.328003 - 9.9952386275 * x + 0.00306730763 * x2 - 7.7634069836E-6 * x3 + 3.1331045394E-9 * x4 + 
                  8.2255308544E-12 * x2 * x3 - 7.4861647156E-15 * x4 * x2 + 1.936246155E-18 * x4 * x3 - 8.4892249378E-23 * x4 * x4;
         } else
         {
            kp_TTminusUT = -1027175.34776 + 2523.2566254 * x - 1.8856868491 * x2 + 5.8692462279E-5 * x3 + 3.3379295816E-7 * x4 + 
                  1.7758961671E-10 * x2 * x3 - 2.7889902806E-13 * x2 * x4 + 1.0224295822E-16 * x3 * x4 - 1.2528102371E-20 * x4 * x4;
         }
         c0 = 0.91072 * (ndot + 25.858) ;
      }

      double c = -c0 * pow((jd - 2435109.0) / 36525.0, 2);
      if (year < 1955 || year > 2005)
         kp_TTminusUT += c;

      setUTDate(jd, obsLon);
   }



// ---- evaluation ------------------------------------------------------------

// Reduce an angle to the half turn either side of zero.  The series are summed
// over arguments that run to tens of thousands of radians a century out, and
// keeping each power of time folded back into one turn as it is formed is what
// keeps the phases from losing digits at the far ends of the range.
static double mod2pi(double x) {
     double y = fmod(x + M_PI, 2.0*M_PI);
     if (y < 0.0)
        y += 2.0*M_PI;

     return y - M_PI;
}

static double polyReduced(const double *c, double T, double T2, double T3, double T4) {
     return c[0] + mod2pi(c[1]*T) + mod2pi(c[2]*T2) + mod2pi(c[3]*T3) + mod2pi(c[4]*T4);
}

// Sum one stretch of the main problem, from term lo up to but not including hi.
// wantCosine picks the distance series, which is a cosine series where the other
// two are sine series.
static double sumMain(int lo, int hi, const double *arg, int wantCosine) {
     double total = 0.0;
     for (int i=lo; i<hi; i++)
     {
         const signed char *m = mainArg + 4*i;
         double phase = m[0]*arg[0] + m[1]*arg[1] + m[2]*arg[2] + m[3]*arg[3];
         total += mainAmp[i] * (wantCosine ? cos(phase) : sin(phase));
     }

     return total;
}

// ... and one of the eleven perturbation series, which carry a phase of their
// own and reach across all thirteen arguments.
static double sumPert(int which, const double *arg) {
     double total = 0.0;
     for (int i=pertStart[which]; i<pertStart[which+1]; i++)
     {
         const signed char *m = pertArg + 13*i;
         double phase = pertPhase[i];
         for (int k=0; k<13; k++)
             if (m[k])
                phase += m[k] * arg[k];

         total += pertAmp[i] * sin(phase);
     }

     return total;
}

// The moon's geometric geocentric place, referred to the mean ecliptic and the
// mean equinox of the date - the frame Meeus chapter 47 hands back, so that
// everything downstream of it is unchanged.  T counts Julian centuries of
// dynamical time from J2000.0.  Longitude and latitude come back in degrees and
// the distance in kilometres, centre to centre.
//
// ELP works in two frames that are not that one.  Its longitude is reckoned
// from the inertial departure point rather than from the equinox, and the plane
// it is reckoned in is carried to J2000 by Laskar's P and Q rather than by the
// ecliptic precession of Meeus chapter 21.  Going out through the first and
// back in through the second is what puts the answer in the frame the caller
// expects; skipping the detour and simply adding the general precession to the
// longitude is right to 0''.002 but leaves the latitude 0''.09 out at worst,
// which is more than the truncated series themselves are worth.
void moonPosition(double T, double &lambdaDeg, double &betaDeg, double &distanceKm) {
     const double kRadToDeg = 57.29577951308232;
     const double kDegToRad = 0.017453292519943295;

     double T2 = T*T, T3 = T2*T, T4 = T3*T;

     double w1  = polyReduced(argW1, T, T2, T3, T4);
     double w2  = polyReduced(argW2, T, T2, T3, T4);
     double w3  = polyReduced(argW3, T, T2, T3, T4);
     double ea  = polyReduced(argEa, T, T2, T3, T4);
     double pip = polyReduced(argPip, T, T2, T3, T4);

     double arg[13];
     arg[0] = mod2pi(w1 - ea + M_PI);   // D,  mean elongation
     arg[1] = mod2pi(w1 - w3);          // F,  argument of latitude
     arg[2] = mod2pi(w1 - w2);          // l,  the moon's mean anomaly
     arg[3] = mod2pi(ea - pip);         // l', the sun's mean anomaly
     for (int i=0; i<8; i++)
         arg[4+i] = mod2pi(argPlanet[i][0] + mod2pi(argPlanet[i][1]*T));

     arg[12] = mod2pi(w1 + zetaRate*T);

     double lon = w1 + sumMain(mainStart[0], mainStart[1], arg, 0)
                + sumPert(0, arg) + mod2pi(sumPert(1, arg)*T)
                + mod2pi(sumPert(2, arg)*T2) + mod2pi(sumPert(3, arg)*T3);

     double lat = sumMain(mainStart[1], mainStart[2], arg, 0)
                + sumPert(4, arg) + mod2pi(sumPert(5, arg)*T)
                + mod2pi(sumPert(6, arg)*T2);

     double r = distScale * (sumMain(mainStart[2], mainStart[3], arg, 1)
                + sumPert(7, arg) + sumPert(8, arg)*T
                + sumPert(9, arg)*T2 + sumPert(10, arg)*T3);

     // ELP's own frame to the J2000 mean ecliptic - Laskar's P and Q, as the
     // theory's getX2000 applies them.
     double x0 = r * cos(lat) * cos(lon);
     double y0 = r * cos(lat) * sin(lon);
     double z0 = r * sin(lat);

     double T5 = T4*T;
     double P = 0.10180391e-4*T + 0.47020439e-6*T2 - 0.5417367e-9*T3
              - 0.2507948e-11*T4 + 0.463486e-14*T5;
     double Q = -0.113469002e-3*T + 0.12372674e-6*T2 + 0.12654170e-8*T3
              - 0.1371808e-11*T4 - 0.320334e-14*T5;
     double sq = sqrt(1.0 - P*P - Q*Q);

     double X = (1.0 - 2.0*P*P)*x0 + (2.0*P*Q)*y0 + (2.0*P*sq)*z0;
     double Y = (2.0*P*Q)*x0 + (1.0 - 2.0*Q*Q)*y0 - (2.0*Q*sq)*z0;
     double Z = -(2.0*P*sq)*x0 + (2.0*Q*sq)*y0 + (1.0 - 2.0*P*P - 2.0*Q*Q)*z0;

     // ... and back out to the ecliptic and equinox of the date - Meeus 21.5,
     // reckoned forward from J2000.
     double dist = sqrt(X*X + Y*Y + Z*Z);
     double lam0 = atan2(Y, X);
     double bet0 = asin(Z / dist);

     double eta = (47.0029*T - 0.03302*T2 + 0.000060*T3) / 3600.0 * kDegToRad;
     double pii = (174.876384*3600.0 - 869.8089*T + 0.03536*T2) / 3600.0 * kDegToRad;
     double pa  = (5029.0966*T + 1.11113*T2 - 0.000006*T3) / 3600.0 * kDegToRad;

     double sinD = sin(pii - lam0);
     double A = cos(eta)*cos(bet0)*sinD - sin(eta)*sin(bet0);
     double B = cos(bet0)*cos(pii - lam0);
     double C = cos(eta)*sin(bet0) + sin(eta)*cos(bet0)*sinD;

     lambdaDeg  = (pa + pii - atan2(A, B)) * kRadToDeg;
     lambdaDeg -= 360.0 * floor(lambdaDeg / 360.0);
     betaDeg    = asin(C) * kRadToDeg;
     distanceKm = dist;
}

}   // namespace elp

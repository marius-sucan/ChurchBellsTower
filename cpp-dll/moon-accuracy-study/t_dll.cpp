// Drive the DLL's own exports, so the harness measures the shipping code.
#include "cbt-main.cpp"
#include <cstdio>
#include <cstdlib>
#include <cstring>

int main(int argc, char** argv) {
    if (argc < 2) return 1;
    const char* mode = argv[1];

    if (!strcmp(mode, "place")) {          // t lat lon  -> az elev lambda beta dist par
        double t, lat, lon;
        while (scanf("%lf %lf %lf", &t, &lat, &lon) == 3) {
            MoonState s;
            moonComputeState(t, lat, lon, s, MOON_DETAIL_ALL);
            printf("%.8f %.8f %.8f %.8f %.6f %.8f %.8f %.8f %.6f %d %.8f\n",
                   s.azimuth, s.altitudeApp, s.lambda, s.beta, s.distance, s.parallax,
                   s.illumination, s.phase, s.age, s.phaseID, s.altitude);
        }
    } else if (!strcmp(mode, "riseset")) { // dayStart span lat lon height -> rise set azr azs
        double t0, span, lat, lon, h;
        while (scanf("%lf %lf %lf %lf %lf", &t0, &span, &lat, &lon, &h) == 5) {
            double r, sv, ra, sa;
            getMoonRiseSetDay(t0, span, lat, lon, h, &r, &sv, &ra, &sa);
            printf("%.4f %.4f %.4f %.4f\n", r, sv, ra, sa);
        }
    } else if (!strcmp(mode, "phases")) {  // t -> four offsets in seconds
        double t;
        while (scanf("%lf", &t) == 1) {
            double a, b, c, d;
            getNextMoonPhases(t, &a, &b, &c, &d);
            printf("%.4f %.4f %.4f %.4f\n", a, b, c, d);
        }
    } else if (!strcmp(mode, "phaseinstant")) {  // k which -> jde
        double k; int w;
        while (scanf("%lf %d", &k, &w) == 2)
            printf("%.9f\n", moonPhaseInstant(k, w));
    } else if (!strcmp(mode, "noon")) {    // t lat lon -> hmax hmin fmax fmin
        double t, lat, lon;
        while (scanf("%lf %lf %lf", &t, &lat, &lon) == 3) {
            double a, b, c, d;
            getMoonNoon(t, lat, lon, 1, &a, &b, &c, &d);
            printf("%.6f %.6f %.6f %.6f\n", a, b, c, d);
        }
    } else if (!strcmp(mode, "legacy")) {  // t rt lat lon -> rise set (hours from rt)
        double t, rt, lat, lon;
        while (scanf("%lf %lf %lf %lf", &t, &rt, &lat, &lon) == 4) {
            double r, sv, tw;
            getSunMoonRiseSet(t, rt, lat, lon, 0, &r, &sv, &tw);
            printf("%.8f %.8f\n", r, sv);
        }
    } else if (!strcmp(mode, "deltat")) {
        double jd;
        while (scanf("%lf", &jd) == 1) printf("%.4f\n", deltaTseconds(jd));
    }
    return 0;
}

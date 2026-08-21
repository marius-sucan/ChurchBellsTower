#include "cbt-main.cpp"
#include <cstdio>
#include <cstring>
#include <ctime>
int main(int argc, char** argv) {
    if (argc < 2) return 1;
    if (!strcmp(argv[1], "place")) {
        double t, lat, lon;
        while (scanf("%lf %lf %lf", &t, &lat, &lon) == 3) {
            MoonState s;
            moonComputeState(t, lat, lon, s, MOON_DETAIL_ALL);
            printf("%.8f %.8f %.8f %.8f %.6f %.8f %.8f %.8f %.6f %d %.8f\n",
                   s.azimuth, s.altitudeApp, s.lambda, s.beta, s.distance, s.parallax,
                   s.illumination, s.phase, s.age, s.phaseID, s.altitude);
        }
    } else if (!strcmp(argv[1], "legacy")) {
        double t, rt, lat, lon;
        while (scanf("%lf %lf %lf %lf", &t, &rt, &lat, &lon) == 4) {
            double r, sv, tw;
            getSunMoonRiseSet(t, rt, lat, lon, 0, &r, &sv, &tw);
            printf("%.8f %.8f\n", r, sv);
        }
    } else if (!strcmp(argv[1], "bench")) {
        clock_t t0; double base = 1755734400.0, lat = 44.43, lon = 26.10;
        double r, s, tw, a, b, c, d;
        t0 = clock();
        for (int i=0;i<365;i++) getMoonNoon(base + i*86400.0, lat, lon, 1, &a,&b,&c,&d);
        printf("getMoonNoon            365 days   %6.3f ms/day\n", (double)(clock()-t0)/CLOCKS_PER_SEC/365*1000);
        t0 = clock();
        for (int i=0;i<365;i++) for (int k=0;k<48;k++) getSunMoonRiseSet(base+i*86400.0+k*3600.0, base+i*86400.0, lat, lon, 0, &r,&s,&tw);
        printf("getSunMoonRiseSet 48x  365 days   %6.3f ms/day\n", (double)(clock()-t0)/CLOCKS_PER_SEC/365*1000);
        t0 = clock();
        for (int i=0;i<20000;i++) { double az, el; getMoonElevation(base, -80.0 + i*0.008, -170.0 + i*0.017, &az, &el); }
        printf("getMoonElevation     20000 places %6.2f us/call\n", (double)(clock()-t0)/CLOCKS_PER_SEC/20000*1e6);
        t0 = clock();
        for (int i=0;i<365;i++) { double n,f,fu,l; getNextMoonPhases(base + i*86400.0, &n,&f,&fu,&l); }
        printf("getNextMoonPhases      365 calls  %6.3f ms/call\n", (double)(clock()-t0)/CLOCKS_PER_SEC/365*1000);
    }
    return 0;
}

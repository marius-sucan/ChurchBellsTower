#include <cstdio>
#include <cstdlib>
#include "MoonELP.cpp"
int main(int argc, char** argv) {
    // read JD TT values on stdin, print lambda beta dist
    double jd;
    while (scanf("%lf", &jd) == 1) {
        double T = (jd - 2451545.0)/36525.0, l, b, d;
        elp::moonPosition(T, l, b, d);
        printf("%.10f %.10f %.6f\n", l, b, d);
    }
    return 0;
}

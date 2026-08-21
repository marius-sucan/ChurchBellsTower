#include "cbt-main.cpp"
#include <cstdio>
#include <ctime>
static double secs(clock_t a){ return (double)(clock()-a)/CLOCKS_PER_SEC; }
int main(){
  double base = 1755734400.0;      // 2025-08-21
  double lat = 44.43, lon = 26.10, r, s, ra, sa, a, b, c, d;
  clock_t t0;

  t0 = clock();
  for (int i=0;i<365;i++) getMoonRiseSetDay(base + i*86400.0, 86400.0, lat, lon, 0, &r,&s,&ra,&sa);
  printf("getMoonRiseSetDay      365 days   %7.3f s   %6.3f ms/day\n", secs(t0), secs(t0)/365*1000);

  t0 = clock();
  for (int i=0;i<365;i++) getMoonNoon(base + i*86400.0, lat, lon, 1, &a,&b,&c,&d);
  printf("getMoonNoon            365 days   %7.3f s   %6.3f ms/day\n", secs(t0), secs(t0)/365*1000);

  t0 = clock();
  for (int i=0;i<365;i++) { double tw; getSunMoonRiseSet(base+i*86400.0, base+i*86400.0, lat, lon, 0, &r,&s,&tw); }
  printf("getSunMoonRiseSet      365 days   %7.3f s   %6.3f ms/day\n", secs(t0), secs(t0)/365*1000);

  t0 = clock();
  for (int i=0;i<20000;i++) { double az, el; getMoonElevation(base, -80.0 + i*0.008, -170.0 + i*0.017, &az, &el); }
  printf("getMoonElevation     20000 places %7.3f s   %6.2f us/call\n", secs(t0), secs(t0)/20000*1e6);

  t0 = clock();
  for (int i=0;i<365;i++) { double n,f,fu,l; getNextMoonPhases(base + i*86400.0, &n,&f,&fu,&l); }
  printf("getNextMoonPhases      365 calls  %7.3f s   %6.3f ms/call\n", secs(t0), secs(t0)/365*1000);

  t0 = clock();
  for (int i=0;i<365;i++) { double p,ag,fr,la,lo,az,el; int id; getMoonPhase(base+i*86400.0, lat, lon, &p,&id,&ag,&fr,&la,&lo,&az,&el); }
  printf("getMoonPhase           365 calls  %7.3f s   %6.3f ms/call\n", secs(t0), secs(t0)/365*1000);
  return 0;
}

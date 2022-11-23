#ifndef Twilight_h
#define Twilight_h

#include <time.h>

class Twilight {
  public:
    time_t queryTime;      // Time since Unix epoch of desired twilight duration.
    double latitude;      // Latitude of location to calculate twilight duration.
    double angleOfTwilight;   // Angle of desired twilight, e.g. 6 degrees for civil.
    time_t twilightDuration;   // Duration of twilight, in seconds.

    void calculate(double latitude, double angle, time_t t);

  private:
    int daysSinceWinterEquinox(time_t t);
    double julianDate(time_t t);
    void initClass();
};
#endif


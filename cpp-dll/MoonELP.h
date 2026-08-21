#ifndef MoonELP_h
#define MoonELP_h

// The moon's geocentric place from ELP/MPP02 - see MoonELP.cpp for what the
// series are, where they came from and how far they can be trusted.
namespace elp {
   void moonPosition(double T, double &lambdaDeg, double &betaDeg, double &distanceKm);
}

#endif

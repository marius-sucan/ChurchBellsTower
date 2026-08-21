"""Instants of the four principal phases: Meeus ch.49 (what the DLL runs) against
a DE440 root-find on the apparent geocentric elongation in longitude."""
import numpy as np
import de440, pipeline as P, elp, compare as C

D2R = np.pi / 180.0
R2D = 180.0 / np.pi
C_KM_S = 299792.458


# ------------------------------------------------------------ Meeus ch.49
def moon_phase_jde(lunation, which):
    k = lunation + which * 0.25
    T = k / 1236.85
    T2, T3, T4 = T * T, T ** 3, T ** 4
    jde = 2451550.09766 + 29.530588861 * k + 0.00015437 * T2 - 0.000000150 * T3 + 0.00000000073 * T4
    E = 1.0 - 0.002516 * T - 0.0000074 * T2
    M = (2.5534 + 29.10535670 * k - 0.0000014 * T2 - 0.00000011 * T3) * D2R
    MA = (201.5643 + 385.81693528 * k + 0.0107582 * T2 + 0.00001238 * T3 - 0.000000058 * T4) * D2R
    F = (160.7108 + 390.67050284 * k - 0.0016118 * T2 - 0.00000227 * T3 + 0.000000011 * T4) * D2R
    om = (124.7746 - 1.56375588 * k + 0.0020672 * T2 + 0.00000215 * T3) * D2R
    s = np.sin
    if which in (0, 2):
        c = ([-0.40720, 0.17241, 0.01608, 0.01039, 0.00739, -0.00514, 0.00208] if which == 0
             else [-0.40614, 0.17302, 0.01614, 0.01043, 0.00734, -0.00515, 0.00209])
        jde = (jde + c[0] * s(MA) + c[1] * E * s(M) + c[2] * s(2 * MA) + c[3] * s(2 * F)
               + c[4] * E * s(MA - M) + c[5] * E * s(MA + M) + c[6] * E * E * s(2 * M)
               - 0.00111 * s(MA - 2 * F) - 0.00057 * s(MA + 2 * F) + 0.00056 * E * s(2 * MA + M)
               - 0.00042 * s(3 * MA) + 0.00042 * E * s(M + 2 * F) + 0.00038 * E * s(M - 2 * F)
               - 0.00024 * E * s(2 * MA - M) - 0.00017 * s(om) - 0.00007 * s(MA + 2 * M)
               + 0.00004 * s(2 * MA - 2 * F) + 0.00004 * s(3 * M) + 0.00003 * s(MA + M - 2 * F)
               + 0.00003 * s(2 * MA + 2 * F) - 0.00003 * s(MA + M + 2 * F)
               + 0.00003 * s(MA - M + 2 * F) - 0.00002 * s(MA - M - 2 * F)
               - 0.00002 * s(3 * MA + M) + 0.00002 * s(4 * MA))
    else:
        jde = (jde - 0.62801 * s(MA) + 0.17172 * E * s(M) - 0.01183 * E * s(MA + M)
               + 0.00862 * s(2 * MA) + 0.00804 * s(2 * F) + 0.00454 * E * s(MA - M)
               + 0.00204 * E * E * s(2 * M) - 0.00180 * s(MA - 2 * F) - 0.00070 * s(MA + 2 * F)
               - 0.00040 * s(3 * MA) - 0.00034 * E * s(2 * MA - M) + 0.00032 * E * s(M + 2 * F)
               + 0.00032 * E * s(M - 2 * F) - 0.00028 * E * E * s(MA + 2 * M)
               + 0.00027 * E * s(2 * MA + M) - 0.00017 * s(om) - 0.00005 * s(MA - M - 2 * F)
               + 0.00004 * s(2 * MA + 2 * F) - 0.00004 * s(MA + M + 2 * F) + 0.00004 * s(MA - 2 * M)
               + 0.00003 * s(MA + M - 2 * F) + 0.00003 * s(3 * M) + 0.00002 * s(2 * MA - 2 * F)
               + 0.00002 * s(MA - M + 2 * F) - 0.00002 * s(3 * MA + M))
        W = (0.00306 - 0.00038 * E * np.cos(M) + 0.00026 * np.cos(MA) - 0.00002 * np.cos(MA - M)
             + 0.00002 * np.cos(MA + M) + 0.00002 * np.cos(2 * F))
        jde = jde + (W if which == 1 else -W)
    aB = [299.77, 251.88, 251.83, 349.42, 84.66, 141.74, 207.14, 154.84, 34.52, 207.19,
          291.34, 161.72, 239.56, 331.55]
    aR = [0.107408, 0.016321, 26.651886, 36.412478, 18.206239, 53.303771, 2.453732, 7.306860,
          27.261239, 0.121824, 1.844379, 24.198154, 25.513099, 3.592518]
    aC = [0.000325, 0.000165, 0.000164, 0.000126, 0.000110, 0.000062, 0.000060, 0.000056,
          0.000047, 0.000042, 0.000040, 0.000037, 0.000035, 0.000023]
    for i in range(14):
        a = aB[i] + aR[i] * k - (0.009173 * T2 if i == 0 else 0.0)
        jde = jde + aC[i] * np.sin(np.mod(a, 360.0) * D2R)
    return jde


# ------------------------------------------------------------ DE440 reference
def _lam_of_date(v, T):
    """Rectangular ICRF -> ecliptic longitude of date (degrees)."""
    w = de440.eq_to_ecl_j2000(v, eps0_arcsec=84381.406)
    lam, _, _ = P._to_date(w[0], w[1], w[2], T)
    return lam


def elongation_de440(jd_tdb):
    """Apparent geocentric elongation in longitude, moon minus sun, degrees.
    Light time is taken off both bodies; nutation cancels in the difference."""
    jd = np.atleast_1d(np.asarray(jd_tdb, dtype=float))
    T = (jd - 2451545.0) / 36525.0
    m = de440.moon_geocentric_icrf(jd)
    tau_m = np.sqrt((m ** 2).sum(0)) / C_KM_S / 86400.0
    m = de440.moon_geocentric_icrf(jd - tau_m)
    s = de440.sun_geocentric_icrf(jd)
    tau_s = np.sqrt((s ** 2).sum(0)) / C_KM_S / 86400.0
    s = de440.sun_geocentric_icrf(jd - tau_s)
    return np.mod(_lam_of_date(m, T) - _lam_of_date(s, T), 360.0)


def phase_instant_de440(jd_guess, target_deg):
    """Refine to the instant the elongation reaches target, by secant."""
    t = float(jd_guess)
    for _ in range(60):
        f0 = np.mod(elongation_de440(np.array([t]))[0] - target_deg + 180.0, 360.0) - 180.0
        dt = 1.0 / 1440.0
        f1 = np.mod(elongation_de440(np.array([t + dt]))[0] - target_deg + 180.0, 360.0) - 180.0
        step = -f0 * dt / (f1 - f0)
        t += step
        if abs(step) < 1e-9:
            break
    return t


def run(k0=290, k1=420):
    """k ~ 290 is 2023; k ~ 420 is 2033."""
    names = ['new moon', 'first quarter', 'full moon', 'last quarter']
    errs = {n: [] for n in names}
    for k in range(k0, k1):
        for which, tgt in enumerate([0.0, 90.0, 180.0, 270.0]):
            jde = moon_phase_jde(float(k), which)
            ref = phase_instant_de440(jde, tgt)
            errs[names[which]].append((jde - ref) * 86400.0)
    print(f"\nMeeus ch.49 phase instants vs a DE440 root-find on the apparent elongation")
    print(f"(k = {k0}..{k1}, roughly {2000 + k0/12.37:.0f}-{2000 + k1/12.37:.0f}; seconds of TT)")
    allv = []
    for n in names:
        v = np.array(errs[n]); allv.append(v)
        print(f"  {n:<16} mean {v.mean():+7.2f}  rms {np.sqrt((v**2).mean()):6.2f}  max |e| {np.abs(v).max():6.2f}")
    v = np.concatenate(allv)
    print(f"  {'all':<16} mean {v.mean():+7.2f}  rms {np.sqrt((v**2).mean()):6.2f}  max |e| {np.abs(v).max():6.2f}")


if __name__ == '__main__':
    run()

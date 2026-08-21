import numpy as np
import pipeline as P, compare as C, rs_compare as RSC, riseset as RS

D2R = np.pi / 180.0


def per_site():
    """MoonRise.cpp's rise/set error, broken down by site."""
    rng = np.random.default_rng(7)
    jd0s = 2451545.0 + 25.0 * 365.25 + np.floor(rng.uniform(0, 3650, 90)) + 0.5
    print("\nMoonRise.cpp rise/set error vs DE440, by site (seconds)")
    print(f"  {'site':<12}{'lat':>7}{'n':>6}{'rms':>9}{'p95':>9}{'max':>9}")
    for name, lat, lon in RSC.SITES:
        e = []
        for jd0 in jd0s:
            ref = RSC.crossings(jd0, lat, lon, P.theory_de440)
            if not ref:
                continue
            t_unix = (jd0 + 0.5 - 2440587.5) * 86400.0
            r, s = RS.moonrise_cpp(lat, lon, t_unix)
            got = ([(r / 86400.0 + 2440587.5, 'rise')] if r else []) + \
                  ([(s / 86400.0 + 2440587.5, 'set')] if s else [])
            for t1, t2, k in RSC.match(ref, got):
                e.append((t2 - t1) * 86400.0)
        e = np.array(e)
        print(f"  {name:<12}{lat:7.1f}{len(e):6d}{np.sqrt((e**2).mean()):9.1f}"
              f"{np.percentile(np.abs(e),95):9.1f}{np.abs(e).max():9.1f}")


def sky_position():
    """Topocentric azimuth / apparent altitude, and the illuminated fraction."""
    rng = np.random.default_rng(11)
    jd = 2451545.0 + rng.uniform(25 * 365.25, 35 * 365.25, 3000)
    p, c = P._ensure_elp()
    trims = {'375': C.trim(c, 0.1, 0.2)[0], '1036': C.trim(c, 0.01, 0.02)[0]}
    print("\nTopocentric sky position, Bucharest 44.43N 26.10E, 3000 random instants 2025-2035")
    print(f"  {'theory':<44}{'d azimuth rms/max':>26}{'d altitude rms/max':>26}")
    lat, lon = 44.43, 26.10
    az0, al0 = P.horizontal(jd, lat, lon, P.theory_de440)
    rows = [('Meeus ch.47 (ships today)', P.theory_meeus, None),
            ('VF&P 1979 (what the rise/set path uses)', P.theory_1989, None),
            ('ELP/MPP02 375-term cut', P.theory_elp, trims['375']),
            ('ELP/MPP02 1036-term cut', P.theory_elp, trims['1036'])]
    for label, th, co in rows:
        az, al = P.horizontal(jd, lat, lon, th, co)
        daz = ((az - az0 + 180) % 360 - 180) * 3600.0 * np.cos(al0 * D2R)
        dal = (al - al0) * 3600.0
        # keep only the moon above the horizon, which is when the numbers are shown
        m = al0 > 0
        print(f"  {label:<44}{np.sqrt((daz[m]**2).mean()):12.2f}\" {np.abs(daz[m]).max():10.2f}\""
              f"{np.sqrt((dal[m]**2).mean()):12.2f}\" {np.abs(dal[m]).max():10.2f}\"")


def illumination():
    rng = np.random.default_rng(13)
    jd = 2451545.0 + rng.uniform(25 * 365.25, 35 * 365.25, 3000)
    import de440
    jt = jd + P.delta_t(jd) / 86400.0
    T = (jt - 2451545.0) / 36525.0

    def frac(lam_m, beta_m, r_m, lam_s, r_s_km):
        el = np.arccos(np.cos(beta_m * D2R) * np.cos((lam_m - lam_s) * D2R))
        ph = np.arctan2(r_s_km * np.sin(el), r_m - r_s_km * np.cos(el))
        return 100.0 * (1 + np.cos(ph)) / 2.0

    # truth from DE440 for both bodies
    vm = de440.eq_to_ecl_j2000(de440.moon_geocentric_icrf(jt), eps0_arcsec=84381.406)
    lm, bm, rm = P._to_date(vm[0], vm[1], vm[2], T)
    vs = de440.eq_to_ecl_j2000(de440.sun_geocentric_icrf(jt), eps0_arcsec=84381.406)
    ls, bs, rs = P._to_date(vs[0], vs[1], vs[2], T)
    f0 = frac(lm, bm, rm, ls, rs)

    # the DLL: Meeus ch.47 moon + the chapter-25 sun it carries
    lam, beta, dist = P.theory_meeus(jt)
    T2 = T * T
    L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T2
    Ms = 357.52911 + 35999.05029 * T - 0.0001537 * T2
    Cs = ((1.914602 - 0.004817 * T - 0.000014 * T2) * np.sin(Ms * D2R)
          + (0.019993 - 0.000101 * T) * np.sin(2 * Ms * D2R) + 0.000289 * np.sin(3 * Ms * D2R))
    es = 0.016708634 - 0.000042037 * T - 0.0000001267 * T2
    vs_ = Ms + Cs
    Rs = (1.000001018 * (1 - es * es)) / (1 + es * np.cos(vs_ * D2R)) * 149597870.7
    lams = np.mod(L0 + Cs - 0.00569 - 0.00478 * np.sin((125.04 - 1934.136 * T) * D2R), 360.0)
    f1 = frac(lam, beta, dist, lams, Rs)
    d = f1 - f0
    print(f"\nIlluminated fraction (per cent of the disk), same 3000 instants")
    print(f"  Meeus ch.47 moon + chapter-25 sun vs DE440:  rms {np.sqrt((d**2).mean()):.5f} pt, "
          f"max {np.abs(d).max():.5f} pt")


if __name__ == '__main__':
    sky_position()
    illumination()
    per_site()

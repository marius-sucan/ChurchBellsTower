"""The app's own reduction (cbt-main.cpp moonComputeState) in Python, so that the
only thing that changes between runs is which lunar theory feeds it."""
import numpy as np
import json
import elp, meeus47, de440

D2R = np.pi / 180.0
R2D = 180.0 / np.pi
AS = 3600.0 * R2D

_t = json.load(open('meeus47.json'))

# --- Meeus ch.22 nutation, the 63-term table the DLL carries -----------------
_src = open('/home/marius/repos/ChurchBellsTower/cpp-dll/cbt-main.cpp').read()
import re


def _tab(name, n):
    m = re.search(r'static const double ' + name + r'\[\d+\]\s*=\s*\{(.*?)\};', _src, re.S)
    return np.array([float(v) for v in m.group(1).replace('\n', ' ').split(',')])


D22, M22, MA22, F22, O22 = (_tab(n, 63) for n in
                            ['dTable22a', 'mTable22a', 'maTable22a', 'fTable22a', 'oTable22a'])

_FI = np.array([[-171996, -174.2], [-13187, -1.6], [-2274, -0.2], [2062, 0.2], [1426, -3.4],
                [712, 0.1], [-517, 1.2], [-386, -0.4], [-301, 0], [217, -0.5], [-158, 0],
                [129, 0.1], [123, 0], [63, 0], [63, 0.1], [-59, 0], [-58, -0.1], [51, 0],
                [48, 0], [46, 0], [-38, 0], [-31, 0], [29, 0], [29, 0], [26, 0], [-22, 0],
                [21, 0], [17, -0.1], [16, 0], [-16, 0.1], [-15, 0], [-13, 0], [-12, 0],
                [11, 0], [-10, 0], [-8, 0], [7, 0], [-7, 0], [-7, 0], [-7, 0], [6, 0],
                [6, 0], [6, 0], [-6, 0], [-6, 0], [5, 0], [-5, 0], [-5, 0], [-5, 0],
                [4, 0], [4, 0], [4, 0], [-4, 0], [-4, 0], [-4, 0], [3, 0], [-3, 0],
                [-3, 0], [-3, 0], [-3, 0], [-3, 0], [-3, 0], [-3, 0]], dtype=float)
_EP = np.array([[92025, 8.9], [5736, -3.1], [977, -0.5], [-895, 0.5], [54, -0.1], [-7, 0],
                [224, -0.6], [200, 0], [129, -0.1], [-95, 0.3], [0, 0], [-70, 0], [-53, 0],
                [0, 0], [-33, 0], [26, 0], [32, 0], [27, 0], [0, 0], [-24, 0], [16, 0],
                [13, 0], [0, 0], [-12, 0], [0, 0], [0, 0], [-10, 0], [0, 0], [-8, 0],
                [7, 0], [9, 0], [7, 0], [6, 0], [0, 0], [5, 0], [3, 0], [-3, 0], [0, 0],
                [3, 0], [3, 0], [0, 0], [-3, 0], [-3, 0], [3, 0], [3, 0], [0, 0], [3, 0],
                [3, 0], [3, 0]] + [[0, 0]] * 14, dtype=float)


def nutation(T):
    T = np.atleast_1d(T)
    fi = _FI[:, 0][:, None] + _FI[:, 1][:, None] * T
    ep = _EP[:, 0][:, None] + _EP[:, 1][:, None] * T
    D = 297.85036 + 445267.111480 * T - 0.0019142 * T ** 2 + T ** 3 / 189474.0
    M = 357.52772 + 35999.050340 * T - 0.0001603 * T ** 2 - T ** 3 / 300000.0
    MA = 134.96298 + 477198.867398 * T + 0.0086972 * T ** 2 + T ** 3 / 56250.0
    F = 93.27191 + 483202.017538 * T - 0.0036825 * T ** 2 + T ** 3 / 327270.0
    om = 125.04452 - 1934.136261 * T + 0.0020708 * T ** 2 + T ** 3 / 450000.0
    arg = D2R * (D22[:, None] * D + M22[:, None] * M + MA22[:, None] * MA
                 + F22[:, None] * F + O22[:, None] * om)
    return (fi * np.sin(arg)).sum(0) / 1e4, (ep * np.cos(arg)).sum(0) / 1e4


def mean_obliquity(T):
    U = T / 100.0
    return (84381.448 + U * (-4680.93 + U * (-1.55 + U * (1999.25 + U * (-51.38 + U * (
        -249.67 + U * (-39.05 + U * (7.12 + U * (27.87 + U * (5.79 + U * 2.45)))))))))) / 3600.0


# --- delta T, as deltaTseconds() has it -------------------------------------
_DT = [56.86, 57.57, 58.31, 59.12, 59.98, 60.78, 61.63, 62.30, 62.97, 63.47,
       63.83, 64.09, 64.30, 64.47, 64.57, 64.69, 64.85, 65.15, 65.46, 65.78,
       66.07, 66.32, 66.60, 66.91, 67.28, 67.64, 68.10, 68.59, 68.97, 69.22,
       69.36, 69.36, 69.29, 69.22, 69.18, 69.19, 69.25]


def delta_t(jd_ut):
    year = 2000.0 + (jd_ut - 2451545.0) / 365.25
    y = np.clip(year, 1990, 2025.999)
    i = np.floor(y).astype(int) - 1990
    f = y - np.floor(y)
    a = np.array(_DT)
    return a[i] + f * (a[np.minimum(i + 1, len(a) - 1)] - a[i])


def refraction(elev_deg):
    e = np.asarray(elev_deg, dtype=float)
    hi = 1.02 / np.tan(D2R * (e + 10.3 / (e + 5.11))) / 60.0
    lo = -20.774 / np.tan(D2R * np.where(e < -0.575, e, -1.0)) / 3600.0
    return np.where(e < -0.575, lo, hi)


# --- the three lunar theories, all giving lambda/beta/r of date -------------
_P_ELP, _C_ELP = None, None
_C_ELP_TRIM = {}


def _ensure_elp():
    global _P_ELP, _C_ELP
    if _P_ELP is None:
        _P_ELP, _C_ELP = elp.load_coefs(0)
    return _P_ELP, _C_ELP


def _to_date(X, Y, Z, T):
    """J2000 mean ecliptic -> mean ecliptic AND equinox of date (IAU 2006 ecliptic
    precession, Meeus 21.5 form with t measured forward from J2000)."""
    t = T
    eta = (47.0029 * t - 0.03302 * t ** 2 + 0.000060 * t ** 3) / 3600.0
    Pi = (174.876384 * 3600.0 - 869.8089 * t + 0.03536 * t ** 2) / 3600.0
    p = (5029.0966 * t + 1.11113 * t ** 2 - 0.000006 * t ** 3) / 3600.0
    r = np.sqrt(X * X + Y * Y + Z * Z)
    lam = np.arctan2(Y, X) * R2D
    beta = np.arcsin(Z / r) * R2D
    A = (np.cos(eta * D2R) * np.cos(beta * D2R) * np.sin((Pi - lam) * D2R)
         - np.sin(eta * D2R) * np.sin(beta * D2R))
    B = np.cos(beta * D2R) * np.cos((Pi - lam) * D2R)
    C = (np.cos(eta * D2R) * np.sin(beta * D2R)
         + np.sin(eta * D2R) * np.cos(beta * D2R) * np.sin((Pi - lam) * D2R))
    lam2 = (p + Pi) - np.arctan2(A, B) * R2D
    return np.mod(lam2, 360.0), np.arcsin(C) * R2D, r


def theory_meeus(jd_tt):
    return meeus47.moon_lbr(jd_tt)


def theory_elp(jd_tt, coefs=None):
    p, c = _ensure_elp()
    T = (jd_tt - 2451545.0) / 36525.0
    X, Y, Z = elp.moon_x2000(T, p, coefs if coefs is not None else c)
    return _to_date(X, Y, Z, T)


def theory_de440(jd_tt):
    T = (jd_tt - 2451545.0) / 36525.0
    v = de440.eq_to_ecl_j2000(de440.moon_geocentric_icrf(jd_tt), eps0_arcsec=84381.406)
    return _to_date(v[0], v[1], v[2], T)


def theory_1989(jd_tt):
    """MoonRise.cpp's moon(): the Sky & Telescope 1989 series the rise/set code uses."""
    d = jd_tt - 2451545.0
    tp = 2 * np.pi

    def frac(x):
        return tp * (x - np.floor(x))
    l = frac(0.606434 + 0.03660110129 * d)
    m = frac(0.374897 + 0.03629164709 * d)
    f = frac(0.259091 + 0.03674819520 * d)
    dd = frac(0.827362 + 0.03386319198 * d)
    n = frac(0.347343 - 0.00014709391 * d)
    g = frac(0.993126 + 0.00273777850 * d)
    v = (0.39558 * np.sin(f + n) + 0.08200 * np.sin(f) + 0.03257 * np.sin(m - f - n)
         + 0.01092 * np.sin(m + f + n) + 0.00666 * np.sin(m - f)
         - 0.00644 * np.sin(m + f - 2 * dd + n) - 0.00331 * np.sin(f - 2 * dd + n)
         - 0.00304 * np.sin(f - 2 * dd) - 0.00240 * np.sin(m - f - 2 * dd - n)
         + 0.00226 * np.sin(m + f) - 0.00108 * np.sin(m + f - 2 * dd)
         - 0.00079 * np.sin(f - n) + 0.00078 * np.sin(f + 2 * dd + n))
    u = (1 - 0.10828 * np.cos(m) - 0.01880 * np.cos(m - 2 * dd) - 0.01479 * np.cos(2 * dd)
         + 0.00181 * np.cos(2 * m - 2 * dd) - 0.00147 * np.cos(2 * m)
         - 0.00105 * np.cos(2 * dd - g) - 0.00075 * np.cos(m - 2 * dd + g))
    w = (0.10478 * np.sin(m) - 0.04105 * np.sin(2 * f + 2 * n) - 0.02130 * np.sin(m - 2 * dd)
         - 0.01779 * np.sin(2 * f + n) + 0.01774 * np.sin(n) + 0.00987 * np.sin(2 * dd)
         - 0.00338 * np.sin(m - 2 * f - 2 * n) - 0.00309 * np.sin(g) - 0.00190 * np.sin(2 * f)
         - 0.00144 * np.sin(m + n) - 0.00144 * np.sin(m - 2 * f - n)
         - 0.00113 * np.sin(m + 2 * f + 2 * n) - 0.00094 * np.sin(m - 2 * dd + g)
         - 0.00092 * np.sin(2 * m - 2 * dd))
    s = w / np.sqrt(u - v * v)
    ra = (l + np.arcsin(s)) * R2D
    s = v / np.sqrt(u)
    dec = np.arcsin(s) * R2D
    dist = 60.40974 * np.sqrt(u) * 6378.14
    return np.mod(ra, 360.0), dec, dist   # NB: equatorial, not ecliptic


def horizontal(jd_ut, lat, lon, theory, coefs=None):
    """Topocentric azimuth / apparent altitude, exactly as moonComputeState does."""
    jd_ut = np.atleast_1d(np.asarray(jd_ut, dtype=float))
    jd_tt = jd_ut + delta_t(jd_ut) / 86400.0
    T = (jd_tt - 2451545.0) / 36525.0
    dpsi, deps = nutation(T)
    eps = mean_obliquity(T) + deps / 3600.0

    if theory is theory_1989:
        ra, dec, dist = theory_1989(jd_tt)
    else:
        lam, beta, dist = (theory(jd_tt, coefs) if coefs is not None else theory(jd_tt))
        lam = lam + dpsi / 3600.0
        bR, lR, eR = beta * D2R, lam * D2R, eps * D2R
        ra = np.mod(np.arctan2(np.sin(lR) * np.cos(eR) - np.tan(bR) * np.sin(eR),
                               np.cos(lR)) * R2D, 360.0)
        dec = np.arcsin(np.sin(bR) * np.cos(eR) + np.cos(bR) * np.sin(eR) * np.sin(lR)) * R2D

    parallax = np.arcsin(6378.14 / dist) * R2D
    Tu = (jd_ut - 2451545.0) / 36525.0
    gmst = np.mod(280.46061837 + 360.98564736629 * (jd_ut - 2451545.0)
                  + 0.000387933 * Tu ** 2 - Tu ** 3 / 38710000.0, 360.0)
    gast = gmst + (dpsi / 3600.0) * np.cos(eps * D2R)
    H = np.mod(gast + lon - ra, 360.0)

    latR = lat * D2R
    u = np.arctan2(0.99664719 * np.sin(latR), np.cos(latR))
    rsp, rcp = 0.99664719 * np.sin(u), np.cos(u)
    sinPi = np.sin(parallax * D2R)
    decR, HR = dec * D2R, H * D2R
    den = np.cos(decR) - rcp * sinPi * np.cos(HR)
    dRA = np.arctan2(-rcp * sinPi * np.sin(HR), den)
    decT = np.arctan2((np.sin(decR) - rsp * sinPi) * np.cos(dRA), den)
    hT = (H - dRA * R2D) * D2R
    alt = np.arcsin(np.sin(latR) * np.sin(decT) + np.cos(latR) * np.cos(decT) * np.cos(hT)) * R2D
    az = np.mod(180.0 + np.arctan2(np.cos(decT) * np.sin(hT),
                                   np.cos(decT) * np.cos(hT) * np.sin(latR)
                                   - np.sin(decT) * np.cos(latR)) * R2D, 360.0)
    return az, alt + refraction(alt)


def geocentric_radec(jd_ut, theory, coefs=None, use_tt=True):
    """Apparent geocentric RA/Dec (deg) and distance (km) for a lunar theory,
    with the app's nutation and obliquity."""
    jd_ut = np.atleast_1d(np.asarray(jd_ut, dtype=float))
    jd_tt = jd_ut + (delta_t(jd_ut) / 86400.0 if use_tt else 0.0)
    T = (jd_tt - 2451545.0) / 36525.0
    dpsi, deps = nutation(T)
    eps = mean_obliquity(T) + deps / 3600.0
    if theory is theory_1989:
        ra, dec, dist = theory_1989(jd_tt)
        return ra, dec, dist
    lam, beta, dist = (theory(jd_tt, coefs) if coefs is not None else theory(jd_tt))
    lam = lam + dpsi / 3600.0
    bR, lR, eR = beta * D2R, lam * D2R, eps * D2R
    ra = np.mod(np.arctan2(np.sin(lR) * np.cos(eR) - np.tan(bR) * np.sin(eR), np.cos(lR)) * R2D, 360.0)
    dec = np.arcsin(np.sin(bR) * np.cos(eR) + np.cos(bR) * np.sin(eR) * np.sin(lR)) * R2D
    return ra, dec, dist


def gast_deg(jd_ut):
    jd_ut = np.atleast_1d(np.asarray(jd_ut, dtype=float))
    jd_tt = jd_ut + delta_t(jd_ut) / 86400.0
    T = (jd_tt - 2451545.0) / 36525.0
    dpsi, deps = nutation(T)
    eps = mean_obliquity(T) + deps / 3600.0
    Tu = (jd_ut - 2451545.0) / 36525.0
    gmst = np.mod(280.46061837 + 360.98564736629 * (jd_ut - 2451545.0)
                  + 0.000387933 * Tu ** 2 - Tu ** 3 / 38710000.0, 360.0)
    return gmst + (dpsi / 3600.0) * np.cos(eps * D2R)


def horizon_func(jd_ut, lat, lon, theory, coefs=None, use_tt=True):
    """The Meeus/MoonRise rise-set discriminant: geocentric altitude minus
    (0.7275*parallax - 34'), zero at upper-limb rise/set."""
    ra, dec, dist = geocentric_radec(jd_ut, theory, coefs, use_tt)
    H = (gast_deg(jd_ut) + lon - ra) * D2R
    d = dec * D2R
    latR = lat * D2R
    alt = np.arcsin(np.sin(latR) * np.sin(d) + np.cos(latR) * np.cos(d) * np.cos(H)) * R2D
    par = np.arcsin(6378.14 / dist) * R2D
    return alt - (0.7275 * par - 0.5667)

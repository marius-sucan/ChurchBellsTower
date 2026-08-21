"""Moonrise / moonset: what MoonRise.cpp actually produces, against a DE440 reference."""
import numpy as np
import pipeline as P

D2R = np.pi / 180.0
R2D = 180.0 / np.pi


# ---------------------------------------------------------------- MoonRise.cpp
def _mr_moon(dayOffset):
    ra, dec, dist_km = P.theory_1989(np.atleast_1d(dayOffset) + 2451545.0)
    return ra[0] * D2R, dec[0] * D2R, dist_km[0] / 6378.14


def _lst(offsetDays, lon):
    rem = offsetDays - np.round(offsetDays)      # C remainder(): [-0.5, 0.5]
    x = (15.0 * (6.697374558 + 0.06570982441908 * offsetDays + rem * 24 + 12
                 + 0.000026 * (offsetDays / 36525) ** 2) + lon) / 360.0
    return (x - np.floor(x)) * 360.0


def _interp(f0, f1, f2, p):
    a = f1 - f0
    b = f2 - f1 - a
    return f0 + p * (2 * a + b * (2 * p - 1))


def moonrise_cpp(lat, lon, t_unix):
    """Faithful replica of MoonRise::calculate (24 h window, UT fed to the series)."""
    W = 24
    K1 = 15 * D2R * 1.0027379
    off = t_unix / 86400.0 + 2440587.5 - 2451545.0 - W / 48.0
    pos = [_mr_moon(off + i * W / 48.0) for i in range(3)]
    ra = [p[0] for p in pos]
    if ra[1] <= ra[0]:
        ra[1] += 2 * np.pi
    if ra[2] <= ra[1]:
        ra[2] += 2 * np.pi
    dec = [p[1] for p in pos]
    lst = _lst(off, lon) * D2R
    s, c = np.sin(lat * D2R), np.cos(lat * D2R)
    z = np.cos(D2R * (90.567 - 41.685 / pos[0][2]))
    rise = set_ = None
    ra0, dec0 = ra[0], dec[0]
    for k in range(W):
        ph = (k + 1) / W
        ra2 = _interp(ra[0], ra[1], ra[2], ph)
        dec2 = _interp(dec[0], dec[1], dec[2], ph)
        h0 = lst - ra0 + k * K1
        h2 = lst - ra2 + k * K1 + K1
        h1 = (h0 + h2) / 2
        d1 = (dec0 + dec2) / 2
        V0 = s * np.sin(dec0) + c * np.cos(dec0) * np.cos(h0) - z
        V2 = s * np.sin(dec2) + c * np.cos(dec2) * np.cos(h2) - z
        if np.signbit(V0) != np.signbit(V2):
            V1 = s * np.sin(d1) + c * np.cos(d1) * np.cos(h1) - z
            a = 2 * V2 - 4 * V1 + 2 * V0
            b = 4 * V1 - 3 * V0 - V2
            d = b * b - 4 * a * V0
            if d >= 0:
                d = np.sqrt(d)
                e = (-b + d) / (2 * a)
                if e < 0 or e > 1:
                    e = (-b - d) / (2 * a)
                tt = t_unix + (k + e + 1 / 120.0 - W / 2) * 3600.0
                if V0 < 0 < V2 and (rise is None or abs(tt - t_unix) < abs(rise - t_unix)):
                    rise = tt
                if V0 > 0 > V2 and (set_ is None or abs(tt - t_unix) < abs(set_ - t_unix)):
                    set_ = tt
        ra0, dec0 = ra2, dec2
    return rise, set_


# ---------------------------------------------------------------- reference
def alt_app(jd_ut, lat, lon, theory, coefs=None):
    return P.horizontal(jd_ut, lat, lon, theory, coefs)[1]


def events(jd0_ut, lat, lon, theory, coefs=None, step_min=4.0, h0=0.0):
    """All horizon crossings of the apparent (refracted) topocentric altitude in
    the 24 h from jd0_ut, refined by bisection to a millisecond."""
    n = int(24 * 60 / step_min) + 1
    grid = jd0_ut + np.arange(n) * (step_min / 1440.0)
    a = alt_app(grid, lat, lon, theory, coefs) - h0
    out = []
    sgn = np.signbit(a)
    for i in np.nonzero(sgn[:-1] != sgn[1:])[0]:
        lo, hi = grid[i], grid[i + 1]
        flo = a[i]
        for _ in range(40):
            mid = 0.5 * (lo + hi)
            fm = alt_app(np.array([mid]), lat, lon, theory, coefs)[0] - h0
            if np.signbit(fm) == np.signbit(flo):
                lo, flo = mid, fm
            else:
                hi = mid
        out.append((0.5 * (lo + hi), 'rise' if a[i] < 0 else 'set'))
    return out

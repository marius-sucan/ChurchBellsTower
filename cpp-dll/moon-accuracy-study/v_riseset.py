"""Moonrise and moonset out of the DLL, against DE440, twelve places, ninety days."""
import numpy as np, t_verify as V, pipeline as P, de440

D2R, R2D = np.pi/180.0, 180.0/np.pi


def sky(jd_ut):
    """Apparent RA/Dec/parallax and Greenwich apparent sidereal time from DE440."""
    jd_tt = jd_ut + P.delta_t(jd_ut)/86400.0
    T = (jd_tt - 2451545.0)/36525.0
    dpsi, deps = P.nutation(T)
    eps = P.mean_obliquity(T) + deps/3600.0
    lam, beta, dist = V.de440_lt(jd_tt)
    lam = lam + dpsi/3600.0
    bR, lR, eR = beta*D2R, lam*D2R, eps*D2R
    ra = np.mod(np.arctan2(np.sin(lR)*np.cos(eR) - np.tan(bR)*np.sin(eR), np.cos(lR))*R2D, 360.0)
    dec = np.arcsin(np.sin(bR)*np.cos(eR) + np.cos(bR)*np.sin(eR)*np.sin(lR))*R2D
    par = np.arcsin(6378.14/dist)*R2D
    Tu = (jd_ut - 2451545.0)/36525.0
    gmst = np.mod(280.46061837 + 360.98564736629*(jd_ut - 2451545.0)
                  + 0.000387933*Tu**2 - Tu**3/38710000.0, 360.0)
    return ra, dec, par, gmst + (dpsi/3600.0)*np.cos(eps*D2R)


def gap_from(ra, dec, par, gast, lat, lon, dip):
    H = (gast + lon - ra)*D2R
    latR = lat*D2R
    u = np.arctan2(0.99664719*np.sin(latR), np.cos(latR))
    rsp, rcp = 0.99664719*np.sin(u), np.cos(u)
    sp = np.sin(par*D2R)
    d = dec*D2R
    den = np.cos(d) - rcp*sp*np.cos(H)
    dRA = np.arctan2(-rcp*sp*np.sin(H), den)
    decT = np.arctan2((np.sin(d) - rsp*sp)*np.cos(dRA), den)
    hT = H - dRA
    alt = np.arcsin(np.sin(latR)*np.sin(decT) + np.cos(latR)*np.cos(decT)*np.cos(hT))*R2D
    return alt + 0.2725*par + 0.5667 + dip


def crossings(day_jd, lat, lon, dip=0.0, n=2881):
    """Rise and set inside [day_jd, day_jd+1), in seconds from its start, or None."""
    t = day_jd + np.linspace(0.0, 1.0, n)
    ra, dec, par, gast = sky(t)
    g = gap_from(ra, dec, par, gast, lat, lon, dip)
    idx = np.nonzero(np.diff(np.signbit(g)))[0]
    out = {}
    for i in idx:
        a, b = t[i], t[i+1]
        fa, fb = g[i], g[i+1]
        for _ in range(45):
            m = 0.5*(a + b)
            ra2, de2, pa2, ga2 = sky(np.array([m]))
            fm = gap_from(ra2, de2, pa2, ga2, lat, lon, dip)[0]
            if (fm < 0) == (fa < 0):
                a, fa = m, fm
            else:
                b, fb = m, fm
            if (b - a)*86400.0 < 0.002:
                break
        kind = 'rise' if g[i+1] > g[i] else 'set'
        out.setdefault(kind, (0.5*(a + b) - day_jd)*86400.0)
    return out


def report(dip_height=0.0, ndays=90, label=''):
    rng = np.random.default_rng(7)
    days = 2451545.0 + 25*365.25 + np.floor(rng.uniform(0, 3650, ndays)) + 0.5
    dip = 0.029333*np.sqrt(dip_height) if dip_height else 0.0
    print(f'\nMoonrise / moonset, DLL vs DE440{label}   (seconds)')
    print(f"  {'site':<12}{'lat':>7}{'n':>5}{'rms':>9}{'p95':>9}{'max':>9}")
    allerr = []
    for name, lat, lon in V.SITES:
        rows = [(V.unix_of(d), 86400.0, lat, lon, dip_height) for d in days]
        got = V.run('riseset', rows)
        err = []
        for (d, row) in zip(days, got):
            ref = crossings(d, lat, lon, dip)
            for k, col in (('rise', 0), ('set', 1)):
                if k in ref and row[col] >= 0:
                    err.append(row[col] - ref[k])
                elif (k in ref) != (row[col] >= 0):
                    err.append(np.nan)
        e = np.array(err)
        miss = int(np.isnan(e).sum())
        e = e[~np.isnan(e)]
        allerr.append(e)
        extra = f'   ({miss} unmatched)' if miss else ''
        print(f'  {name:<12}{lat:7.1f}{len(e):5d}{np.sqrt((e**2).mean()):9.3f}'
              f'{np.percentile(np.abs(e),95):9.3f}{np.abs(e).max():9.3f}{extra}')
    e = np.concatenate(allerr)
    print(f"  {'ALL':<12}{'':>7}{len(e):5d}{np.sqrt((e**2).mean()):9.3f}"
          f'{np.percentile(np.abs(e),95):9.3f}{np.abs(e).max():9.3f}')


if __name__ == '__main__':
    report()
    report(300.0, 40, ', observer 300 m up')

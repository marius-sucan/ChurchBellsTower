"""Drive the rebuilt DLL and lay its answers beside JPL DE440."""
import numpy as np, subprocess, de440, pipeline as P

D2R, R2D = np.pi/180.0, 180.0/np.pi
C_KM_S = 299792.458
DLL = './t_dll'


def run(mode, rows):
    inp = '\n'.join(' '.join('%.9f' % v for v in r) for r in rows)
    out = subprocess.run([DLL, mode], input=inp, capture_output=True, text=True)
    if out.returncode:
        raise RuntimeError(out.stderr)
    return np.array([[float(v) for v in ln.split()] for ln in out.stdout.split('\n') if ln.strip()])


def jd_of(unix):
    return unix/86400.0 + 2440587.5


def unix_of(jd):
    return (jd - 2440587.5)*86400.0


# ---- DE440 with the light time taken off, which is what the DLL reports -----
def de440_lt(jd_tt):
    jd = np.atleast_1d(np.asarray(jd_tt, float))
    v = de440.moon_geocentric_icrf(jd)
    tau = np.sqrt((v**2).sum(0))/C_KM_S/86400.0
    v = de440.moon_geocentric_icrf(jd - tau)
    return P._to_date(*de440.eq_to_ecl_j2000(v, eps0_arcsec=84381.406), (jd - 2451545.0)/36525.0)


def topo(jd_ut, lat, lon, theory):
    """Geometric topocentric altitude, azimuth and horizontal parallax."""
    jd_ut = np.atleast_1d(np.asarray(jd_ut, float))
    jd_tt = jd_ut + P.delta_t(jd_ut)/86400.0
    T = (jd_tt - 2451545.0)/36525.0
    dpsi, deps = P.nutation(T)
    eps = P.mean_obliquity(T) + deps/3600.0
    lam, beta, dist = theory(jd_tt)
    lam = lam + dpsi/3600.0
    bR, lR, eR = beta*D2R, lam*D2R, eps*D2R
    ra = np.mod(np.arctan2(np.sin(lR)*np.cos(eR) - np.tan(bR)*np.sin(eR), np.cos(lR))*R2D, 360.0)
    dec = np.arcsin(np.sin(bR)*np.cos(eR) + np.cos(bR)*np.sin(eR)*np.sin(lR))*R2D
    par = np.arcsin(6378.14/dist)*R2D
    Tu = (jd_ut - 2451545.0)/36525.0
    gmst = np.mod(280.46061837 + 360.98564736629*(jd_ut - 2451545.0)
                  + 0.000387933*Tu**2 - Tu**3/38710000.0, 360.0)
    gast = gmst + (dpsi/3600.0)*np.cos(eps*D2R)
    H = np.mod(gast + lon - ra, 360.0)
    latR = lat*D2R
    u = np.arctan2(0.99664719*np.sin(latR), np.cos(latR))
    rsp, rcp = 0.99664719*np.sin(u), np.cos(u)
    sinPi = np.sin(par*D2R)
    decR, HR = dec*D2R, H*D2R
    den = np.cos(decR) - rcp*sinPi*np.cos(HR)
    dRA = np.arctan2(-rcp*sinPi*np.sin(HR), den)
    decT = np.arctan2((np.sin(decR) - rsp*sinPi)*np.cos(dRA), den)
    hT = (H - dRA*R2D)*D2R
    alt = np.arcsin(np.sin(latR)*np.sin(decT) + np.cos(latR)*np.cos(decT)*np.cos(hT))*R2D
    az = np.mod(180.0 + np.arctan2(np.cos(decT)*np.sin(hT),
                np.cos(decT)*np.cos(hT)*np.sin(latR) - np.sin(decT)*np.cos(latR))*R2D, 360.0)
    return az, alt, par


def gap(jd_ut, lat, lon, theory, dip=0.0):
    az, alt, par = topo(jd_ut, lat, lon, theory)
    return alt + 0.2725*par + 0.5667 + dip


SITES = [('Bucharest', 44.43, 26.10), ('London', 51.51, -0.13), ('Reykjavik', 64.13, -21.90),
         ('Quito', -0.18, -78.47), ('Sydney', -33.87, 151.21), ('Cape Town', -33.92, 18.42),
         ('Anchorage', 61.22, -149.90), ('Singapore', 1.35, 103.82), ('Tromso', 69.65, 18.96),
         ('Ushuaia', -54.80, -68.30), ('New York', 40.71, -74.01), ('Tokyo', 35.68, 139.65)]

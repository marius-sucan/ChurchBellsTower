import numpy as np, t_verify as V, pipeline as P
D2R = np.pi/180.0
rng = np.random.default_rng(11)
jd_ut = 2451545.0 + rng.uniform(25*365.25, 35*365.25, 3000)
lat, lon = 44.43, 26.10

got = V.run('place', [(V.unix_of(j), lat, lon) for j in jd_ut])
az_d, altapp_d, lam_d, bet_d, dist_d, par_d, illum_d, ph_d, age_d, id_d, alt_d = got.T

az_r, alt_r, par_r = V.topo(jd_ut, lat, lon, V.de440_lt)
jd_tt = jd_ut + P.delta_t(jd_ut)/86400.0
lam_r, bet_r, dist_r = V.de440_lt(jd_tt)
dpsi, _ = P.nutation((jd_tt - 2451545.0)/36525.0)
lam_r = np.mod(lam_r + dpsi/3600.0, 360.0)

def rms(x): return float(np.sqrt(np.mean(x**2)))
m = alt_r > 0
dl = (np.mod(lam_d - lam_r + 180, 360) - 180)*3600
db = (bet_d - bet_r)*3600
dd = dist_d - dist_r
daz = ((az_d - az_r + 180) % 360 - 180)*3600*np.cos(alt_r*D2R)
dal = (alt_d - alt_r)*3600
print('DLL vs DE440, 3000 instants 2025-2035, Bucharest      rms / max')
print(f'  apparent longitude   {rms(dl):8.3f}" / {np.abs(dl).max():7.3f}"')
print(f'  apparent latitude    {rms(db):8.3f}" / {np.abs(db).max():7.3f}"')
print(f'  distance             {rms(dd):8.3f}  / {np.abs(dd).max():7.3f} km')
print(f'  azimuth   (moon up)  {rms(daz[m]):8.3f}" / {np.abs(daz[m]).max():7.3f}"')
print(f'  altitude  (moon up)  {rms(dal[m]):8.3f}" / {np.abs(dal[m]).max():7.3f}"')

# illuminated fraction
import de440
# apparent sun as well: light time off it is what its aberration constant stands for
sv = de440.sun_geocentric_icrf(jd_tt)
tau = np.sqrt((sv**2).sum(0))/299792.458/86400.0
vs = de440.eq_to_ecl_j2000(de440.sun_geocentric_icrf(jd_tt - tau), eps0_arcsec=84381.406)
ls, bs, rs = P._to_date(vs[0], vs[1], vs[2], (jd_tt - 2451545.0)/36525.0)
el = np.arccos(np.cos(bet_r*D2R)*np.cos((lam_r - dpsi/3600.0 - ls)*D2R))
pa = np.arctan2(rs*np.sin(el), dist_r - rs*np.cos(el))
f0 = 100.0*(1 + np.cos(pa))/2.0
d = illum_d - f0
print(f'  illuminated fraction {rms(d):8.5f}  / {np.abs(d).max():7.5f} percentage points')

print(f'  (mean bias on the fraction {d.mean():+.5f} pt)')
# phase name and age
print(f'  phase (fraction of the lunation) rms {rms(np.mod(ph_d - np.mod((lam_r - dpsi/3600.0 - ls)/360.0, 1.0) + 0.5, 1.0) - 0.5)*29.53*86400:.2f} s equivalent')

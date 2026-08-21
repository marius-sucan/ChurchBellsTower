"""Is the ELP longitude referable to the mean equinox of date by a single
polynomial in T?  Compare V + p(T) against the validated two-rotation route."""
import numpy as np, elp, pipeline as P

R2D = 180.0/np.pi
AS  = 3600.0*R2D

p, c = elp.load_coefs(0)
# 1500-2600, dense
T = np.linspace(-5.0, 6.0, 4001)
lonI, latI, r = elp.moon_lbr(T, p, c)          # inertial ecliptic of date
X, Y, Z = elp.moon_x2000(T, p, c)
lamD, betD, rD = P._to_date(X, Y, Z, T)        # mean ecliptic AND equinox of date

d = np.mod(lamD - lonI*R2D + 180.0, 360.0) - 180.0
print("lambda_date - V  (degrees): min %.6f max %.6f" % (d.min(), d.max()))
# fit a polynomial in T
for deg in (1,2,3,4):
    co = np.polyfit(T, d*3600.0, deg)
    res = d*3600.0 - np.polyval(co, T)
    print(" deg %d  resid rms %8.5f\"  max %8.5f\"   coeffs(as) %s"
          % (deg, np.sqrt((res**2).mean()), np.abs(res).max(),
             ' '.join('%.6f' % v for v in co[::-1])))

db = (betD - latI*R2D)*3600.0
print("beta_date - U   (arcsec): rms %.6f max %.6f" % (np.sqrt((db**2).mean()), np.abs(db).max()))
dr = rD - r
print("r_date  - r     (km):     rms %.3g max %.3g" % (np.sqrt((dr**2).mean()), np.abs(dr).max()))

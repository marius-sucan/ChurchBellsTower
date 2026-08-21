"""DE440 ground truth: geocentric Moon vector, and rotations between frames."""
import numpy as np
from jplephem.spk import SPK

_kernel = SPK.open('de440s.bsp')
AS = np.pi / 648000.0


def moon_geocentric_icrf(jd_tdb):
    """Geocentric Moon position, ICRF equatorial, km.  (3, n)."""
    jd = np.atleast_1d(np.asarray(jd_tdb, dtype=float))
    moon_emb = _kernel[3, 301].compute(jd)[:3]
    earth_emb = _kernel[3, 399].compute(jd)[:3]
    return moon_emb - earth_emb


def sun_geocentric_icrf(jd_tdb):
    jd = np.atleast_1d(np.asarray(jd_tdb, dtype=float))
    sun_ssb = _kernel[0, 10].compute(jd)[:3]
    emb_ssb = _kernel[0, 3].compute(jd)[:3]
    earth_emb = _kernel[3, 399].compute(jd)[:3]
    return sun_ssb - (emb_ssb + earth_emb)


def frame_bias_matrix():
    """IAU 2006 frame bias: ICRS -> J2000.0 mean equator and equinox."""
    dpsi_b = -0.041775 * AS
    deps_b = -0.0068192 * AS
    dra0 = -0.0146 * AS
    # first order is good to ~1e-12 rad here
    return np.array([[1.0, dra0, -dpsi_b * np.sin(84381.448 * AS)],
                     [-dra0, 1.0, -deps_b],
                     [dpsi_b * np.sin(84381.448 * AS), deps_b, 1.0]])


def eq_to_ecl_j2000(v, eps0_arcsec=84381.448):
    """ICRF equatorial -> J2000 mean ecliptic (the frame ELP's getX2000 uses)."""
    e = eps0_arcsec * AS
    B = frame_bias_matrix()
    v = B @ v
    R = np.array([[1, 0, 0], [0, np.cos(e), np.sin(e)], [0, -np.sin(e), np.cos(e)]])
    return R @ v


def laskar_PQ(T):
    T2, T3, T4, T5 = T ** 2, T ** 3, T ** 4, T ** 5
    P = 0.10180391e-4 * T + 0.47020439e-6 * T2 - 0.5417367e-9 * T3 - 0.2507948e-11 * T4 + 0.463486e-14 * T5
    Q = -0.113469002e-3 * T + 0.12372674e-6 * T2 + 0.12654170e-8 * T3 - 0.1371808e-11 * T4 - 0.320334e-14 * T5
    return P, Q


def ecl_date_to_j2000(x0, y0, z0, T):
    """The rotation ELP applies: mean ecliptic/equinox of date -> J2000."""
    P, Q = laskar_PQ(T)
    sq = np.sqrt(1 - P * P - Q * Q)
    X = (1 - 2 * P * P) * x0 + (2 * P * Q) * y0 + (2 * P * sq) * z0
    Y = (2 * P * Q) * x0 + (1 - 2 * Q * Q) * y0 + (-2 * Q * sq) * z0
    Z = (-2 * P * sq) * x0 + (2 * Q * sq) * y0 + (1 - 2 * P * P - 2 * Q * Q) * z0
    return X, Y, Z


def j2000_to_ecl_date(X, Y, Z, T):
    """Inverse of the above (the matrix is orthogonal)."""
    P, Q = laskar_PQ(T)
    sq = np.sqrt(1 - P * P - Q * Q)
    M = np.array([[1 - 2 * P * P, 2 * P * Q, 2 * P * sq],
                  [2 * P * Q, 1 - 2 * Q * Q, -2 * Q * sq],
                  [-2 * P * sq, 2 * Q * sq, 1 - 2 * P * P - 2 * Q * Q]])
    # M is per-epoch; do it elementwise
    x = M[0, 0] * X + M[1, 0] * Y + M[2, 0] * Z
    y = M[0, 1] * X + M[1, 1] * Y + M[2, 1] * Z
    z = M[0, 2] * X + M[1, 2] * Y + M[2, 2] * Z
    return x, y, z


def to_lbr(x, y, z):
    r = np.sqrt(x * x + y * y + z * z)
    return np.arctan2(y, x), np.arcsin(z / r), r

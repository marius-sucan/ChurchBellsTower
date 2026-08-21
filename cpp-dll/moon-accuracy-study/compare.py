import numpy as np
import elp, meeus47, de440

AS = 180.0 * 3600.0 / np.pi   # radians -> arcsec


def sample_jd(y0, y1, n, seed=1):
    rng = np.random.default_rng(seed)
    return np.sort(rng.uniform(2451545.0 + (y0 - 2000.0) * 365.25,
                               2451545.0 + (y1 - 2000.0) * 365.25, n))


def meeus_x2000(jd):
    """Meeus ch.47 lambda/beta (mean equinox of date) rotated back to J2000 with
    the ecliptic precession of Meeus ch.21, so it can be laid beside ELP and DE."""
    lam, beta, r = meeus47.moon_lbr(jd)
    T = (jd - 2451545.0) / 36525.0
    t = -T   # from the date back to J2000: reverse the interval
    T0 = T
    # Meeus 21.5, reduction from the equinox of date (T0) to J2000 (t = -T0)
    eta = ((47.0029 - 0.06603 * T0 + 0.000598 * T0 ** 2) * t
           + (-0.03302 + 0.000598 * T0) * t ** 2 + 0.000060 * t ** 3) / 3600.0
    Pi = (174.876384 * 3600.0 + 3289.4789 * T0 + 0.60622 * T0 ** 2
          - (869.8089 + 0.50491 * T0) * t + 0.03536 * t ** 2) / 3600.0
    p = ((5029.0966 + 2.22226 * T0 - 0.000042 * T0 ** 2) * t
         + (1.11113 - 0.000042 * T0) * t ** 2 - 0.000006 * t ** 3) / 3600.0
    d2r = np.pi / 180.0
    b = beta * d2r
    A = np.cos(eta * d2r) * np.cos(b) * np.sin((Pi - lam) * d2r) - np.sin(eta * d2r) * np.sin(b)
    B = np.cos(b) * np.cos((Pi - lam) * d2r)
    C = np.cos(eta * d2r) * np.sin(b) + np.sin(eta * d2r) * np.cos(b) * np.sin((Pi - lam) * d2r)
    lam2 = (p + Pi) - np.degrees(np.arctan2(A, B))
    beta2 = np.degrees(np.arcsin(C))
    lr, br = np.radians(lam2), np.radians(beta2)
    return r * np.cos(br) * np.cos(lr), r * np.cos(br) * np.sin(lr), r * np.sin(br)


def diffs(X, Y, Z, truth):
    """Along-ecliptic and across-ecliptic angular differences, in arcsec, plus dr in km."""
    r = np.sqrt(X * X + Y * Y + Z * Z)
    lam, beta = np.arctan2(Y, X), np.arcsin(Z / r)
    tr = np.sqrt((truth ** 2).sum(axis=0))
    tlam, tbeta = np.arctan2(truth[1], truth[0]), np.arcsin(truth[2] / tr)
    dl = ((lam - tlam + np.pi) % (2 * np.pi) - np.pi) * np.cos(tbeta) * AS
    db = (beta - tbeta) * AS
    return dl, db, r - tr


def line(name, dl, db, dr):
    sep = np.hypot(dl, db)
    print(f"  {name:<38} dlam {rms(dl):9.4f} / {np.abs(dl).max():9.3f}   "
          f"dbeta {rms(db):8.4f} / {np.abs(db).max():8.3f}   "
          f"sep max {sep.max():9.3f}   dr {rms(dr):9.4f} / {np.abs(dr).max():9.3f} km")


def rms(x):
    return float(np.sqrt(np.mean(np.asarray(x) ** 2)))


def elp_chunked(jd, p, c, chunk=250):
    Xs, Ys, Zs = [], [], []
    for i in range(0, len(jd), chunk):
        T = (jd[i:i + chunk] - 2451545.0) / 36525.0
        X, Y, Z = elp.moon_x2000(T, p, c)
        Xs.append(X); Ys.append(Y); Zs.append(Z)
    return np.concatenate(Xs), np.concatenate(Ys), np.concatenate(Zs)


def trim(c, thr_arcsec, thr_km):
    thr_rad = thr_arcsec / AS
    out, n = {}, 0
    for k, s in c.items():
        st, cnt = s.trim(thr_km if 'dist' in k else thr_rad)
        out[k] = st
        n += cnt
    return out, n


def run(y0, y1, n=2000, label=''):
    jd = sample_jd(y0, y1, n)
    truth = de440.eq_to_ecl_j2000(de440.moon_geocentric_icrf(jd))
    print(f"\n===== {label or f'{y0}-{y1}'}, n={n}, vs DE440, J2000 mean ecliptic; "
          f"columns are rms / max, arcsec =====")

    X, Y, Z = meeus_x2000(jd)
    line('Meeus ch.47 (what ships today)', *diffs(X, Y, Z, truth))

    for corr, tag in ((1, 'DE405/406 fit'), (0, 'LLR fit')):
        p, c = elp.load_coefs(corr)
        line(f'ELP/MPP02 full, 35901 terms [{tag}]', *diffs(*elp_chunked(jd, p, c), truth))

    p, c = elp.load_coefs(1)
    print()
    for thr_as, thr_km in [(3.0, 6.0), (1.0, 2.0), (0.3, 0.6), (0.1, 0.2),
                           (0.03, 0.06), (0.01, 0.02), (0.003, 0.006), (0.001, 0.002)]:
        ct, cnt = trim(c, thr_as, thr_km)
        line(f'ELP/MPP02 cut at {thr_as}" -> {cnt} terms', *diffs(*elp_chunked(jd, p, ct), truth))


if __name__ == '__main__':
    run(1900, 2100, 2000, '1900-2100')
    run(2020, 2040, 2000, '2020-2040')

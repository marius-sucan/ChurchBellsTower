import numpy as np
import pipeline as P
import riseset as RS
import compare as C

SITES = [('Bucharest', 44.43, 26.10), ('London', 51.51, -0.13), ('Reykjavik', 64.14, -21.94),
         ('Quito', -0.18, -78.47), ('Sydney', -33.87, 151.21), ('Cape Town', -33.92, 18.42),
         ('Anchorage', 61.22, -149.90), ('Singapore', 1.35, 103.82),
         ('Tromso', 69.65, 18.96), ('Ushuaia', -54.80, -68.30),
         ('New York', 40.71, -74.01), ('Tokyo', 35.68, 139.69)]

STEP_MIN = 1.0


def crossings(jd0, lat, lon, theory, coefs=None, use_tt=True):
    """Horizon crossings in [jd0, jd0+1), from a one-minute grid refined by cubic
    inverse interpolation (residual well under 0.01 s for the moon)."""
    n = int(24 * 60 / STEP_MIN) + 3
    grid = jd0 + (np.arange(n) - 1) * (STEP_MIN / 1440.0)
    f = P.horizon_func(grid, lat, lon, theory, coefs, use_tt)
    out = []
    s = np.signbit(f)
    for i in np.nonzero(s[1:-2] != s[2:-1])[0] + 1:
        y = f[i - 1:i + 3]
        x = np.arange(-1.0, 3.0)
        # invert locally: solve the cubic through the four samples for f = 0
        cpoly = np.polyfit(x, y, 3)
        roots = np.roots(cpoly)
        roots = [r.real for r in roots if abs(r.imag) < 1e-9 and -0.001 <= r.real <= 1.001]
        if not roots:
            continue
        t = grid[i] + roots[0] * (STEP_MIN / 1440.0)
        out.append((t, 'rise' if f[i] < 0 else 'set'))
    return out


def match(a, b, tol_min=60.0):
    pairs = []
    for t, k in a:
        cands = [(abs(t2 - t) * 1440.0, t2) for t2, k2 in b if k2 == k]
        if cands:
            d, t2 = min(cands)
            if d < tol_min:
                pairs.append((t, t2, k))
    return pairs


def run(n_days=90, seed=7):
    rng = np.random.default_rng(seed)
    jd0s = 2451545.0 + 25.0 * 365.25 + np.floor(rng.uniform(0, 3650, n_days)) + 0.5
    p, c = P._ensure_elp()
    trims = {'375': C.trim(c, 0.1, 0.2)[0], '1036': C.trim(c, 0.01, 0.02)[0],
             '1824': C.trim(c, 0.003, 0.006)[0]}
    theories = [
        ('MoonRise.cpp as the DLL runs it', 'cpp', None, None),
        ('  ... its VF&P 1979 series alone, solved exactly, TT', 'th', P.theory_1989, (None, True)),
        ('  ... same series but UT fed as TT (the DLL does this)', 'th', P.theory_1989, (None, False)),
        ('Meeus ch.47 (the DLL\'s other moon), solved exactly', 'th', P.theory_meeus, (None, True)),
        ('ELP/MPP02 375-term cut, solved exactly', 'th', P.theory_elp, (trims['375'], True)),
        ('ELP/MPP02 1036-term cut, solved exactly', 'th', P.theory_elp, (trims['1036'], True)),
        ('ELP/MPP02 1824-term cut, solved exactly', 'th', P.theory_elp, (trims['1824'], True)),
    ]
    errs = {t[0]: [] for t in theories}
    for name, lat, lon in SITES:
        for jd0 in jd0s:
            ref = crossings(jd0, lat, lon, P.theory_de440)
            if not ref:
                continue
            for label, kind, th, spec in theories:
                if kind == 'cpp':
                    t_unix = (jd0 + 0.5 - 2440587.5) * 86400.0
                    r, s = RS.moonrise_cpp(lat, lon, t_unix)
                    got = ([(r / 86400.0 + 2440587.5, 'rise')] if r else []) + \
                          ([(s / 86400.0 + 2440587.5, 'set')] if s else [])
                else:
                    got = crossings(jd0, lat, lon, th, spec[0], spec[1])
                for t1, t2, kind2 in match(ref, got):
                    errs[label].append((t2 - t1) * 86400.0)

    print(f"\nMoonrise / moonset against DE440 -- {len(SITES)} sites x {n_days} days in 2025-2035")
    print(f"{'':<56}{'n':>6}{'rms s':>9}{'p95 s':>9}{'max s':>9}")
    for label, *_ in theories:
        v = np.array(errs[label])
        if not len(v):
            print(f"  {label:<54} (none)")
            continue
        print(f"  {label:<54}{len(v):6d}{np.sqrt((v**2).mean()):9.1f}"
              f"{np.percentile(np.abs(v),95):9.1f}{np.abs(v).max():9.1f}")


if __name__ == '__main__':
    run()

"""getMoonNoon against DE440, and the legacy window function against the day one."""
import numpy as np, t_verify as V, v_riseset as R, pipeline as P
D2R = np.pi/180.0

rng = np.random.default_rng(21)
days = 2451545.0 + 25*365.25 + np.floor(rng.uniform(0, 3650, 40)) + 0.5

# ---- transit: the DLL's highest point vs a fine DE440 search ----------------
for name, lat, lon in V.SITES[:6]:
    rows = [(V.unix_of(d), lat, lon) for d in days]
    got = V.run('noon', rows)
    dt, dalt = [], []
    for d, row in zip(days, got):
        t = d + np.linspace(0, 1, 2881)
        ra, dec, par, gast = R.sky(t)
        g = R.gap_from(ra, dec, par, gast, lat, lon, 0.0)   # altitude + constants
        i = int(np.argmax(g))
        a, b = t[max(i-1,0)], t[min(i+1,2880)]
        for _ in range(60):                                  # golden section
            c = b - 0.6180339887*(b-a); e = a + 0.6180339887*(b-a)
            gc = R.gap_from(*R.sky(np.array([c])), lat, lon, 0.0)[0]
            ge = R.gap_from(*R.sky(np.array([e])), lat, lon, 0.0)[0]
            if gc > ge: b = e
            else: a = c
            if (b-a)*86400 < 0.01: break
        peak = 0.5*(a+b)
        dt.append((row[0]*60.0/86400.0 + d - peak)*86400.0)
        gp = R.gap_from(*R.sky(np.array([peak])), lat, lon, 0.0)[0] - 0.5667
        _, alt, par2 = V.topo(np.array([peak]), lat, lon, V.de440_lt)
        dalt.append((row[2] - (alt[0] + P.refraction(alt[0])))*3600.0)
    dt, dalt = np.array(dt), np.array(dalt)
    print(f'  transit {name:<11} time rms {np.sqrt((dt**2).mean()):6.3f} s  max {np.abs(dt).max():6.3f} s   '
          f'altitude rms {np.sqrt((dalt**2).mean()):6.3f}" max {np.abs(dalt).max():6.3f}"')

# ---- the legacy 24-hour window against the day function --------------------
print('\nLegacy getSunMoonRiseSet against getMoonRiseSetDay (same events, seconds)')
bad = 0; diffs = []
for name, lat, lon in V.SITES:
    for d in days[:20]:
        t0 = V.unix_of(d)
        day = V.run('riseset', [(t0, 86400.0, lat, lon, 0.0)])[0]
        # ask the legacy call at the middle of the day: its window is that day +- 12h
        leg = V.run('legacy', [(t0 + 43200.0, t0, lat, lon)])[0]
        for col, lc in ((0, 0), (1, 1)):
            if day[col] >= 0:
                if leg[lc] > 999998:
                    bad += 1
                else:
                    diffs.append(leg[lc]*3600.0 - day[col])
diffs = np.array(diffs)
print(f'  {len(diffs)} events matched, {bad} the window did not see;'
      f' worst disagreement {np.abs(diffs).max()*1000:.3f} ms')

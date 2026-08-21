"""The rise/set the old DLL gave, against the same DE440 reference."""
import numpy as np, subprocess, t_verify as V, v_riseset as R

rng = np.random.default_rng(7)
days = 2451545.0 + 25*365.25 + np.floor(rng.uniform(0, 3650, 90)) + 0.5

def old(rows):
    inp = '\n'.join(' '.join('%.9f' % v for v in r) for r in rows)
    o = subprocess.run(['./t_old', 'legacy'], input=inp, capture_output=True, text=True).stdout
    return np.array([[float(v) for v in ln.split()] for ln in o.split('\n') if ln.strip()])

print('Moonrise / moonset, OLD DLL (MoonRise.cpp) vs DE440   (seconds)')
print(f"  {'site':<12}{'lat':>7}{'n':>5}{'rms':>9}{'p95':>9}{'max':>9}{'':>6}")
alle, miss_total = [], 0
for name, lat, lon in V.SITES:
    t0 = np.array([V.unix_of(d) for d in days])
    got = old([(a + 43200.0, a, lat, lon) for a in t0])
    err, miss = [], 0
    for d, row in zip(days, got):
        ref = R.crossings(d, lat, lon)
        for k, col in (('rise', 0), ('set', 1)):
            here = row[col] < 999998
            if k in ref and here:
                err.append(row[col]*3600.0 - ref[k])
            elif (k in ref) != here:
                miss += 1
    e = np.array(err); alle.append(e); miss_total += miss
    extra = f'   ({miss} unmatched)' if miss else ''
    print(f'  {name:<12}{lat:7.1f}{len(e):5d}{np.sqrt((e**2).mean()):9.1f}'
          f'{np.percentile(np.abs(e),95):9.1f}{np.abs(e).max():9.1f}{extra}')
e = np.concatenate(alle)
print(f"  {'ALL':<12}{'':>7}{len(e):5d}{np.sqrt((e**2).mean()):9.1f}"
      f'{np.percentile(np.abs(e),95):9.1f}{np.abs(e).max():9.1f}   ({miss_total} unmatched)')

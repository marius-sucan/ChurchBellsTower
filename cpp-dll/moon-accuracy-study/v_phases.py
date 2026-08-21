import numpy as np, subprocess, t_verify as V, phases

k0, k1 = 290, 420
names = ['new moon', 'first quarter', 'full moon', 'last quarter']
rows = [(k, w) for k in range(k0, k1) for w in range(4)]
import subprocess as SP
inp = '\n'.join('%d %d' % r for r in rows)
got = np.array([float(x) for x in SP.run(['./t_dll','phaseinstant'], input=inp,
                capture_output=True, text=True).stdout.split()])

errs = {n: [] for n in names}
old  = {n: [] for n in names}
for (k, w), jde in zip(rows, got):
    ref = phases.phase_instant_de440(jde, w*90.0)
    errs[names[w]].append((jde - ref)*86400.0)
    old[names[w]].append((phases.moon_phase_jde(float(k), w) - ref)*86400.0)

print(f'Instants of the four phases vs a DE440 root-find, k = {k0}..{k1} (2023-2033)')
print(f"  {'phase':<16}{'DLL mean':>10}{'rms':>9}{'max':>9}     {'ch.49 mean':>11}{'rms':>9}{'max':>9}")
alln, allo = [], []
for n in names:
    v, o = np.array(errs[n]), np.array(old[n])
    alln.append(v); allo.append(o)
    print(f'  {n:<16}{v.mean():+10.3f}{np.sqrt((v**2).mean()):9.3f}{np.abs(v).max():9.3f}     '
          f'{o.mean():+11.2f}{np.sqrt((o**2).mean()):9.2f}{np.abs(o).max():9.2f}')
v, o = np.concatenate(alln), np.concatenate(allo)
print(f'  {"all":<16}{v.mean():+10.3f}{np.sqrt((v**2).mean()):9.3f}{np.abs(v).max():9.3f}     '
      f'{o.mean():+11.2f}{np.sqrt((o**2).mean()):9.2f}{np.abs(o).max():9.2f}')

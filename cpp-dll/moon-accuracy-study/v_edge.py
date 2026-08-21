import numpy as np, t_verify as V, v_riseset as R

print('Polar edge cases (rise/set seconds from the day start, -1 = no crossing)')
for name, lat, lon, d0 in [('Tromso winter', 69.65, 18.96, '2026-01-05'),
                           ('Tromso summer', 69.65, 18.96, '2026-06-20'),
                           ('Alert  (82N)',  82.50, -62.35, '2026-02-10'),
                           ('South Pole',   -89.99, 0.0,    '2026-03-15'),
                           ('North Pole',    89.99, 0.0,    '2026-09-05')]:
    import datetime
    dt = datetime.datetime.strptime(d0, '%Y-%m-%d').replace(tzinfo=datetime.timezone.utc)
    t0 = dt.timestamp()
    day = V.jd_of(t0)
    for k in range(6):
        got = V.run('riseset', [(t0 + k*86400.0, 86400.0, lat, lon, 0.0)])[0]
        ref = R.crossings(day + k, lat, lon)
        r = ref.get('rise', -1.0); s = ref.get('set', -1.0)
        agree = 'ok' if (abs(got[0] - r) < 1.0 and abs(got[1] - s) < 1.0) else 'MISMATCH'
        print(f'  {name:<14} +{k}d   DLL {got[0]:9.1f} {got[1]:9.1f}   DE440 {r:9.1f} {s:9.1f}   {agree}')

print('\nDaylight-saving day lengths, Bucharest (span given to the DLL)')
for span in (82800.0, 86400.0, 90000.0):
    got = V.run('riseset', [(1774486800.0, span, 44.43, 26.10, 0.0)])[0]
    print(f'  span {span:8.0f} s   rise {got[0]:9.1f}   set {got[1]:9.1f}')

print('\nFar dates, Bucharest (a sanity check that nothing blows up)')
for y, t0 in (('1900', -2208988800.0), ('1950', -631152000.0),
              ('2100', 4102444800.0), ('2200', 7258118400.0)):
    got = V.run('riseset', [(t0, 86400.0, 44.43, 26.10, 0.0)])[0]
    pl = V.run('place', [(t0, 44.43, 26.10)])[0]
    print(f'  {y}   rise {got[0]:8.1f}  set {got[1]:8.1f}   lambda {pl[2]:8.3f}  dist {pl[4]:9.1f} km  illum {pl[6]:6.2f}%')

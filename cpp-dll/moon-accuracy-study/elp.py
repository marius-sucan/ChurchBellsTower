"""ELP/MPP02 in numpy, written from the equations in Yuk Tung Liu's write-up
(which restates Chapront & Francou 2002).  Analysis harness only - nothing here
is meant to ship."""
import numpy as np

PI = np.pi
DEG = PI / 180.0
SEC = PI / 648000.0


def mod2pi(x):
    return np.mod(x + PI, 2 * PI) - PI


class Paras:
    pass


def setup_parameters(corr):
    p = Paras()
    if corr == 0:  # LLR
        (p.Dw1_0, p.Dw2_0, p.Dw3_0, p.Deart_0, p.Dperi, p.Dw1_1, p.Dgam, p.De,
         p.Deart_1, p.Dep, p.Dw2_1, p.Dw3_1, p.Dw1_2, p.Dw1_3, p.Dw1_4,
         p.Dw2_2, p.Dw2_3, p.Dw3_2, p.Dw3_3) = (
            -0.10525, 0.16826, -0.10760, -0.04012, -0.04854, -0.32311, 0.00069,
            0.00005, 0.01442, 0.00226, 0.08017, -0.04317, -0.03794,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    else:  # DE405/DE406
        (p.Dw1_0, p.Dw2_0, p.Dw3_0, p.Deart_0, p.Dperi, p.Dw1_1, p.Dgam, p.De,
         p.Deart_1, p.Dep, p.Dw2_1, p.Dw3_1, p.Dw1_2, p.Dw1_3, p.Dw1_4,
         p.Dw2_2, p.Dw2_3, p.Dw3_2, p.Dw3_3) = (
            -0.07008, 0.20794, -0.07215, -0.00033, -0.00749, -0.35106, 0.00085,
            -0.00006, 0.00732, 0.00224, 0.08017, -0.04317, -0.03743,
            -0.00018865, -0.00001024, 0.00470602, -0.00025213, -0.00261070,
            -0.00010712)

    am = 0.074801329
    alpha = 0.002571881
    dtsm = 2.0 * alpha / (3.0 * am)
    xa = 2.0 * alpha / 3.0
    bp = [(0.311079095, -0.103837907), (-0.004482398, 0.000668287),
          (-0.001102485, -0.001298072), (0.001056062, -0.000178028),
          (0.000050928, -0.000037342)]
    w11 = (1732559343.73604 + p.Dw1_1) * SEC
    w21 = (14643420.3171 + p.Dw2_1) * SEC
    w31 = (-6967919.5383 + p.Dw3_1) * SEC
    x2, x3 = w21 / w11, w31 / w11
    y2 = am * bp[0][0] + xa * bp[4][0]
    y3 = am * bp[0][1] + xa * bp[4][1]
    p.Cw2_1 = ((x2 - y2) * p.Dw1_1 + (y2 / am) * p.Deart_1
               + w11 * bp[1][0] * p.Dgam + w11 * bp[2][0] * p.De
               + w11 * bp[3][0] * p.Dep)
    p.Cw3_1 = ((x3 - y3) * p.Dw1_1 + (y3 / am) * p.Deart_1
               + w11 * bp[1][1] * p.Dgam + w11 * bp[2][1] * p.De
               + w11 * bp[3][1] * p.Dep)

    delnu_nu = (0.55604 + p.Dw1_1) * SEC / w11
    dele = (0.01789 + p.De) * SEC
    delg = (-0.08066 + p.Dgam) * SEC
    delnp_nu = (-0.06424 + p.Deart_1) * SEC / w11
    delep = (-0.12879 + p.Dep) * SEC
    facs = dict(fB1=-am * delnu_nu + delnp_nu, fB2=delg, fB3=dele, fB4=delep,
                fB5=-xa * delnu_nu + dtsm * delnp_nu,
                fA=1.0 - 2.0 / 3.0 * delnu_nu)
    return p, facs


def compute_args(T, p):
    T = np.asarray(T, dtype=float)
    T2, T3, T4 = T * T, T ** 3, T ** 4
    w1 = ((-142.0 + 18.0 / 60.0 + (59.95571 + p.Dw1_0) / 3600.0) * DEG
          + mod2pi((1732559343.73604 + p.Dw1_1) * T * SEC)
          + mod2pi((-6.8084 + p.Dw1_2) * T2 * SEC)
          + mod2pi((0.006604 + p.Dw1_3) * T3 * SEC)
          + mod2pi((-3.169e-5 + p.Dw1_4) * T4 * SEC))
    w2 = ((83.0 + 21.0 / 60.0 + (11.67475 + p.Dw2_0) / 3600.0) * DEG
          + mod2pi((14643420.3171 + p.Dw2_1 + p.Cw2_1) * T * SEC)
          + mod2pi((-38.2631 + p.Dw2_2) * T2 * SEC)
          + mod2pi((-0.045047 + p.Dw2_3) * T3 * SEC)
          + mod2pi(0.00021301 * T4 * SEC))
    w3 = ((125.0 + 2.0 / 60.0 + (40.39816 + p.Dw3_0) / 3600.0) * DEG
          + mod2pi((-6967919.5383 + p.Dw3_1 + p.Cw3_1) * T * SEC)
          + mod2pi((6.359 + p.Dw3_2) * T2 * SEC)
          + mod2pi((0.007625 + p.Dw3_3) * T3 * SEC)
          + mod2pi(-3.586e-5 * T4 * SEC))
    Ea = ((100.0 + 27.0 / 60.0 + (59.13885 + p.Deart_0) / 3600.0) * DEG
          + mod2pi((129597742.293 + p.Deart_1) * T * SEC)
          + mod2pi(-0.0202 * T2 * SEC) + mod2pi(9e-6 * T3 * SEC)
          + mod2pi(1.5e-7 * T4 * SEC))
    pomp = ((102.0 + 56.0 / 60.0 + (14.45766 + p.Dperi) / 3600.0) * DEG
            + mod2pi(1161.24342 * T * SEC) + mod2pi(0.529265 * T2 * SEC)
            + mod2pi(-1.1814e-4 * T3 * SEC) + mod2pi(1.1379e-5 * T4 * SEC))

    a = {}
    a['W1'] = mod2pi(w1)
    a['D'] = mod2pi(w1 - Ea + PI)
    a['F'] = mod2pi(w1 - w3)
    a['L'] = mod2pi(w1 - w2)
    a['Lp'] = mod2pi(Ea - pomp)
    a['Me'] = mod2pi((-108.0 + 15.0 / 60.0 + 3.216919 / 3600.0) * DEG + mod2pi(538101628.66888 * T * SEC))
    a['Ve'] = mod2pi((-179.0 + 58.0 / 60.0 + 44.758419 / 3600.0) * DEG + mod2pi(210664136.45777 * T * SEC))
    a['EM'] = mod2pi((100.0 + 27.0 / 60.0 + 59.13885 / 3600.0) * DEG + mod2pi(129597742.293 * T * SEC))
    a['Ma'] = mod2pi((-5.0 + 26.0 / 60.0 + 3.642778 / 3600.0) * DEG + mod2pi(68905077.65936 * T * SEC))
    a['Ju'] = mod2pi((34.0 + 21.0 / 60.0 + 5.379392 / 3600.0) * DEG + mod2pi(10925660.57335 * T * SEC))
    a['Sa'] = mod2pi((50.0 + 4.0 / 60.0 + 38.902495 / 3600.0) * DEG + mod2pi(4399609.33632 * T * SEC))
    a['Ur'] = mod2pi((-46.0 + 3.0 / 60.0 + 4.354234 / 3600.0) * DEG + mod2pi(1542482.57845 * T * SEC))
    a['Ne'] = mod2pi((-56.0 + 20.0 / 60.0 + 56.808371 / 3600.0) * DEG + mod2pi(786547.897 * T * SEC))
    a['zeta'] = mod2pi(w1 + 0.02438029560881907 * T)
    return a


PERT_ORDER = ['D', 'F', 'L', 'Lp', 'Me', 'Ve', 'EM', 'Ma', 'Ju', 'Sa', 'Ur', 'Ne', 'zeta']


class Series:
    """One ELP/MPP02 series held as integer multiplier matrix + amplitudes."""

    def __init__(self, idx, amp, phase0, kind):
        self.idx = idx          # (n, 4) or (n, 13) ints
        self.amp = amp          # (n,)
        self.phase0 = phase0    # (n,) or None
        self.kind = kind        # 'main_sin', 'main_cos', 'pert'

    def sum(self, args):
        if self.kind.startswith('main'):
            ph = (self.idx[:, 0, None] * args['D'] + self.idx[:, 1, None] * args['F']
                  + self.idx[:, 2, None] * args['L'] + self.idx[:, 3, None] * args['Lp'])
            f = np.cos if self.kind == 'main_cos' else np.sin
            return (self.amp[:, None] * f(ph)).sum(axis=0)
        m = np.atleast_1d(args['D']).size
        ph = np.repeat(self.phase0[:, None], m, axis=1)
        for k, name in enumerate(PERT_ORDER):
            mult = self.idx[:, k]
            nz = mult != 0
            if nz.any():
                ph[nz] += mult[nz, None] * np.atleast_1d(args[name])[None, :]
        return (self.amp[:, None] * np.sin(ph)).sum(axis=0)

    def trim(self, thresh):
        keep = np.abs(self.amp) >= thresh
        return Series(self.idx[keep], self.amp[keep],
                      None if self.phase0 is None else self.phase0[keep], self.kind), int(keep.sum())


def read_main(path, fA, facs, kind):
    raw = np.loadtxt(path, skiprows=1)
    idx = raw[:, :4].astype(int)
    A, B1, B2, B3, B4, B5 = (raw[:, 4], raw[:, 5], raw[:, 6], raw[:, 7], raw[:, 8], raw[:, 9])
    amp = fA * A + facs['fB1'] * B1 + facs['fB2'] * B2 + facs['fB3'] * B3 + facs['fB4'] * B4 + facs['fB5'] * B5
    return Series(idx, amp, None, kind)


def read_pert(path):
    raw = np.loadtxt(path, skiprows=1, ndmin=2)
    return Series(raw[:, :13].astype(int), raw[:, 13], raw[:, 14], 'pert')


def load_coefs(corr=1, datadir='.'):
    p, facs = setup_parameters(corr)
    c = {}
    c['main_long'] = read_main(f'{datadir}/elp_main.long', 1.0, facs, 'main_sin')
    c['main_lat'] = read_main(f'{datadir}/elp_main.lat', 1.0, facs, 'main_sin')
    c['main_dist'] = read_main(f'{datadir}/elp_main.dist', facs['fA'], facs, 'main_cos')
    for q in ['long', 'lat', 'dist']:
        n = 4 if q != 'lat' else 3
        for i in range(n):
            c[f'pert_{q}T{i}'] = read_pert(f'{datadir}/elp_pert.{q}T{i}')
    return p, c


RA0 = 384747.961370173 / 384747.980674318


def moon_lbr(T, p, c):
    """Geocentric ecliptic longitude/latitude (radians, mean ecliptic AND mean
    equinox of date) and distance (km)."""
    T = np.atleast_1d(np.asarray(T, dtype=float))
    args = compute_args(T, p)
    lon = args['W1'] + c['main_long'].sum(args) + c['pert_longT0'].sum(args)
    lon = lon + mod2pi(c['pert_longT1'].sum(args) * T)
    lon = lon + mod2pi(c['pert_longT2'].sum(args) * T ** 2)
    lon = lon + mod2pi(c['pert_longT3'].sum(args) * T ** 3)
    lat = c['main_lat'].sum(args) + c['pert_latT0'].sum(args)
    lat = lat + mod2pi(c['pert_latT1'].sum(args) * T) + mod2pi(c['pert_latT2'].sum(args) * T ** 2)
    r = RA0 * (c['main_dist'].sum(args) + c['pert_distT0'].sum(args)
               + c['pert_distT1'].sum(args) * T + c['pert_distT2'].sum(args) * T ** 2
               + c['pert_distT3'].sum(args) * T ** 3)
    return lon, lat, r


def moon_x2000(T, p, c):
    """Geocentric rectangular coordinates, J2000.0 mean ecliptic and equinox, km."""
    T = np.atleast_1d(np.asarray(T, dtype=float))
    lon, lat, r = moon_lbr(T, p, c)
    x0 = r * np.cos(lon) * np.cos(lat)
    y0 = r * np.sin(lon) * np.cos(lat)
    z0 = r * np.sin(lat)
    T2, T3, T4, T5 = T ** 2, T ** 3, T ** 4, T ** 5
    P = 0.10180391e-4 * T + 0.47020439e-6 * T2 - 0.5417367e-9 * T3 - 0.2507948e-11 * T4 + 0.463486e-14 * T5
    Q = -0.113469002e-3 * T + 0.12372674e-6 * T2 + 0.12654170e-8 * T3 - 0.1371808e-11 * T4 - 0.320334e-14 * T5
    sq = np.sqrt(1 - P * P - Q * Q)
    X = (1 - 2 * P * P) * x0 + (2 * P * Q) * y0 + (2 * P * sq) * z0
    Y = (2 * P * Q) * x0 + (1 - 2 * Q * Q) * y0 + (-2 * Q * sq) * z0
    Z = (-2 * P * sq) * x0 + (2 * Q * sq) * y0 + (1 - 2 * P * P - 2 * Q * Q) * z0
    return X, Y, Z

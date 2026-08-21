"""Meeus ch.47 exactly as cbt-main.cpp has it today (tables lifted from the source)."""
import json
import numpy as np

_t = json.load(open('meeus47.json'))
D47A = np.array(_t['dTable47a']); M47A = np.array(_t['mTable47a'])
MA47A = np.array(_t['maTable47a']); F47A = np.array(_t['fTable47a'])
L47A = np.array(_t['lTable47a']); R47A = np.array(_t['rTable47a'])
D47B = np.array(_t['dTable47b']); M47B = np.array(_t['mTable47b'])
MA47B = np.array(_t['maTable47b']); F47B = np.array(_t['fTable47b'])
B47B = np.array(_t['bTable47b'])

RAD = np.pi / 180.0


def wrap360(x):
    return np.mod(x, 360.0)


def moon_lbr(jd_tt):
    """Geocentric ecliptic longitude/latitude in degrees (geometric, mean equinox
    of date - no nutation) and distance in km."""
    jd = np.atleast_1d(np.asarray(jd_tt, dtype=float))
    T = (jd - 2451545.0) / 36525.0
    T2, T3, T4 = T * T, T ** 3, T ** 4

    LA = wrap360(218.3164477 + 481267.88123421 * T - 0.0015786 * T2 + T3 / 538841.0 - T4 / 65194000.0)
    D = wrap360(297.8501921 + 445267.1114034 * T - 0.0018819 * T2 + T3 / 545868.0 - T4 / 113065000.0)
    M = wrap360(357.5291092 + 35999.0502909 * T - 0.0001536 * T2 + T3 / 24490000.0)
    MA = wrap360(134.9633964 + 477198.8675055 * T + 0.0087414 * T2 + T3 / 69699.0 - T4 / 14712000.0)
    F = wrap360(93.2720950 + 483202.0175233 * T - 0.0036539 * T2 - T3 / 3526000.0 + T4 / 863310000.0)
    A1 = wrap360(119.75 + 131.849 * T)
    A2 = wrap360(53.09 + 479264.290 * T)
    A3 = wrap360(313.45 + 481266.484 * T)
    E = 1.0 - 0.002516 * T - 0.0000074 * T2
    E2 = E * E

    def eterm(mt):
        f = np.ones((len(mt), len(T)))
        f[np.abs(mt) == 1.0] = E
        f[np.abs(mt) == 2.0] = E2
        return f

    argA = RAD * (D47A[:, None] * D + M47A[:, None] * M + MA47A[:, None] * MA + F47A[:, None] * F)
    eA = eterm(M47A)
    Sl = (L47A[:, None] * eA * np.sin(argA)).sum(axis=0)
    Sr = (R47A[:, None] * eA * np.cos(argA)).sum(axis=0)
    argB = RAD * (D47B[:, None] * D + M47B[:, None] * M + MA47B[:, None] * MA + F47B[:, None] * F)
    eB = eterm(M47B)
    Sb = (B47B[:, None] * eB * np.sin(argB)).sum(axis=0)

    Sl = Sl + 3958.0 * np.sin(RAD * A1) + 1962.0 * np.sin(RAD * (LA - F)) + 318.0 * np.sin(RAD * A2)
    Sb = (Sb - 2235.0 * np.sin(RAD * LA) + 382.0 * np.sin(RAD * A3)
          + 175.0 * np.sin(RAD * (A1 - F)) + 175.0 * np.sin(RAD * (A1 + F))
          + 127.0 * np.sin(RAD * (LA - MA)) - 115.0 * np.sin(RAD * (LA + MA)))

    lam = LA + Sl / 1e6
    beta = Sb / 1e6
    dist = 385000.56 + Sr / 1000.0
    return wrap360(lam), beta, dist

"""How many Chebyshev nodes does one day of the moon need?"""
import numpy as np, elp, pipeline as P, compare as C

p, c0 = elp.load_coefs(0)
ct, n = C.trim(c0, 0.01, 0.02)

def block(day, N):
    k = np.arange(N)
    xk = np.cos(np.pi*(k+0.5)/N)              # Chebyshev-Gauss nodes on [-1,1]
    jd = day + 0.5 + 0.5*xk
    T  = (jd - 2451545.0)/36525.0
    X, Y, Z = elp.moon_x2000(T, p, ct)
    lam, bet, r = P._to_date(X, Y, Z, T)
    lam = np.unwrap(np.radians(lam))*180/np.pi   # nodes are ordered high->low in jd
    out = []
    for f in (lam, bet, r):
        a = np.array([(2.0/N)*np.sum(f*np.cos(np.pi*j*(k+0.5)/N)) for j in range(N)])
        a[0] *= 0.5
        out.append(a)
    return out

def evalc(a, x):
    b1 = b2 = 0.0
    for j in range(len(a)-1, 0, -1):
        b1, b2 = 2*x*b1 - b2 + a[j], b1
    return x*b1 - b2 + a[0]

rng = np.random.default_rng(3)
for N in (8, 10, 12, 14, 16):
    el, eb, er = [], [], []
    for day in 2451545.0 + np.floor(rng.uniform(-40000, 40000, 12)):
        A = block(day, N)
        jd = day + 0.5 + 0.5*np.linspace(-1, 1, 97)
        T = (jd - 2451545.0)/36525.0
        X, Y, Z = elp.moon_x2000(T, p, ct)
        lam, bet, r = P._to_date(X, Y, Z, T)
        x = 2*(jd - day) - 1
        gl = np.array([evalc(A[0], xi) for xi in x])
        gb = np.array([evalc(A[1], xi) for xi in x])
        gr = np.array([evalc(A[2], xi) for xi in x])
        el.append(((np.mod(gl - lam + 180, 360) - 180)*3600))
        eb.append((gb - bet)*3600)
        er.append(gr - r)
    el, eb, er = np.concatenate(el), np.concatenate(eb), np.concatenate(er)
    print(f'N={N:3d}  dlam max {np.abs(el).max():10.3e}"  dbeta max {np.abs(eb).max():10.3e}"  '
          f'dr max {np.abs(er).max():10.3e} km')

import numpy as np, elp, compare as C, de440

p, c = elp.load_coefs(0)   # LLR fit

def show(y0, y1, n=1500):
    jd = C.sample_jd(y0, y1, n)
    truth = de440.eq_to_ecl_j2000(de440.moon_geocentric_icrf(jd))
    print(f"\n== {y0}-{y1} vs DE440 (LLR fit), rms / max ==")
    C.line('full 35901', *C.diffs(*C.elp_chunked(jd, p, c), truth))
    for thr, thk in [(0.1,0.2),(0.05,0.1),(0.03,0.06),(0.02,0.04),(0.01,0.02),(0.005,0.01)]:
        ct, cnt = C.trim(c, thr, thk)
        C.line(f'cut {thr}" -> {cnt}', *C.diffs(*C.elp_chunked(jd, p, ct), truth))

show(1900, 2100)
show(1850, 2150)

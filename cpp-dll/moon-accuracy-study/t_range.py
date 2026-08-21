"""Truncation error alone, measured against the complete 35901-term theory,
where DE440s does not reach."""
import numpy as np, elp, compare as C
p, c = elp.load_coefs(0)
ct, cnt = C.trim(c, 0.01, 0.02)
for y0, y1 in [(1850,2150),(1700,2300),(1600,2400),(1500,2500)]:
    jd = C.sample_jd(y0, y1, 900)
    full = np.array(C.elp_chunked(jd, p, c))
    C.line(f'{y0}-{y1}  {cnt} terms vs full', *C.diffs(*C.elp_chunked(jd, p, ct), full))

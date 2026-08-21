import numpy as np, pipeline as P, rs_compare as RSC
orig = P.delta_t
def cross(jd0, lat, lon):
    n=int(24*60)+3
    grid=jd0+(np.arange(n)-1)/1440.0
    f=P.horizon_func(grid, lat, lon, P.theory_de440)
    out=[]; s=np.signbit(f)
    for i in np.nonzero(s[1:-2]!=s[2:-1])[0]+1:
        c=np.polyfit(np.arange(-1.,3.), f[i-1:i+3], 3)
        r=[x.real for x in np.roots(c) if abs(x.imag)<1e-9 and -0.001<=x.real<=1.001]
        if r: out.append((grid[i]+r[0]/1440.0, 'rise' if f[i]<0 else 'set'))
    return out
rng=np.random.default_rng(3)
jd0s=2451545.0+25*365.25+np.floor(rng.uniform(0,3650,40))+0.5
for err in (10.0, 60.0):
    e=[]
    for name,lat,lon in RSC.SITES:
        for jd0 in jd0s:
            P.delta_t = orig
            a=cross(jd0,lat,lon)
            P.delta_t = lambda j, o=orig, d=err: o(j)+d
            b=cross(jd0,lat,lon)
            P.delta_t = orig
            for t1,t2,k in RSC.match(a,b,tol_min=120): e.append((t2-t1)*86400.0)
    e=np.array(e)
    print(f"  delta T wrong by {err:.0f} s -> rise/set moves rms {np.sqrt((e**2).mean()):.2f} s, max {np.abs(e).max():.2f} s")

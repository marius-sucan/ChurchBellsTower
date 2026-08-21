import numpy as np, pipeline as P, rs_compare as RSC

D2R=np.pi/180
def cross(jd0, lat, lon, dh=0.0, dt_err=0.0):
    n=int(24*60)+3
    grid=jd0+(np.arange(n)-1)/1440.0
    f=P.horizon_func(grid+dt_err/86400.0, lat, lon, P.theory_de440)+dh
    out=[]; s=np.signbit(f)
    for i in np.nonzero(s[1:-2]!=s[2:-1])[0]+1:
        c=np.polyfit(np.arange(-1.,3.), f[i-1:i+3], 3)
        r=[x.real for x in np.roots(c) if abs(x.imag)<1e-9 and -0.001<=x.real<=1.001]
        if r: out.append((grid[i]+r[0]/1440.0, 'rise' if f[i]<0 else 'set'))
    return out

rng=np.random.default_rng(3)
jd0s=2451545.0+25*365.25+np.floor(rng.uniform(0,3650,40))+0.5
# dh raises the discriminant, i.e. it lets the event happen with the moon lower,
# which is what MORE refraction (or a depressed horizon) does.
cases=[("refraction 5' more than the 34' assumed",  5.0/60.0, 0.0),
       ("refraction 6' less than the 34' assumed", -6.0/60.0, 0.0),
       ("observer 100 m up (horizon dip 17.6')",           17.6/60.0, 0.0),
       ("observer 500 m up (horizon dip 39.3')",           39.3/60.0, 0.0),
       ("delta T wrong by 10 s",                            0.0,     10.0)]
print("\nHow much a rise/set time moves for reasons that have nothing to do with the lunar theory")
print("  (DE440 throughout, 12 sites x 40 days; seconds of time)")
print(f"  {'cause':<48}{'rms':>9}{'max':>9}")
for label, dh, dte in cases:
    e=[]
    for name,lat,lon in RSC.SITES:
        for jd0 in jd0s:
            a=cross(jd0,lat,lon); b=cross(jd0,lat,lon,dh,dte)
            for t1,t2,k in RSC.match(a,b,tol_min=120):
                e.append((t2-t1)*86400.0)
    e=np.array(e)
    print(f"  {label:<48}{np.sqrt((e**2).mean()):9.1f}{np.abs(e).max():9.1f}")

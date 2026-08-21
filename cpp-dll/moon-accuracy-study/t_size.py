import numpy as np, elp, compare as C, de440

AS = 180.0*3600.0/np.pi
p, c = elp.load_coefs(0)          # LLR fit - closer to DE440

order = ['main_long','main_lat','main_dist',
         'pert_longT0','pert_longT1','pert_longT2','pert_longT3',
         'pert_latT0','pert_latT1','pert_latT2',
         'pert_distT0','pert_distT1','pert_distT2','pert_distT3']

for thr_as, thr_km in [(0.1,0.2),(0.05,0.1),(0.03,0.06),(0.02,0.04),(0.01,0.02),(0.005,0.01)]:
    ct, n = C.trim(c, thr_as, thr_km)
    nm = sum(ct[k].idx.shape[0] for k in order if k.startswith('main'))
    npz = n - nm
    # nonzero multiplier histogram for the pert terms kept
    nz = []
    for k in order:
        if k.startswith('pert') and ct[k].idx.shape[0]:
            nz.append((ct[k].idx != 0).sum(axis=1))
    nz = np.concatenate(nz) if nz else np.array([0])
    # how many pert terms touch only D,F,L,Lp
    only4 = 0
    for k in order:
        if k.startswith('pert') and ct[k].idx.shape[0]:
            only4 += int(((ct[k].idx[:,4:] != 0).sum(axis=1) == 0).sum())
    bytes_ = nm*(4+8) + npz*(13+16)
    print(f'cut {thr_as:6}"  total {n:5d}  main {nm:5d}  pert {npz:5d}  '
          f'pert-nonzero mults mean {nz.mean():.2f} max {nz.max()}  only-D/F/l/lp {only4:5d}  '
          f'~{bytes_/1024:.1f} KB')

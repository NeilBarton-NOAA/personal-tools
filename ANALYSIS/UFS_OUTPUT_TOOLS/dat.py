import os
import xarray as xr
import numpy as np

def get(files, var):
    dat, label = [], []
    print('LOAD DATA:')
    for f in files:
        print(' ', f, var)
        ds = xr.open_dataset(f)
        var_file = os.path.dirname(f) + '/' + var + '.nc'
        ds = ds.assign_attrs({'var_file': var_file})
        for v in list(ds.keys()):
            if (v != var) and (v != 'area'):
                ds = ds.drop(v)
        if 'P8T' in f:
            ds = ds.assign_attrs({'test_name': 'Thompson'})
        if 'P8G' in f:
            ds = ds.assign_attrs({'test_name': 'GFDL'})
        ds = ds.assign_attrs({'var_name': var})
        ############
        # add area of cells
        if 'CICE' not in f: 
            area_file = os.path.dirname(f) + '/gridarea.nc'
            ds_area = xr.open_dataset(area_file)
            ds['area'] = (ds_area['cell_area'].dims, ds_area['cell_area'].astype('float32').values / 1e6)
        ############
        # add var file
        if os.path.exists(var_file):
            print('     adding',  var_file)
            vs = xr.open_dataset(var_file)
            v = 'NH_extent'
            for v in list(vs.keys()):
                ds[v] = (vs[v].dims, vs[v].astype('float32').values)
        ds['tau'] = ds['tau'] / 24.0
        dat.append(ds)
    return dat

def checktimes(dat):
    # make sure they have same init times
    for i in np.arange(len(dat)):
        if ((dat[i]['time'] == dat[i+1]['time']).any() == False):
            print('times do not match')
            exit(1)
        if ((dat[i]['tau'] == dat[i+1]['tau']).any() == False):
            print('forecast day/taus do not match')
            exit(1)
        if i + 2 >= len(dat):
            break

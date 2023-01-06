import xarray as xr
import os
def get(var):
    data_dir='/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT'
    f = data_dir + '/CFSV2_' + var + '.nc'
    print(' ', f, var)
    ds = xr.open_dataset(f)
    # add area
    f = data_dir + '/CFSV2_area.nc'
    ds_area = xr.open_dataset(f)
    ds['area'] = (ds_area['cell_area'].dims, ds_area['cell_area'].astype('float32').values / 1e6)
    ds = ds.assign_attrs({'test_name': 'CFSv2'})
    ds = ds.assign_attrs({'var_name': 'ICEC_surface'})
    var_file = os.path.dirname(f) + '/' + var + '.nc'
    ds = ds.assign_attrs({'var_file': var_file})
    if os.path.exists(var_file):
        print('     adding',  var_file)
        vs = xr.open_dataset(var_file)
        for v in list(vs.keys()):
            ds[v] = (vs[v].dims, vs[v].astype('float32').values)
    return ds

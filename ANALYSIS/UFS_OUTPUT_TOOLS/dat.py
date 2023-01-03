import os
import xarray as xr
import numpy as np
import pandas as pd

def get(files, var, grab_seasons = True):
    dat, label = [], []
    print('LOAD DATA:')
    for f in files:
        print(' ', f, var)
        ds = xr.open_dataset(f)
        var_file = os.path.dirname(f) + '/' + var + '.nc'
        ds = ds.assign_attrs({'var_file': var_file})
        ds = ds.assign_attrs({'file_dir': os.path.dirname(f)})
        for v in list(ds.keys()):
            if (v != var) and (v != 'area'):
                ds = ds.drop(v)
        if 'P8T' in f:
            ds = ds.assign_attrs({'test_name': 'P8'})
        if 'P8G' in f:
            ds = ds.assign_attrs({'test_name': 'P8: GFDL'})
        ds = ds.assign_attrs({'var_name': var})
        ############
        # add area of cells
        if 'CICE' not in f: 
            area_file = os.path.dirname(f) + '/gridarea.nc'
            ds_area = xr.open_dataset(area_file)
            ds['area'] = (ds_area['cell_area'].dims, ds_area['cell_area'].astype('float32').values / 1e6)
        ############
        # add var file
        if 'CRF' not in var_file:
            if os.path.exists(var_file):
                print('     adding',  var_file)
                vs = xr.open_dataset(var_file)
                for v in list(vs.keys()):
                    ds[v] = (vs[v].dims, vs[v].astype('float32').values)
            ############
            # tau
            ds['tau'] = ds['tau'].astype('float32') / 24.0
        else:
            ds['tau'] = np.arange(0,141*6,6)
        dat.append(ds)
    return dat

def add_season_data(DAT):
    RETURN_DAT = []
    for ds in DAT:
        # read season if already calculated
        DIMS = ['DJF', 'MAM', 'JJA', 'SON']
        ds = ds.assign_attrs({'seasons': DIMS})
        if grab_seasons:
            DIM_DAT = []
            for DIM in DIMS:
                season_file = os.path.dirname(ds.var_file) + '/' + ds.var_name + DIM + '.nc'
                if os.path.exists(season_file):
                    print('     adding',  season_file)
                    vs = xr.open_dataset(season_file)
                    DIM_DAT.append(vs[ds.var_name])
            list_dims = list(vs[ds.var_name].dims)
            list_dims.insert(0, 'season')
            DIM_DAT = np.array(DIM_DAT).astype('float32')
            ds['mean_' + ds.var_name] = (list_dims, DIM_DAT)
            ds['season'] = (('season'), DIMS)
        RETURN_DAT.append(ds)
    return DAT

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

def seasons(DAT):
    print('ADDING MEANS of SEASONS')
    DIM = ['DJF', 'MAM', 'JJA', 'SON']
    for i, ds in enumerate(DAT):
        for i, months in enumerate([[12,1,2], [3,4,5], [6,7,8], [9,10,11]]):
            season_file = os.path.dirname(ds.var_file) + '/' + ds.var_name + DIM[i] + '.nc'
            force_calc = False
            if (not os.path.exists(season_file)) | (force_calc):
                print('CALCULATING:', DIM[i], ds.test_name)
                ############
                # model data
                # turn time into pandas for indexing month
                #t = pd.to_datetime(ds['time'].values)
                #m_index = np.where((t.month == months[0]) | (t.month == months[1]) | (t.month == months[2]))[0]
                #d = ds[ds.var_name].isel(time = m_index).mean(dim = 'time')
                d = ds[ds.var_name].isel(time = ds['time'].dt.month.isin(months)).mean('time')
                if os.path.exists(season_file):
                    d.to_netcdf(season_file, mode = 'a')
                else:
                    d.to_netcdf(season_file)
                print('wrote:', season_file)
                del d
    ########################
    # adding to file
    RETURN_DAT = []
    for ds in DAT:
        print(ds.test_name)
        # read season if already calculated
        ds = ds.assign_attrs({'seasons': DIM})
        DIM_DAT = []
        for D in DIM:
            season_file = os.path.dirname(ds.var_file) + '/' + ds.var_name + D + '.nc'
            print('     adding',  season_file)
            vs = xr.open_dataset(season_file)
            DIM_DAT.append(vs[ds.var_name])
        list_dims = list(vs[ds.var_name].dims)
        list_dims.insert(0, 'season')
        DIM_DAT = np.array(DIM_DAT).astype('float32')
        ds['mean_' + ds.var_name] = (list_dims, DIM_DAT)
        ds['season'] = (('season'), DIM)
        RETURN_DAT.append(ds)
    return RETURN_DAT

def time_array_with_tau(DAT):
    DAT_RETURN = []
    for ds in DAT:
        t_array = []
        times = pd.to_datetime(ds['time'].values) 
        for t in times:
            t_array.append((t + pd.to_timedelta(ds['tau'].values, unit = 'D')).to_numpy())
        ds['times_in_tau'] = (('time', 'tau') , np.array(t_array))
        DAT_RETURN.append(ds)
    return DAT_RETURN

import pandas as pd
import numpy as np
import xarray as xr
import os
import sys
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + '/../PYTHON_TOOLS')
import PYTHON_TOOLS as npb

def extent(DAT, var = 'aice_d', force_calc = False):
    # grab data if already calculated
    try:
        f = DAT.extent_file
    except:
        f = None
    if os.path.exists(f):
       dd = xr.open_dataset(f)
       DAT['NH_extent'] = (dd['NH_extent'].dims, dd['NH_extent'].values)
       DAT['SH_extent'] = (dd['SH_extent'].dims, dd['SH_extent'].values)
    # assume data are from CICE model
    dims = ('nj', 'ni')
    DIV = 1e12
    # see if data are already there
    if ('NH_extent' not in list(DAT.keys()) and 'SH_extent' not in list(DAT.keys())) or force_calc:
        print('CALCULATING ICE EXTENT:')
        # too much memory for below, must loop
        #NH = d['area'].where(d['ICEC_surface'] > 0.15).sum(dim=('latitude', 'longitude'))
        NH, SH = [], []
        ds = DAT.isel(time = 0)  
        _, area = xr.broadcast(ds[var], DAT['tarea'].isel(time = 1, tau = 1))
        DAT['tau_area'] = (area.dims, area.values) 
        print('     looping through time')
        for t in DAT['time']:
            print('     ', t.values)
            # NH
            ds = DAT.sel(time = t.values)
            ds = ds.where(ds.TLAT > 20)
            NH.append(DAT['tau_area'].where(ds[var] >= 0.15).sum(dim = dims) / DIV)
            # SH
            ds = DAT.sel(time = t.values)
            ds = ds.where(ds.TLAT < -20)
            SH.append(ds['tau_area'].where(ds[var] >= 0.15).sum(dim = dims) / DIV)
        DAT = DAT.assign(NH_extent=(['time', 'tau'], np.array(NH)))
        DAT = DAT.assign(SH_extent=(['time', 'tau'], np.array(SH)))
        DAT = DAT.drop('tau_area')
        if f:
            SAVE_DAT = DAT.copy()
            for key in SAVE_DAT.keys():
                if key not in ['NH_extent', 'SH_extent', 'time', 'tau']:
                    SAVE_DAT = SAVE_DAT.drop(key)
            print('writing:', f)
            if os.path.exists(f):
                SAVE_DAT.to_netcdf(f, mode = 'a')
            else:
                SAVE_DAT.to_netcdf(f)
    return DAT

def iiee(DAT, OBS, var = 'aice_d', force_calc = False):
    # grab data if already calculated
    try:
        f = DAT.iiee_file
    except:
        f = None
    # assume data are from CICE model
    dims = ('nj', 'ni')
    DIV = 1e12
    DLAT = DAT['TLAT'].values
    DLON = DAT['TLON'].values
    print(OBS)
    OLAT = OBS['lat']
    exit(1)
    OLON = OBS['ygrid'].values
    # see if data are already there
    if ('NH_IIEE' not in list(DAT.keys()) and 'SH_IIEE' not in list(DAT.keys())) or force_calc:
        print('CALCULATING INTEGRATED ICE EDGE ERROR:')
        print('     looping through time')
        for t in DAT['time']:
            for tau in DAT['tau']:
                print(DAT)
                print(DAT[var].sel(time = t, tau = tau))
                print(t)
                exit(1)
            
            # too much memory for below, must loop
        ##NH = d['area'].where(d['ICEC_surface'] > 0.15).sum(dim=('latitude', 'longitude'))
        #NH, SH = [], []
        #ds = DAT.isel(time = 0)  
        #_, area = xr.broadcast(ds[var], DAT['tarea'].isel(time = 1, tau = 1))
        #DAT['tau_area'] = (area.dims, area.values) 
        #    print tau in 
        #    print('     ', t.values)
        #    # NH
        #    ds = DAT.sel(time = t.values)
        #    ds = ds.where(ds.TLAT > 20)
        #    NH.append(DAT['tau_area'].where(ds[var] >= 0.15).sum(dim = dims) / DIV)
        #    # SH
        #    ds = DAT.sel(time = t.values)
        #    ds = ds.where(ds.TLAT < -20)
        #    SH.append(ds['tau_area'].where(ds[var] >= 0.15).sum(dim = dims) / DIV)
        #DAT = DAT.assign(NH_extent=(['time', 'tau'], np.array(NH)))
        #DAT = DAT.assign(SH_extent=(['time', 'tau'], np.array(SH)))
        #DAT = DAT.drop('tau_area')
        #if f:
        #    SAVE_DAT = DAT.copy()
        #    for key in SAVE_DAT.keys():
        #        if key not in ['NH_extent', 'SH_extent', 'time', 'tau']:
        #            SAVE_DAT = SAVE_DAT.drop(key)
        #    print('writing:', f)
        #    if os.path.exists(f):
        #        SAVE_DAT.to_netcdf(f, mode = 'a')
        #    else:
        #        SAVE_DAT.to_netcdf(f)
    #return DAT


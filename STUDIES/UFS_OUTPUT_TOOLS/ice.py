import pandas as pd
import numpy as np
import xarray as xr
import os
import sys
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + '/../PYTHON_TOOLS')
import PYTHON_TOOLS as npb

def extent(dat, force_calc = False):
    for ii, d in enumerate(dat):
        if ('NH_extent' not in list(d.keys()) and 'SH_extent' not in list(d.keys())) or force_calc:
            if ii == 0:
                print('CALCULATING ICE EXTENT:')
            print(' ',d.test_name)
            # too much memory for below, must loop
            #NH = d['area'].where(d['ICEC_surface'] > 0.15).sum(dim=('latitude', 'longitude'))
            NH, SH = [], []
            print('     looping through time')
            ds = d.isel(time = 0)
            _, area = xr.broadcast(ds['ICEC_surface'], d['area'])
            d['tau_area'] = (area.dims, area.values)
            for t in d['time']:
                print('     ', t.values)
                ds = d.sel(time = t.values, latitude=(slice(0,90)))
                #ds['test_area'] = ds['tau_area'] #.mean()
                #print(ds['test_area'].min())
                #print(ds['test_area'].max())
                #dds = ds.isel(tau = 0)
                #print(dds)
                #import matplotlib.pyplot as plt
                #plt.figure(1)
                #dds['tau_area'].plot()
                #print(dds['tau_area'].max())
                #plt.figure(2)
                #dds['ICEC_surface'].plot()
                #print(ds['ICEC_surface'][0].min())
                #print(ds['ICEC_surface'][0].max())
                #test = ds['test_area'].where(ds['ICEC_surface'] >= 0.15).sum(dim=('latitude', 'longitude')) / 1e6
                #print(test)
                #plt.show()
                #exit(1)
                NH.append(ds['tau_area'].where(ds['ICEC_surface'] >= 0.15).sum(dim=('latitude', 'longitude')) / 1e6)
                ds = d.sel(time = t.values, latitude=(slice(-90,0)))
                SH.append(ds['tau_area'].where(ds['ICEC_surface'] >= 0.15).sum(dim=('latitude', 'longitude')) / 1e6)
            d = d.assign(NH_extent=(['time', 'tau'], np.array(NH)))
            d = d.assign(SH_extent=(['time', 'tau'], np.array(SH)))
            d = d.drop('tau_area')
            dat[ii] = d
            # write file for variable
            var_file = d.var_file
            d = d.drop(d.var_name)
            print('writing:', var_file)
            if os.path.exists(var_file):
                d.to_netcdf(var_file, mode = 'a')
            else:
                d.to_netcdf(var_file)
        else:
            print('ICE extent already calculated:',d.test_name)
    return dat

def get_extentobs():
    ice_dir = '/scratch1/NCEPDEV/climate/Denise.Worthen/IceData'
    files = ['N_seaice_extent_daily_v3.0.csv', 'S_seaice_extent_daily_v3.0.csv']
    ob = []
    for ii, f in enumerate(files):
        obs = pd.read_csv(ice_dir + '/' + f, header = [0,1])
        obs.columns = obs.columns.droplevel(1)
        t = []
        for i in range(obs.shape[0]):
            y = str(obs[obs.keys()[0]][i])
            m = str(obs[obs.keys()[1]][i]).zfill(2)
            d = str(obs[obs.keys()[2]][i]).zfill(2)
            t.append(np.datetime64(y + '-' + m + '-' + d, 'ns'))
        obs['time'] = t
        for k in obs.keys():
            if k.strip() not in ['time', 'Extent']:
                obs.drop(k, axis = 1, inplace = True)
            else:
                obs.rename(columns = {k: k.strip()}, inplace = True)
        obs.rename(columns = {'Extent': f[0] + 'H_extent'}, inplace = True)
        obs.set_index('time', inplace = True)
        ob.append(obs)
    obs = pd.concat(ob, axis = 1)
    #return obs.set_index('time').to_xarray()
    return obs.to_xarray()

def get_iceobs(netcdf_dir):
    ice_dir = '/scratch1/NCEPDEV/climate/Denise.Worthen/IceData'
    poles = ['north', 'south']
    ob = []
    for ii, pole in enumerate(poles):
        print('READING ICE CONCENTRATIONS:', pole)
        obs_file = netcdf_dir + 'ICECON_OBS_' + pole + '.nc'
        if os.path.exists(obs_file):
            obs = xr.open_dataset(obs_file)
        else:
            obs = xr.open_mfdataset(ice_dir + '/' + pole + '/*/*daily*.nc')
            obs['ice_con'] = obs['goddard_merged_seaice_conc']
            for key in list(obs.keys()):
                obs = obs.drop(key)
            # grid
            grid = xr.open_dataset(ice_dir + '/ps' + pole[0] + '25.grid.nc')
            obs['area'] = (grid['area'].dims, grid['area'].values)
            # save to netcdf
            obs.to_netcdf(obs_file)
            print('wrote:', obs_file)
        ob.append(obs)
    return ob

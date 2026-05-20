#!/usr/bin/env python3 
########################
from pathlib import Path
import numpy as np
import pandas as pd
import argparse
import sys, os
p = os.getenv("pytools", os.path.dirname(os.path.realpath(__file__)))
if p not in sys.path: sys.path.insert(0, p)
import pytools as py
from pytools.obs import cm

def main():
    ################################################
    parser = argparse.ArgumentParser( description = "Comparing SFS Runs")
    parser.add_argument('-ymd', '--yearmonthday', action = 'store', nargs = 1,
                        default = ["20250701"],
                        #default = ["20260401"],
                        help = 'YYYYMMDD of start of run')
    parser.add_argument('-v', '--var', action = 'store', nargs = 1,
                        default = ['SST'],
                        help = 'variable to analyze')
    parser.add_argument('-e', '--experiments', action = 'store', nargs = '+', 
                        default = 'ALL',
                        help = 'experiments names from COMROOT directory')
    parser.add_argument('-c', '--comroot', action = 'store', nargs = 1,
                        default = os.getenv('NPB_WORKDIR') + '/RUNS/COMROOT',
                        help = 'comroot/top directory of experiments')
    parser.add_argument('-f','--force_read', action = argparse.BooleanOptionalAction, default=False,
                        help = 're-read in files to create zarr') 
    parser.add_argument('-d','--debug', action = argparse.BooleanOptionalAction, default=False,
                        help = 'show plot for debugging') 
    ############
    args = parser.parse_args()
    ymd = args.yearmonthday[0]
    var = args.var[0]
    experiments = args.experiments
    comroot = args.comroot
    FORCE_READ_DATA = args.force_read
    DEBUG = args.debug

    ############
    if experiments == 'ALL':
        print('GRABBING ALL EXPERIMENTS AT:', comroot)
        experiments = [comroot + '/' + d for d in os.listdir(comroot) if os.path.isdir(comroot + '/' + d) and d != 'ZARR']
    exp_names, exp_dirs = [], []
    for e in experiments:
        name = os.path.basename(os.path.normpath(e))
        name = name.replace('beta1.1_','')
        exp_names.append(name)
        d = e if '/' in e else comroot + '/' + e
        exp_dirs.append(d)
    exps = dict(zip(exp_names, exp_dirs))
    
    ################################################
    # hopeful nothing below here needs to be changed
    ds_save = Path(comroot + "/ZARR/" + ymd) / 'monthly.zarr'
    Path(ds_save).parent.mkdir(parents=True, exist_ok=True)
    ds = py.grabdata(ds_save, exps, ymd, FORCE_READ_DATA)
    list_file = set(ds.experiment.values)
    list_exp = set(exp_names)
    missing = list_exp - list_file
    if len(missing) > 0:
        print('FATAL: not all experiments in dataset:', missing)
        exit(1)

    ################################################
    ds = py.ds_addvar(ds, var)
    ice_vars = ['ice_extent', 'ice_volume', 'snow_volume', 'Tsfc', 'aice', 'albsni', 'hi', 'hs']
    model = 'ice' if var in ice_vars else 'ocn'
    da = ds[var].sel(component = model, experiment = exp_names) 
    if (model == 'ice') and (var not in ['ice_extent', 'ice_volume', 'snow_volume']):
        da_aice = ds['aice'].sel(component='ice', experiment=exp_names)
        cell_area = ds['cell_area'].sel(component='ice', experiment=exp_names)
        da = da.where(da_aice > 0, drop = False) 
        if var == 'albsni': da = da.where(da < 100, drop = False) 
    else:
        cell_area = np.cos(np.deg2rad(ds.latitude))

    ################################################
    # grab obs
    if var in ['ice_extent']:
        cm.start_dtg = pd.to_datetime(ds.time.values[0]).replace(day = 1)
        cm.end_dtg = pd.to_datetime(ds.time.values[-1]) + pd.offsets.MonthEnd(0)
        cm.var = var
        obs = cm.grab()
    else:
        obs = False

    ########################
    # spatial plots
    # global
    if (len(exps) == 2) and (model == 'ocn'):
        py.maps.three_panel(da, DEBUG)
    # polar 
    if (len(exps) == 2) and (model == 'ice') and (var not in ['ice_extent', 'ice_volume', 'snow_volume']):
        py.maps.six_panel(da, DEBUG)
    ########################
    # line plots
    if model == 'ocn':
        py.plots.line(da, 'global', obs, cell_area)
        py.plots.line(da, 'nino34', obs, cell_area)
        py.plots.line(da, 'tropics', obs, cell_area)
    if 'hemisphere' in da.dims:
        ob = obs.sel(hemisphere = 'NH') if var in ['ice_extent'] else False
        py.plots.line(da.sel(hemisphere = 'NH'), 'Arctic', ob, cell_area)
        ob = obs.sel(hemisphere = 'SH') if var in ['ice_extent'] else False
        py.plots.line(da.sel(hemisphere = 'SH'), 'Antarctic', ob, cell_area)
    else:
        py.plots.line(da, 'Arctic', obs, cell_area)
        py.plots.line(da, 'Antarctic', obs, cell_area)

    print('SCRIPT FINISHED')

if __name__ == "__main__":
    main()

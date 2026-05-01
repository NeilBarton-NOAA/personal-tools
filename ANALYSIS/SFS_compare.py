#!/usr/bin/env python3 
########################
from pathlib import Path
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
                        help = 'YYYYMMDD of start of run')
    parser.add_argument('-v', '--var', action = 'store', nargs = 1,
                        default = ['SST'],
                        help = 'variable to analyze')
    parser.add_argument('-d', '--dirs', action = 'store', nargs = '+', 
                        default = [ os.getenv('NPB_WORKDIR') + "/RUNS/COMROOT/beta1.1_GFS_ICs", 
                                    os.getenv('NPB_WORKDIR') + "/RUNS/COMROOT/beta1.1_CPC_ICs",
                                    os.getenv('NPB_WORKDIR') + "/RUNS/COMROOT/beta1.1_CPC_ICs_CICE_EDITS"],
                        help = 'top directories of experiments')
    parser.add_argument('-n', '--names', action = 'store', nargs = '+',
                        default = [ 'gfs_ics',
                                    'cpc_ics',
                                    'cpc_ics_edits'],
                        help = 'names of experiments')
    parser.add_argument('-f','--force_read', action = argparse.BooleanOptionalAction, default=False,
                        help = 're-read in files to create zarr') 
    parser.add_argument('-wd','--working_directory', action = 'store', nargs = 1,
                        default = [os.getenv("NPB_WORKDIR")],
                        help = 'top working directory')
    ############
    args = parser.parse_args()
    ymd = args.yearmonthday[0]
    var = args.var[0]
    exp_dirs = args.dirs
    exp_names = args.names
    FORCE_READ_DATA = args.force_read
    work_dir = args.working_directory[0]
    exps = dict(zip(exp_names, exp_dirs))
    
    ################################################
    # hopeful nothing below here needs to be changed
    ds_save = Path(work_dir + "/DIAG/ZARR/" + ymd) / 'monthly.zarr'
    Path(ds_save).parent.mkdir(parents=True, exist_ok=True)
    ds = py.grabdata(ds_save, exps, ymd, FORCE_READ_DATA)

    ################################################
    ds = py.ds_addvar(ds, var)
    ice_vars = ['ice_extent', 'ice_volume', 'snow_volume', 'aice', 'albsni', 'hi', 'hs']
    model = 'ice' if var in ice_vars else 'ocn'
    ds = ds[var].sel(component = model) 
    
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
    if len(exps) == 2 and model == 'ocn':
        py.maps.three_panel(ds)

    ########################
    # line plots
    if model == 'ocn':
        py.plots.line(ds, 'global', obs)
        py.plots.line(ds, 'nino34', obs)
        py.plots.line(ds, 'tropics', obs)
        py.plots.line(ds, 'Arctic', obs)
        py.plots.line(ds, 'Antarctic', obs)
    if 'hemisphere' in ds.dims:
        ob = obs.sel(hemisphere = 'NH') if var in ['ice_extent'] else False
        py.plots.line(ds.sel(hemisphere = 'NH'), 'Arctic', ob)
        ob = obs.sel(hemisphere = 'SH') if var in ['ice_extent'] else False
        py.plots.line(ds.sel(hemisphere = 'SH'), 'Antarctic', ob)

    print('SCRIPT FINISHED')

if __name__ == "__main__":
    main()

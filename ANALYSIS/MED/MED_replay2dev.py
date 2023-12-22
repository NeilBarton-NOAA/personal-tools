#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   edit replay mediator restart for more recent version of model
########################
# Denise's email 
#   The actual process will depend on the field though. 
#    For fields which are now present, but were not present previously, I think you can safely set any added field to zero. 
#   evap Field   
#       Previously the ATM exported latent which was converted in the mediator to evap (sent to the ocean). 
#       Now the ATM exports evap directly. So the new evap field will need to be created from the latent field.
#   There are also a set of fields which will need to have their signs changed (taux,tauy,sensible). 
########################
import argparse
import numpy as np
import os
import sys
import xarray as xr

################################################
# parse arguments
parser = argparse.ArgumentParser( description = "mediator file")
parser.add_argument('-r', '--replay', action = 'store', nargs = 1, \
        default=['/scratch2/NCEPDEV/stmp3/Neil.Barton/ICs/2017100503/ufs.cpld.cpl.r.2017-10-05-10800.nc'], \
        help="replay mediator restart file (ufs.cpld.cpl.r)")
parser.add_argument('-d', '--dev', action = 'store', nargs = 1, \
        default=['/home/Neil.Barton/ANALYSIS/MED/ufs.cpld.cpl.r.2013-04-01-36000.nc'], \
        help="dev mediator restart file (ufs.cpld.cpl.r)")
args = parser.parse_args()
r = args.replay[0]
d = args.dev[0]
print('Replay Med File:', r)
print('Develop Med File:', d)
rdat = xr.open_dataset(r)
ddat = xr.open_dataset(d)

################################################
# get variables in data
#   variable naming convention
#    modelDirection_variable 
#    model -> atm, ocn, ice, wav
#    Direction -> Imp: into the mediator (from model)
#                 Exp: out of mediator (to the model)
#    variable -> variable 
r_vars = set(rdat.variables.keys())
d_vars = set(ddat.variables.keys())
diff_vars = list(d_vars - r_vars)

################################################
# update in code has fluxed defined as positive down, and some variables need to be multipled by -1 
#   does the update code need atmExp_Faox_* variables added?
#   replay code only has atmExp_Faii_* variables
c_vars = ['tauy', 'taux', 'sen']
for v in r_vars:
    v_name = v.split('_')[-1]
    if (v[0:3] == 'atm') and (v_name in c_vars):
        print('Switching sign of', v)
        rdat[v] = rdat[v] * -1.0

################################################
# add evaporation: (replay latent heat) to (dev evaporation)
#   atmImp_Faxa_lat to atmImp_Faxa_evap 
#   https://github.com/NOAA-EMC/CMEPS/compare/cec8db8d09fa0a0b016d197a68edc67cbd100d97...9923d6d17700daf502d9a016138bf8eb8aad7f09
#   latent heat / const_lhvap = > evap
const_lhvap = 2.501e6  # latent heat of evaporation  used in replay (J/kg)
# should this be multiplied by negative 1?
rdat['atmImp_Faxa_evap'] = (rdat['atmImp_Faxa_lat'].dims, -1.0 * rdat['atmImp_Faxa_lat'].values / const_lhvap)

################################################
# add missing variables
#   if lat/lon add lat and lon
#   if variable, add as zero 
for v in r_vars:
#    if (v in d_vars) and (v != 'time') and (v[0:6] == 'atmExp'):
#        print(v)
#        print(ddat[v].mean().values)
#        print(rdat[v].mean().values)
#        #if np.sign(ddat[v].mean().values) != np.sign(rdat[v].mean().values):
#        #    print(v)
#        #    print(ddat[v].mean().values)
#        #    print(rdat[v].mean().values)
#        #    print('')
#        #    print('')
################################################
# add new variables as zeros
for v in diff_vars:
    if v[-3:] in ['lat', 'lon']:
        print('adding lat/lon values', v)
        rdat[v] = (ddat[v].dims, ddat[v].values)
    else:
        print('adding zeros', v)
        rdat[v] = (ddat[v].dims, np.zeros(ddat[v].shape))
#print(diff_vars)


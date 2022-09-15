#!/usr/bin/env python3
########################
#  Neil P. Barton (NOAA-EMC), 2022-08-30 Tue 08:05 AM UTC
#   tools to determing timings for different MPI configurations for running coupled model
# http://earthsystemmodeling.org/docs/release/ESMF_8_3_0/ESMF_refdoc/node6.html#SECTION060132200000000000000
########################
import argparse
import collections
import glob
import numpy as np
import pandas as pd
import os

parser = argparse.ArgumentParser(description="This script parses the stout_espc.list file to display a summary of UFS forecast timings")
parser.add_argument('-d', '--directory', action='store', default='RTs', nargs = 1, help="top directory to search for stout_espc.list files")
parser.add_argument('-s', '--sortby', action='store', default='WALLTIME', nargs = 1, help='header to sort results, default is WALLTIME')
parser.add_argument('-m', '--med', action='store_true', help='show mediator MPI, PE and Timings')
parser.add_argument('-io', '--atmio', action='store_true', help='show ATM IO timings')
parser.add_argument('-l', '--loop', action='store_true', help='show what coupling loop component is on')
parser.add_argument('-pe', '--pes', action='store_true', help='show PEs for components')
args = parser.parse_args()
TOPDIR = args.directory
if TOPDIR == 'RTs':
    TOPDIR = os.environ['NPB_WORKDIR'] + '/RUNs/RTs'
else:
    TOPDIR = TOPDIR[0]
SHOW_MED =  args.med
SHOW_ATMIO = args.atmio
SHOW_LOOP = args.loop
SHOW_PES = args.pes
SORTBY = args.sortby

####################################
# search for ESMF_Profile.summary files
s = 0
files = []
search = ''
print('searching for namelist files in:', TOPDIR)
while (s < 4 ):
    test_dir = TOPDIR + search + '/'
    if len(glob.glob(test_dir)) == 0:
        if s == 0:
            print('directory does not exist:', test_dir)
        s = 9999
    search = search + '/*'
    text_search = TOPDIR + search + 'ESMF_Profile.summary'
    s_files = glob.glob(text_search)
    if len(s_files) > 0:
        files.extend(s_files)
        s += 1
    if (s > 0) and len(s_files) == 0:
        s += 1       
if len(files) == 0:        
    print('no ESMF_Profile.summary files found')
    exit(1)

####################################
# grab data from files
#files=[files[1]]
ESMF_SUMMARY, MODEL_SUMMARY = [], []
for i, f in enumerate(list(files)):
  print(i+1, f)
  DICT = { }
  dir_name = os.path.dirname(f)
  DICT['NAME'] = dir_name.split('/')[-1]
  ############
  # model configuration information
  config_file = dir_name + '/nems.configure'
  for line in open(config_file): 
    if 'EARTH_component_list:' in line:
      DICT['COMPONENTS'] = line.split(':')[-1].strip().replace(' ','-')
    if 'omp_num_threads:' in line:
      DICT[line[0:3] + 'thr'] = int(line.split(':')[-1])
    if 'mesh_' in line:
      C = line.split('mesh_')[-1][0:3].upper()
      RES = line.strip()[-6:-3]
      if RES[0] == '0':
        RES= '0.' + RES.split('0')[-1]
      DICT[C + 'res'] = RES
    if '_petlist_bounds' in line:
      DICT[line.split('_petlist_bounds')[0].strip() + 'pet_beg'] = int(line.split('_petlist_bounds:')[-1].strip().split(' ')[0])
      DICT[line.split('_petlist_bounds')[0].strip() + 'pet_end'] = int(line.split('_petlist_bounds:')[-1].strip().split(' ')[-1])
  ############
  # FV3
  config_file = dir_name + '/model_configure'
  for line in open(config_file):
    if 'nhours_fcst' in line:
      DICT['TAU'] = int(line.split(':')[-1])
  DICT['ATMres'] = glob.glob(dir_name + '/INPUT/*_grid.tile1.nc')[0].split('/')[-1].split('_grid')[0]
  config_file = dir_name + '/input.nml'
  for line in open(config_file):
    if 'levp =' in line:
      DICT['ATMres'] = DICT['ATMres'] + 'L' + line.split('levp = ')[-1].strip()
  ############
  # out file for total amount of wall time
  config_file = dir_name + '/out'
  for line in open(config_file):
    if ' The total amount of wall time' in line:
      DICT['WALLTIME'] = round(float(line.split('=')[-1]) / 3600.,2)
  ############
  # GOCART
  config_file = dir_name + '/AERO_HISTORY.rc'
  for line in open(config_file):
    if 'GRID_LABELS:' in line:
      DICT['CHMres'] = line.split(':')[-1].strip()[2:9]
  ############
  # MOM
  config_file = dir_name + '/INPUT/MOM_input'
  for line in open(config_file):
    if 'NK = ' in line:
      DICT['OCNres'] = DICT['OCNres'] + 'L' + line.split('NK = ')[1].split('!')[0].strip() 
  ############
  # CICE
  #config_file = dir_name + '/ice_in'
  ############
  # WAV
  #config_file = dir_name + '/log.ww3'
  MODEL_SUMMARY.append(DICT)
  ########################
  # create a configuration header
  COMPS = DICT['COMPONENTS'].replace('-',' ').split(' ')
  if 'ATM' and 'OCN' and 'ICE' and 'WAV' and 'CHM' in COMPS:
    DICT['CONFIG'] = 'S2SWA'
  elif 'ATM' and 'OCN' and 'ICE' and 'WAV' and not 'CHM' in COMPS:
    DICT['CONFIG'] = 'S2SW'
  elif 'ATM' and 'OCN' and 'ICE' and not 'WAV' and not 'CHM' in COMPS:
    DICT['CONFIG'] = 'S2S'
  elif 'ATM' and not 'OCN' and not 'ICE' and not 'WAV' and not 'CHM' in COMPS:
    DICT['CONFIG'] = 'ATM'
  else:
    print('FATAL: configuration unkown from', COMPS)
    exit(1)
  COMPS_NOMED = COMPS.copy()
  COMPS_NOMED.remove('MED')
  DICT['RESOLUTION'] = ''
  for C in COMPS_NOMED:
    DICT['RESOLUTION'] = DICT['RESOLUTION'] + DICT[C+'res'] + ' '
  ########################
  # information from ESMF_Profile.summary
  ESMF_data = []
  for j, line in enumerate(open(f)):
    if j == 10:
      ESMF_header = ['Region', 'Phase']
      for t in line.split('  '):
        if len(t) > 1 and t != 'Region':
          if ' PET ' in t:
            ESMF_header.append(t.split('Max')[0].strip())
            ESMF_header.append(t.split('PET')[-1].strip())
          else:
            ESMF_header.append(t.strip())
    elif j > 10:
      d, col_text = [], []
      text = line[0:70].strip()
      if ']' in text:
        r = text.split(']')[0].replace(']','').replace('[','')
        p = text.split(']')[-1]
      elif 'ESMF' in text:
        r = text.split('ESMF')[0]
        p = text.split('ESMF_')[-1]
      elif ':' in text:
        r = text.split(':')[0].replace(':','')
        p = text.split(':')[-1]
      else:
        print('FATAL: script cannot parse column')
        exit(1)
      d.append(r)
      d.append(p)
      for t in line[71::].split(' '):
        try:
          d.append(float(t))
        except:
          pass
      ESMF_data.append(d)
  ESMF_df = pd.DataFrame(ESMF_data, np.arange(len(ESMF_data)) + 1, ESMF_header )
  ####################################
  # add mean time for each component
  DICT['PETs'] = int(ESMF_df['PETs'].max()) 
  LOOP_ALL = []
  for C in COMPS:
    if C == 'ATM':
      DICT[C+'mpi'] = int(ESMF_df['PETs'].where(ESMF_df['Region'] == 'fv3_fcst').max())
      DICT[C+'pe'] = int(ESMF_df['PEs'].where(ESMF_df['Region'] == 'fv3_fcst').max()) 
      DICT['ATMIOmpi'] = int(ESMF_df['PETs'].where(ESMF_df['Region'] == 'wrtComp_01').max())
      DICT['ATMIOpe'] = int(ESMF_df['PEs'].where(ESMF_df['Region'] == 'wrtComp_01').max())
      DICT['ATMIOsec'] = round(ESMF_df['Mean (s)'].where(ESMF_df['Region'] == 'wrtComp_01').sum(),1)
    else:
      DICT[C+'mpi'] = int(ESMF_df['PETs'].where(ESMF_df['Region'] == C).max())
      DICT[C+'pe'] = int(ESMF_df['PEs'].where(ESMF_df['Region'] == C).max()) 
    LOOP = ESMF_df[ESMF_df['Region'] == C ]['Count'].max()
    try:
      DICT[C+'mpi-t'] = str(DICT[C+'mpi']) + '-' + str(int(DICT[C+'thr']))
    except:
      DICT[C+'thr'] = ''
      DICT[C+'mpi-t'] = str(DICT[C+'mpi']) + '-' + str(DICT[C+'thr'])
    if C == 'MED':
      DICT[C+'sec'] = round(ESMF_df[ESMF_df['Region'] == C].sum()['Mean (s)'], 1)
    else:
      LOOP_ALL.append(LOOP) 
      DICT[C+'loop'] = LOOP
      DICT[C+'sec'] = round(ESMF_df[ESMF_df['Region'] == C].loc[ESMF_df['Count'] == LOOP].sum()['Mean (s)'],1)
  ########################
  # See if components are on same PETs
  #   and define if coupling is on the fast or slow loop
  PET_DATA = np.zeros([len(COMPS_NOMED),2]) - 9999
  for k, C in enumerate(COMPS_NOMED):
    PET_DATA[k,0] = DICT[C+'pet_beg']
    PET_DATA[k,1] = DICT[C+'pet_end']
    DICT[C+'loop'] = 'Slow' if DICT[C+'loop'] == min(LOOP_ALL) else 'Fast'
  DICT['MEDloop'] = 'MED'
  ########################
  # summarize variables when compoents on same PETS
  index = np.where(np.diff(PET_DATA[:,0]) == 0)[0]
  for k in index:
    C0 = COMPS_NOMED[k]
    C1 = COMPS_NOMED[k+1]
    C_NAME = C0 + "+" + C1 
    DICT[C_NAME+'loop'] = DICT[C+'loop']
    DICT[C_NAME+'pet_beg'] = min(DICT[C0+'pet_beg'], DICT[C1+'pet_beg'])
    DICT[C_NAME+'pet_end'] = min(DICT[C0+'pet_end'], DICT[C1+'pet_end'])
    DICT[C_NAME+'mpi'] = max(DICT[C0+'mpi'], DICT[C1+'mpi'])
    DICT[C_NAME+'pe'] = max(DICT[C0+'pe'], DICT[C1+'pe'])
    DICT[C_NAME+'mpi-t'] = str(DICT[C_NAME+'mpi']) + '-' + str(DICT[C0+'thr']) 
    DICT[C_NAME+'sec'] = DICT[C0+'sec'] + DICT[C1+'sec']
    COMPS_NOMED.insert(k+2, C_NAME)
    COMPS.insert(k+3, C_NAME)
  ########################
  # Calculate a percentage of time for each component/PET (to do)  
  ########################
  # Save ESMF panda for future if needed
  ESMF_SUMMARY.append(ESMF_df)

########################
# create pandas from summaries
pd.options.display.max_rows = None
pd.options.display.max_columns = 99
pd.options.display.width = 500
pd.options.display.colheader_justify = 'center'

MODEL_header = []
for key, value in DICT.items():
  MODEL_header.append(key)
MODEL_df = pd.DataFrame(MODEL_SUMMARY, np.arange(len(files)) + 1, MODEL_header )

if SORTBY[0] not in MODEL_header:
  print("FATAL: SORTBY not found in header")
  print("\t SORTBY:\t", SORTBY[0])
  print("\t HEADER:\t", MODEL_header)
  exit(1)

########################
# filter through what to print from MODEL_header
HEAD_PRINT = ['CONFIG', 'RESOLUTION', 'TAU', 'WALLTIME', 'PETs']
HEAD_COMPS = COMPS if SHOW_MED else COMPS_NOMED
REMOVE_HEAD_PRINT = []
for C in HEAD_COMPS: 
  HEAD_PRINT.append(C+'mpi-t')
  if '+' in C:
    for CC in C.split('+'):
      if (MODEL_df[C+'mpi-t'] == MODEL_df[CC+'mpi-t']).all():
        REMOVE_HEAD_PRINT.append(CC)
  if C == 'ATM':
    HEAD_PRINT.append('ATMIOmpi')

for C in HEAD_COMPS: 
  HEAD_PRINT.append(C+'sec')
  if C == 'ATM':
    HEAD_PRINT.append('ATMIOsec')

# remove items that share PEs
for C in REMOVE_HEAD_PRINT:
  HEAD_PRINT.remove(C+'mpi-t')
  HEAD_PRINT.remove(C+'sec')

# if showing ATMIO stats
if SHOW_ATMIO:
  HEAD_PRINT.insert(HEAD_PRINT.index('ATMIOsec'),'ATMsec')
else:
  if (MODEL_df['ATMsec'] > MODEL_df['ATMIOsec']).all():
    HEAD_PRINT.remove('ATMIOsec')
  else:
    print('WARNING: ATMIO is taking longer than ATM')
    HEAD_PRINT.insert(HEAD_PRINT.index('ATMIOsec'),'ATMsec')

# if showing loop
if SHOW_LOOP:
  for C in COMPS_NOMED:
    HEAD_PRINT.append(C+'loop')

# if showing PEs
if SHOW_PES:
  for C in HEAD_COMPS:
    try:
      HEAD_PRINT.insert(HEAD_PRINT.index(C+'mpi-t')+1,C+'pe')
    except:
      pass


if SORTBY[0] not in HEAD_PRINT:
  print(SORTBY, HEAD_PRINT)
  print('in here')
  HEAD_PRINT.append(SORTBY[0])

SUM = 'SHARED \n'
LOOP = HEAD_PRINT.copy()
for H in LOOP:
  if (MODEL_df[H] == MODEL_df[H][1]).all():
    TABS = ': \t\t' if len(H) < 5 else ': \t'
    SUM = SUM + H + TABS + str(MODEL_df[H][1]) + '\n'
    HEAD_PRINT.remove(H)

MODEL_df = MODEL_df.sort_values(SORTBY)
print('\n\n\n')
print(SUM)
print(MODEL_df[HEAD_PRINT])


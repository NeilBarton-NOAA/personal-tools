########################
# read namelist and out files to obtain data
#   nems.configure -> ESMF configure
#   input.nml, model_configure -> FV3
#   MOM_input -> MOM6
#   ice_in -> CICE
#   log.ww3 -> WW3
####################################
def read_nemsconfigure(dir_name):
    import numpy as np
    DICT = {}
    config_file = dir_name + '/nems.configure'
    L = []
    for line in open(config_file): 
        if 'EARTH_component_list:' in line:
            DICT['COMPONENTS'] = line.strip('EARTH_component_list:').strip().replace(' ','-')
            DICT['COMPS'] = DICT['COMPONENTS'].replace('-',' ').split(' ')
        if 'omp_num_threads:' in line:
            DICT[line[0:3] + 'thr'] = int(line.split(':')[-1])
        if 'mesh_' in line:
            C = line.split('mesh_')[-1][0:3].upper()
            RES = line.strip()[-6:-3]
            if RES[0] == '0':
                RES= '0.' + RES.split('0')[-1]
            DICT[C + 'res'] = RES
        if '_petlist_bounds' in line:
            DICT[line.split('_petlist_bounds')[0].strip() + 'pet_beg'] = \
                int(line.split('_petlist_bounds:')[-1].strip().split(' ')[0])
            DICT[line.split('_petlist_bounds')[0].strip() + 'pet_end'] = \
                int(line.split('_petlist_bounds:')[-1].strip().split(' ')[-1])
        if '@' in line:
            if len(line.strip()) > 1:
                L.append(int(line.strip().strip('@')))
    if len(L) > 2:
        print('FATAL: more than two coupling loops found')
        print(L)
        exit(1)
    DICT['LOOPslow'] = max(L)
    DICT['LOOPfast'] = min(L)
    return DICT

####################################
def read_model_configure(dir_name):
    DICT = {}
    config_file = dir_name + '/model_configure'
    for line in open(config_file):
        if 'nhours_fcst' in line:
            DICT['TAU'] = int(line.split(':')[-1])
        if 'restart_interval:' in line:
            DICT['RESTART_N'] = int(line.split('restart_interval:')[1].strip().split(' ')[0])
        if 'dt_atmos' in line:
            DICT['ATMdt'] = int(line.strip('dt_atmos:'))
    config_file = dir_name + '/input.nml'
    for line in open(config_file):
        if 'npx' in line:
            DICT['ATMres'] = 'C' + str(int(line.split('npx =')[-1].strip()) - 1)
        if 'levp =' in line:
            ATMlev = line.split('levp = ')[-1].strip()
        if ' layout =' in line:
            DICT['ATMlayout'] = line.split(' layout = ')[-1].strip()
        if 'io_layout' in line:
            DICT['ATMiolayout'] = line.strip('io_layout =').strip()
    if 'ATMres' in DICT:
        DICT['ATMres'] = DICT['ATMres'] + 'L' + ATMlev
        DICT['CHMres'] = DICT['ATMres']
    return DICT

####################################
def read_stdout(dir_name):
    DICT = {}
    config_file = dir_name + '/out'
    for line in open(config_file):
        if ' The total amount of wall time' in line:
            DICT['WALLTIMEsec'] = float(line.split('=')[-1]) 
            DICT['WALLTIME'] = round(float(line.split('=')[-1]) / 3600.,2)
    return DICT

####################################
def read_MOM_input(dir_name):
    DICT = {}
    config_file = dir_name + '/INPUT/MOM_input'
    for line in open(config_file):
        if 'NIGLOBAL = ' in line:
            I = int(line.split('NIGLOBAL = ')[1].split(' ')[0])
        if 'NJGLOBAL = ' in line:
            J = int(line.split('NJGLOBAL = ')[1].split(' ')[0])
        if 'NK = ' in line:
            L = 'L' + line.split('NK = ')[1].split('!')[0].strip() 
        if 'DT =' in line:
            DICT['OCNdt'] = int(line.strip('DT =').split('!')[0])
        if 'DT_THERM =' in line:
            DICT['OCNdttherm'] = int(line.strip('DT_THERM =').split('!')[0])
    if I == 1440 and J == 1080:
        RES = '0.25'
    else:
        print('FATAL: OCNres unknown from I and J: I =', I, ' J =', J)
    DICT['OCNres'] = RES + L
    config_file = dir_name + '/INPUT/MOM_layout'
    for line in open(config_file):
        if 'IO_LAYOUT' in line:
            DICT['OCNiolayout'] = line.strip('IO_LAYOUT =').strip()
    return DICT

####################################
def read_ice_in(dir_name):
    DICT = {}
    config_file = dir_name + '/ice_in'
    for line in open(config_file):
        if '  dt  ' in line:
            DICT['ICEdt'] = int(line.split('=')[-1])
    return DICT

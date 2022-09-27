import glob
import numpy as np
import pandas as pd

####################################
# search for ESMF_Profile.summary files
def getfiles(TOPDIR):
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
    else:
        return files

####################################
def panda_addto_dict(df, DICT, MED_VAR):
    DICT['MED_VAR'] = MED_VAR
    DICT['PETs'] = int(df['PETs'].max()) 
    LOOP_ALL = []
    for C in DICT['COMPS']:
        if C == 'ATM':
            DICT[C+'mpi'] = int(df['PETs'].where(df['Region'] == 'fv3_fcst').max())
            DICT[C+'pe'] = int(df['PEs'].where(df['Region'] == 'fv3_fcst').max()) 
            DICT['ATMIOmpi'] = int(df['PETs'].where(df['Region'] == 'wrtComp_01').max())
            DICT['ATMIOpe'] = int(df['PEs'].where(df['Region'] == 'wrtComp_01').max())
            DICT['ATMIOsec_mean'] = round(df['Mean (s)'].where(df['Region'] == 'wrtComp_01').sum(),1)
            DICT['ATMIOsec_max'] = round(df['Max (s)'].where(df['Region'] == 'wrtComp_01').sum(),1)
        else:
            DICT[C+'mpi'] = int(df['PETs'].where(df['Region'] == C).max())
            DICT[C+'pe'] = int(df['PEs'].where(df['Region'] == C).max()) 
        LOOP = df[df['Region'] == C ]['Count'].max()
        try:
            DICT[C+'mpi-t'] = str(DICT[C+'mpi']) + '-' + str(int(DICT[C+'thr']))
        except:
            DICT[C+'thr'] = 1
            DICT[C+'mpi-t'] = str(DICT[C+'mpi']) + '-' + str(DICT[C+'thr'])
        if C == 'MED':
            DICT[C+'sec_mean'] = round(df[df['Region'] == C].sum()['Mean (s)'], 1)
            DICT[C+'sec_max'] = round(df[df['Region'] == C].sum()['Max (s)'], 1)
        else:
            LOOP_ALL.append(LOOP) 
            DICT[C+'loop'] = LOOP
            if C == 'ATM':
                DICT[C+'sec_mean'] = round(df[df['Region'] == 'fv3_fcst'].loc[df['Count'] == LOOP].sum()['Mean (s)'],1)
                DICT[C+'sec_max'] = round(df[df['Region'] == 'fv3_fcst'].loc[df['Count'] == LOOP].sum()['Max (s)'],1)
            else:
                DICT[C+'sec_mean'] = round(df[df['Region'] == C].loc[df['Count'] == LOOP].sum()['Mean (s)'],1)
                DICT[C+'sec_max'] = round(df[df['Region'] == C].loc[df['Count'] == LOOP].sum()['Max (s)'],1)
    DICT['TOstd'] = 0
    me, ma = [], []
    for M in MED_VAR: 
        DICT[M+'sec_mean'] = round(df[df['Region'] == M].loc[df['Phase'] == 'RunPhase1']\
            .loc[df['Count'] > 1].sum()['Mean (s)'],1)
        DICT[M+'sec_max'] = round(df[df['Region'] == M].loc[df['Phase'] == 'RunPhase1']\
            .loc[df['Count'] > 1].sum()['Max (s)'],1)
        me.append(DICT[M+'sec_mean'])
        ma.append(DICT[M+'sec_max'])
    me = np.array(me)
    ma = np.array(ma)
    for M in MED_VAR: 
        DICT[M+'z_mean'] = round((DICT[M+'sec_mean'] - np.mean(me)) / np.std(me),1)
        DICT[M+'z_max'] = round((DICT[M+'sec_max'] - np.mean(ma)) / np.std(ma),1)
    return DICT

####################################
def to_panda(f):
    ESMF_data, MED_VAR  = [], []
    AFTER_HEADER = False
    for line in open(f):
        if len(line.strip()) > 0:
            # find APP-TO-APP that may be causing load imbalances
            if line.strip()[0] == '-':
                MED_VAR.append(line.split(' ')[2].replace('[','').replace(']',''))
                AFTER_HEADER = True
            # get header
            elif line.split(' ')[0].strip()  == 'Region':
                ESMF_header = ['Region', 'Phase']
                for t in line.split('  '):
                    if len(t) > 1 and t != 'Region':
                        if ' PET ' in t:
                            ESMF_header.append(t.split('Max')[0].strip())
                            ESMF_header.append(t.split('PET')[-1].strip())
                        else:
                            ESMF_header.append(t.strip())
            # data set
            elif AFTER_HEADER and line[0] != '*':
                # parse colums with text
                text, d, = line[0:70].strip(), []
                if ']' in text:
                    r = text.split(']')[0].replace(']','').replace('[','').strip()
                    p = text.split(']')[-1].strip()
                elif 'ESMF' in text:
                    r = text.split('ESMF')[0].strip()
                    p = text.split('ESMF_')[-1].strip()
                elif ':' in text:
                    r = text.split(':')[0].replace(':','').strip()
                    p = text.split(':')[-1].strip()
                else:
                    print('FATAL: script cannot parse column')
                    exit(1)
                d.append(r)
                d.append(p)
                # parse numbers
                for t in line[71::].split(' '):
                    try:
                        d.append(float(t))
                    except:
                        pass
                ESMF_data.append(d)
    ESMF_df = pd.DataFrame(ESMF_data, np.arange(len(ESMF_data)) + 1, ESMF_header )
    return ESMF_df, MED_VAR

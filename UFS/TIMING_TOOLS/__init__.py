import args, esmfprofile, namelists, plot


####################################
def nameruns(DICT):
    COMPS = DICT['COMPS']
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
    COMPS = DICT['COMPS']
    COMPS_NOMED = COMPS.copy()
    COMPS_NOMED.remove('MED')
    DICT['RESOLUTION'] = ''
    for C in COMPS_NOMED:
        if '+' in C:
            DICT['RESOLUTION'] = DICT['RESOLUTION'] + DICT[C.split('+')[0] + 'res'] + ' '
        if C != 'CHM' and C != 'ICE' and '+' not in C:
            DICT['RESOLUTION'] = DICT['RESOLUTION'] + DICT[C+'res'] + ' '
        elif C == 'ICE' and DICT['ICEres'] != DICT['OCNres'][0:4]:
            DICT['RESOLUTION'] = DICT['RESOLUTION'] + DICT[C+'res'] + ' '
    return DICT

####################################
def parse_same_pets(DICT):
    import numpy as np
    # get start and ending PETS
    COMPS = DICT['COMPS']
    COMPS_NOMED = COMPS.copy()
    COMPS_NOMED.remove('MED')
    LOOP_ALL = []
    for C in COMPS_NOMED:
        LOOP_ALL.append(DICT[C+'loop'])
    PET_DATA = np.zeros([len(COMPS_NOMED),2]) - 9999
    for k, C in enumerate(COMPS_NOMED):
        PET_DATA[k,0] = DICT[C+'pet_beg']
        PET_DATA[k,1] = DICT[C+'pet_end']
        DICT[C+'loop'] = 'Slow' if DICT[C+'loop'] == min(LOOP_ALL) else 'Fast'
    DICT['MEDloop'] = 'MED'
    # summarize variables when compoents on same PETS
    index = np.where(np.diff(PET_DATA[:,0]) == 0)[0]
    DICT['COMPS_SAMEPETS'] = []
    for k in index:
        C0 = COMPS_NOMED[k]
        C1 = COMPS_NOMED[k+1]
        C_NAME = C0 + "+" + C1 
        DICT[C_NAME+'loop'] = DICT[C+'loop']
        DICT[C_NAME+'pet_beg'] = min(DICT[C0+'pet_beg'], DICT[C1+'pet_beg'])
        DICT[C_NAME+'pet_end'] = min(DICT[C0+'pet_end'], DICT[C1+'pet_end'])
        DICT[C_NAME+'mpi'] = max(DICT[C0+'mpi'], DICT[C1+'mpi'])
        DICT[C_NAME+'thr'] = max(DICT[C0+'thr'], DICT[C1+'thr'])
        DICT[C_NAME+'pe'] = max(DICT[C0+'pe'], DICT[C1+'pe'])
        DICT[C_NAME+'mpi-t'] = str(DICT[C_NAME+'mpi']) + '-' + str(DICT[C0+'thr']) 
        DICT[C_NAME+'sec_mean'] = DICT[C0+'sec_mean'] + DICT[C1+'sec_mean']
        DICT[C_NAME+'sec_max'] = DICT[C0+'sec_max'] + DICT[C1+'sec_max']
        DICT['COMPS_SAMEPETS'].append(C_NAME)
    return DICT

########################
def print_summary(df, ARGS):
    import pandas as pd
    # create pandas from summaries
    pd.options.display.max_rows = None
    pd.options.display.max_columns = 99
    pd.options.display.width = 500
    pd.options.display.colheader_justify = 'center'
    
    # filter through what to print from MODEL_header
    HEAD_PRINT = ['CONFIG', 'RESOLUTION', 'TAU', 'MINpDAY', 'MINpDAYgoal', 'PETs']
    HEAD_COMPS = df['COMPS'][1] 
    HEAD_COMPS.remove('MED')
    REMOVE_HEAD_PRINT = []
    for C in df['COMPS_SAMEPETS'][1]:
        HEAD_PRINT.append(C+'mpi-t')
    for C in HEAD_COMPS: 
        for SM in df['COMPS_SAMEPETS'][1]:
            if C not in SM:
                HEAD_PRINT.append(C+'mpi-t')
        if C == 'ATM':
            HEAD_PRINT.append('ATMIOmpi')

    for C in HEAD_COMPS: 
        HEAD_PRINT.append(C+'sec_max')
        if C == 'ATM':
            HEAD_PRINT.append('ATMIOsec_max')

    # remove items that share PEs
    for C in REMOVE_HEAD_PRINT:
        HEAD_PRINT.remove(C+'mpi-t')
        HEAD_PRINT.remove(C+'sec_max')

    # if showing ATMIO stats
    if ARGS.SHOW_ATMIO:
        HEAD_PRINT.insert(HEAD_PRINT.index('ATMIOsec_max'),'ATMsec_max')
    else:
        if (df['ATMsec_max'] > df['ATMIOsec_max']).all():
            HEAD_PRINT.remove('ATMIOsec_max')
        else:
            print('WARNING: ATMIO is taking longer than ATM')
            HEAD_PRINT.insert(HEAD_PRINT.index('ATMIOsec_max'),'ATMsec_max')

    # if showing loop
    if ARGS.SHOW_LOOP:
        for C in COMPS_NOMED:
            HEAD_PRINT.append(C+'loop')

    # if showing PEs
    if ARGS.SHOW_PES:
        for C in HEAD_COMPS:
            try:
                HEAD_PRINT.insert(HEAD_PRINT.index(C+'mpi-t')+1,C+'pe')
            except:
                pass

    if ARGS.SHOW_MED:
        MED_VAR = df['MED_VAR'][1]
        for M in MED_VAR:
            HEAD_PRINT.append(M+'sec_max')
    
    # remove items that are the same 
    SUM = 'SHARED \n'
    LOOP = HEAD_PRINT.copy()
    for H in LOOP:
        if (df[H] == df[H][1]).all():
            TABS = ': \t\t' if len(H) < 5 else ': \t'
            SUM = SUM + H + TABS + str(df[H][1]) + '\n'
            HEAD_PRINT.remove(H)

    if ARGS.SORTBY not in HEAD_PRINT:
        print(ARGS.SORTBY, HEAD_PRINT)
        HEAD_PRINT.append(SORTBY)

    df = df.sort_values(ARGS.SORTBY)
    fw = 'esmf_summary.txt'
    print('\n\n\n')
    print(SUM)
    print(df[HEAD_PRINT])
    df[HEAD_PRINT].to_string(fw)
    f = open(fw,'a')
    f.write('\n\n')
    f.write(SUM)
    f.write('\n') 
    for i in range(df.shape[0]):
        f.write(str(i+1) + ' ' + df['NAME'][i+1] + '\n')
    f.close()


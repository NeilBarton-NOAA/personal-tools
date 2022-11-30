########################
#read hdf5 data
########################

def getdata(filename, key, variable):
    import h5py
    import numpy as np
    file_id = h5py.File(filename, 'r')
    d = file_id[key]
    dat = d[variable]
    if dat.shape[0] == 1:
        dat = np.squeeze(dat)
    file_id.close()
    return dat

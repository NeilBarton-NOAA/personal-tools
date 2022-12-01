########################
#read/write numpy npz data
########################
def getdata(filename, variable):
    """
    """
    from numpy import load
    dat = load(filename)
    return dat[variable]

def getvars(filename):
    """
    """
    from numpy import load
    dat = load(filename)
    return dat.keys()

def writedata(filename, variablename, variable):
    """
    """
    from numpy import load, savez
    from os.path import isfile
    ###############
    if isfile(filename):
        datnpz = load(filename)
        keys = datnpz.keys()
        for i, k in enumerate(keys):
            if i == 0.0:
                d = dict(zip((k, 'dum'), (datnpz[k], -9999.0)))
            else:
                d.update(zip((k, 'dum'), (datnpz[k], -9999.0)))
        d.update(zip((variablename, 'dum'), (variable, -9999.0)))
        d.pop('dum')
        savez(filename, **d)
    else:
        d = dict(zip((variablename, 'dum'), (variable, -9999.0)))
        d.pop('dum')
        savez(filename, **d)


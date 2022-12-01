########################
#read NetCDF data
########################

def getattrs(filename, variable):
    from netCDF4 import Dataset
    file_id = Dataset(filename, 'r')
    var = file_id.variables[variable]
    dict = {}
    ############
    # dimensions
    dims = var.dimensions
    dim = []
    for d in dims:
        dim.append(d.encode('ascii'))
    dict['dimensions'] = dim
    ############
    # shape
    sha = var.shape
    dict['shape'] = sha
    ############
    # attributes
    attrs = var.ncattrs()
    for a in attrs:
        if a[0] != '_':
            try:
                dict[a.encode('ascii')] = eval('var.' + a).encode('ascii')
            except AttributeError:
                dict[a.encode('ascii')] = eval('var.' + a)
    file_id.close()
    return dict

def getdata(filename, variable):
    from netCDF4 import Dataset
    from numpy import squeeze
    file_id = Dataset(filename, 'r')
    dat = file_id.variables[variable][:]
    if dat.shape[0] == 1:
        dat = squeeze(dat)
    file_id.close()
    return dat

def getvariable(filename, variable):
    from netCDF4 import Dataset
    from numpy import squeeze
    file_id = Dataset(filename, 'r')
    dat = file_id.variables[variable]
    return dat

def getvars(filename):
    from netCDF4 import Dataset
    file_id = Dataset(filename, 'r')
    keys = file_id.variables.keys()
    keys.sort()
    vars = []
    for k in keys:
        vars.append(k.encode('ascii'))
    file_id.close()
    return vars


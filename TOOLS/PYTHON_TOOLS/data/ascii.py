
def getdata(filename, var = 'all_data', delimiter = False, string = False):
    """
    reads data from .dat file (and hopefully text files, et cetera)
    INPUT
        filename:  string of the name of the file to be examined
        delimiter:  the string that seperates the data, if one exist (default is false)
        string:     if desired output of matrix is strings, set to True
    OUTPUT
        data:           the data associated with the file in an numpy.array format
        header:     the text of the file header
    DEPENDENCIES
        numpy
    """
    from numpy import array, where
    dat = []
    header = []
    for line in file(filename):
        if delimiter:
            li = line.split(delimiter)
        else:
            li = line.split()
        try: # read data
            #float(li[0])
            datcol = []
            for i in li:
                if string:
                    datcol.append(i)
                else:
                    try:
                        datcol.append(float(i))
                    except:
                        datcol.append(-9999.0)
            dat.append(datcol)
            del datcol
        except ValueError: # read header
            for i in li:
                header.append(i)
    if var == 'all':
        return array(dat), header
    elif var == 'all_data':
        return array(dat)
    else:
        index = where(header = var)
        return array(dat)[:,index]

def getvars(filename, delimiter = False):
    """
    reads data from .dat file (and hopefully text files, et cetera)
    INPUT
        filename:  string of the name of the file to be examined
        delimiter:  the string that seperates the data, if one exist (default is false)
    OUTPUT
        vars/header:     the text of the file header
    DEPENDENCIES
        numpy
    """
    from numpy import array
    dat = []
    header = []
    line = file(filename).readline()
    if delimiter:
        li = line.split(delimiter)
    else:
        li = line.split()
    for i in li:
        header.append(i)
    return header


################################################
# common utilities
################################################

################################################
################################################
def dist_on_sphere(lon1,lat1,lon2,lat2, R = 6373.1):
    """
    find the distanace on a sphere between two points
    Note, this is NOT the most accurate way of determining distance on EARTH, but is used to compute relative distances and find min and max distances. 
    Maybe something wrong in higher latitudes
    INPUTS
        lon1:    longitude array associated with lat1
        lat1: latitude array associated with lon1
        lon2:    longitude array associated with lat2 (lon2.size must == lat2.size)
        lat2:    latitude array associated with lon2 (lon2.size must == lat2.size)
        R:        radius of sphere (default = 6373.1 (Earth))
    OUTPUT
        dist:    distances in kilometers
    DEPENDENCIES
        numpy 
    """
    from numpy import arccos, array, cos, meshgrid, sin
    from math import pi
    lon1=array(lon1)*pi/180.0
    lat1=array(lat1)*pi/180.0
    lon2=array(lon2)*pi/180.0
    lat2=array(lat2)*pi/180.0
    if (lon2.size != lat2.size):
        lon2, lat2=meshgrid(lon2,lat2)
    di = (sin(lat1)*sin(lat2))+cos(lat1)*cos(lat2)*cos(lon1-lon2)
    result = R*arccos(di)
    return result

################################################
################################################
def closest(matrix, n, axis = None):
    """
    calculate the array location of the closest 'n' equals to the 'array'
    a integer is returned
    This could be optimized
    INPUTS
         matrix:    numpy array of numbers
         n:            the number in which the matrix should be closest
         axis:        the axis of the numpy array in which to calculate the where the data are closest to n
    OUTPUT:
         index:    array of indices where the numpy array is closest to the values in the matrix
    DEPENDENCIES
         numpy
    """
    from numpy import abs
    if axis:
        return abs(matrix - n).argmin(axis = axis)
    else:
        return abs(matrix - n).argmin()

################################################
################################################
def intersect(a, b):
    """
    return an intersect of two arrays
    INPUTS
        a: one array
        b: another array
    OUTPUT
        c: union of the two arrays
    DEPENDENCIES
        numpy
    """
    from numpy import array
    return list(set(a) & set(b))


################################################
################################################
def pause(text=False):
    """
    Pause the program
    INPUT
        text: if text is a number, the program is paused for this amount of seconds
              if text is a string, the string is printed to the screen
    OUTPUT
        a paused program
    DEPENDENCIES
        none
    """
    from time import ctime
    if text:
        if isinstance(text,int) or isinstance(text,float):
            print('PAUSED for ',str(int(text)),' seconds')
            sleep(text)
        else:
            raw_input(text)
    else:
        input = raw_input('PAUSED: press return to continue or q to quit ')
        if input == 'q':
            print('program stopped at ', ctime())
            exit()

########################
########################
def spatialinterp(datS, lonS, latS, lonD, latD, k = 5, R = 6373.1):
    """
    Spatial Interpolatoin
    http://earthpy.org/interpolation_between_grids_with_ckdtree.html
    """
    from scipy.spatial import cKDTree
    from numpy import cos, sin, sum, radians, reshape
    ############
    latD[latD == 90] = 89.9999
    latD[latD == -90] = -89.9999
    from numpy import min, max
    shapeD = lonD.shape
    datS = datS.flatten()
    lonS = lonS.flatten()
    latS = latS.flatten()
    lonD = lonD.flatten()
    latD = latD.flatten()
    ############
    # convert lon, lat to points on sphere
    xS = R * cos(radians(latS)) * cos(radians(lonS))
    yS = R * cos(radians(latS)) * sin(radians(lonS))
    zS = R * sin(radians(latS))
    xD = R * cos(radians(latD)) * cos(radians(lonD))
    yD = R * cos(radians(latD)) * sin(radians(lonD))
    zD = R * sin(radians(latD))
    d = cos(radians(latS))
    ############
    # tree
    #dum = zip(xS, yS) #, zS)
    tree = cKDTree(zip(xS, yS, zS))
    d, inds = tree.query(zD, k = k)
    d[d == 0] = 1.0e-17
    w = 1.0 / d**2.
    datD = sum(w * datS[inds], axis = 1) / sum(w, axis = 1)
    datD = reshape(datD, shapeD)
    return datD

################################################
################################################
def union(a, b):
    """
    return an union of two arrays
    INPUTS
        a:    one array
        b: another array
    OUTPUT
        c: union of the two arrays
    DEPENDENCIES
        numpy
    """
    from numpy import array
    return list(set(a) | set(b))


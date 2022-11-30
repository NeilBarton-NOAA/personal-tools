# grid tools

def area(lat1, lon1):
    #https://stackoverflow.com/questions/639695/how-to-convert-latitude-or-longitude-to-meters/11172685#11172685
    #https://en.wikipedia.org/wiki/Haversine_formula
    #https://stackoverflow.com/questions/639695/how-to-convert-latitude-or-longitude-to-meters/11172685#11172685
    import numpy as np
    lon2 = lon1 + np.diff(lon1, append = lon1[-1] + np.mean(np.diff(lon1)))
    lat2 = lat1 + np.diff(lat1, append = lat1[-1] + np.mean(np.diff(lat1)))
    lat_len = np.abs(lat2 - lat1) * 111.32 #(km)
    lon_len = np.abs(lon2 - lon1) * 40075. * np.cos(np.deg2rad((lat1))) / 360.0
    #lon_len, lat_len = np.meshgrid(lon_len, lat_len)
    return lon_len * lat_len

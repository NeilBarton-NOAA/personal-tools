# some plotting graph 
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import numpy as np
import sys
sys.path.append('/home/Neil.Barton/TOOLS')
import PYTHON_TOOLS as npb
import warnings
warnings.filterwarnings("ignore")
def fxn():
    warnings.warn("deprecated", DeprecationWarning)
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    fxn()

def getICEdomain(domain):
    dx = dy = 25000
    if domain == 'Arctic':
        x = np.arange(-3850000, +3750000, +dx)
        y = np.arange(+5850000, -5350000, -dy)
        kw = dict(central_latitude=90, central_longitude=-45, true_scale_latitude=70)
    elif domain == 'Antarctic':
        x = np.arange(-3950000, +3950000, +dx)
        y = np.arange(+4350000, -3950000, -dy)
        kw = dict(central_latitude=-90, central_longitude=0, true_scale_latitude=-70)
    return x, y, kw

def difference(DAT1, DAT2, ICEOBS = None, domain = 'Arctic'):
    print('in maps.difference')
    if ICEOBS.any():
        x, y, kw = npb.maps.getICEdomain(domain)
    DES = npb.defaults_from_array(DAT1, DAT2)
    titles = DES['TITLES']
    olat, olon = DES['LAT'], DES['LON']
    VMIN, VMAX = DES['MIN'], DES['MAX']
    DMIN, DMAX = DES['DMIN'], DES['DMAX']
    plot_title = DES['PLOT_TITLE']
    save_dir = DES['SAVE_DIR']
    print('before index')
    lon, lat, DAT1 = npb.maptools.index_lon_lat_dat(olon, olat, DAT1.values)
    lon, lat, DAT2 = npb.maptools.index_lon_lat_dat(olon, olat, DAT2.values)
    cmap_DAT = plt.get_cmap('terrain_r')
    cmap_DIFF = plt.get_cmap('seismic')
    # FIGURE
    fig = plt.figure(figsize=(10, 5))
    axs, pcs = [], []
    DAT = [DAT1, DAT2, DAT1 - DAT2]
    try:
        DMIN, DMAX = DAT1['DMIN'].values, DAT1['DMAX'].values
    except:
        DMAX = np.nanmax(np.abs(DAT1 - DAT2))
        DMIN = -1.0 * DMAX
    print('looping plots')
    for i in range(3):
        if domain == 'Arctic':
            ax = fig.add_subplot(1,3,i+1, projection=ccrs.NorthPolarStereo())
            ax = npb.base_maps.Arctic(ax)
            t_lon, t_lat = 180.0, 47.0
        elif domain == 'Antarctic':
            ax = fig.add_subplot(1,3,i+1, projection=ccrs.SouthPolarStereo())
            ax = npb.base_maps.Antarctic(ax)
            t_lon, t_lat = 0.0, -37.
        cmap = cmap_DIFF if i == 2 else cmap_DAT
        MIN = DMIN if i == 2 else VMIN
        MAX = DMAX if i == 2 else VMAX
        pcs.append(ax.pcolormesh(lon, lat, DAT[i], 
            transform=ccrs.PlateCarree(), 
            vmin = MIN,
            vmax = MAX,
            cmap = cmap))
        ax.set_title(titles[i])
        ax = npb.base_maps.add_features(ax)
        if ICEOBS.any():
            ax.contour(x, y, ICEOBS, [0.15], colors = ['k'], transform = ccrs.Stereographic(**kw))
        axs.append(ax)
    axs = np.array(axs)
    cbar_ax = fig.add_axes([0.16, 0.15, 0.44, 0.05])
    fig.colorbar(pcs[0], ax = axs[1], cax = cbar_ax, orientation='horizontal' )
    cbar_ax = fig.add_axes([0.70, 0.15, 0.17, 0.05])
    fig.colorbar(pcs[-1], ax = axs[1], cax = cbar_ax, orientation='horizontal' )
    axs[1].text(t_lon, t_lat, plot_title, fontweight = 'bold', fontsize = 16, ha = 'center', transform = ccrs.PlateCarree())
    fig_name = save_dir + '/' +  domain.upper() + '_' +\
        plot_title.replace(':','').replace(' ','') + '_' +\
        titles[0].replace(' ','') + '_' +\
        titles[1].replace(' ','') + '.png'
    print('SAVED:', fig_name)
    plt.savefig(fig_name, bbox_inches = 'tight')
    plt.close()

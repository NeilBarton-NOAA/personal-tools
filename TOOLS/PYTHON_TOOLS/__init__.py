from . import base_maps, iceobs, maps, maptools, plot, timetools

############################################################
def defaults_from_array(DAT1, DAT2 = None):
    import numpy as np
    DEFAULTS = { }
    # lats and lons
    try:
        DEFAULTS['LAT'], DEFAULTS['LON'] = DAT1['lat'].values, DAT1['lon'].values
    except:
        DEFAULTS['LAT'], DEFAULTS['LON'] = DAT1['TLAT'].values, DAT1['TLON'].values
    # min and maxes
    try:
        DEFAULTS['MIN'], DEFAULTS['MAX'] = DAT1['MIN'].values, DAT1['MAX'].values
    except:
        DEFAULTS['MIN'], DEFAULTS['MAX'] = np.nanmin(DAT1.values), np.nanmax(DAT1.values)
    # plot title
    try:
        DEFAULTS['PLOT_TITLE'] = DAT1.title
    except:
        DEFAULTS['PLOT_TITLE'] = ''
    # directory to save plot
    try:
        DEFAULTS['SAVE_DIR'] = DAT1.save_dir
    except:
        DEFAULTS['SAVE_DIR'] = ''
    # names or subplots
    try:
        DEFAULTS['TITLES'] = [DAT1.test_name]
    except:
        DEFAULT['TITLES'] = ['data1']
    if DAT2.any():
        try:
            DEFAULTS['DMIN'], DEFAULTS['DAX'] = DAT1['DMIN'].values, DAT1['DMAX'].values
        except:
            DEFAULTS['DMAX'] = np.nanmin(np.abs(DAT1.values - DAT2.values))
            DEFAULTS['DMIN'] = -1.0 * DEFAULTS['DMAX'] 
        try:
            DEFAULTS['TITLES'].append(DAT2.test_name)
        except:
            DEFAULTS['TITLES'].append('data2')
    DEFAULTS['TITLES'].append('Diff')
    return DEFAULTS

############################################################
# https://earth-env-data-science.github.io/lectuires/mapping_cartopy.html
class quickmap(object):
    from matplotlib.cm import jet
    region = 'global'
    colormap = jet
    units = ' '
    dpi = 300
    @classmethod
    def create(cls):
        import cartopy.crs as ccrs
        import cartopy.feature as cfeature
        from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER
        import matplotlib.ticker as mticker
        import matplotlib.pyplot as plt
        import matplotlib
        import numpy as np
        from matplotlib.cm import ScalarMappable
        matplotlib.use('TkAgg')
        matplotlib.rc('text', usetex=True)
        ########################    
        if cls.region == 'global':
            ax = plt.axes(projection=ccrs.Mollweide())
            gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=False,
                   linewidth=0.5, color='gray', alpha=0.5, linestyle='--')
            gl.xlines = True
            xticks = [-180, -120,  -60, 0, 60, 120, 180]
            yticks = [-90, -60, -30, 0, 30, 60, 90]
            gl.xlocator = mticker.FixedLocator(xticks)
            gl.ylocator = mticker.FixedLocator(yticks)
            gl.xformatter = LONGITUDE_FORMATTER
            gl.yformatter = LATITUDE_FORMATTER
            for x in xticks[1::]:
                suffix = 'W' if x < 0 and abs(x) != 180 else 'E'
                txt = str(abs(x)) + r'$^{\circ}$' + suffix
                ax.text(x,-60,txt, size = 8, ha = 'center', va = 'center', transform=ccrs.Geodetic())
            for y in yticks[1:-1]:
                suffix = 'S' if y < 0  else 'N'
                txt = str(abs(y)) + r'$^{\circ}$' + suffix + r'   '
                ax.text(-180,y,txt, size = 8, ha = 'right', va = 'center', transform=ccrs.Geodetic())
        else:
            print('region unknown')
            exit(1)
        if hasattr(cls, 'limits'):
            vmin = cls.limits[0]
            vmax = cls.limits[1]
        else:
            vmin = np.min(cls.dat)
            vmax = np.max(cls.dat)
        #print('before pcolormesh or contourf')
        #fd = ax.pcolormesh(cls.lon, cls.lat, cls.dat, shading = 'nearest', 
        #                   vmin = vmin, vmax = vmax,
        #                   transform=ccrs.PlateCarree(), cmap = cls.colormap)
        fd = ax.contourf(cls.lon, cls.lat, cls.dat, 
                           levels = np.linspace(vmin,vmax,20),
                           transform=ccrs.PlateCarree(), cmap = cls.colormap)
        #print('after pcolormesh or contourf')
        ax.set_title(cls.title, size = 'x-large', weight = 'bold')
        ax.coastlines()
        ax.add_feature(cfeature.LAKES, edgecolor = "black", facecolor = 'None' )
        ax.add_feature(cfeature.RIVERS, edgecolor = "black")
        ax.add_feature(cfeature.BORDERS, linestyle="--")
        #ax.add_feature(cfeature.OCEAN, color="skyblue", alpha=0.4)
        #cb = plt.colorbar(fd, orientation='horizontal', fraction = 0.05, pad = 0.05) #, label = cls.units)
        cb_ticks = np.linspace(vmin,vmax,10)
        cb = plt.colorbar(fd, ticks = cb_ticks, orientation = 'horizontal',
                           fraction = 0.05, pad = 0.05) #, label = cls.units)
        cb_tick_label = []
        for c in cb_ticks:
            cb_tick_label.append(str(np.round(c,1)))
        cb.ax.set_xticklabels(cb_tick_label)
        cb.set_label(cls.units)
        ax.set_global()
        if hasattr(cls, 'figname'):
            if '.png' in cls.figname: cls.figname = cls.figname.replace('.png','')
            fig_name = cls.figname + '_' + cls.region.upper() + '.png'
            plt.savefig(fig_name, format = 'png', bbox_inches = 'tight', dpi = cls.dpi, transparent = False)
            plt.close()
            print('saved:', fig_name)



################################################################################
# Neil P. Barton
# (c) Neil P. Barton, 2014-02-26 Wed 01:42 AM UTC
################################################################################
# These Modules Provide default maps based on basemap and matplotlib
#   updated to python3 12/14/2020
################################################################################///

class Global(object):
     def __new__(self, ax = None):
        import cartopy.crs as ccrs
        import cartopy.feature as cfeature
        from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER
        import matplotlib.pyplot as plt
        import matplotlib.ticker as mticker
        if not ax:
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
        ax.coastlines()
        ax.add_feature(cfeature.LAKES, edgecolor = "black", facecolor = 'None' )
        ax.add_feature(cfeature.RIVERS, edgecolor = "black")
        ax.add_feature(cfeature.BORDERS, linestyle="--")
        for x in xticks[1::]:
            suffix = 'W' if x < 0 and abs(x) != 180 else 'E'
            txt = str(abs(x)) + r'$^{\circ}$' + suffix
            ax.text(x,-60,txt, size = 8, ha = 'center', va = 'center', transform=ccrs.Geodetic())
        for y in yticks[1:-1]:
            suffix = 'S' if y < 0  else 'N'
            txt = str(abs(y)) + r'$^{\circ}$' + suffix + r'   '
            ax.text(-180,y,txt, size = 8, ha = 'right', va = 'center', transform=ccrs.Geodetic())
        return ax


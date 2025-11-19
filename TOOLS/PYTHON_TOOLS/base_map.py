################################################################################
# Neil P. Barton
# (c) Neil P. Barton, 2014-02-26 Wed 01:42 AM UTC
################################################################################
# These Modules Provide default maps based on basemap and matplotlib
#   updated to python3 12/14/2020
################################################################################///
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER
import matplotlib.pyplot as plt
import matplotlib.path as mpath
import matplotlib.ticker as mticker
import numpy as np

def axis(domain = 'Global', ax = None):
    if domain == 'Global':
        if not ax:
            #ax = plt.axes(projection=ccrs.Mollweide())
            #ax = plt.axes(projection=ccrs.Robinson())
            ax = plt.axes(projection=ccrs.LambertCylindrical())
            #ax = plt.axes(projection=ccrs.Mercator())
        ax.set_global()
    elif domain == 'Arctic':
        if not ax:
            ax = plt.axes(projection=ccrs.NorthPolarStereo())
        ax.set_extent([-180, 180, 55, 90], ccrs.PlateCarree())
    elif domain == 'Antarctic':
        if not ax:
            ax = plt.axes(projection=ccrs.SouthPolarStereo())
        ax.set_extent([-180, 180, -45, -90], ccrs.PlateCarree())
    else:
        print('FATAL: cls.domain unknown', cls.domain)
        exit(1)
    ############
    # draw grid a labels
    #gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=False,
    #     linewidth=0.5, color='gray', alpha=0.5, linestyle='--')
    #gl.xlines = True
    ############
    # make map a circle
    if domain in ['Arctic', 'Antarctic']:
        theta = np.linspace(0, 2*np.pi, 100)
        center, radius = [0.5, 0.5], 0.5
        verts = np.vstack([np.sin(theta), np.cos(theta)]).T
        circle = mpath.Path(verts * radius + center)
        ax.set_boundary(circle, transform=ax.transAxes)
    ############
    # add features
    ax.coastlines()
    ax.add_feature(cfeature.LAKES, edgecolor = "black", facecolor = 'None' )
    #ax.add_feature(cfeature.RIVERS, edgecolor = "black")
    ax.add_feature(cfeature.BORDERS, linestyle="--")
    return ax


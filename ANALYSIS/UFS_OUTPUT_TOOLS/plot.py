import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import numpy as np
import sys
sys.path.append('/home/Neil.Barton/TOOLS')
import PYTHON_TOOLS as npb
# some plotting graph 

def ice_extent(DAT,OBS):
    t_anal = np.datetime64('2012-07-15', 'ns')
    # Model Data
    for d in DAT:
        dd = d['NH_extent'].sel(time = t_anal)
        print(d.test_name)
        print(dd[0].values)
        dd.plot(linewidth = 2.0, label = d.test_name)      
    # Observations
    last_tau = int(dd['tau'][-1].values)
    t_last = t_anal + np.timedelta64(last_tau, 'D')  
    dd = OBS['NH_extent'].sel(time = slice(t_anal, t_last))
    print('Obs')
    print(dd[0].values)
    plt.plot(np.arange(0, dd.values.size, 1), dd.values, color = 'k', linewidth = 2.0, label = 'Obs') 
    #print(dd.shape)
    plt.legend()
    plt.show()
    #exit(1)

def difference_plots(DAT):
    diff, axs = [], []
    fig = plt.figure(figsize=(12, 5))
    # turn time into pandas for indexing month
    # x= pd.to_datetime(t) && x.month
    for i, ds in enumerate(DAT):
        print(ds)
        d = ds[ds.var_name].isel(time = 0, tau = 25)
        ax = fig.add_subplot(1,3,i+1, projection=ccrs.NorthPolarStereo())
        axs.append(ax)
        lon, lat, dat = npb.maptools.index_lon_lat_dat(d['TLON'].values, d['TLAT'].values, d.values)
        diff.append(np.copy(dat))
        dat[dat<0.15] = np.nan
        ax = npb.maps.Arctic(ax)
        cmap = plt.get_cmap('terrain_r')
        pcm = ax.contourf(lon, lat, dat, transform=ccrs.PlateCarree(), cmap = cmap)
        ax = npb.maps.add_features(ax)
        ax.set_title(ds.test_name)
    dat = diff[1] - diff[0]
    dat[dat == 0] = np.nan
    ax = fig.add_subplot(1,3,3, projection=ccrs.NorthPolarStereo())
    ax = npb.maps.Arctic(ax)
    cmap = plt.get_cmap('seismic')
    dcm = ax.contourf(lon, lat, dat, transform=ccrs.PlateCarree(), cmap = cmap)
    ax = npb.maps.add_features(ax)
    ax.set_title('Difference')
    axs.append(ax)
    axs = np.array(axs)
    cbar_ax = fig.add_axes([0.16, 0.15, 0.44, 0.05])
    fig.colorbar(pcm, ax = axs[1], cax = cbar_ax, orientation='horizontal' )
    cbar_ax = fig.add_axes([0.70, 0.15, 0.17, 0.05])
    fig.colorbar(dcm, ax = axs[1], cax = cbar_ax, orientation='horizontal' )
    #fig.colorbar(pcm, ax = axs[0:2], location = 'bottom', shrink = 0.6)
    #fig.colorbar(dcm, ax = axs[-1], location = 'bottom', shrink = 1.3)
    # show
    plt.show()
    exit(1)
        


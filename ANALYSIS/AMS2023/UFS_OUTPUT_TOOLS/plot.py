# some plotting graph 
import calendar
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import xarray as xr
import os
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

save_dir='/scratch2/NCEPDEV/stmp3/Neil.Barton/FIGURES/'

def ice_extent_meanmonth(DAT, var = 'NH_extent'):
    dat_plot = []
    y_label = []
    for m in np.arange(12) + 1:
        dat = []
        y_label.append(calendar.month_abbr[m])
        d1_time = DAT[0]['time'].isel(time = DAT[0]['time'].dt.month.isin([m]))
        d2_time = DAT[1]['time'].isel(time = DAT[1]['time'].dt.month.isin([m]))
        same_times = np.array(list(set(d1_time.values) & set(d2_time.values)))
        for ds in DAT[0:2]:
            if 'tau' not in ds.keys():
                # Observations
                last_tau = int(DAT[0]['tau'][-1].values)
                ob = []
                for t in same_times:
                    t_last = t + np.timedelta64(last_tau, 'D')
                    obs = ds[var].sel(time = slice(t, t_last)).values
                    ob.append(np.interp(DAT[0]['tau'].values, np.arange(0, obs.size), obs))
                dat.append(np.mean(np.array(ob), axis = 0))
            else:
                dat.append(ds[var].sel(time = same_times).mean('time'))
        dat_plot.append(dat[0] - dat[1])
    dat_plot = np.array(dat_plot)
    title = var[0:2] + ': ' +DAT[0].test_name + ' minus ' + DAT[1].test_name
    print(title)
    print(' Min:', np.round(dat_plot.min(),2), '  Max:', np.round(dat_plot.max(),2))
    if var == 'NH_extent':
        if 'CFS' in title:
            vmin = -2.5
        elif 'OBS' in title:
            vmin = -1.5
        else:
            vmin = -0.50
        vmin = -2.5
    if var == 'SH_extent':
        if 'CFS' in title:
            vmin = -10.0
        elif 'OBS' in title:
            vmin = -5.6
        else:
            vmin = -1.00
        vmin = -10.0
    #vmin = -0.5
    vmax = abs(vmin)
    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(1,1,1)
    cmap = plt.get_cmap('seismic')
    im = ax.imshow(dat_plot, cmap = cmap, 
                    vmin = vmin, vmax = vmax, 
                    aspect = 'auto', 
                    interpolation = 'none')
    cbar = plt.colorbar(im)
    cbar.set_label('million sq km') 
    plt.xticks(np.arange(141)[::12], DAT[0]['tau'].values[::12])
    plt.yticks(np.arange(12), y_label)
    ax.set_xlabel('Forecast Day')
    ax.set_xlabel('Forecast Day')
    ax.set_title(title, fontsize = 16, fontweight = 'bold')
    plt.savefig(save_dir + '/MONTHvsTAU_' + var + '_' + title.replace(' ','').replace(':','') + '.png', bbox_inches = 'tight')

def ice_extent_month(DAT, obs, OBS2 = None, var = 'NH_extent'):
    # loop through all times
    months = np.arange(1,13)
    for m in months:
        name=''
        for ds in DAT:
            dat_time = ds['time'].isel(time = ds['time'].dt.month.isin([m]))
            obs_time = obs['time'].isel(time = obs['time'].dt.month.isin([m]))
            times_means = np.array(list(set(obs_time.values) & set(dat_time.values)))
            dat = ds[var].sel(time = times_means).mean('time')
            dat.plot(linewidth = 2.0, label = ds.test_name)
            name = name + ds.test_name.replace(':','').replace(' ','')
        # Observations
        last_tau = int(dat['tau'][-1].values)
        ob = []
        for t in times_means:
            t_last = t + np.timedelta64(last_tau, 'D')
            ob.append(obs[var].sel(time = slice(t, t_last)))
        ob = np.mean(np.array(ob), axis = 0)
        plt.plot(np.arange(0, ob.size, 1), ob, color = 'k', linewidth = 2.0, label = obs.test_name) 
        name = name + obs.test_name.replace(':','').replace(' ','')
        if OBS2:
            ob2 = []
            for t in times_means:
                t_last = t + np.timedelta64(last_tau, 'D')
                ob2.append(OBS2[var].sel(time = slice(t, t_last)))
            ob2 = np.mean(np.array(ob2), axis = 0)
            plt.plot(np.arange(0, ob2.size, 1), ob2, color = 'r', linestyle = 'dashed', linewidth = 2.0, label = OBS2.test_name) 
            name = name + OBS2.test_name.replace(':','').replace(' ','')
        plt.title(calendar.month_abbr[m], fontsize = 16, fontweight = 'bold')
        plt.legend(frameon = False)
        fig_name = var + '_' + calendar.month_abbr[m] + '_' + name + '.png'
        print(fig_name)
        plt.savefig(fig_name, bbox_inches = 'tight')
        plt.close()
        #plt.show()
        #exit(1)

def ice_extent(DAT,OBS):
    # loop through all times
    t_anal = np.datetime64('2017-09-01', 'ns')
    # Model Data
    for d in DAT:
        print(d.test_name)
        dd = d['NH_extent'].sel(time = t_anal)
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

def weekly_seasons_maps(ds, ICE_OBS = False, pole = 'SH'):
    DIMS = ['DJF', 'MAM', 'JJA', 'SON']
    MONTHS = [[12,1,2], [3,4,5], [6,7,8], [9,10,11]]
    if ICE_OBS:
        dx = dy = 25000
        if pole == 'NH':
            x = np.arange(-3850000, +3750000, +dx)
            y = np.arange(+5850000, -5350000, -dy)
            kw = dict(central_latitude=90, central_longitude=-45, true_scale_latitude=70)
        elif pole == 'SH':
            x = np.arange(-3950000, +3950000, +dx)
            y = np.arange(+4350000, -3950000, -dy)
            kw = dict(central_latitude=-90, central_longitude=0, true_scale_latitude=-70)
    for s, DIM in enumerate(DIMS):
        fig = plt.figure(figsize=(16, 5))
        axs = []
        for i, taus in enumerate([[0,7], [8,14], [15,21], [22,28]]):
            if ICE_OBS:
                t_time = pd.to_datetime(ds['time'].isel(time = ds['time'].dt.month.isin(MONTHS[s])).values)
                t_taus = ds['tau'].sel(tau = slice(taus[0], taus[1])).values
                t_array = []
                for t in t_time:
                    t_array.extend((t + pd.to_timedelta(t_taus, unit = 'D')).to_numpy())
                t_array = np.array(t_array) 
                t_array = list(set(ICE_OBS['time'].values) & set(t_array))
                obs = ICE_OBS['ice_con'].sel(time = t_array).mean('time').values
                obs[obs > 1] = np.nan
                #obs = obs.where(obs < 1.0)
            print('taus:', taus[0], taus[1])
            print(ds)
            d = ds['mean_' + ds.var_name].isel(season = s)
            d = d.sel(tau = slice(taus[0], taus[1])).mean('tau') 
            lat = d['TLAT'].values
            lon = d['TLON'].values
            m_levels = np.arange(0.15, 1.05, 0.05)
            d_levels = np.arange(-0.5, 0.5+0.1, 0.1)
            ############
            # plot
            lon, lat, dat = npb.maptools.index_lon_lat_dat(lon, lat, d.values)
            if pole == 'SH':
                ax = fig.add_subplot(1,4,i+1, projection=ccrs.SouthPolarStereo())
                ax = npb.maps.Antarctic(ax)
            elif pole == 'NH':
                ax = fig.add_subplot(1,4,i+1, projection=ccrs.NorthPolarStereo())
                ax = npb.maps.Arctic(ax)
            cmap = plt.get_cmap('terrain_r')
            pcm = ax.contourf(lon, lat, dat, 
                    levels = m_levels, 
                    transform=ccrs.PlateCarree(), 
                    cmap = cmap)
            dat[dat > 1 ] = np.nan
            #ax.contour(lon, lat, dat, [0.15], colors = ['r'], transform = ccrs.PlateCarree())
            # add ice obs
            ax.contour(x, y, obs, [0.15], colors = ['k'], transform = ccrs.Stereographic(**kw))
            ax = npb.maps.add_features(ax)
            ax.set_title('Week ' + str(i+1))
            axs.append(ax)
        cbar_ax = fig.add_axes([0.16, 0.15, 0.70, 0.05])
        fig.colorbar(pcm, ax = axs[1], cax = cbar_ax, orientation='horizontal' )
        title = DIM + ' Ice Extent '
        #axs[2].text(160.0, 40., title, fontsize=16, ha = 'center', transform = ccrs.PlateCarree())
        plt.text(0.58, 13.85, title, fontweight = 'bold', fontsize = 16, ha = 'center')
        # show
        plt.savefig(pole + '_' + ds.var_name + '_' + title.replace(' ','') + '_week.png', bbox_inches = 'tight')
        #plt.show()
        #exit(1)

def difference_maps_seasons_weeks(DAT, ICE_OBS = False):
    DIMS = ['DJF', 'MAM', 'JJA', 'SON']
    MONTHS = [[12,1,2], [3,4,5], [6,7,8], [9,10,11]]
    if ICE_OBS:
        dx = dy = 25000
        x = np.arange(-3850000, +3750000, +dx)
        y = np.arange(+5850000, -5350000, -dy)
        kw = dict(central_latitude=90, central_longitude=-45, true_scale_latitude=70)
    for s, DIM in enumerate(DIMS):
        for i, taus in enumerate([[0,7], [8,14], [15,21], [22,28]]):
            if ICE_OBS:
                t_ds = DAT[0]
                t_time = pd.to_datetime(t_ds['time'].isel(time = t_ds['time'].dt.month.isin(MONTHS[s])).values)
                t_taus = t_ds['tau'].sel(tau = slice(taus[0], taus[1])).values
                t_array = []
                for t in t_time:
                    t_array.extend((t + pd.to_timedelta(t_taus, unit = 'D')).to_numpy())
                t_array = np.array(t_array) 
                t_array = list(set(ICE_OBS['time'].values) & set(t_array))
                obs = ICE_OBS['ice_con'].sel(time = t_array).mean('time')
                obs = obs.where(obs < 1.0)
            diff, axs = [], []
            fig = plt.figure(figsize=(12, 5))
            for j, ds in enumerate(DAT[0:2]):
                print('taus:', taus[0], taus[1])
                d = ds['mean_' + ds.var_name].isel(season = s)
                d = d.sel(tau = slice(taus[0], taus[1])).mean('tau') 
                if (ds.var_name == 'aice_h'):
                    lat = d['TLAT'].values
                    lon = d['TLON'].values
                    m_levels = np.arange(0.15, 1.05, 0.05)
                    d_levels = np.arange(-0.5, 0.5+0.1, 0.1)
                else:
                    d = ds[ds.var_name].isel(time = ds['time'].dt.month.isin([12,1,2])).mean('time')
                    d = d.sel(tau = slice(taus[0], taus[1])).mean('tau')
                    lon, lat = np.meshgrid(d['longitude'], d['latitude'])
                    ma = d.where(d['latitude'] > 60).max()
                    mi = d.where(d['latitude'] > 60).min()
                    n = (ma - mi) / 10.0
                    m_levels = np.arange(mi, ma + n, n)
                    print(m_levels)
                print(np.min(lon), np.max(lon))
                ############
                # plot
                ax = fig.add_subplot(1,3,j+1, projection=ccrs.NorthPolarStereo())
                axs.append(ax)
                lon, lat, dat = npb.maptools.index_lon_lat_dat(lon, lat, d.values)
                diff.append(np.copy(dat))
                ax = npb.maps.Arctic(ax)
                cmap = plt.get_cmap('terrain_r')
                pcm = ax.contourf(lon, lat, dat, 
                        levels = m_levels, 
                        transform=ccrs.PlateCarree(), 
                        cmap = cmap)
                # add ice obs
                if ICE_OBS:
                    ax.contour(x, y, obs, [0.15], colors = ['k'], transform = ccrs.Stereographic(**kw))
                ax = npb.maps.add_features(ax)
                ax.set_title(ds.test_name)
            dat = diff[1] - diff[0]
            if (ds.var_name == 'aice_h'):
                dat[(diff[1] < 0.15) & (diff[0] < 0.15)] = np.nan
                dat[dat == 0] = np.nan
            else:
                ma = max(abs(dat[lat > 60].max()), abs(dat[lat > 60].min()))
                mi = ma * - 1.0
                n = (ma - mi) / 10.0
                d_levels = np.arange(mi, ma + n, n)
            ax = fig.add_subplot(1,3,3, projection=ccrs.NorthPolarStereo())
            ax = npb.maps.Arctic(ax)
            cmap = plt.get_cmap('seismic')
            #dcm = ax.contourf(lon, lat, dat, 
            #    transform=ccrs.PlateCarree(), cmap = cmap)
            dcm = ax.contourf(lon, lat, dat, 
                levels = d_levels, 
                transform=ccrs.PlateCarree(), cmap = cmap)
            ax = npb.maps.add_features(ax)
            ax.set_title('Difference')
            axs.append(ax)
            axs = np.array(axs)
            cbar_ax = fig.add_axes([0.16, 0.15, 0.44, 0.05])
            fig.colorbar(pcm, ax = axs[1], cax = cbar_ax, orientation='horizontal' )
            cbar_ax = fig.add_axes([0.70, 0.15, 0.17, 0.05])
            fig.colorbar(dcm, ax = axs[1], cax = cbar_ax, orientation='horizontal' )
            #title = str(pd.to_datetime(ds.time[0].values))[0:10] + ' forecast day: ' + str(ds.tau[25].values)  
            title = DIM + ' Week ' + str(i+1)
            axs[1].text(180.0, 47., title, fontsize=16, ha = 'center', transform = ccrs.PlateCarree())
            # show
            plt.savefig(ds.var_name + '_' + title.replace(' ','') + '.png')
            #exit(1)

        


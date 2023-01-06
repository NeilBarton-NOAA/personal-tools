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

long_name = {
'aice_h' : 'Sea Ice Concentration',
'TMP_2maboveground' : 'Temp 2m',
'TMP_1hybridlevel' : 'Temp at Lowest Level',
'SPFH_1hybridlevel' : 'Specific Humidity at Lowest Level',
'LCDC_lowcloudlayer' : 'Low Clouds',
'MCDC_middlecloudlayer' : 'Mid Clouds',
'DSWRF_surface' : 'SW Down',
'DLWRF_surface' : 'LW Down'
}
levels_m = {
'TMP_2maboveground2' : np.arange(235,280,5),
'TMP_2maboveground9' : np.arange(250,290,5),
'TMP_1hybridlevel2' : np.arange(235,280,5),
'TMP_1hybridlevel9' : np.arange(250,287.5,2.5),
'SPFH_1hybridlevel2' : np.arange(0,9,0.5),
'LCDC_lowcloudlayer1' : np.arange(0,110,10),
'LCDC_lowcloudlayer2' : np.arange(0,110,10),
'LCDC_lowcloudlayer9' : np.arange(0,110,10),
'LCDC_lowcloudlayer12' : np.arange(0,110,10),
'MCDC_middlecloudlayer1' : np.arange(0,110,10),
'MCDC_middlecloudlayer2' : np.arange(0,110,10),
'MCDC_middlecloudlayer9' : np.arange(0,110,10),
'MCDC_middlecloudlayer12' : np.arange(0,110,10),
'DLWRF_surface2' : np.arange(130,290+20,20),
'DLWRF_surface9' : np.arange(160,320,10),
'DSWRF_surface9' : np.arange(0,160,20)
}
levels_d = {
'TMP_2maboveground2' : np.arange(-5,6,1),
'TMP_2maboveground9' : np.arange(-5,6,1),
'TMP_1hybridlevel2' : np.arange(-5,6,1),
'TMP_1hybridlevel9' : np.arange(-3,3.5,0.5),
'SPFH_1hybridlevel2' : np.arange(-1.5,1.75,0.25),
'LCDC_lowcloudlayer1' : np.arange(-40,50,10),
'LCDC_lowcloudlayer2' : np.arange(-40,50,10),
'LCDC_lowcloudlayer9' : np.arange(-40,50,10),
'LCDC_lowcloudlayer12' : np.arange(-40,50,10),
'MCDC_middlecloudlayer1' : np.arange(-40,50,10),
'MCDC_middlecloudlayer9' : np.arange(-40,50,10),
'MCDC_middlecloudlayer2' : np.arange(-40,50,10),
'MCDC_middlecloudlayer12' : np.arange(-40,50,10),
'DLWRF_surface2' : np.arange(-35,45,10),
'DLWRF_surface9' : np.arange(-25,30,5),
'DSWRF_surface9' : np.arange(-25,30,5)
}
save_dir='/scratch2/NCEPDEV/stmp3/Neil.Barton/FIGURES/'

def monthly_seaice_thickness(dat, obs):
    months = pd.to_datetime(obs['time']).month.unique()
    for m in months:    
        print('Sea Ice Thickness: ' +  calendar.month_abbr[m])
        # times_all maybe
        d = dat['hi_h'].isel(time = dat['time'].dt.month.isin(m))
        obs = obs.where(obs['status_flag'] == 0)
        obs = obs.where(obs['quality_flag'] == 0)
        ob = obs['sea_ice_thickness'].isel(time = obs['time'].dt.month.isin(m))
        time_dat = pd.to_datetime(d['time'].values)
        time_obs = pd.to_datetime(ob['time'].values)
        time_same = np.array(list(set(time_dat.year) & set(time_obs.year)))
        d = d.isel(time = d['time'].dt.year.isin(time_same)).mean('time')
        d = d.sel(tau = slice(0, 7)).mean('tau')
        ob = ob.isel(time = ob['time'].dt.year.isin(time_same)).mean('time')
        d = d.where(d > 0.01)
        ob = ob.where(ob > 0.01)
        #model_dat[model_dat < 0.01 ] = np.nan
        print(np.nanmin(d.values), np.nanmax(d.values))
        print(np.nanmin(ob.values), np.nanmax(ob.values))
        m_levels = np.arange(0, 8.0, 5/10)
        print(m_levels)
        fig = plt.figure(figsize=(10, 5))
        if pole == 'NH':
            ax = fig.add_subplot(1,2,1, projection=ccrs.NorthPolarStereo())
            ax = npb.maps.Arctic(ax)
        elif pole == 'SH':
            ax = fig.add_subplot(1,2,1, projection=ccrs.SouthPolarStereo())
            ax = npb.maps.Antarctic(ax)
        lon, lat, model_dat = npb.maptools.index_lon_lat_dat(d['TLON'].values, d['TLAT'].values, d.values)
        cmap = plt.get_cmap('terrain_r')
        pcm = ax.contourf(lon, lat, model_dat, 
               levels = m_levels, 
               transform=ccrs.PlateCarree(), 
               cmap = cmap)
        ax = npb.maps.add_features(ax)
        ax.set_title(dat.test_name)
        ax1 = ax
        # second subplot
        if pole == 'NH':
            ax = fig.add_subplot(1,2,2, projection=ccrs.NorthPolarStereo())
            ax = npb.maps.Arctic(ax)
        elif pole == 'SH':
            ax = fig.add_subplot(1,2,2, projection=ccrs.SouthPolarStereo())
            ax = npb.maps.Antarctic(ax)
        obs_lon, obs_lat, obs_dat = npb.maptools.index_lon_lat_dat(ob['lon'].values, ob['lat'].values, ob.values)
        ax.contourf(obs_lon, obs_lat, obs_dat, 
               levels = m_levels, 
               transform=ccrs.PlateCarree(), 
               cmap = cmap)
        ax = npb.maps.add_features(ax)
        ax.set_title('Obs')
        title = 'Sea Ice Thickness: ' +  calendar.month_abbr[m]
        cbar_ax = fig.add_axes([0.16, 0.05, 0.70, 0.05])
        fig.colorbar(pcm, ax = ax1, cax = cbar_ax, orientation='horizontal' )
        plt.text(3.75, 16.85, title, fontweight = 'bold', fontsize = 16, ha = 'center')
        # show
        plt.savefig(title.replace(' ','').replace(':','') + '_' + dat.var_name + '.png', bbox_inches = 'tight')
        plt.close()

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

def difference_month_weeksave(DAT, ICE_OBS = False, pole = 'NH'):
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
    months = np.arange(12) + 1
    months = [1,12]
    print(DAT[0].var_name)
    for s, m in enumerate(months):
        for i, taus in enumerate([[0,7], [8,14], [15,21], [22,28], [29, 35]]):
            print('MONTH:', m, ' TAUS:', taus[0], taus[1])
            if ICE_OBS:
                t_ds = DAT[0]
                t_time = pd.to_datetime(t_ds['time'].isel(time = t_ds['time'].dt.month.isin(m)).values)
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
                d = ds[ds.var_name].isel(time = ds['time'].dt.month.isin(m))
                d = d.sel(tau = slice(taus[0], taus[1])).mean('tau').mean('time')
                if 'SPFH'  in ds.var_name:
                    d.values = d.values * 1000.0
                if (ds.var_name == 'aice_h'):
                    lat = d['TLAT'].values
                    lon = d['TLON'].values
                    m_levels = np.arange(0.15, 1.05, 0.05)
                    d_levels = np.arange(-0.5, 0.5+0.1, 0.1)
                else:
                    lon, lat = np.meshgrid(d['longitude'], d['latitude'])
                    ma = np.nanmax(d.where(d['latitude'] > 60).values)
                    mi = np.nanmin(d.where(d['latitude'] > 60).values)
                    n = (ma - mi) / 10.0
                    print(np.min(d.values), np.max(d.values))
                    try:
                        m_levels = levels_m[ds.var_name + str(m)]
                    except:
                        m_levels = np.arange(mi, ma, n)
                        print(ds.var_name + str(m))
                        print('levels not defined')
                ############
                # plot
                if pole == 'NH':
                    ax = fig.add_subplot(1,3,j+1, projection=ccrs.NorthPolarStereo())
                    ax = npb.maps.Arctic(ax)
                elif pole == 'SH':
                    ax = fig.add_subplot(1,3,j+1, projection=ccrs.SouthPolarStereo())
                    ax = npb.maps.Antarctic(ax)
                axs.append(ax)
                lon, lat, dat = npb.maptools.index_lon_lat_dat(lon, lat, d.values)
                diff.append(np.copy(dat))
                cmap = plt.get_cmap('terrain_r')
                pcm = ax.contourf(lon, lat, dat, 
                        levels = m_levels, 
                        extend = 'both',
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
                ma = max(np.nanmax(abs(dat[lat > 60])), np.nanmin(abs(dat[lat > 60])))
                mi = ma * - 1.0
                n = (ma - mi) / 10.0
                print(np.min(dat), np.max(dat))
                try:
                    d_levels = levels_d[ds.var_name + str(m)]
                except:
                    print(ds.var_name + str(m))
                    print('difference levels not defined')
                    d_levels = np.arange(mi, ma + n, n)
            if pole == 'NH':
                ax = fig.add_subplot(1,3,3, projection=ccrs.NorthPolarStereo())
                ax = npb.maps.Arctic(ax)
            elif pole == 'SH':
                ax = fig.add_subplot(1,3,3, projection=ccrs.SouthPolarStereo())
                ax = npb.maps.Antarctic(ax)
            cmap = plt.get_cmap('seismic')
            #dcm = ax.contourf(lon, lat, dat, 
            #    transform=ccrs.PlateCarree(), cmap = cmap)
            dcm = ax.contourf(lon, lat, dat, 
                levels = d_levels, 
                extend = 'both',
                transform=ccrs.PlateCarree(), cmap = cmap)
            if ICE_OBS:
                ax.contour(x, y, obs, [0.15], colors = ['k'], transform = ccrs.Stereographic(**kw))
            ax = npb.maps.add_features(ax)
            ax.set_title('Difference')
            axs.append(ax)
            axs = np.array(axs)
            cbar_ax = fig.add_axes([0.16, 0.15, 0.44, 0.05])
            fig.colorbar(pcm, ax = axs[1], cax = cbar_ax, orientation='horizontal' )
            cbar_ax = fig.add_axes([0.70, 0.15, 0.17, 0.05])
            fig.colorbar(dcm, ax = axs[1], cax = cbar_ax, orientation='horizontal' )
            #title = str(pd.to_datetime(ds.time[0].values))[0:10] + ' forecast day: ' + str(ds.tau[25].values)  
            try:
                title = long_name[ds.var_name] + ': ' + calendar.month_abbr[m] + ' Week ' + str(i+1)
            except:
                print('long_name[ds.var_name] not defined')
                title = ds.var_name + ': ' + calendar.month_abbr[m] + ' Week ' + str(i+1)
            if pole == 'NH':
                axs[1].text(180.0, 47., title, fontsize=16, ha = 'center', transform = ccrs.PlateCarree())
            elif pole == 'SH':
                axs[1].text(0.0, -37., title, fontsize=16, ha = 'center', transform = ccrs.PlateCarree())
            # show
            fig_name = save_dir + '/' +  ds.var_name + '_' + calendar.month_abbr[m] + 'Week' + str(i+1)
            plt.savefig(fig_name, bbox_inches = 'tight')
            #plt.show()
            #plt.close()
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

        


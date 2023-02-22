import calendar
import numpy as np
import matplotlib.pyplot as plt

def ice_extent_per_month(DATS, OBS = None, var = 'NH_extent'):
    # one plot per month for data of sea ice extent
    # doesn't assume number of DATS
    if OBS != None:
        if type(OBS) != list:
            OBS = [OBS]
    for month in np.arange(1,13):
        ALL_DS = DATS.copy()
        if len(OBS) > 0:
            for OB in OBS:
                ALL_DS.append(OB)
        for i, ds in enumerate(ALL_DS):
            c_time = ds['time'].isel(time = ds['time'].dt.month.isin([month]))
            if i == 0:
                a_time = c_time
            else:
                same_times = np.array(list(set(c_time.values) & set(a_time.values)))
        name = calendar.month_abbr[month].upper() + '_' + var.upper() + '_'
        # plot model data with tau
        for i, ds in enumerate(DATS):
            dat = ds[var].sel(time = same_times).mean('time')
            try:
                text = ds.test_name
            except:
                text = str(i)
            dat.plot(linewidth = 2.0, label = text)
            name = name + text.replace(':', '').replace(' ','').replace('/','') + '_'
        # observations
        #   get times for obs
        last_tau = int(ds['tau'][-1].values)
        ob = []
        for t in same_times:
            t_last = t + np.timedelta64(last_tau, 'D')
            ob.append(OBS[0][var].sel(time = slice(t, t_last)).values)
        ob = np.mean(np.array(ob), axis = 0)
        try:
            text = OBS[0].test_name
        except:
            text = 'Obs'
        plt.plot(np.arange(0, ob.size, 1), ob, color = 'k', linewidth = 2.0, label = text)
        name = name + text.replace(':', '').replace(' ','').replace('/','') 
        try:
            save_dir = DATS[0].save_dir
        except:
            save_dir = './'
        fig_name = save_dir + '/' + name + '.png'
        plt.legend(frameon = False)
        plt.xlabel('Forecast Day')
        plt.ylabel(var[0:2] + ' Sea Ice Extent')
        plt.title(var[0:2] + ' Sea Ice Extent: ' + calendar.month_abbr[month])
        #plt.show()
        plt.savefig(fig_name, bbox_inches = 'tight')
        print('SAVED:', fig_name)
        plt.close()
        #exit(1)

def ice_extent_imshowdiff(DAT1, DAT2, var = 'NH_extent'):
    dat_plot = []
    y_label = []
    taus = DAT1['tau'].values
    for m in np.arange(12) + 1:
        dat = []
        y_label.append(calendar.month_abbr[m])
        d1_time = DAT1['time'].isel(time = DAT1['time'].dt.month.isin([m]))
        d2_time = DAT2['time'].isel(time = DAT2['time'].dt.month.isin([m]))
        same_times = np.array(list(set(d1_time.values) & set(d2_time.values)))
        for ds in [DAT1, DAT2]:
            if 'tau' not in ds.keys():
                # Observations
                last_tau = int(DAT1['tau'][-1].values)
                ob = []
                for t in same_times:
                    t_last = t + np.timedelta64(last_tau, 'D')
                    obs = ds[var].sel(time = slice(t, t_last)).values
                    ob.append(np.interp(taus, np.arange(0, obs.size), obs))
                dat.append(np.mean(np.array(ob), axis = 0))
            else:
                dat.append(ds[var].sel(time = same_times).mean('time'))
        dat_plot.append(dat[0] - dat[1])
    dat_plot = np.array(dat_plot)
    try:
        title = var[0:2] + ': ' + DAT1.test_name + ' minus ' + DAT2.test_name
    except:
        title = var[0:2] + ': DAT1 minus DAT2'
    print(title)
    print(' Min:', np.round(dat_plot.min(),2), '  Max:', np.round(dat_plot.max(),2))
    try:
        vmin = DAT1.DMIN
        vmax = DAT1.DMAX
    except:
        vmin = np.min(dat_plot)
        vmax = -1 * vmin
    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(1,1,1)
    cmap = plt.get_cmap('seismic')
    im = ax.imshow(dat_plot, cmap = cmap, 
                    vmin = vmin, vmax = vmax, 
                    aspect = 'auto', 
                    interpolation = 'none')
    cbar = plt.colorbar(im)
    cbar.set_label('million sq km') 
    plt.xticks(np.arange(taus.size)[::3], taus[::3].astype('int'))
    plt.yticks(np.arange(12), y_label)
    ax.set_xlabel('Forecast Day')
    ax.set_xlabel('Forecast Day')
    ax.set_title(title, fontsize = 16, fontweight = 'bold')
    #plt.show()
    try:
        save_dir = DAT1.save_dir
    except:
        save_dir = './'
    fig_name = save_dir + '/MONTHvsTAU_' + var.upper() + '_' + title[2::].replace(' ','').replace(':','').replace('/','') + '.png'
    plt.savefig(fig_name, bbox_inches = 'tight')
    plt.close()
    print('SAVED:', fig_name)


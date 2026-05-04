import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

def line(ds, region = 'globe', obs = False):
    ####################################
    if ds.name in ['ice_extent', 'ice_volume', 'snow_volume']:
        dat = ds
    else:
        if region == 'nino34':
            ds = ds.sel(latitude=slice(-5, 5), longitude=slice(190, 240))
        if region == 'tropics':
            ds = ds.sel(latitude=slice(-20, 20), longitude=slice(120, 260))
        if region == 'Arctic':
            ds = ds.sel(latitude=slice(70, 90), longitude=slice(0, 360))
        if region == 'Antarctic':
            ds = ds.sel(latitude=slice(-90, -70), longitude=slice(0, 360))
        weights = np.cos(np.deg2rad(ds.latitude))
        weights.name = "weights"
        dat = ds.weighted(weights).mean(("latitude", "longitude"))
    plt.figure()
    if len(ds.experiment.values) == 2:
        colors = ['blue', 'green']
    else:
        colors = plt.cm.tab10(np.linspace(0, 1, len(ds.experiment)))
    for i, n in enumerate(ds.experiment.values):
        mean = dat.sel(experiment = n).mean(dim = 'member') 
        lower = dat.sel(experiment = n).quantile(0.25, dim = 'member') 
        upper = dat.sel(experiment = n).quantile(0.75, dim = 'member') 
        plt.plot(mean.time, mean, color=colors[i], label = n)
        plt.fill_between(mean.time, lower, upper, color=colors[i], alpha=0.2)
    # plot obs
    if not isinstance(obs, bool):
        plt.plot(obs.time, obs, color='k', label = obs.title)
    plt.legend(frameon=False)
    plt.ylabel(ds.name)
    plt.title(region)
    fig_name = ds.name + '_' + region + '_' + pd.to_datetime(mean.time.values[0]).strftime('%Y%m%d') + '.png'
    plt.savefig(fig_name)
    print('SAVED:', fig_name)


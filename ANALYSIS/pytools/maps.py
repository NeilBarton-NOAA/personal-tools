import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from PIL import Image

############
# model data
limits = {  'SST':                  [(0, 28), (0, 28), (-3, 3)],
            'SSS':                  [(25, 40), (25, 40), (-3, 3)],
            'SSH':                  [(-2.0, 1.0), (-2., 1.), (-0.5, 0.5)],
            'WWV':                  [(1000.0, 2000.0), (1000., 2000.), (-800., 800.)],
            'MLD_003':              [(0.0, 40.0), (0., 40.), (-50., 50.)],
            'SW':                   [(50.0, 300.0), (50., 300.), (-30., 30.)],
            'salinity_vert_ave':    [(25, 35), (25, 35), (-1, 1)],
            'dt20c':                [(100, 200), (100, 200), (-50, 50)],
            'T300':                 [(10, 30), (10, 30), (-15, 15)],
            'ocnheat':              [(10, 30), (10, 30), (-15, 15)]
         }   

def three_panel(ds):
    c_maps = ['magma', 'magma', 'RdBu_r']
    exp_names = list(ds.experiment.values)
    exp_names.append(exp_names[0] + ' minus ' + exp_names[1])
    gif_files=[]
    for t in ds.time:
        print(t.values)
        fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(18, 5), \
            subplot_kw={'projection': ccrs.Robinson(central_longitude=180)})
        for i, ax in enumerate(axes):
            # Select the data (example: first 3 time steps)
            if i == 2:
                dat1 = ds.sel(time = t, experiment = exp_names[0]).mean(dim = 'member')
                dat2 = ds.sel(time = t, experiment = exp_names[1]).mean(dim = 'member')
                dat = dat1 - dat2
            else:
                dat = ds.sel(time = t, experiment = exp_names[i]).mean(dim = 'member')
            # Plot using xarray's built-in plotting (transform is CRITICAL here)
            if ds.name in limits:
                v_min, v_max = limits[ds.name][i]
            else:
                v_min, v_max = dat.min().values, dat.max().values
                print('limits not set:', v_min, v_max)
            dat.plot(
                ax=ax, 
                transform=ccrs.PlateCarree(), # Data is usually lat/lon (PlateCarree)
                cmap = c_maps[i],
                vmin = v_min,
                vmax = v_max,
                levels = 16,
                cbar_kwargs={'orientation': 'horizontal', 'pad': 0.05}
            )
            # lines
            gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True, linewidth=1, color='gray', alpha=0.5, linestyle='--')
            gl.ylocator = mticker.FixedLocator([-60,-20,-5,0,5,20,60])
            gl.xlocator = mticker.FixedLocator([-170,-120,-80,120])
            # Add map features
            ax.coastlines()
            ax.add_feature(cfeature.BORDERS, linestyle=':')
            ax.set_global() # Ensures the whole world is shown
            ax.set_title(str(t.dt.year.values) + '-' + str(t.dt.month.values).zfill(2) + ': ' + exp_names[i])
        plt.tight_layout()
        name = ds.name + '_' + str(t.dt.year.values) + '-' + str(t.dt.month.values).zfill(2) + '.png'
        gif_files.append(name)
        #plt.show(); exit(1)
        plt.savefig(name)
        plt.close()
    frames = [Image.open(image) for image in gif_files]
    frames[0].save(ds.name + "_maps.gif", save_all=True, append_images=frames[1:], duration=500, loop=0)


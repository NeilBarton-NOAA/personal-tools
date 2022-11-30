import matplotlib.pyplot as plt
import numpy as np
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


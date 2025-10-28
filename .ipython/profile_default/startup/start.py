#from IPython import get_ipython
#ipython = get_ipython()
#if ipython:
#    ipython.run_line_magic('matplotlib', 'inline')

import cartopy.crs as ccrs
import cartopy.feature as cfeature
import glob
import numpy as np
import matplotlib.pylab as plt
import os
import pandas as pd
import sys
import xarray as xr

HOME = os.environ.get('HOME')
sys.path.append(HOME + '/TOOLS')
import PYTHON_TOOLS as npb

print('Libraries in .ipython/profile_default/startup/start.py have been loaded')

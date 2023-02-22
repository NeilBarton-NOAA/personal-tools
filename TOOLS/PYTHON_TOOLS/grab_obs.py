########################
# grab data 
import xarray as xr

FILE_DICT={
'TMP_2maboveground': '/scratch1/NCEPDEV/climate/Lydia.B.Stefanova/ReferenceData/era5/ERA5_6hrly/t2m.2011-2018.nc',
'ICEC_surface':'/scratch1/NCEPDEV/climate/Denise.Worthen/IceData'
}

def to_xarray(VAR):
    print(' ',FILE_DICT[VAR])
    DAT = xr.open_dataset(FILE_DICT[VAR])

    

    


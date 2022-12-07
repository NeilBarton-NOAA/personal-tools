__all__ = ['get']
import argparse

class get:
    parser = argparse.ArgumentParser( description=
        "This script parses the stout_espc.list file to display a summary of UFS forecast timings")
    parser.add_argument('-f', '--files', 
        action='store', 
        default=['/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/P8T/CICE_aice_h.nc',
        '/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/P8G/CICE_aice_h.nc'],
        nargs = '+', help='files for analysis')
    parser.add_argument('-v', '--variable', 
        action='store', 
        default = ['aice_h'], 
        nargs = 1, help="variable for analysis")
    parser.add_argument('-r', '--region', 
        action='store', 
        default = ['ARCTIC'], 
        nargs = 1, help="region for analysis/plots")
    def __new__(self, args = parser.parse_args()):
        self.files = args.files
        self.var = args.variable[0]
        self.region = args.region[0]
        return self
        


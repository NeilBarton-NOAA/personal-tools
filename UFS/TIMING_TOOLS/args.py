__all__ = ['get']
import argparse
import os

class get:
    parser = argparse.ArgumentParser(description="This script parses the stout_espc.list file to display a summary of UFS forecast timings")
    parser.add_argument('-d', '--directory', action='store', default='RTs', nargs = 1, help="top directory to search for stout_espc.list files")
    parser.add_argument('-sb', '--sortby', action='store', default=['MINpDAY'], nargs = 1, help='header to sort results, default is WALLTIME')
    parser.add_argument('-m', '--med', action='store_true', help='show mediator MPI, PE and Timings')
    parser.add_argument('-io', '--atmio', action='store_true', help='show ATM IO timings')
    parser.add_argument('-l', '--loop', action='store_true', help='show what coupling loop component is on')
    parser.add_argument('-pe', '--pes', action='store_true', help='show PEs for components')
    parser.add_argument('-plot', '--plot', action='store_true', default=None, help='plot Secs for all or component')
    ####################################
    def __new__(self, args = parser.parse_args()):
        TOPDIR = args.directory
        if TOPDIR == 'RTs':
            self.TOPDIR = os.environ['NPB_WORKDIR'] + '/RUNs/RTs'
        else:
            self.TOPDIR = TOPDIR[0]
        self.SHOW_MED =  args.med
        self.SHOW_ATMIO = args.atmio
        self.SHOW_LOOP = args.loop
        self.SHOW_PES = args.pes
        self.SORTBY = args.sortby[0]
        if args.plot is not None:
            self.PLOT = True
        else:
            self.PLOT = False
        return self

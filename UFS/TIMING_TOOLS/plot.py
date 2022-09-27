import matplotlib.pyplot as plt
import numpy as np

class ufs(object):
    @classmethod
    def comp_plot(cls):
        df = cls.df.groupby([cls.comp + 'mpi', cls.comp + 'thr']).mean().sort_values(cls.comp + cls.x_axis).reset_index()
        fig, ax1 = plt.subplots()
        #ax2 = ax1.twinx()
        #SAME_PETS = cls.df['COMPS_SAMEPETS'][1]
        #LOOP_COMPS = cls.all_comps.copy()
        #LOOP_COMPS.remove(cls.comp)
        AT = ''
        #for C in SAME_PETS:
        #    AT = AT + C + ':' + cls.df[C+'mpi-t'].mode()[0] + ' '
        #for C in LOOP_COMPS:
        #    df = df.loc[df[C+'mpi'].mode()[0] == df[C+'mpi']]
        #    df = df.loc[df[C+'thr'].mode()[0] == df[C+'thr']]
        #    for M in SAME_PETS:
        #        if C not in M:
        #            AT = AT + C + ':' + cls.df[C+'mpi-t'].mode()[0] + ' '
        for i in np.sort(df[cls.comp + 'thr'].unique()):
            X = df[df[cls.comp + 'thr'] == i][cls.comp + cls.x_axis] 
            Y = df[df[cls.comp + 'thr'] == i][cls.comp + 'sec_max']
            Y2 = df[df[cls.comp + 'thr'] == i]['WALLTIME'] * 3600.0
            ax1.plot(X,Y, '-o', label = 'Threads = ' + str(i))
        #    ax2.plot(X,Y2, ':x', label = 'Threads = ' + str(i), alpha = 0.45)
        ax1.legend(loc='upper center', bbox_to_anchor=(0.5,-0.10), ncol = i, frameon = False)
        ax1.set_xlabel(cls.x_label)
        ax1.set_ylabel(cls.comp +' secs')
        #ax2.set_ylabel(cls.app +' secs' + '\n' + AT)
        try:
            FL = str(df['TAU'][1])
        except:
            FL = str(df['TAU'][0])
        plt.title(cls.comp + ': FL ' + FL + ' hours')
        plt.tight_layout()
        plt.savefig('FIGURES/' + cls.comp + '_' + cls.x_axis + '_timings.png')
    
    @classmethod
    def all_plot(cls):
        df = cls.df.sort_values('PETs')
        X = df['PETs'] 
        Y = df['WALLTIME'] * 3600.
        fig, ax = plt.subplots()
        ax.plot(X,Y, '-ok', label = 'Total Walltime')
        #for i in np.arange(len(X)):
        #    ax.text(X[i], Y[i], str(i+1))
        for C in cls.all_comps:
            ax.plot(X, df[C + 'sec_max'], label = C + ' RunPhase', alpha = 0.5)
        ax.set_ylabel('secs')
        ax.set_xlabel('Total PETs')
        ax.legend(loc='center left', bbox_to_anchor=(1., 0.5), frameon = False)
        plt.title(cls.app + ': FL ' + str(df['TAU'][1]) + ' hours')
        plt.tight_layout()
        plt.savefig('FIGURES/TOTAL_WALLTIME.png')


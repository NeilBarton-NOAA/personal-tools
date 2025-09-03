# @(#).bashrc  2019.04.14
################################################################################
##  Source global definitions: The next line must be the first non-commented line.
[ -f /etc/bashrc ] && . /etc/bashrc
umask 022
machine=$(uname -n)

################################################################################
##  All non-interactive shells will exit on the next line.
##  Nothing after this line is used by batch shell scripts.
if [ -z "$PS1" ]; then return; fi

##  Set the default prompt
export PS1="\e[0;31m\u\e[0;33m[\W]\e[0;30m:\e[m "
PROMPT_COMMAND='echo -ne "\033]0;${HOSTNAME}\007"'
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward' 2>/dev/null
##  Set the number of commands to be maintained in history within a session.
export HISTSIZE=1000
# env vars expand to directories
shopt -s direxpand
# modules
source ~/.profile
# aliases
alias ls='ls -B --group-directories-first --color=auto'
alias dirs='dirs -v'
alias psu="ps U $USER"
alias gitgeturl="git config --get remote.origin.url"
alias qme="squeue -u $USER --format='%.18i %.50j %.2t %.8M %.10l %.6D'"
alias qdelme="squeue -u $USER | grep -v JOBID | awk '{print \$1}' | xargs scancel"
alias "cylc_check"="~/.cylc_check.sh"
export ARCHIVE_HOME="/NCEPDEV/emc-marine/*year/Neil.Barton"
########################
# machine specific
# orion and hercules
if [[ ${machine} == orion* ]] || [[ ${machine} == hercules-* ]]; then
    node=${HOSTNAME#*-*-} && node=${node%%.*}
    PROMPT_COMMAND='echo -ne "\033]0;${HOSTNAME%%-*}-0${node}\007"'
    export COMPUTE_ACCOUNT=marine-cpu
    export NPB_WORKDIR=/work/noaa/marine/nbarton
    PATH=/work/noaa/marine/nbarton/TOOLS/hercules_miniconda3/bin:${PATH}
# gaeac6
elif [[ ${machine} == gaea* ]] || [[ ${machine} == dtn* ]]; then
    export COMPUTE_ACCOUNT=ira-sti
    export NPB_WORKDIR=/gpfs/f6/sfs-emc/scratch/Neil.Barton
    if [[ $(uname -n) != gaea63 ]] && [[ ${machine} != dtn* ]]; then
        ssh -X gaea63
    fi
# ursa
elif [[ ${machine} == ufe* ]]; then
    export COMPUTE_ACCOUNT=marine-cpu
    export NPB_WORKDIR=/scratch4/NCEPDEV/stmp/Neil.Barton
    #export PROJ_LIB=/scratch2/NCEPDEV/stmp3/Neil.Barton/TOOLS/miniconda3/share/proj
    if [[ $(uname -n) != ufe03 ]] && [[ $(uname -n) != u*[cm]* ]]; then
        ssh -X uf03
    fi
# WCOSS2
elif [[ ${machine} == *[cd]login* ]]; then
    # list of working directories
    export COMPUTE_ACCOUNT=GFS-DEV
    export ptmp=/lfs/h2/emc/ptmp/neil.barton
    export couple_noscrub=/lfs/h2/emc/couple/noscrub/neil.barton
    export ens_noscrub=/lfs/h2/emc/ens/noscrub/neil.barton
    export gefstemp=/lfs/h2/emc/gefstemp/neil.barton
    export NPB_WORKDIR=${ens_noscrub}
    alias qme="qstat -u $USER"
    alias qdelme="qselect -u ${USER} | xargs qdel"
# mercury
elif [[ ${machine} == mfe* ]]; then
    if [[ $(uname -n) != mfe01.fairmont.rdhpcs.noaa.gov ]]; then
        ssh -X mfe01.fairmont.rdhpcs.noaa.gov
    fi
    export NPB_WORKDIR=/collab2/data/Neil.Barton
    alias qme="ps U $USER"
else
    echo "machine unknown in .bashrc: " $machine
fi
alias sd="cd $NPB_WORKDIR"
export CYLC_WORKDIR=${NPB_WORKDIR}



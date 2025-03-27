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
##  Set the number of commands to be maintained in history across logins.
#export HISTFILESIZE=0

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
alias qdelme="squeue -u $USER | grep -v JOBID | awk '{print $1}' | xargs scancel"
ARCHIVE_HOME="/NCEPDEV/emc-marine/*year/Neil.Barton"

if [[ ${machine} == orion* ]] || [[ ${machine} == hercules-* ]]; then
    alias sd="cd /work/noaa/marine/nbarton"
    alias sd2="cd /work/noaa/stmp/nbarton"
    export NPB_WORKDIR=/work/noaa/marine/nbarton
    PATH=/work/noaa/marine/nbarton/TOOLS/hercules_miniconda3/bin:${PATH}
elif [[ ${machine} == gaea** ]]; then
    export NPB_WORKDIR=/gpfs/f6/sfs-emc/scratch/Neil.Barton
    PATH=~/TOOLS/miniconda3/bin:${PATH}
    #/gpfs/f6/scratch/Neil.Barton/
    alias sd="cd ${NPB_WORKDIR}"
    if [[ $(uname -n) != gaea63 ]]; then
        ssh -X gaea63
    fi    
elif [[ ${machine} == h* ]]; then
    export NPB_WORKDIR=/scratch2/NCEPDEV/stmp3/Neil.Barton
    alias sd="cd $NPB_WORKDIR"
    if [[ $(uname -n) != hfe07 ]] && [[ $(uname -n) != h*[cm]* ]]; then
        ssh -X hfe07
    fi
    PATH=/scratch2/NCEPDEV/stmp3/Neil.Barton/TOOLS/miniconda3/bin:${PATH}
elif [[ ${machine} == *[cd]login* ]]; then
    # list of working directories
    export ptmp=/lfs/h2/emc/ptmp/neil.barton
    export couple_noscrub=/lfs/h2/emc/couple/noscrub/neil.barton
    export ens_noscrub=/lfs/h2/emc/ens/noscrub/neil.barton
    export gefstemp=/lfs/h2/emc/gefstemp/neil.barton
    export NPB_WORKDIR=${ens_noscrub}
    alias qme="qstat -u $USER"
    alias sd="cd $NPB_WORKDIR"
    alias qdelme="qselect -u ${USER} | xargs qdel"
elif [[ $machine == nfe* ]]; then
    export NPB_WORKDIR=/collab1/data/Neil.Barton
    alias sd="cd $NPB_WORKDIR"
else
    echo "machine unknown in .bashrc: " $machine
fi
alias "cylc_check"="cylc scan -t rich && cylc scan --states=stopped,paused && globus task list --limit 1000 --filter-status ACTIVE | grep ACTIVE | wc -l && psu | grep SCRIPT | grep get && uptime"
export CYLC_WORKDIR=${NPB_WORKDIR}



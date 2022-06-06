# @(#).bashrc  2019.04.14
################################################################################
##  Source global definitions: The next line must be the first non-commented line.
[ -f /etc/bashrc ] && . /etc/bashrc
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

# aliases
alias ls='ls -B --group-directories-first --color=auto'
alias dirs='dirs -v'
alias psu="ps U $USER"
alias gitgeturl="git config --get remote.origin.url"
alias qme="squeue -u $USER --format='%.18i %.50j %.2t %.8M %.10l %.6D'"

if [[ $machine == *hfe* ]]; then
    alias sd="cd /scratch2/NCEPDEV/stmp1/Neil.Barton"
    export NPB_WORKDIR=/scratch2/NCEPDEV/stmp1/Neil.Barton
elif [[ ${machine} == *Orion* ]]; then
    alias sd="cd /work/noaa/marine/nbarton"
    alias sd2="cd /work/noaa/stmp/nbarton"
    export NPB_WORKDIR=/work/noaa/marine/nbarton
else
    echo "machine unknown in .bashrc: " $machine
fi

# modules
source ~/.profile

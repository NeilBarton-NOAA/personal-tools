#!/bin/sh
cylc scan -t rich 
cylc scan --states=stopped,paused 
#gt=$(globus task list --limit 1000 --filter-status ACTIVE | grep ACTIVE | wc -l)
#echo "# of Globus Tasks Active: ${gt}" 
up=$(uptime)
echo "uptime: ${up}"

#alias "cylc_check"="cylc scan -t rich && cylc scan --states=stopped,paused && globus task list --limit 1000 --filter-status ACTIVE | grep ACTIVE | wc -l && uptime"


#!/bin/sh
#salloc --x11=first -t 2:00:00 --nodes=1 -A marine-cpu --exclusive
salloc --x11=first -q debug -t 0:30:00 --nodes=6 -A marine-cpu #--exclusive
#salloc --x11=first -q debug -t 0:30:00 --nodes=1 -A marine-cpu #--exclusive

#!/bin/sh
salloc --x11=first -t 8:00:00 --nodes=1 -A marine-cpu
#salloc --x11=first -q debug -t 8:00:00 --nodes=1 -A marine-cpu
export START_INT=T

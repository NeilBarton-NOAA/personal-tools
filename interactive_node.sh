#!/bin/sh
salloc --x11=first -q debug -t 0:30:00 --nodes=2 -A marine-cpu

#!/bin/bash

#Processes a queue item for queue.sh
#echo "process worker launched" >&2
cmd=$(echo $1 | sed 's|^[0-9]\+ ||')
pid=$(echo $1 | sed 's|^\([0-9]\+\) .*$|\1|')
echo -e "$(date +%b\ %e\ %T) [$pid]:\t$cmd" >&2
if [ ! -d "/proc/$pid" ]
then
	echo -e "$(date +%b\ %e\ %T) [$pid]:\t\033[0;31mProcess terminated before execution.\033[0m" >&2
	exit 999
fi
#hook up file descriptors to invoking process (as well as fd4 for retval)
exec 0<>"/proc/$pid/fd/0"
exec 1>"/proc/$pid/fd/1"
exec 2>"/proc/$pid/fd/2"
exec 4>"/proc/$pid/fd/4"
eval $cmd <&0 
echo -e "$?"'\0' >&4
#echo "retval transmitted"

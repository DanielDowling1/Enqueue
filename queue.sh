#!/bin/bash

#Daemon that queues a commands in a buffer, executes them in order

daemontmp='/tmp/queued'
mkdir -p $daemontmp
#Check that queue exists. If not, create it.
if [[ ! -p $daemontmp/queue_fifo ]]
then
	mkfifo -m 600 $daemontmp/queue_fifo
else
	echo "fifo already exists! quitting." >&2
	exit 1
fi
#Set parallelism if applicable
if [[ -v 1 ]] && [[ $1 -ge 0 ]]
then
	threads=$1
	if [[ $threads -eq 1 ]]
	then
		echo "$threads thread configured" >&2
	elif [[ $threads -ne 0 ]]
	then
		echo "$threads threads configured" >&2
	else
		echo "∞ threads configured" >&2
	fi
else
	threads=1
fi

#Cleanup fifo after exit
cleanup() {
	rm -rf $daemontmp
}

trap cleanup EXIT
#Process queue subroutine
process_queue() {
	local cmd=$(echo $1 | sed 's|^[0-9]\+ ||')
	local pid=$(echo $1 | sed 's|^\([0-9]\+\) .*$|\1|')
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
}
export -f process_queue

exec 9<> "$daemontmp/queue_fifo"
echo "Starting process loop" >&2
xargs -d '\n' -P$threads -I## bash -c "process_queue '##'" <&9

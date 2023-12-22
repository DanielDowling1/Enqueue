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

exec 9<> "$daemontmp/queue_fifo"
echo "Starting process loop" >&2
xargs -d '\n' -P$threads -I## /home/sentient/process_queue.sh '##' <&9

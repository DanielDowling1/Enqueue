#!/bin/bash

#Agent that enqueues command in queue.sh's queue and returns result to invoking tty

daemontmp='/tmp/queued'

#Check queue buffer exists
if [[ ! -p "$daemontmp/queue_fifo" ]]
then
	echo "No queue exists. Run daemon" >&2
	exit 2
fi

#Check for argument to queue
if [[ $# -eq 0 ]]
then
	echo "Enqueue: No command specified" >&2
	exit 1
fi

#create fds
#echo "creating fds" >&2
exec 9> "$daemontmp/queue_fifo"
#echo "creating retval fifo" >&2
retvalf="$(mktemp -u --tmpdir="$daemontmp")"
#echo "filename $retvalf" >&2
mkfifo -m 600 "$retvalf"
#echo "assigning retval fd" >&2
exec 4<> "$retvalf"
#Create cleanup trap
cleanup() {
	flock -u 9
	exec 4<&-
	exec 9<&-
	rm -f "$retvalf"
}
trap cleanup EXIT

#check mutex and load command to queue
#echo "awaiting mutex" >&2
flock -x 9
#echo "queueing task" >&2
echo "$$ ${@:1}" >&9 
#echo "releasing mutex" >&2
flock -u 9
#echo "waiting for retval" >&2

read retval <&4
#echo "received $retval" >&2
exit $retval

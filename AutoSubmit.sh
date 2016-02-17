#!/bin/bash

my_netid=<fill in your net id>
my_script=<fill in your script path and its corresponding parameters>
check_interval=1800
n_req_engines=40

printf "You have 10 seconds to choose # of engines [$n_req_engines]: \n"
read -t 10 tmp_var
if [ ! -z "$tmp_var" ]
then
	n_req_engines=$tmp_var
fi

epoch=1
while true
do
	printf "| Cycle: $epoch =====[ `date` ]===========================\n"
	n_running_engines=`squeue -u $my_netid | grep 'short.*Eng.*$my_netid  R' | wc -l`
	n_all_engines=`squeue -u $my_netid | grep 'short.*Eng.*$my_netid' | wc -l`

	printf "|--- QInfo: [$n_running_engines running, $n_all_engines submitted, $n_req_engines required] ------- \n"
	if [ $n_all_engines -lt $n_req_engines ]
	then
		let "n_new_engines=$n_req_engines-$n_all_engines"
		printf "Requesting [$n_new_engines] more engines...\n"
		for i in $(seq 1 $req_engines)
		do 
			sbatch $my_script
		done
	fi
	old_time=$(date +"%s")
	while true
	do
		cur_time=$(date +"%s")
		if [ $(($cur_time - $old_time)) -gt $check_interval ]
		then
			break
		fi
		n_running_engines=`squeue -u $my_netid | grep 'short.*Eng.*$my_netid  R' | wc -l`
		echo "There are [$n_running_engines] jobs running in the queue. [$(($old_time + $check_interval - $cur_time))] seconds remaining until next check."
		sleep 60
	done

	printf "Waited [$check_interval] seconds, performing job check ...\n"
	printf "|---------------------- End of cycle [$epoch] -------------------------\n\n\n\n\n"
	let "epoch++"
done

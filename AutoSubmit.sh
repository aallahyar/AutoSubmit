#!/bin/bash

# Fill in your script path and its corresponding parameters
# E.g. my_script=( script.sh 1 2 3 )
my_script=( )
# Fill in your script name
# E.g. my_script_name='script.sh'
my_script_name=''
# Fill in the command to check if your work is done
# E.g. my_script=( test -e output_file )
my_done_check=( )
n_req_engines=1
check_interval=1800
sleep_interval=60

if [ "${#my_script[@]}" -eq 0 -o -z "$my_script_name" -o "${#my_done_check[@]}" -eq 0 ]
then
	echo "Some of the required variables in this file have not been set."
	echo "Edit this file and provide the input to my_script, my_script_name and my_done_check."
	exit 1
fi

read -p "You have 10 seconds to choose # of engines [$n_req_engines]: " -t 10 tmp_var
if [ -n "$tmp_var" ]
then
	n_req_engines=$tmp_var
fi

cleanup() {
  scancel --user="$USER" --name="$my_script_name"
}

trap cleanup INT TERM

epoch=0
while ! "${my_done_check[@]}"
do
	echo "| Cycle: $((++epoch)) =====[ `date` ]==========================="
	n_running_engines=`squeue --noheader --user="$USER" --name="$my_script_name" --states='COMPLETING,RUNNING,SUSPENDED' | wc -l`
	n_all_engines=`squeue --noheader --user="$USER" --name="$my_script_name" | wc -l`

	echo "|--- QInfo: [$n_running_engines running, $n_all_engines submitted, $n_req_engines required] -------"
	if [ $n_all_engines -lt $n_req_engines ]
	then
		echo "Requesting [$((n_req_engines-n_all_engines))] more engines..."
		for ((i=n_all_engines; i<n_req_engines; i++))
		do 
			sbatch "${my_script[@]}"
		done
	fi
	for ((i=0; i<check_interval; i+=sleep_interval))
	do
		n_running_engines=`squeue --noheader --user="$USER" --name="$my_scriptname" --states='COMPLETING,RUNNING,SUSPENDED' | wc -l`
		echo "There are [$n_running_engines] jobs running in the queue. [$((check_interval-i))] seconds remaining until next check."
		sleep "$sleep_interval"
	done

	echo "Waited [$check_interval] seconds, performing job check ..."
	echo -e "|---------------------- End of cycle [$epoch] -------------------------\n\n\n\n"
done

cleanup
exit 0

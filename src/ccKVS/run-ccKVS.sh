#!/usr/bin/env bash

### Start of initialization ###
is_RoCE=0
executable="ccKVS-sc" # choose "ccKVS-sc" or "ccKVS-lin" according to the coherence protocol
export MEMCACHED_IP="10.10.1.4" #Node having memcached for to initialize RDMA QPs connections/handlers
export MLX5_SINGLE_THREADED=1
export MLX5_SCATTER_TO_CQE=1

# Setting up a unique machine id via a list of all ip addresses
machine_id=-1
allIPs=(10.10.1.1 10.10.1.2 10.10.1.3 10.10.1.4 10.10.1.5 10.10.1.6 10.10.1.7 10.10.1.8 10.10.1.9)
#allIPs=(10.10.1.4 10.10.1.2 10.10.1.5)
#allIPs=(10.10.1.4 10.10.1.2)
#localIP=$(ip addr | grep 'state UP' -A2 | sed -n 3p | awk '{print $2}' | cut -f1  -d'/')
localIP=$(cat /etc/hosts | grep $(hostname | cut -d . -f 1) | awk '{print $1}')
for i in "${!allIPs[@]}"; do
	if [  "${allIPs[i]}" ==  "$localIP" ]; then
		machine_id=$i
	else
    remoteIPs+=( "${allIPs[i]}" )
	fi
done

# machine_id = # uncomment this line to manually set the machine id
echo Machine-Id "$machine_id"

### End of initialization ###

# A function to echo in blue color
function blue() {
	es=`tput setaf 4`
	ee=`tput sgr0`
	echo "${es}$1${ee}"
}

blue "Removing SHM keys used by the workers 24 -> 24 + Workers_per_machine (request regions hugepages)"
for i in `seq 0 32`; do
	key=`expr 24 + $i`
	sudo ipcrm -M $key 2>/dev/null
done

# free the  pages workers use
blue "Removing SHM keys used by MICA"
for i in `seq 0 28`; do
	key=`expr 3185 + $i`
	sudo ipcrm -M $key 2>/dev/null
	key=`expr 4185 + $i`
	sudo ipcrm -M $key 2>/dev/null
done

: ${MEMCACHED_IP:?"Need to set MEMCACHED_IP non-empty"}


blue "Removing hugepages"
shm-rm.sh 1>/dev/null 2>/dev/null


blue "Reset server QP registry"
sudo killall memcached
sudo killall ccKVS-sc
if [ "$localIP" == "$MEMCACHED_IP" ]; then
	memcached -l $MEMCACHED_IP 1>/dev/null 2>/dev/null &
fi
sleep 1

blue "Running client and worker threads"
sudo LD_LIBRARY_PATH=/usr/local/lib/ -E \
	./${executable} \
	--machine-id $machine_id \
	--is-roce $is_RoCE \
	2>&1

#if [ "$localIP" == "10.10.1.5" ]; then
	#sudo LD_LIBRARY_PATH=/usr/local/lib/ -E \
		#gdb --args ./${executable} \
		#--machine-id $machine_id \
		#--is-roce $is_RoCE \
		#2>&1
#else
	#sudo LD_LIBRARY_PATH=/usr/local/lib/ -E \
		#./${executable} \
		#--machine-id $machine_id \
		#--is-roce $is_RoCE \
		#2>&1
#fi

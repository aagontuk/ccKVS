set -exuo pipefail

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

SRC_DIR=$SCRIPT_DIR/../src

LOG_DIR=/tmp/cckvs-logs

mkdir -p $LOG_DIR

declare -A pids

servers=(
		"node-0"
		"node-1"
		"node-2"
		"node-3"
		"node-4"
		"node-5"
		"node-6"
		"node-7"
		"node-8"
)

setup_all() {
	for s in ${servers[@]}; do
		echo "[$0] Installing OFED on $s"
		ssh -t -o "StrictHostKeyChecking=no" $s "rm -rf /tmp/mlx; cd /proj/sandstorm-PG0/ashfaq/ccKVS/bin; ./install-mlx-ofed.sh" &> $LOG_DIR/${s}_ofed.log &
		# Get pids
		pids[$s]=$!
	done
	echo "pids: ${pids[@]}"

	# Wait for all pids
	for s in ${servers[@]}; do
		echo "[$0] Waiting for $s"
		wait ${pids[$s]}
		echo "[$0] Done waiting for $s"
	done

	# Reboot all servers
	for s in ${servers[@]}; do
		# Skip this node
		if [[ $s == $(hostname | cut -d . -f 1) ]]; then
			continue
		fi
		echo "[$0] Rebooting $s"
		ssh -t -o "StrictHostKeyChecking=no" $s "sudo reboot"
	done

	# Wait for all servers to come back up
	for s in ${servers[@]}; do
		# Skip this node
		if [[ $s == $(hostname | cut -d . -f 1) ]]; then
			continue
		fi
		echo "[$0] Waiting for $s to come back up"
		while ! ssh -t -o "StrictHostKeyChecking=no" $s "echo 'Server is up'"; do
			sleep 1
		done
		echo "[$0] $s is up"
	done

	# Configure infiniband
	for s in ${servers[@]}; do
		# Skip this node
		if [[ $s == $(hostname | cut -d . -f 1) ]]; then
			continue
		fi
		echo "[$0] Configuring infiniband on $s"
		ssh -t -o "StrictHostKeyChecking=no" $s "cd /proj/sandstorm-PG0/ashfaq/ccKVS/bin; ./ib-config.sh"
	done
}

build_cckvs() {
	# Build CCKVS
	echo "[$0] Building CCKVS"
	cd $SRC_DIR
	make clean &> /dev/null
	make &> /dev/null
}

deploy() {
	build_cckvs

	# Deploy CCKVS
	for s in ${servers[@]}; do
		echo "[$0] Deploying ccKVS to $s"
		ssh -t -o "StrictHostKeyChecking=no" $s "rm -rf ~/ccKVS; cp -r /proj/sandstorm-PG0/ashfaq/ccKVS ~/ccKVS; cd ccKVS/src/ccKVS/; ./run-ccKVS.sh" > $LOG_DIR/$s.log 2>&1 &
	done
}

kill_em_all() {
	all_procs=$(ps aux | grep ccKVS | grep ssh | awk '{print $2}')
	for p in $all_procs; do
		echo "[$0] Killing $p"
		kill -9 $p
	done
}

# Help message
usage() {
	echo "Usage: $0 [OPTION]"
	echo "Options:"
	echo "  -d, --deploy		Deploy ccKVS"
	echo "  -k, --kill		Kill all ccKVS processes"
	echo "  -s, --setup		Setup all servers"
	echo "  -h, --help		Display this help message"
}

# Check enough arguments are passed
if [[ $# -lt 1 ]]; then
	echo "[$0] Invalid number of arguments"
	usage
	exit 1
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		-d|--deploy)
			deploy
			exit 0
			;;
		-k|--kill)
			kill_em_all
			exit 0
			;;
		-s|--setup)
			setup_all
			exit 0
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "[$0] Invalid option: $key"
			usage
			exit 1
			;;
	esac
done

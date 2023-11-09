set -euo pipefail

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

SRC_DIR=$SCRIPT_DIR/../src

LOG_DIR=/tmp/cckvs-logs

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

build_cckvs() {
	# Build CCKVS
	echo "[$0] Building CCKVS"
	cd $SRC_DIR
	make clean
	make
}

deploy() {
	build_cckvs &> /dev/null
	mkdir -p $LOG_DIR

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

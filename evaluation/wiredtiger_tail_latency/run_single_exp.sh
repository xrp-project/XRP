if [ "$(uname -r)" !=  "5.12.0-xrp+" ]; then
    printf "Not in XRP kernel. Please run the following commands to boot into XRP kernel:\n"
    printf "    sudo grub-reboot \"Advanced options for Ubuntu>Ubuntu, with Linux 5.12.0-xrp+\"\n"
    printf "    sudo reboot\n"
    exit 1
fi

SCRIPT_PATH=`realpath $0`
EVAL_PATH=`dirname $SCRIPT_PATH`
BASE_DIR=`realpath $EVAL_PATH/../..`
WT_PATH="$BASE_DIR/wiredtiger"
YCSB_PATH="$BASE_DIR/My-YCSB"
UTILS_PATH="$BASE_DIR/utils"
MOUNT_POINT="/mnt/xrp"
DB_PATH="$MOUNT_POINT/tigerhome"
CACHED_DB_PATH="/tigerhome"

DEV_NAME="/dev/nvme0n1"

if [ $# -ne 4 ] && [ $# -ne 5 ]; then
    printf "Usage: $0 <config file (ycsb_*.yaml)> <cache size in MB (min: 512, max: 4096)> <number of threads (min: 1, max: 3)> <use XRP (y/n)> <block device (optional, default: $DEV_NAME)>\n"
    exit 1
fi
CONFIG=$1
if [ "$CONFIG" != "ycsb_a.yaml" ] &&
   [ "$CONFIG" != "ycsb_b.yaml" ] &&
   [ "$CONFIG" != "ycsb_c.yaml" ] &&
   [ "$CONFIG" != "ycsb_d.yaml" ] &&
   [ "$CONFIG" != "ycsb_e.yaml" ] &&
   [ "$CONFIG" != "ycsb_f.yaml" ]; then
   printf "Invalid config file $CONFIG\n"
   exit 1
fi
CACHE_SIZE=$2
if [ $CACHE_SIZE -lt 512 ] || [ $CACHE_SIZE -gt 4096 ]; then
    printf "Cache size $CACHE_SIZE is out of range. Min: 512. Max: 4096.\n"
    exit 1
fi
CACHE_SIZE=${CACHE_SIZE}M
NUM_THREADS=$3
if [ $NUM_THREADS -lt 1 ] || [ $NUM_THREADS -gt 3 ]; then
    printf "Number of threads $NUM_THREADS is out of range. Min #threads: 1. Max #threads: 3.\n"
    exit 1
fi
USE_XRP=$4
if [ $USE_XRP != 'y' ] && [ $USE_XRP != 'n' ]; then
    printf "USE_XRP $USE_XRP is invalid. It should be either y or n.\n"
    exit 1
fi
if [ ! -z $5 ]; then
    DEV_NAME=$5
fi
if [ "$CONFIG" != "ycsb_e.yaml" ]; then
    OP_INTERVAL=50000
else
    OP_INTERVAL=200000
fi

printf "CONFIG=$CONFIG\n"
printf "CACHE_SIZE=$CACHE_SIZE\n"
printf "USE_XRP=$USE_XRP\n"
printf "DEV_NAME=$DEV_NAME\n"
printf "NUM_THREADS=$NUM_THREADS\n"
printf "OP_INTERVAL=$OP_INTERVAL\n"

# Check whether WiredTiger is built
if [ ! -e "$WT_PATH/wt" ]; then
    printf "Cannot find WiredTiger binary. Please build WiredTiger first.\n"
    exit 1
fi
# Check whether My-YCSB is built
if [ ! -e "$YCSB_PATH/build/init_wt" ]; then
    printf "Cannot find My-YCSB binary. Please build My-YCSB first.\n"
    exit 1
fi

# Disable CPU frequency scaling
$UTILS_PATH/disable_cpu_freq_scaling.sh

# Mount disk
$UTILS_PATH/mount_disk.sh $DEV_NAME $MOUNT_POINT

# Create result folder
mkdir -p $EVAL_PATH/result

pushd $YCSB_PATH/build
YCSB_CONFIG_PATH="$YCSB_PATH/wiredtiger/config/$CONFIG"

# Update configuration file
git checkout $YCSB_CONFIG_PATH
sed -i 's#data_dir: .*#data_dir: "'$DB_PATH'"#' $YCSB_CONFIG_PATH
sed -i 's#nr_thread: .*#nr_thread: '$NUM_THREADS'#' $YCSB_CONFIG_PATH
sed -i 's#cache_size=[0-9A-Za-z]*,#cache_size='$CACHE_SIZE',#' $YCSB_CONFIG_PATH
sed -i 's#next_op_interval_ns: [0-9A-Za-z]*#next_op_interval_ns: '$OP_INTERVAL'#' $YCSB_CONFIG_PATH

# Create database file
printf "Creating database folder...\n"
sudo rm -rf $MOUNT_POINT/*
sudo mkdir -p $DB_PATH
if [ -e $CACHED_DB_PATH ]; then
    printf "Found cached database file. Copying...(This will take a while)\n"
    pushd $CACHED_DB_PATH
    sudo cp * $DB_PATH/
    popd
else
    printf "Failed to find cached database file. Creating a new one...(This will take a very long time)\n"
    sudo ./init_wt $YCSB_CONFIG_PATH
fi

printf "Evaluating WiredTiger with $CACHE_SIZE cache and $NUM_THREADS threads...\n"
if [ $USE_XRP == 'y' ]; then
    export WT_BPF_PATH="$WT_PATH/bpf_prog/wt_bpf.o"
    sudo -E ./run_wt $YCSB_CONFIG_PATH | tee $EVAL_PATH/result/$CONFIG-$CACHE_SIZE-cache-$NUM_THREADS-threads-xrp.txt
else
    unset WT_BPF_PATH
    sudo -E ./run_wt $YCSB_CONFIG_PATH | tee $EVAL_PATH/result/$CONFIG-$CACHE_SIZE-cache-$NUM_THREADS-threads-read.txt
fi
popd

printf "Done. Results are stored in $EVAL_PATH/result\n"

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
if [ ! -z $1 ]; then
    DEV_NAME=$1
fi
printf "DEV_NAME=$DEV_NAME\n"

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
for CONFIG in "ycsb_a.yaml" "ycsb_b.yaml" "ycsb_c.yaml" "ycsb_d.yaml" "ycsb_e.yaml" "ycsb_f.yaml"; do
    YCSB_CONFIG_PATH="$YCSB_PATH/wiredtiger/config/$CONFIG"
    if [ "$CONFIG" != "ycsb_e.yaml" ]; then
        OP_INTERVAL=50000
    else
        OP_INTERVAL=200000
    fi

    CACHE_SIZE=512M
    for NUM_THREADS in 1 2 3; do
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

        # Run with XRP
        export WT_BPF_PATH="$WT_PATH/bpf_prog/wt_bpf.o"
        printf "Evaluating WiredTiger with $CACHE_SIZE cache, $NUM_THREADS threads, and XRP...\n"
        sudo -E ./run_wt $YCSB_CONFIG_PATH | tee $EVAL_PATH/result/$CONFIG-$CACHE_SIZE-cache-$NUM_THREADS-threads-xrp.txt

        # Run without XRP
        unset WT_BPF_PATH
        printf "Evaluating WiredTiger with $CACHE_SIZE cache, $NUM_THREADS threads, and read()...\n"
        sudo -E ./run_wt $YCSB_CONFIG_PATH | tee $EVAL_PATH/result/$CONFIG-$CACHE_SIZE-cache-$NUM_THREADS-threads-read.txt
    done
done
popd

printf "Done. Results are stored in $EVAL_PATH/result\n"

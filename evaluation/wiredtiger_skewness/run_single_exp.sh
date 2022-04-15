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
TRACE_PATH="$YCSB_PATH/build/trace"
TRACE_GENERATOR_PATH="$YCSB_PATH/script/zipfian_trace.py"
UTILS_PATH="$BASE_DIR/utils"
MOUNT_POINT="/mnt/xrp"
DB_PATH="$MOUNT_POINT/tigerhome"
CACHED_DB_PATH="/tigerhome"
CACHED_TRACE_PATH="/zipfian_trace"

CONFIG="ycsb_c.yaml"
YCSB_CONFIG_PATH="$YCSB_PATH/wiredtiger/config/$CONFIG"
CACHE_SIZE="512M"
NUM_THREADS=1
DEV_NAME="/dev/nvme0n1"

if [ $# -ne 2 ] && [ $# -ne 3 ]; then
    printf "Usage: $0 <zipfian constant (min: 0)> <use XRP (y/n)> <block device (optional, default: $DEV_NAME)>\n"
    exit 1
fi
ZIPF=$1
if [ `echo "$ZIPF < 0" | bc` -eq 1 ]; then
    printf "Invalid zipfian constant $ZIPF. Min: 0.\n"
    exit 1
fi
USE_XRP=$2
if [ $USE_XRP != 'y' ] && [ $USE_XRP != 'n' ]; then
    printf "USE_XRP $USE_XRP is invalid. It should be either y or n.\n"
    exit 1
fi
if [ ! -z $3 ]; then
    DEV_NAME=$3
fi

printf "ZIPF=$ZIPF\n"
printf "CONFIG=$CONFIG\n"
printf "CACHE_SIZE=$CACHE_SIZE\n"
printf "USE_XRP=$USE_XRP\n"
printf "DEV_NAME=$DEV_NAME\n"
printf "NUM_THREADS=$NUM_THREADS\n"

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

# Prepare trace file (if needed)
if [ `echo "$ZIPF >= 1" | bc` -eq 1 ]; then
    printf "Creating trace file...\n"
    if [ -e $TRACE_PATH/trace_$ZIPF ]; then
        printf "Trace file already exists\n"
    else
        mkdir -p $TRACE_PATH
        if [ -e $CACHED_TRACE_PATH/trace_$ZIPF ]; then
            printf "Found cached trace file. Copying...\n"
            pushd $CACHED_TRACE_PATH
            sudo cp trace_$ZIPF $TRACE_PATH/
            popd
        else
            printf "Failed to find cached trace file. Generating trace...(This will take a while)\n"
            python3 $TRACE_GENERATOR_PATH $ZIPF $TRACE_PATH/trace_$ZIPF
        fi
    fi
fi

# Update configuration file
git checkout $YCSB_CONFIG_PATH
sed -i 's#data_dir: .*#data_dir: "'$DB_PATH'"#' $YCSB_CONFIG_PATH
sed -i 's#nr_thread: .*#nr_thread: '$NUM_THREADS'#' $YCSB_CONFIG_PATH
sed -i 's#cache_size=[0-9A-Za-z]*,#cache_size='$CACHE_SIZE',#' $YCSB_CONFIG_PATH

if [ `echo "$ZIPF == 0" | bc` -eq 1 ]; then
    # Uniform distribution
    DIST="uniform"
elif [ `echo "$ZIPF >= 1" | bc` -eq 1 ]; then
    # Use pre-generated trace because the embedded Zipfian sampler does not support ZIPF >= 1
    DIST="trace"
    rm -rf cur_trace
    ln -s $TRACE_PATH/trace_$ZIPF cur_trace
else
    # Normal Zipfian distribution
    DIST="zipfian"
    sed -i 's#zipfian_constant: .*#zipfian_constant: '$ZIPF'#' $YCSB_CONFIG_PATH
fi
sed -i 's#request_distribution: .*#request_distribution: "'$DIST'"#' $YCSB_CONFIG_PATH

printf "Evaluating WiredTiger with ZIPF=$ZIPF...\n"
if [ $USE_XRP == 'y' ]; then
    export WT_BPF_PATH="$WT_PATH/bpf_prog/wt_bpf.o"
    sudo -E ./run_wt $YCSB_CONFIG_PATH | tee $EVAL_PATH/result/$ZIPF-zipf-xrp.txt
else
    unset WT_BPF_PATH
    sudo -E ./run_wt $YCSB_CONFIG_PATH | tee $EVAL_PATH/result/$ZIPF-zipf-read.txt
fi
popd

printf "Done. Results are stored in $EVAL_PATH/result\n"

if [ "$(uname -r)" !=  "5.12.0-xrp+" ]; then
    printf "Not in XRP kernel. Please run the following commands to boot into XRP kernel:\n"
    printf "    sudo grub-reboot \"Advanced options for Ubuntu>Ubuntu, with Linux 5.12.0-xrp+\"\n"
    printf "    sudo reboot\n"
    exit 1
fi

SCRIPT_PATH=`realpath $0`
EVAL_PATH=`dirname $SCRIPT_PATH`
BASE_DIR=`realpath $EVAL_PATH/../..`
BPFKV_PATH="$BASE_DIR/BPF-KV"
UTILS_PATH="$BASE_DIR/utils"
MOUNT_POINT="/mnt/xrp"
DB_PATH="$MOUNT_POINT/bpfkv_test_db"

DEV_NAME="/dev/nvme0n1"
LAYER=6
NUM_OPS=100000

if [ $# -ne 2 ] && [ $# -ne 3 ]; then
    printf "Usage: $0 <range length (min: 1, max: 100)> <use XRP (y/n)> <block device (optional, default: $DEV_NAME)>\n"
    exit 1
fi
RANGE_LEN=$1
if [ $RANGE_LEN -lt 1 ] || [ $RANGE_LEN -gt 100 ]; then
    printf "Range length $RANGE_LEN is out of range. Min range: 1. Max range: 100.\n"
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

printf "LAYER=$LAYER\n"
printf "USE_XRP=$USE_XRP\n"
printf "DEV_NAME=$DEV_NAME\n"
printf "NUM_OPS=$NUM_OPS\n"
printf "RANGE_LEN=$RANGE_LEN\n"

# Check whether BPF-KV is built
if [ ! -e "$BPFKV_PATH/simplekv" ]; then
    printf "Cannot find BPF-KV binary. Please build BPF-KV first.\n"
    exit 1
fi

# Disable CPU frequency scaling
$UTILS_PATH/disable_cpu_freq_scaling.sh

# Mount disk
$UTILS_PATH/mount_disk.sh $DEV_NAME $MOUNT_POINT

# Create result folder
mkdir -p $EVAL_PATH/result

pushd $BPFKV_PATH
sudo rm -rf $MOUNT_POINT/*
printf "Creating a BPF-KV database file with $LAYER layers of index...\n"
sudo ./simplekv $DB_PATH $LAYER create

printf "Evaluating BPF-KV with range lookup (size: $RANGE_LEN)...\n"
if [ $USE_XRP == 'y' ]; then
    sudo ./simplekv $DB_PATH $LAYER range --requests=$NUM_OPS --range-size=$RANGE_LEN --use-xrp | tee $EVAL_PATH/result/$RANGE_LEN-range-xrp.txt
else
    sudo ./simplekv $DB_PATH $LAYER range --requests=$NUM_OPS --range-size=$RANGE_LEN | tee $EVAL_PATH/result/$RANGE_LEN-range-read.txt
fi
popd

printf "Done. Results are stored in $EVAL_PATH/result\n"

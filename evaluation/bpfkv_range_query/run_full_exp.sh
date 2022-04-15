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
if [ ! -z $1 ]; then
    DEV_NAME=$1
fi
printf "DEV_NAME=$DEV_NAME\n"

NUM_OPS=100000
LAYER=6
printf "NUM_OPS=$NUM_OPS\n"
printf "LAYER=$LAYER\n"

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

for RANGE_LEN in $(seq 1 5 100); do
    printf "Evaluating BPF-KV with range lookup (size: $RANGE_LEN) and XRP...\n"
    sudo ./simplekv $DB_PATH $LAYER range --requests=$NUM_OPS --range-size=$RANGE_LEN --use-xrp | tee $EVAL_PATH/result/$RANGE_LEN-range-xrp.txt

    printf "Evaluating BPF-KV with range lookup (size: $RANGE_LEN) and read()...\n"
    sudo ./simplekv $DB_PATH $LAYER range --requests=$NUM_OPS --range-size=$RANGE_LEN | tee $EVAL_PATH/result/$RANGE_LEN-range-read.txt
done
popd

printf "Done. Results are stored in $EVAL_PATH/result\n"

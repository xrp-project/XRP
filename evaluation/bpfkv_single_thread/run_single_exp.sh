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

# Specialized BPF-KV
BPFKV_IO_URING_PATH="$BASE_DIR/Specialized-BPF-KV/io_uring"
BPFKV_IO_URING_OPEN_LOOP_PATH="$BASE_DIR/Specialized-BPF-KV/io_uring_open_loop"
BPFKV_SPDK_PATH="$BASE_DIR/Specialized-BPF-KV/spdk"
BPFKV_SPDK_OPEN_LOOP_PATH="$BASE_DIR/Specialized-BPF-KV/spdk_open_loop"

MOUNT_POINT="/mnt/xrp"
DB_PATH="$MOUNT_POINT/bpfkv_test_db"

DEV_NAME="/dev/nvme0n1"
NUM_OPS=1000000
NUM_THREADS=1

if [ $# -ne 2 ] && [ $# -ne 3 ]; then
    printf "Usage: $0 <index layer (min: 1, max: 6)> <mode (read, xrp, io_uring, spdk)> <block device (optional, default: $DEV_NAME)>\n"
    exit 1
fi
LAYER=$1
if [ $LAYER -lt 1 ] || [ $LAYER -gt 6 ]; then
    printf "Index layer $LAYER is out of range. Min layer: 1. Max layer: 6.\n"
    exit 1
fi
MODE="$2"
if [ $MODE != "read" ] && [ $MODE != "xrp" ] && [ $MODE != "io_uring" ] && [ $MODE != "spdk" ]; then
    printf "MODE $MODE is invalid. Available options are: read, xrp, io_uring, spdk.\n"
    exit 1
fi
if [ ! -z $3 ]; then
    DEV_NAME=$3
fi

printf "LAYER=$LAYER\n"
printf "MODE=$MODE\n"
printf "DEV_NAME=$DEV_NAME\n"
printf "NUM_OPS=$NUM_OPS\n"
printf "NUM_THREADS=$NUM_THREADS\n"

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

if [ $MODE == "read" ]; then
    pushd $BPFKV_PATH
    sudo rm -rf $MOUNT_POINT/*
    printf "Creating a BPF-KV database file with $LAYER layers of index...\n"
    sudo ./simplekv $DB_PATH $LAYER create

    printf "Evaluating BPF-KV with $LAYER index lookup and read()...\n"
    sudo ./simplekv $DB_PATH $LAYER get --requests=$NUM_OPS --threads $NUM_THREADS | tee $EVAL_PATH/result/$LAYER-layer-read.txt
    popd
elif [ $MODE == "xrp" ]; then
    pushd $BPFKV_PATH
    sudo rm -rf $MOUNT_POINT/*
    printf "Creating a BPF-KV database file with $LAYER layers of index...\n"
    sudo ./simplekv $DB_PATH $LAYER create

    printf "Evaluating BPF-KV with $LAYER index lookup and XRP...\n"
    sudo ./simplekv $DB_PATH $LAYER get --requests=$NUM_OPS --threads $NUM_THREADS --use-xrp | tee $EVAL_PATH/result/$LAYER-layer-xrp.txt
    popd
elif [ $MODE == "io_uring" ]; then
    pushd $BPFKV_IO_URING_PATH
    # Unmont disk (io_uring is measured with raw block device)
    $UTILS_PATH/unmount_disk.sh $DEV_NAME
    printf "Creating a BPF-KV database file with $LAYER layers of index...\n"
    sudo ./db --load $LAYER

    printf "Evaluating BPF-KV with $LAYER index lookup and io_uring...\n"
    sudo ./db --run $LAYER $NUM_OPS $NUM_THREADS 100 0 0 | tee $EVAL_PATH/result/$LAYER-layer-iouring.txt
    popd
elif [ $MODE == "spdk" ]; then
    pushd $BPFKV_SPDK_PATH
    # Bind disk to UIO driver so that SPDK can use it
    $UTILS_PATH/spdk_setup.sh $DEV_NAME
    printf "Creating a BPF-KV database file with $LAYER layers of index...\n"
    sudo ./db --mode load --layer $LAYER

    printf "Evaluating BPF-KV with $LAYER index lookup and SPDK...\n"
    sudo ./db --mode run --layer $LAYER --thread $NUM_THREADS --request $NUM_OPS --cache 0 | tee $EVAL_PATH/result/$LAYER-layer-spdk.txt
    # Rebind disk to kernel NVMe driver
    $UTILS_PATH/spdk_reset.sh
    popd
fi

printf "Done. Results are stored in $EVAL_PATH/result\n"

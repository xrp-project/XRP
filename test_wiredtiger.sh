if [ "$(uname -r)" !=  "5.12.0-xrp+" ]; then
    printf "Not in XRP kernel. Please run the following commands to boot into XRP kernel:\n"
    printf "    sudo grub-reboot \"Advanced options for Ubuntu>Ubuntu, with Linux 5.12.0-xrp+\"\n"
    printf "    sudo reboot\n"
    exit 1
fi

SCRIPT_PATH=`realpath $0`
BASE_DIR=`dirname $SCRIPT_PATH`
WT_PATH="$BASE_DIR/wiredtiger"
YCSB_PATH="$BASE_DIR/My-YCSB"
YCSB_CONFIG_PATH="$YCSB_PATH/wiredtiger/config/test.yaml"
UTILS_PATH="$BASE_DIR/utils"
MOUNT_POINT="/mnt/xrp"
DB_PATH="$MOUNT_POINT/tigerhome"

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

pushd $YCSB_PATH/build

printf "Creating database folder...\n"
sudo rm -rf $MOUNT_POINT/*
sudo mkdir -p $DB_PATH
sed -i 's#data_dir: .*#data_dir: "'$DB_PATH'"#' $YCSB_CONFIG_PATH
export WT_BPF_PATH="$WT_PATH/bpf_prog/wt_bpf.o"

printf "Creating a small WiredTiger database...\n"
sudo ./init_wt $YCSB_CONFIG_PATH

printf "Running a short YCSB A experiment with XRP enabled...\n"
sudo ./run_wt $YCSB_CONFIG_PATH

popd
printf "Done.\n"

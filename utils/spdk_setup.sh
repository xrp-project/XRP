SCRIPT_PATH=`realpath $0`
UTILS_PATH=`dirname $SCRIPT_PATH`
BASE_DIR=`realpath $UTILS_PATH/..`
SPDK_PATH="$BASE_DIR/spdk"

DEV_NAME=$1
DEV_ID=`basename $DEV_NAME`
DEV_PCI_ADDR=`cat /sys/block/$DEV_ID/device/address`

# Unmount device
$UTILS_PATH/unmount_disk.sh $DEV_NAME

pushd $SPDK_PATH
unset PCI_BLOCKED
export PCI_ALLOWED="$DEV_PCI_ADDR"
sudo -E ./scripts/setup.sh config
popd

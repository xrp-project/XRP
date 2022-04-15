SCRIPT_PATH=`realpath $0`
UTILS_PATH=`dirname $SCRIPT_PATH`
BASE_DIR=`realpath $UTILS_PATH/..`
SPDK_PATH="$BASE_DIR/spdk"

pushd $SPDK_PATH
unset PCI_ALLOWED
unset PCI_BLOCKED
sudo -E ./scripts/setup.sh reset
popd

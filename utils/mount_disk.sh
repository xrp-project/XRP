DEV_NAME=$1
MOUNT_POINT=$2

SCRIPT_PATH=`realpath $0`
UTILS_PATH=`dirname $SCRIPT_PATH`
BASE_DIR=`realpath $UTILS_PATH/..`

printf "Using $DEV_NAME as the storage device\n"
if [ ! -e $DEV_NAME ]; then
    printf "Cannot find $DEV_NAME. Trying to reset SPDK...\n"
    $UTILS_PATH/spdk_reset.sh
fi
if [ ! -e $DEV_NAME ]; then
    printf "Cannot find $DEV_NAME. Please change DEV_NAME in the script accordingly.\n"
    exit 1
fi

if [ ! -e $MOUNT_POINT ]; then
   sudo mkdir -p $MOUNT_POINT
fi

if [ -z "$(cat /proc/mounts | grep -m 1 $DEV_NAME)" ]; then
    printf "$DEV_NAME is not mounted\n"
    if [ -z "$(sudo file -sL $DEV_NAME | grep ext4)" ]; then
        printf "The format of $DEV_NAME is not ext4\n"
        printf "Formatting $DEV_NAME as ext4...\n"
        sudo mkfs.ext4 $DEV_NAME
    fi
    printf "Mounting $DEV_NAME to $MOUNT_POINT...\n"
    sudo mount -t ext4 $DEV_NAME $MOUNT_POINT
fi

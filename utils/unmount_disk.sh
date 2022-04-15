DEV_NAME=$1

while [ ! -z "$(cat /proc/mounts | grep -m 1 $DEV_NAME)" ]; do
    ARR=(`cat /proc/mounts | grep -m 1 $DEV_NAME`)
    MOUNT_POINT=${ARR[1]}
    sudo umount $MOUNT_POINT
done

if [ "$(uname -r)" !=  "5.12.0-xrp+" ]; then
    printf "Not in XRP kernel. Please run the following commands to boot into XRP kernel:\n"
    printf "    sudo grub-reboot \"Advanced options for Ubuntu>Ubuntu, with Linux 5.12.0-xrp+\"\n"
    printf "    sudo reboot\n"
    exit 1
fi

# Install build dependencies
printf "Installing dependencies...\n"
sudo apt-get update
sudo apt-get install -y gcc-multilib clang llvm libelf-dev libdwarf-dev cmake

wget -O /tmp/libbpf0_0.1.0-1_amd64.deb https://http.kali.org/kali/pool/main/libb/libbpf/libbpf0_0.1.0-1_amd64.deb
wget -O /tmp/libbpf-dev_0.1.0-1_amd64.deb https://http.kali.org/kali/pool/main/libb/libbpf/libbpf-dev_0.1.0-1_amd64.deb
wget -O /tmp/dwarves_1.17-1_amd64.deb http://old.kali.org/kali/pool/main/d/dwarves-dfsg/dwarves_1.17-1_amd64.deb

sudo dpkg -i /tmp/libbpf0_0.1.0-1_amd64.deb
sudo dpkg -i /tmp/libbpf-dev_0.1.0-1_amd64.deb
sudo dpkg -i /tmp/dwarves_1.17-1_amd64.deb


SCRIPT_PATH=`realpath $0`
BASE_DIR=`dirname $SCRIPT_PATH`
BPFKV_PATH="$BASE_DIR/BPF-KV"
UTILS_PATH="$BASE_DIR/utils"

DEV_NAME="/dev/nvme0n1"
if [ ! -z $1 ]; then
    DEV_NAME=$1
fi
printf "DEV_NAME=$DEV_NAME\n"

# For specialized BPF-KV
SPDK_PATH="$BASE_DIR/spdk"
BPFKV_IO_URING_PATH="$BASE_DIR/Specialized-BPF-KV/io_uring"
BPFKV_IO_URING_OPEN_LOOP_PATH="$BASE_DIR/Specialized-BPF-KV/io_uring_open_loop"
BPFKV_SPDK_PATH="$BASE_DIR/Specialized-BPF-KV/spdk"
BPFKV_SPDK_OPEN_LOOP_PATH="$BASE_DIR/Specialized-BPF-KV/spdk_open_loop"

$UTILS_PATH/build_and_install_liburing.sh

# Build BPF-KV
pushd $BPFKV_PATH
if [ ! -e "Makefile" ]; then
    git submodule init
    git submodule update
fi

printf "Building BPF-KV...\n"
make
popd

# Build SPDK & specialized BPF-KV
pushd $SPDK_PATH
if [ ! -e "LICENSE" ]; then
    git submodule init
    git submodule update
fi
git submodule update --init
sudo scripts/pkgdep.sh
./configure
make -j8
sudo make install
popd

pushd $BPFKV_IO_URING_PATH
if [ ! -e "CMakeLists.txt" ]; then
    git submodule init
    git submodule update
fi
sed -i 's|#define DB_PATH .*|#define DB_PATH "'$DEV_NAME'"|' db.h
cmake .
make
popd

pushd $BPFKV_IO_URING_OPEN_LOOP_PATH
if [ ! -e "CMakeLists.txt" ]; then
    git submodule init
    git submodule update
fi
sed -i 's|#define DB_PATH .*|#define DB_PATH "'$DEV_NAME'"|' db-bpf.h
cmake .
make db-bpf
# Copy BPF program
cp $BPFKV_PATH/xrp-bpf/get.o .
popd

pushd $BPFKV_SPDK_PATH
if [ ! -e "Makefile" ]; then
    git submodule init
    git submodule update
fi
make
popd

pushd $BPFKV_SPDK_OPEN_LOOP_PATH
if [ ! -e "Makefile" ]; then
    git submodule init
    git submodule update
fi
make
popd

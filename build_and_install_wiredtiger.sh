#!/bin/bash

if [ "$(uname -r)" !=  "5.12.0-xrp+" ]; then
    printf "Not in XRP kernel. Please run the following commands to boot into XRP kernel:\n"
    printf "    sudo grub-reboot \"Advanced options for Ubuntu>Ubuntu, with Linux 5.12.0-xrp+\"\n"
    printf "    sudo reboot\n"
    exit 1
fi

# Install build dependencies
printf "Installing dependencies...\n"
sudo apt-get update
sudo apt-get install -y gcc-multilib clang llvm libelf-dev libdwarf-dev

wget -O /tmp/libbpf0_0.1.0-1_amd64.deb https://http.kali.org/kali/pool/main/libb/libbpf/libbpf0_0.1.0-1_amd64.deb
wget -O /tmp/libbpf-dev_0.1.0-1_amd64.deb https://http.kali.org/kali/pool/main/libb/libbpf/libbpf-dev_0.1.0-1_amd64.deb
wget -O /tmp/dwarves_1.17-1_amd64.deb http://old.kali.org/kali/pool/main/d/dwarves-dfsg/dwarves_1.17-1_amd64.deb

sudo dpkg -i /tmp/libbpf0_0.1.0-1_amd64.deb
sudo dpkg -i /tmp/libbpf-dev_0.1.0-1_amd64.deb
sudo dpkg -i /tmp/dwarves_1.17-1_amd64.deb


SCRIPT_PATH=`realpath $0`
BASE_DIR=`dirname $SCRIPT_PATH`
WT_PATH="$BASE_DIR/wiredtiger"

# Build WiredTiger
pushd $WT_PATH
if [ ! -e "autogen.sh" ]; then
    git submodule init
    git submodule update
fi

git checkout xrp

printf "Building WiredTiger...\n"
./autogen.sh
./configure
make -j8
sudo make install
popd

# Build WiredTiger BPF program
pushd $WT_PATH/bpf_prog
printf "Building WiredTiger BPF program...\n"
make
popd

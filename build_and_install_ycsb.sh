# Install build dependencies
printf "Installing dependencies...\n"
sudo apt-get update
sudo apt-get install -y build-essential unzip python3

SCRIPT_PATH=`realpath $0`
BASE_DIR=`dirname $SCRIPT_PATH`
WT_PATH="$BASE_DIR/wiredtiger"
YCSB_PATH="$BASE_DIR/My-YCSB"

if [ ! -e "$WT_PATH/wt" ]; then
    printf "Please build and install WiredTiger first.\n"
    exit 1
fi

# Install YAML CPP
wget -O /tmp/yaml-cpp-0.6.3.zip https://github.com/jbeder/yaml-cpp/archive/yaml-cpp-0.6.3.zip
pushd /tmp
unzip yaml-cpp-0.6.3.zip
cd yaml-cpp-yaml-cpp-0.6.3
mkdir build
cd build
cmake ..
make -j8
sudo make install
popd

# Build YCSB
pushd $YCSB_PATH
if [ ! -e "CMakeLists.txt" ]; then
    git submodule init
    git submodule update
fi

printf "Building My-YCSB...\n"
mkdir build
cd build
cmake ..
make init_wt
make run_wt
popd

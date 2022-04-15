pushd /tmp
git clone https://github.com/axboe/liburing.git
git checkout tags/liburing-2.1
cd liburing
./configure
make -j8
sudo make install
popd

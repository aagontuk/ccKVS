#!/usr/bin/env bash
sudo apt update
sudo apt-get --yes --force-yes install \
   git make gcc numactl libnuma-dev \
   libmemcached-dev zlib1g-dev memcached \
   libmemcached-dev libmemcached-tools libpapi-dev \
   libgsl-dev


wget https://github.com/ivmai/libatomic_ops/releases/download/v7.4.6/libatomic_ops-7.4.6.tar.gz

tar xzvf libatomic_ops-7.4.6.tar.gz

cd libatomic_ops-7.4.6

./configure

make

sudo make install

cd ..

rm -rf libatomic_ops-7.4.6*

# Install and activate gcc-6
sudo add-apt-repository 'deb http://us.archive.ubuntu.com/ubuntu/ bionic main universe'
sudo apt update
sudo apt install -y gcc-6
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 50
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 40
sudo update-alternatives --set gcc /usr/bin/gcc-6

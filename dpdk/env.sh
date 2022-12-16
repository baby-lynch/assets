#!/bin/bash

########################################
#   SETUP ENVIRONMENT FOR DPDK 21.11   #
#######################################

HOME=/usr/src
RTE_SDK=${HOME}/dpdk-stable-21.11

# Download dependencies, ignore if installed
sudo apt update
sudo apt install build-essential
sudo apt install python3
sudo apt install python3-pip
sudo pip3 install meson ninja pyelftools
sudo apt install libnuma-dev
sudo apt install linux-headers-$(uname -r)

sudo apt install pkg-config
sudo apt install git

# Download dpdk
cd ${HOME}
wget https://fast.dpdk.org/rel/dpdk-21.11.2.tar.xz
tar -xf dpdk-21.11.2.tar.xz
rm -rf dpdk-21.11.2.tar.xz
mv dpdk-stable-21.11.2 dpdk2111

# Download igb-uio
cd ${HOME}
git clone http://dpdk.org/git/dpdk-kmods
cp -r ${HOME}/dpdk-kmods/linux/igb_uio ${RTE_SDK}/kernel/linux/
rm -rf dpdk-kmods

# add igb_uio in dpdk/kernel/linux/meson.build subdirs as below:
cd ${RTE_SDK}/kernel/linux
vim meson.build
subdirs = ['kni', 'igb_uio']
# sed -i -e '/^subdirs/d' meson.build \
#         -e "/Copyright/a\subdirs = ['kni', 'igb_uio']" meson.build \
#         -e '/Copyright/{G;}'

# create a file of meson.build in dpdk/kernel/linux/igb_uio/ as below:
cd ${RTE_SDK}/kernel/linux/igb_uio
vim meson.build
'''
# SPDX-License-Identifier: BSD-3-Clause
# Copyright(c) 2017 Intel Corporation

kernel_version = run_command('uname', '-r', check: true).stdout().strip()
kernel_dir = '/lib/modules/' + kernel_version

mkfile = custom_target('igb_uio_makefile',
        output: 'Makefile',
        command: ['touch', '@OUTPUT@'])

custom_target('igb_uio',
        input: ['igb_uio.c', 'Kbuild'],
        output: 'igb_uio.ko',
        command: ['make', '-C', kernel_dir + '/build',
                'M=' + meson.current_build_dir(),
                'src=' + meson.current_source_dir(),
                'EXTRA_CFLAGS=-I' + meson.current_source_dir() +
                        '/../../../lib/librte_eal/include',
                'modules'],
        depends: mkfile,
        install: true,
        install_dir: kernel_dir + '/extra/dpdk',
        build_by_default: get_option('enable_kmods'))
'''

# Build dpdk
cd ${RTE_SDK}
meson -Denable_kmods=true build
# For debug
# meson -Dc_args='-O0 -g' -Dc_link_args='-O0 -g' -Denable_kmods=true build
cd build
ninja
sudo ninja install
sudo ldconfig

# Check dpdk install
pkg-config --modversion libdpdk

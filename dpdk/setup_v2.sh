#!/bin/bash

#################################################################
#   Runtime Environment Configuration For DPDK(build by meson)  #
#################################################################

#--------------------- USER PARAMETERS ---------------------#
# DPDK source directory
RTE_SDK=/usr/local/src/dpdk-stable-21.11.2
# NIC devices that you want dpdk to take over
devices=(ens160)
# Number of hugepages you want to allocate for dpdk
pages=256
# Mapping: device_name -> pci_address
declare -A dev2pci=(
    [ens160]=03:00.0
    [ens192]=0b:00.0
)

#--------------------- UTILITY FUNCTIONS ---------------------#
# Unloads igb_uio.ko.
remove_igb_uio_module() {
    echo "Unloading any existing DPDK UIO module"
    /sbin/lsmod | grep -s igb_uio >/dev/null
    if [ $? -eq 0 ]; then
        sudo /sbin/rmmod igb_uio
    fi
}

# Loads new igb_uio.ko (and uio module if needed).
load_igb_uio_module() {
    if [ ! -f $RTE_SDK/build/kernel/linux/igb_uio/igb_uio.ko ]; then
        echo "## ERROR: Target does not have the DPDK UIO Kernel Module."
        echo "       To fix, please try to rebuild target."
        return
    fi

    remove_igb_uio_module

    /sbin/lsmod | grep -s uio >/dev/null
    if [ $? -ne 0 ]; then
        modinfo uio >/dev/null
        if [ $? -eq 0 ]; then
            echo "Loading uio module"
            sudo /sbin/modprobe uio
        fi
    fi

    # UIO may be compiled into kernel, so it may not be an error if it can't
    # be loaded.

    echo "Loading DPDK UIO module"
    sudo /sbin/insmod $RTE_SDK/build/kernel/linux/igb_uio/igb_uio.ko
    if [ $? -ne 0 ]; then
        echo "## ERROR: Could not load kmod/igb_uio.ko."
        quit
    fi
}

# Unloads the rte_kni.ko module.
remove_kni_module() {
    echo "Unloading any existing DPDK KNI module"
    /sbin/lsmod | grep -s rte_kni >/dev/null
    if [ $? -eq 0 ]; then
        sudo /sbin/rmmod rte_kni
    fi
}

# Loads the rte_kni.ko module.
load_kni_module() {
    # Check that the KNI module is already built.
    if [ ! -f $RTE_SDK/build/kernel/linux/kni/rte_kni.ko ]; then
        echo "## ERROR: Target does not have the DPDK KNI Module."
        echo "       To fix, please try to rebuild target."
        return
    fi

    # Unload existing version if present.
    remove_kni_module

    # Now try load the KNI module.
    echo "Loading DPDK KNI module"
    sudo /sbin/insmod $RTE_SDK/build/kernel/linux/kni/rte_kni.ko carrier=on
    if [ $? -ne 0 ]; then
        echo "## ERROR: Could not load kmod/rte_kni.ko."
        quit
    fi
}

# Removes hugepage filesystem.
HUGEPGSZ=$(cat /proc/meminfo | grep Hugepagesize | cut -d : -f 2 | tr -d ' ')

remove_mnt_huge() {
    echo "Unmounting /mnt/huge and removing directory"
    grep -s '/mnt/huge' /proc/mounts >/dev/null
    if [ $? -eq 0 ]; then
        sudo umount /mnt/huge
    fi

    if [ -d /mnt/huge ]; then
        sudo rm -R /mnt/huge
    fi
}

# Removes all reserved hugepages.
clear_huge_pages() {
    echo >.echo_tmp
    for d in /sys/devices/system/node/node?; do
        echo "echo 0 > $d/hugepages/hugepages-${HUGEPGSZ}/nr_hugepages" >>.echo_tmp
    done
    echo "Removing currently reserved hugepages"
    sudo sh .echo_tmp
    rm -f .echo_tmp

    remove_mnt_huge
}

# Creates hugepage filesystem.
create_mnt_huge() {
    echo "Creating /mnt/huge and mounting as hugetlbfs"
    sudo mkdir -p /mnt/huge

    grep -s '/mnt/huge' /proc/mounts >/dev/null
    if [ $? -ne 0 ]; then
        sudo mount -t hugetlbfs nodev /mnt/huge
    fi
}

# Creates hugepages.
set_non_numa_pages() {
    clear_huge_pages

    echo "echo $pages > /sys/kernel/mm/hugepages/hugepages-${HUGEPGSZ}/nr_hugepages" >.echo_tmp

    echo "Reserving hugepages"
    sudo sh .echo_tmp
    rm -f .echo_tmp

    create_mnt_huge
}

# Uses dpdk-devbind.py to move devices to work with igb_uio
bind_devices_to_igb_uio() {
    if [ -d /sys/module/igb_uio ]; then
        for ((i = 0; i < ${#devices[@]}; i++)); do
            # dev_pci=$(ethtool -i ${devices[i]} | grep bus-info | cut -d " " -f 2)
            dev_pci=${dev2pci[${devices[i]}]}
            sudo ${RTE_SDK}/usertools/dpdk-devbind.py -b igb_uio ${dev_pci}
        done
    else
        echo "# Please load the 'igb_uio' kernel module before querying or "
        echo "# adjusting device bindings"
    fi
}

setup() {
    # Shutting down specified devices if active
    for ((i = 0; i < ${#devices[@]}; i++)); do
        if [ -L "/sys/class/net/${devices[i]}" ]; then
            echo "Shutting down device: ${devices[i]}"
            sudo ifconfig ${devices[i]} down
        fi
    done
    # Insert IGB UIO module
    load_igb_uio_module
    # Insert KNI module
    load_kni_module
    # Setup hugepage mappings for non-NUMA systems
    set_non_numa_pages
    # Bind Ethernet/Baseband/Crypto device to IGB UIO module
    bind_devices_to_igb_uio
}

display() {
    # Display current Ethernet/Baseband/Crypto device settings
    ${RTE_SDK}/usertools/dpdk-devbind.py --status

    # List hugepage info from /proc/meminfo
    grep -i huge /proc/meminfo
}

setup
display

#!/bin/bash

# Author: Gao Lei

# 生成一些记录code文件夹相关的日志信息
function createTodayLogs() {
    today=$(date +%y%m%d)

    # 记录code文件夹下大小
    du -m | sort -nr >./logs/filesize/${today}.log
    # go文件夹以外 最大的20个文件
    grep -v "go" ./logs/filesize/${today}.log | head -n 21 >./logs/filesize/top20.txt

}
# 将一些可以清理的文件清除掉
function freespace() {
    # --------日志清理--------
    journalctl --disk-usage            # 检查日志大小
    sudo journalctl --vacuum-time=1w   # 最长只保留一周的日志
    sudo journalctl --vacuum-size=200M # 最多只保留200MB的日志

    # drag_and_drop 缓存清理
    sudo rm -rf /home/gao/.cache/vmware/drag_and_drop/*
}

# 设置Git代理
function setGitProxy() {
    ip=10.210.128.1
    port=7890
    http_proxy=${ip}:${port}
    https_proxy=${ip}:${port}

    git config --global http.proxy ${http_proxy}
    git config --global https.proxy ${https_proxy}

    git config --global --list
}

# 清理生成的备份文件
function cleanBackup() {
    rm -rdf /home/gao/backup/*
    rm -rdf /home/gao/code/logs/backup/*
}

# 压缩虚拟机大小
function shrinkVmdisk() {
    # 查看磁盘挂载列表
    sudo vmware-toolbox-cmd disk list
    # 清理挂载列表上的磁盘
    sudo vmware-toolbox-cmd disk shrink /

}

# createTodayLogs
# freespace
setGitProxy
# cleanBackup
# shrinkVmdisk

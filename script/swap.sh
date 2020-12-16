#!/bin/bash
#=============================================================
# https://github.com/cgkings/script-store
# File Name: cg_swap.sh
# Author: cgkings
# Created Time : 2020.12.16
# Description:swap一键脚本
# System Required: Debian/Ubuntu
# 抄自3位作者：wuhuai2020、moerats、？
# Version: 1.0
#=============================================================
#前置变量[字体颜色]
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 
RED_W='\E[41;37m'
END='\E[0m'
totalmem=`free -m | awk '/Mem:/{print $2}'`
totalswap=`free -m | awk '/Swap:/{print $2}'`

#root权限[done]
check_root(){
	if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}Error:本脚本必须root账号运行，请切换root用户后再执行本脚本!${END}"
        exit 1
  fi
}

#检测VPS架构[done]
check_vz(){
  if [[ -d "/proc/vz" ]]; then
    echo -e "${Red}Error:您的VPS是openVZ架构，臣妾办不到啊!${END}"
    exit 1
  fi
}

#生成swap[done]
make-swapfile() {
  echo -e "${Green}正在为您创建"$swapsize"的swap分区...${Font}"
  #分配大小
	fallocate -l ${swapsize} /swapfile
	#设置适当的权限
  chmod 600 /swapfile
  #设置swap区
	mkswap /swapfile
  #启用swap区
	swapon /swapfile
	echo '/swapfile none swap defaults 0 0' >> /etc/fstab
  echo -e "${Green}swap创建成功，信息如下：${Font}"
  cat /proc/swaps
  cat /proc/meminfo | grep Swap
}

#全自动添加swap[done]
auto_swap(){
  if [ -z "$1" ]; then
	  if [ $totalmem -le 1024 ]; then
      swapsize="3072MB"
    elif [ $totalmem -gt 1024 ]; then
      swapsize="$(($totalmem * 3))MB"
    fi
  else
	  swapsize="$1MB"
  fi
  if [ "$totalswap" == '0' ]; then
    make-swapfile
  else
    del_swap
    make-swapfile
  fi
}

#自定义添加swap[done]
add_swap(){
  echo -e "${Green}请输入需要添加的swap，建议为物理内存的2倍大小\n默认为MB，您也可以输入数字+[KB、MB、GB]的方式！（例如：4GB、4096MB、4194304KB）！${END}"
  read -p "请输入swap数值:" swapsize
  echo
  swapsize=`echo ${swapsize} | tr '[a-z]' '[A-Z]'`
  swapsize_unit=${swapsize:0-2:2}
  echo "${swapsize_unit}" | grep -qE '^[0-9]+$'
  if [ $? -eq 0 ];then
    swapsize="${swapsize}MB"
  else
 	  if [ "${swapsize_unit}" != "GB" ] && [ "${swapsize_unit}" != "MB" ] && [ "${swapsize_unit}" != "KB" ];then
	  echo -e "${Red}Error:swap大小只能是数字+单位，并且单位只能是KB、MB、GB。请检查后重新输入!${END}"
    add_swap
    fi
  fi
  #检查是否存在swapfile
  grep -q "swapfile" /etc/fstab
  #如果不存在将为其创建swap
  if [ $? -ne 0 ]; then
	  make-swapfile
  else
	  del_swap
    make-swapfile
  fi
}

#删除swap[done]
del_swap(){
  #检查是否存在swapfile
  grep -q "swapfile" /etc/fstab
  #如果存在就将其移除
  if [ $? -eq 0 ]; then
	  echo -e "${Green}swapfile已发现，正在删除SWAP空间...${Font}"
	  sed -i '/swapfile/d' /etc/fstab
	  echo "3" > /proc/sys/vm/drop_caches
	  swapoff -a
	  rm -f /swapfile
    echo -e "${Green}swap 删除成功！${Font}"
  else
	  echo -e "${Red}你没建过swap,删什么玩意，跟我闹呢，删除失败！${Font}"
    swap_menu
  fi
}

#开始菜单
swap_menu(){
  clear
  echo -e "———————————————————————————————————————"
  echo "当前SWAP：$totalswap MB"
  echo -e "${Green}swap一键脚本 by cgkings${Font}"
  echo -e "${Green}1、全自动添加swap[默认值][内存*3，最小设置3G]${Font}"
  echo -e "${Green}2、自定义添加swap${Font}"
  echo -e "${Green}3、删除swap${Font}"
  echo -e "${Green}4、退出${Font}"
  echo -e "${Green}注：10秒不选或者输入2、3、4外任意字符，默认1.自动添加${Font}"
  echo -e "———————————————————————————————————————"
  read -t 10 -n 1 -p "请输入数字 [1-4]:" num
  num=${num:-1}
  check_root
  check_vz
  case "$num" in
    1)
    echo
    auto_swap
    ;;
    2)
    echo
    add_swap
    ;;
    3)
    echo    
    del_swap
    ;;
    4)
    exit
    ;;
    *)
    echo
    auto_swap
    ;;
  esac
}
swap_menu

#swap调用参数调整
#modi(){
#echo "正在优化..."
#echo
#cat /proc/sys/vm/swappiness
#sudo sysctl vm.swappiness=10
#cat /proc/sys/vm/vfs_cache_pressure
#sudo sysctl vm.vfs_cache_pressure=50
#cp /etc/sysctl.conf /etc/sysctl.conf.bak
#echo >> /etc/sysctl.conf
#echo "vm.swappiness=10" >> /etc/sysctl.conf
#echo >> /etc/sysctl.conf
#echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf
#echo "优化完成"
#swap_menu
#}
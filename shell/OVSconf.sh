#!/bin/bash

echo "该脚本需要网络支持，下载github上的Openvswitch2.4.0版本。在此之前，需安装编译所需的工具。"
echo "若您已经成功安装该版本，你也可以跳过编译安装。"
read -p "是否继续？(y/n):" yn

cd ~

if [[ "$yn" == "y" ]]; then

echo "正在下载源文件，下载完成后将自动为您编译。。。"


yum install -y bridge-utils
yum -y install wget openssl-devel kernel-devel
yum groupinstall -y "Development Tools"


#开始编译

if [ ! -f "openvswitch-2.4.0.tar.gz" ]; then
  wget http://openvswitch.org/releases/openvswitch-2.4.0.tar.gz
fi

tar -zxvpf openvswitch-2.4.0.tar.gz
mkdir -p ~/rpmbuild/SOURCES
sed 's/openvswitch-kmod, //g' openvswitch-2.4.0/rhel/openvswitch.spec > openvswitch-2.4.0/rhel/openvswitch_no_kmod.spec
cp openvswitch-2.4.0.tar.gz ~/rpmbuild/SOURCES/

if [ ! -f "rpmbuild/RPMS/x86_64/openvswitch-2.4.0-1.x86_64.rpm" ]; then
        rpmbuild -bb --without check ~/openvswitch-2.4.0/rhel/openvswitch_no_kmod.spec
        echo "编译完成！即将为您安装..."
fi
#安装编译好的程序
yum localinstall -y ~/rpmbuild/RPMS/x86_64/openvswitch-2.4.0-1.x86_64.rpm


fi

echo "即将为您配置程序，默认情况为您创建一个名为ovs0的网桥"

mkdir /etc/openvswitch
setenforce 0
echo '1' > /proc/sys/net/ipv4/ip_forward

systemctl restart openvswitch

#查看状态
systemctl status openvswitch -l

eth0=$1
hostIP=$2

#添加网桥
ovs-vsctl add-br ovs0
#将主机网卡地址加入网桥
ip addr add $hostIP dev ovs0
ip addr del $hostIP dev $eth0
ovs-vsctl add-port ovs0 $eth0
#添加外网访问路由
route del default
route add default gw 192.168.2.1 dev ovs0
#设置ovs-system 、 ovs0 启动
ip link set ovs-system up
ip link set ovs0 up

ovs-vsctl add-port ovs0 docker0


# From http://goldmann.pl/blog/2014/01/21/connecting-docker-containers-on-multiple-hosts/
 
# Edit this variable: the 'other' host.
REMOTE_IP=192.168.4.112
 
# Edit this variable: the bridge address on 'this' host.
BRIDGE_ADDRESS=172.16.42.1/24
 
# Name of the bridge (should match /etc/default/docker).
BRIDGE_NAME=docker0
 
# bridges
 
# Deactivate the docker0 bridge
ip link set $BRIDGE_NAME down
# Remove the docker0 bridge
brctl delbr $BRIDGE_NAME
# Delete the Open vSwitch bridge
ovs-vsctl del-br br0
# Add the docker0 bridge
brctl addbr $BRIDGE_NAME
# Set up the IP for the docker0 bridge
ip a add $BRIDGE_ADDRESS dev $BRIDGE_NAME
# Activate the bridge
ip link set $BRIDGE_NAME up
# Add the br0 Open vSwitch bridge
ovs-vsctl add-br br0
# Create the tunnel to the other host and attach it to the
# br0 bridge
ovs-vsctl add-port br0 gre0 -- set interface gre0 type=gre options:remote_ip=$REMOTE_IP
# Add the br0 bridge to docker0 bridge
brctl addif $BRIDGE_NAME br0
 
# iptables rules
 
# Enable NAT
iptables -t nat -A POSTROUTING -s 172.16.42.0/24 ! -d 172.16.42.0/24 -j MASQUERADE
# Accept incoming packets for existing connections
iptables -A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Accept all non-intercontainer outgoing packets
iptables -A FORWARD -i docker0 ! -o docker0 -j ACCEPT
# By default allow all outgoing traffic
iptables -A FORWARD -i docker0 -o docker0 -j ACCEPT
 
# Restart Docker daemon to use the new BRIDGE_NAME
service docker restart



 eth0: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:11:00:01 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe11:1/64 scope link 
       valid_lft forever preferred_lft forever


       eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 3a:ef:d8:a3:c2:dd brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::38ef:d8ff:fea3:c2dd/64 scope link tentative dadfailed 
       valid_lft forever preferred_lft forever


 veth7801abe: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP 
    link/ether 96:95:f3:46:f5:d8 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::9495:f3ff:fe46:f5d8/64 scope link 
       valid_lft forever preferred_lft forever



6db9f9dfa7fd4_l: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 6e:8a:3c:48:26:67 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::6c8a:3cff:fe48:2667/64 scope link 
       valid_lft forever preferred_lft forever

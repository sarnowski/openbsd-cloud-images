#!/usr/bin/env bash

if [ $# -ne 2 ]; then
	echo "Usage:  $0 <targetroot> <disksize>" >&2
	exit 1
fi

TARGETROOT=$1
DISKSIZE=$2

# script state
HOST_IF_CREATED=false
GUEST_IF_CREATED=false
DNSMASQ_STARTED=false
WEBFSD_STARTED=false

# networking
HOST_IF=br9
HOST_IP=192.168.253.1

GUEST_IF=tap9

cd $TARGETROOT

echo "=> Creating private network..."
sudo ip link add $HOST_IF type bridge && HOST_IF_CREATED=true
sudo ip link set $HOST_IF up
sudo ip addr add $HOST_IP/24 dev $HOST_IF
ip address show $HOST_IF

echo "=> Creating VM interface..."
sudo ip tuntap add dev $GUEST_IF mode tap user $USER && GUEST_IF_CREATED=true
sudo ip link set $GUEST_IF up
sudo ip link set dev $GUEST_IF master $HOST_IF
ip link show $GUEST_IF

echo "=> Starting dnsmasq (DNS, DHCP, TFTP)..."
rm -fv $PWD/dnsmasq.pid
sudo dnsmasq \
	--listen-address=$HOST_IP \
	--bind-interfaces \
	--domain=local \
	--no-resolv \
	--no-hosts \
	--enable-tftp \
	--tftp-root=$PWD/pxeroot \
	--dhcp-range=192.168.253.2,192.168.253.240,255.255.255.0,12h \
	--dhcp-host=52:*:*:*:*:*,openbsd,192.168.253.2,12h \
	--dhcp-option=option:dns-server,$HOST_IP \
	--dhcp-boot=auto_install \
	--pid-file=$PWD/dnsmasq.pid \
	--dhcp-leasefile=$PWD/dnsmasq.leases \
	&& DNSMASQ_STARTED=true

echo "=> Starting webfsd (HTTP)..."
rm -fv $PWD/webfsd.pid
sudo webfsd \
	-r $PWD/pxeroot \
	-i $HOST_IP \
	-p 80 \
	-k $PWD/webfsd.pid \
	&& WEBFSD_STARTED=true

echo "=> Private network prepared."
sudo netstat -apn | grep "$HOST_IP"

echo "=> Preparing $DISKSIZE disk..."
rm -fv disk.qcow2
qemu-img create -f qcow2 disk.qcow2 ${DISKSIZE}G

echo "=> Executing stage 1: auto installation:"
qemu-system-x86_64 \
	-smp cores=2 \
	-m 2048 \
	-drive if=virtio,file=disk.qcow2,format=qcow2 \
	-netdev tap,id=guestnet,ifname=$GUEST_IF,script=no,downscript=no \
	-device virtio-net,netdev=guestnet \
	-option-rom /usr/share/qemu/pxe-virtio.rom \
	-boot n \
	-no-reboot \
	-nographic
	#-display curses # for boot debugging
INSTALL_STATUS=$?

if [ $INSTALL_STATUS -ne 0 ]; then
	echo "Failed to install OpenBSD!"
	rm -vf disk.qcow2
else
	echo "=> Executing stage 2: firsttime installation:"
	# second stage, run rc.firsttime in real system
	qemu-system-x86_64 \
		-smp cores=2 \
		-m 2048 \
		-no-fd-bootchk \
		-drive if=virtio,file=disk.qcow2,format=qcow2 \
		-netdev user,id=guestnet \
		-device virtio-net,netdev=guestnet \
		-no-reboot \
		-nographic
	if [ $INSTALL_STATUS -ne 0 ]; then
		echo "Failed to install OpenBSD!"
		rm -vf disk.qcow2
	fi
fi

if [ $WEBFSD_STARTED = true ]; then
	echo "=> Stopping webfsd (HTTP)..."
	sudo kill -9 $(sudo cat $PWD/webfsd.pid)
fi

if [ $DNSMASQ_STARTED = true ]; then
	echo "=> Stopping dnsmasq (DNS, DHCP, TFTP)..."
	sudo kill -9 $(sudo cat $PWD/dnsmasq.pid)
fi

if [ $GUEST_IF_CREATED = true ]; then
	echo "=> Deleting VM interface..."
	sudo ip link set $GUEST_IF down
	sudo ip tuntap del dev $GUEST_IF
fi

if [ $HOST_IF_CREATED = true ]; then
	echo "=> Deleting private network..."
	sudo ip link set $HOST_IF down
	sudo ip link del $HOST_IF
fi

echo "=> Environment cleaned up."

#!/usr/bin/env bash

if [ $# -ne 1 ]; then
	echo "Usage:  $0 <disk.qcow2>" >&2
	exit 1
fi

DISK=$1

ACCEL_OPTION=
sudo kvm-ok && ACCEL_OPTION=--enable-kvm

qemu-system-x86_64 \
	$ACCEL_OPTION \
	-smp cores=2 \
	-m 2048 \
	-no-fd-bootchk \
	-drive if=virtio,file=$DISK,format=qcow2 \
	-netdev user,id=guestnet \
	-device virtio-net,netdev=guestnet \
	-nographic

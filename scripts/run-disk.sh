#!/usr/bin/env bash

if [ $# -ne 1 ]; then
	echo "Usage:  $0 <disk.qcow2>" >&2
	exit 1
fi

DISK=$1

qemu-system-x86_64 \
	-smp cores=2 \
	-m 2048 \
	-no-fd-bootchk \
	-drive if=virtio,file=$DISK \
	-netdev user,id=guestnet,hostfwd=tcp::2222-:22 \
	-device virtio-net,netdev=guestnet \
	-nographic

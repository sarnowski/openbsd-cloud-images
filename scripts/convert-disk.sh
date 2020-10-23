#!/usr/bin/env bash

if [ $# -lt 3 ]; then
	echo "Usage:  $0 <disk.qcow2> <disk.ext> <format> [<options>]" >&2
	exit 1
fi

SOURCE_DISK=$1
TARGET_DISK=$2
FORMAT=$3
OPTIONS=$4

[ -n "$OPTIONS" ] && OPTIONS="-o $OPTIONS"

qemu-img convert $SOURCE_DISK -O $FORMAT $OPTIONS $TARGET_DISK

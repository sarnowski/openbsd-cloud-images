#!/bin/sh

if [ $# -ne 2 ]; then
	echo "Usage:  $0 <original-version> <new-version>" >&2
	exit 1
fi

original_version=$1
new_version=$2

cd "$(dirname "$0")"

if [ ! -d "$original_version" ]; then
	echo "Given original version does not exist!" >&2
	exit 2
fi
if [ -d "$new_version" ]; then
	echo "Given new version already exists!" >&2
	exit 3
fi

# make a full copy
cp -r "$original_version" "$new_version"
cd "$new_version"

# modify files

original_version_short="$(echo "$original_version" | sed 's/\.//g')"
new_version_short="$(echo "$new_version" | sed 's/\.//g')"

# get new file hashes
rm SHA256
wget --quiet "https://cdn.openbsd.org/pub/OpenBSD/$new_version/amd64/SHA256"

rm SHA256.sig
wget --quiet "https://cdn.openbsd.org/pub/OpenBSD/$new_version/amd64/SHA256.sig"

rm "openbsd-$original_version_short-base.pub"
wget --quiet "https://ftp.openbsd.org/pub/OpenBSD/$new_version/openbsd-$new_version_short-base.pub"

# update set files
find . -name 'SETS' -exec sed -i "s#$original_version_short#$new_version_short#g" "{}" ";"

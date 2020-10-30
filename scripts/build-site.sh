#!/usr/bin/env bash

if [ $# -lt 3 ]; then
	echo "Usage:  $0 <site.tgz> <provider> <profile> [customization]" >&2
	exit 1
fi

SITE_TARBALL=$1
PROVIDER=$2
PROFILE=$3
CUSTOMIZATION=$4

# make tarball filename absolute
pushd $(dirname $SITE_TARBALL) >/dev/null; SITE_TARBALL=$(pwd)/$(basename $SITE_TARBALL); popd >/dev/null

# we want to go back here
ROOT=$(pwd)

# build temporary directory
TARGETROOT=$(dirname $(dirname $SITE_TARBALL))
SITEROOT=$TARGETROOT/site

rm -rf $SITEROOT
mkdir -p $SITEROOT

# overlay all different sources
PROFILE_VERSION=$(dirname $PROFILE)
PROVIDER_NAME=$(dirname $PROVIDER)

for src in profiles/$PROFILE_VERSION profiles/$PROFILE providers/$PROVIDER_NAME providers/$PROVIDER $CUSTOMIZATION; do
	echo "=> Applying $src"
	cd $ROOT/$src

	if [ -f FILES ]; then
		echo "==> Executing FILES:"
		cat FILES | while read -r FILE OWNER PERM TARGET; do

			if [ "$FILE" = "-" ]; then
				sudo mkdir -vp $SITEROOT/$TARGET || exit $?
			else
				sudo cp -v $FILE $SITEROOT/$TARGET || exit $?
			fi

			sudo chown -v $OWNER $SITEROOT/$TARGET || exit $?
			sudo chmod -v $PERM $SITEROOT/$TARGET || exit $?
		done
	fi

	if [ -x ./post-process-files ]; then
		echo "==> Executing post-process-files:"
		./post-process-files $SITEROOT $ROOT/$src $PROFILE $PROVIDER || exit $?
	fi
done

echo "=> Building site tarball: $SITE_TARBALL..."
touch $SITE_TARBALL
cd $SITEROOT
sudo tar czvf $SITE_TARBALL * || exit $?

echo "=> Recreating index.txt..."
cd $(dirname $SITE_TARBALL)
/bin/ls -l --time-style="+%b %d %H:%M:%S %Y" | tee index.txt

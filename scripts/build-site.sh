#!/usr/bin/env bash

if [ $# -ne 3 ]; then
	echo "Usage:  $0 <site.tgz> <provider> <profile>" >&2
	exit 1
fi

SITE_TARBALL=$1
PROVIDER=$2
PROFILE=$3

# make tarball filename absolute
pushd $(dirname $SITE_TARBALL) >/dev/null; SITE_TARBALL=$(pwd)/$(basename $SITE_TARBALL); popd >/dev/null

# reset to provider files
cd $(dirname $0)/../providers/$PROVIDER

# build temporary directory
TARGETROOT=$(dirname $(dirname $SITE_TARBALL))
VARIANT=$(basename $PROVIDER)

SITEROOT=$TARGETROOT/site

rm -rf $SITEROOT
mkdir -p $SITEROOT

cd ..
echo "=> Creating site file structure..."
cat $VARIANT/FILES | while read -r FILE OWNER PERM TARGET; do

	if [ "$FILE" = "-" ]; then
		mkdir -v $SITEROOT/$TARGET || exit $?
	else
		cp -v $FILE $SITEROOT/$TARGET || exit $?
	fi

	sudo chown -v $OWNER $SITEROOT/$TARGET || exit $?
	sudo chmod -v $PERM $SITEROOT/$TARGET || exit $?
done

if [ -x $VARIANT/post-build ]; then
	echo "=> Executing $VARIANT/post-build:"
	$VARIANT/post-build $SITEROOT $PROVIDER $PROFILE || exit $?
elif [ -x ./post-build ]; then
	echo "=> Executing post-build:"
	./post-build $SITEROOT $PROVIDER $PROFILE || exit $?
fi

echo "=> Building site tarball: $SITE_TARBALL..."
touch $SITE_TARBALL
cd $SITEROOT
sudo tar czvf $SITE_TARBALL * || exit $?

echo "=> Recreating index.txt..."
cd $(dirname $SITE_TARBALL)
/bin/ls -l --time-style="+%b %d %H:%M:%S %Y" | tee index.txt

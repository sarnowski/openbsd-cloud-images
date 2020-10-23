#!/usr/bin/env bash

[ -z "$BUILD_ID" ] && BUILD_ID=$(date '+%Y%m%d%H%M%S')

set -ueo pipefail

if [ $# -ne 3 ]; then
	echo "Usage:  $0 <provider-variant> <profile> <openbsd.vhd>" >&2
	exit 1
fi

PROVIDER_VARIANT=$1
PROFILE=$2
DISK=$3

PROFILE_VERSION=$(echo $PROFILE | sed 'sX/.*XXg')
PROFILE_VARIANT=$(echo $PROFILE | sed 'sX.*/XXg')

DISK_NAME=OpenBSD-${PROFILE_VERSION}-${PROFILE_VARIANT}-${BUILD_NUMBER}.vhd

echo "Build Number: $BUILD_NUMBER"
echo "Subscription ID: $AZURE_SUBSCRIPTION_ID"
echo "Resource Group Name: $AZURE_RESOURCE_GROUP_NAME"
echo "Storage Account Name: $AZURE_STORAGE_ACCOUNT_NAME"
echo "Provider Variant: $PROVIDER_VARIANT"
echo "Profile Version: $PROFILE_VERSION"
echo "Profile Variant: $PROFILE_VARIANT"
echo "Disk Name: $DISK_NAME"
echo "Disk: $DISK"
echo
ls -lh $DISK
echo

az group create \
	--subscription $AZURE_SUBSCRIPTION_ID \
	--name $AZURE_RESOURCE_GROUP_NAME \
	--location $AZURE_LOCATION

az storage account create \
	--subscription $AZURE_SUBSCRIPTION_ID \
	--resource-group $AZURE_RESOURCE_GROUP_NAME \
	--location $AZURE_LOCATION \
	--name $AZURE_STORAGE_ACCOUNT_NAME \
	--sku Premium_LRS

STORAGE_KEY=$(az storage account keys list \
	--subscription $AZURE_SUBSCRIPTION_ID \
	--resource-group $AZURE_RESOURCE_GROUP_NAME \
	--account-name $AZURE_STORAGE_ACCOUNT_NAME \
	--query "[?keyName=='key1']  | [0].value" -o tsv)

az storage blob upload \
	--container-name $PROVIDER_VARIANT \
	--file $DISK \
	--name $DISK_NAME \
	--account-name $AZURE_STORAGE_ACCOUNT_NAME \
	--account-key "$STORAGE_KEY"

echo "Disk uploaded:"
echo
echo "  https://${AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net/$PROVIDER_VARIANT/$DISK_NAME"
echo

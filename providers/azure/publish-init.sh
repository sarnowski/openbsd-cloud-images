#!/usr/bin/env bash

set -ue

if [ $# -ne 1 ]; then
	echo "Usage:  $0 <provider-variant>" >&2
	exit 1
fi

PROVIDER_VARIANT=$1

echo "Subscription ID: $AZURE_SUBSCRIPTION_ID"
echo "Resource Group Name: $AZURE_RESOURCE_GROUP_NAME"
echo "Location: $AZURE_LOCATION"
echo "Storage Account Name: $AZURE_STORAGE_ACCOUNT_NAME"
echo "Provider Variant: $PROVIDER_VARIANT"
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

az storage container create \
	--name $PROVIDER_VARIANT \
	--account-name $AZURE_STORAGE_ACCOUNT_NAME \
	--account-key "$STORAGE_KEY"

echo "Repository prepared: $AZURE_STORAGE_ACCOUNT_NAME/$PROVIDER_VARIANT"

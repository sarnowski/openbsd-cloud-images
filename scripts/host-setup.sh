#!/usr/bin/env bash

if [ -d /vagrant ]; then
	sed -i 's|deb http://us.archive.ubuntu.com/ubuntu/|deb mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list
	timedatectl set-timezone Europe/Berlin
fi

# azure repository
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
    sudo tee /etc/apt/sources.list.d/azure-cli.list

# update packages
apt-get update

if [ -d /vagrant ]; then
	apt-get -o Dpkg::Options::=--force-confnew --allow-downgrades --allow-remove-essential --allow-change-held-packages -fuy dist-upgrade
	apt-get -o Dpkg::Options::=--force-confnew --allow-downgrades --allow-remove-essential --allow-change-held-packages -fuy autoremove

	# set time correctly
	apt-get -o Dpkg::Options::=--force-confnew --allow-downgrades --allow-remove-essential --allow-change-held-packages -fuy install ntpdate
	ntpdate pool.ntp.org
fi

# install required packages
apt-get -o Dpkg::Options::=--force-confnew --allow-downgrades --allow-remove-essential --allow-change-held-packages -fuy install \
	vim \
	qemu \
	dnsmasq \
	signify-openbsd \
	webfs \
	awscli \
	azure-cli

# deactivate webfs
systemctl stop webfs
systemctl disable webfs

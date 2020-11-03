#!/usr/bin/env bash

if [ -d /vagrant ]; then
	sed -i 's|deb http://us.archive.ubuntu.com/ubuntu/|deb mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list
	timedatectl set-timezone Europe/Berlin
fi

if [ -d /vagrant ]; then
	# update packages
	apt-get update

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
	webfs

# deactivate webfs
systemctl stop webfs
systemctl disable webfs

#
# OpenBSD Cloud Image Builder
#
#

#
# Arguments, override as necessary
#
PROVIDER ?= qemu/default
PROFILE ?= 6.8/default
MIRROR ?= https://cdn.openbsd.org/pub/OpenBSD/
DISKSIZE ?= 10
BUILD_ID ?= dev

#
# internal variables
#

# architecture to build for, nothing else supported atm
ARCH := amd64

# profile and provider infos
PROFILE_VERSION := $(shell echo ${PROFILE} | sed 'sX/.*XXg')
PROFILE_VERSION_SHORT := $(shell echo ${PROFILE_VERSION} | sed 'sX\.XXg')
PROFILE_VARIANT := $(shell echo ${PROFILE} | sed 'sX.*/XXg')
PROFILE_VERSION_DIR := profiles/${PROFILE_VERSION}
PROFILE_VARIANT_DIR := profiles/${PROFILE}

PROVIDER_NAME := $(shell echo ${PROVIDER} | sed 'sX/.*XXg')
PROVIDER_VARIANT := $(shell echo ${PROVIDER} | sed 'sX.*/XXg')
PROVIDER_NAME_DIR := providers/${PROVIDER_NAME}
PROVIDER_VARIANT_DIR := providers/${PROVIDER}

# build locations
MIRROR_DIR := mirror/${PROFILE_VERSION}
TARGET_DIR := target/${BUILD_ID}/${PROVIDER}/${PROFILE}
PXEROOT := ${TARGET_DIR}/pxeroot

# installation input
SETS := $(shell cat ${PROFILE_VARIANT_DIR}/SETS)
MINDISK := $(shell cat ${PROFILE_VARIANT_DIR}/MINDISK)

INSTALL_FILES := $(shell echo "${SETS}" | sed 's/ /.tgz /g').tgz
INSTALL_FILES += bsd
INSTALL_FILES += bsd.mp
INSTALL_FILES += site${PROFILE_VERSION_SHORT}.tgz

# final disk
DISKEXT := $(shell cat ${PROVIDER_NAME_DIR}/DISKEXT)
DISKFORMAT := $(shell cat ${PROVIDER_NAME_DIR}/DISKFORMAT)

# site customization
SITE_TARBALL := ${PXEROOT}/site${PROFILE_VERSION_SHORT}.tgz
BUILD_DISK := ${TARGET_DIR}/disk.qcow2
FINAL_DISK := ${TARGET_DIR}/openbsd.${DISKEXT}

# files to download from the mirror
DOWNLOAD_FILES := $(shell echo "${SETS}" | sed 's/ /.tgz /g').tgz
DOWNLOAD_FILES += bsd
DOWNLOAD_FILES += bsd.rd
DOWNLOAD_FILES += bsd.mp
DOWNLOAD_FILES += pxeboot

MIRROR_FILES := ${MIRROR_DIR}/$(shell echo "${DOWNLOAD_FILES}" | sed 'sX X ${MIRROR_DIR}/Xg')

VERSION_FILES := SHA256 SHA256.sig

# all files that need to available for the PXEBOOT
PXE_VERSION_FILES := ${PXEROOT}/$(shell echo "${VERSION_FILES}" | sed 'sX X ${PXEROOT}/Xg')
PXE_MIRROR_FILES := ${PXEROOT}/$(shell echo "${DOWNLOAD_FILES}" | sed 'sX X ${PXEROOT}/Xg')

PXEBOOT_FILES := ${PXE_VERSION_FILES} \
	${PXE_MIRROR_FILES} \
	${PXEROOT}/etc/boot.conf \
	${PXEROOT}/auto_install \
	${PXEROOT}/openbsd-install.conf \
	${PXEROOT}/DISKLABEL \
	${SITE_TARBALL}

# default target for the Makefile
.PHONY: default
default: ${FINAL_DISK}


#
# Prepare /mirror diretory
#

${MIRROR_FILES}:
	@mkdir -p ${MIRROR_DIR}; \
	wget -O $@ ${MIRROR}/${PROFILE_VERSION}/${ARCH}/$(shell basename $@) || exit 1; \
	cd ${MIRROR_DIR}; \
	signify-openbsd -C -p ../../${PROFILE_VERSION_DIR}/openbsd-${PROFILE_VERSION_SHORT}-base.pub -x ../../${PROFILE_VERSION_DIR}/SHA256.sig $(shell basename $@); \
	if [ $$? -ne 0 ]; then \
		rm $(shell basename $@); \
		exit 1; \
	fi


#
# Prepare PXEBOOT
#

${PXE_VERSION_FILES}:
	@mkdir -p ${PXEROOT}; \
	cp -v ${PROFILE_VERSION_DIR}/$(shell basename $@) $@

${PXE_MIRROR_FILES}: ${MIRROR_FILES}
	@mkdir -p ${PXEROOT}; \
	cp -v ${MIRROR_DIR}/$(shell basename $@) $@

${PXEROOT}/etc/boot.conf: ${PROFILE_VERSION_DIR}/boot.conf
	@mkdir -p ${PXEROOT}/etc; \
	cp -v ${PROFILE_VERSION_DIR}/boot.conf ${PXEROOT}/etc/boot.conf

${PXEROOT}/auto_install:
	@ln -sv pxeboot ${PXEROOT}/auto_install

${PXEROOT}/openbsd-install.conf: ${PROFILE_VERSION_DIR}/openbsd-install.conf
	@cp -v ${PROFILE_VERSION_DIR}/openbsd-install.conf ${PXEROOT}/openbsd-install.conf; \
	sed -i 's/PROFILE_DEFINED_SETS/${INSTALL_FILES}/g' ${PXEROOT}/openbsd-install.conf; \
	sed -i 's/VERSION_SHORT/${PROFILE_VERSION_SHORT}/g' ${PXEROOT}/openbsd-install.conf

${PXEROOT}/DISKLABEL: ${PROFILE_VARIANT_DIR}/DISKLABEL
	@cp -v ${PROFILE_VARIANT_DIR}/DISKLABEL ${PXEROOT}/DISKLABEL

#
# Create site.tgz
#


${SITE_TARBALL}:
	@scripts/build-site.sh ${SITE_TARBALL} ${PROVIDER} ${PROFILE}


#
# Run Installation
#

${BUILD_DISK}: ${PXEBOOT_FILES}
	@if [ ${DISKSIZE} -lt ${MINDISK} ]; then \
		echo "Specified disk size (${DISKSIZE} GB) is less than the minimum required for ${PROFILE} (${MINDISK} GB)" >&2; \
		exit 1; \
	fi; \
	scripts/run-install.sh ${TARGET_DIR} ${DISKSIZE}


#
# Convert to final disk image
#

${FINAL_DISK}: ${BUILD_DISK} ${PROVIDER_NAME_DIR}/DISKFORMAT ${PROVIDER_NAME_DIR}/DISKEXT
	@scripts/convert-disk.sh ${BUILD_DISK} ${FINAL_DISK} ${DISKFORMAT}; \
	ls -lh ${FINAL_DISK}


#
# Publish Disk
#

.PHONY: publish-init
publish-init:
	@${PROVIDER_NAME_DIR}/publish-init.sh ${PROVIDER_VARIANT}

.PHONY: publish
publish:
	@${PROVIDER_NAME_DIR}/publish.sh ${PROVIDER_VARIANT} ${PROFILE} ${FINAL_DISK}


#
# Utility functions
#

.PHONY: profiles
profiles:
	@find profiles -maxdepth 2 -mindepth 2 -type d | sed 'sXprofiles/XX'

.PHONY: profile
profile:
	@echo ${PROFILE}

.PHONY: providers
providers:
	@find providers -maxdepth 2 -mindepth 2 -type d | sed 'sXproviders/XX'

.PHONY: provider
provider:
	@echo ${PROVIDER}

.PHONY: mirror
mirror:
	@echo ${MIRROR}

.PHONY: clean
clean:
	@sudo rm -rfv target

.PHONY: distclean
distclean: clean
	@sudo rm -rfv mirror

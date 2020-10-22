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

#
# internal variables
#
ARCH := amd64

VERSION := $(shell echo ${PROFILE} | sed 'sX/.*XXg')
VERSION_SHORT := $(shell echo ${VERSION} | sed 'sX\.XXg')
VARIANT := $(shell echo ${PROFILE} | sed 'sX.*/XXg')

SETS := $(shell cat profiles/${PROFILE}/SETS)
MINDISK := $(shell cat profiles/${PROFILE}/MINDISK)

VERSIONROOT := profiles/${VERSION}
PROFILEROOT := profiles/${PROFILE}

MIRRORROOT := mirror/${VERSION}
TARGETROOT := target/${PROVIDER}/${PROFILE}
PXEROOT := ${TARGETROOT}/pxeroot
SITE_TARBALL=${PXEROOT}/site${VERSION_SHORT}.tgz


.PHONY: default
default: target/${PROVIDER}/${PROFILE}/disk.qcow2


#
# Prepare /mirror diretory
#

DOWNLOAD_FILES := $(shell echo "${SETS}" | sed 's/ /.tgz /g').tgz
DOWNLOAD_FILES += bsd
DOWNLOAD_FILES += bsd.rd
DOWNLOAD_FILES += bsd.mp
DOWNLOAD_FILES += pxeboot

MIRRORED_FILES := ${MIRRORROOT}/$(shell echo "${DOWNLOAD_FILES}" | sed 'sX X ${MIRRORROOT}/Xg')

.PHONY: prepare-mirror
prepare-mirror: ${MIRRORED_FILES}
	@cd ${MIRRORROOT}; \
	signify-openbsd -C -p ../../profiles/6.8/openbsd-68-base.pub -x ../../profiles/6.8/SHA256.sig ${DOWNLOAD_FILES}

${MIRRORED_FILES}:
	@mkdir -p ${MIRRORROOT}; \
	wget -O $@ ${MIRROR}/${VERSION}/${ARCH}/$(shell basename $@) || exit 1; \
	cd ${MIRRORROOT}; \
	signify-openbsd -C -p ../../profiles/6.8/openbsd-68-base.pub -x ../../profiles/6.8/SHA256.sig $(shell basename $@); \
	if [ $$? -ne 0 ]; then \
		rm $(shell basename $@); \
		exit 1; \
	fi


#
# Prepare PXEBOOT
#

VERSION_FILES := SHA256 SHA256.sig

PXE_VERSION_FILES := ${PXEROOT}/$(shell echo "${VERSION_FILES}" | sed 'sX X ${PXEROOT}/Xg')
PXE_MIRRORED_FILES := ${PXEROOT}/$(shell echo "${DOWNLOAD_FILES}" | sed 'sX X ${PXEROOT}/Xg')

INSTALL_FILES := $(shell echo "${SETS}" | sed 's/ /.tgz /g').tgz
INSTALL_FILES += bsd
INSTALL_FILES += bsd.mp
INSTALL_FILES += site${VERSION_SHORT}.tgz

.PHONY: prepare-pxeboot
prepare-pxeboot: ${PXE_VERSION_FILES} ${PXE_MIRRORED_FILES} ${PXEROOT}/etc/boot.conf ${PXEROOT}/auto_install ${PXEROOT}/openbsd-install.conf ${PXEROOT}/DISKLABEL ${SITE_TARBALL}

${PXE_VERSION_FILES}:
	@mkdir -p ${PXEROOT}; \
	cp -v ${VERSIONROOT}/$(shell basename $@) $@  # TODO change cp to ln

${PXE_MIRRORED_FILES}: prepare-mirror
	@mkdir -p ${PXEROOT}; \
	cp -v ${MIRRORROOT}/$(shell basename $@) $@  # TODO change cp to ln

${PXEROOT}/etc/boot.conf: ${VERSIONROOT}/boot.conf
	@mkdir -p ${PXEROOT}/etc; \
	cp -v ${VERSIONROOT}/boot.conf ${PXEROOT}/etc/boot.conf

${PXEROOT}/auto_install:
	@ln -sv pxeboot ${PXEROOT}/auto_install

${PXEROOT}/openbsd-install.conf: ${VERSIONROOT}/openbsd-install.conf
	@cp -v ${VERSIONROOT}/openbsd-install.conf ${PXEROOT}/openbsd-install.conf; \
	sed -i 's/PROFILE_DEFINED_SETS/${INSTALL_FILES}/g' ${PXEROOT}/openbsd-install.conf; \
	sed -i 's/VERSION_SHORT/${VERSION_SHORT}/g' ${PXEROOT}/openbsd-install.conf

${PXEROOT}/DISKLABEL: ${PROFILEROOT}/DISKLABEL
	@cp -v ${PROFILEROOT}/DISKLABEL ${PXEROOT}/DISKLABEL

#
# Create site.tgz
#


${SITE_TARBALL}:
	@scripts/build-site.sh ${SITE_TARBALL} ${PROVIDER} ${PROFILE}

#
# Run Installation
#

${TARGETROOT}/disk.qcow2: prepare-pxeboot
	@if [ ${DISKSIZE} -lt ${MINDISK} ]; then \
		echo "Specified disk size (${DISKSIZE} GB) is less than the minimum required for ${PROFILE} (${MINDISK} GB)" >&2; \
		exit 1; \
	fi; \
	scripts/run-install.sh ${TARGETROOT} ${DISKSIZE}

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

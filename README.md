# OpenBSD Cloud Images

![OpenBSD Cloud Images Status](https://github.com/sarnowski/openbsd-cloud-images/workflows/Cloud-Images/badge.svg?branch=main)

This repository contains a build system to create OpenBSD cloud images on Linux machines.
Most automated build systems provide great support for Linux but mostly not for OpenBSD.
Until this changes, the build framework will focus on Linux to allow everyone to automatically build OpenBSD images for their servers.

The following providers are supported:

  * azure
  * qemu / kvm

## Local Build Environment

This framework provides a Vagrantfile with a defined host system to build the images.

    $ vagrant up
    $ vagrant ssh
    $ cd /vagrant

## Usage

Build cloud image:

    make

Possible arguments:

  * `PROFILE`: the OpenBSD profile to build, see below
  * `PROVIDER`: the cloud provider to build for, see below
  * `DISKSIZE`: image size like `10` (GB)

## Profiles

Profiles define the basic configuration of the OpenBSD system.
They primarily define the installed file sets.
There are the following profiles defined:

  * `default`: Installs all sets except for `comp` (compiler) and `game` (games).
  * `full`: Installs all sets.
  * `minimal`: Installs only `base` and `man`.

List all available profiles:

    make profiles

Show current profile:

    make profile

Set the profile with the `PROFILE` variable:

    make PROFILE=6.8/minimal

### New profile

OpenBSD releases new versions every half a year.
The `profiles/clone-version.sh` script can be used to easily clone an old version for the new one.
In almost all cases, this will just work as OpenBSD generally has a quite stable ecosystem.

Once a new profile is finished, don't forget to update `.github/workflows/pipeline.yml` to build with the new one.
Also change the default profile in the `Makefile` to the new version.

## Provider

Providers define cloud specific configurations of the OpenBSD system.

List all available providers:

    make providers

Show current provider:

    make provider

Set the profile with the `PROVIDER` variable:

    make PROVIDER=qemu/default

## Mirror

To download the OpenBSD file sets, a default mirror is set but can be overriden.

Show current mirror:

    make mirror

Set the mirror with the `MIRROR` variable:

    make MIRROR=https://ftp.openbsd.org/pub/OpenBSD/

## Local Execution

To run the produced qemu images locally, you can use the provided scripts.
For example:

    ./scripts/run-disk.sh target/dev/qemu/dev/7.1/minimal/disk.qcow2

If you are using the default `qemu/dev` provider, the `root` password will be `openbsd`.

## License

Copyright (c) 2020-2022 Tobias Sarnowski <tobias@sarnowski.io>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# afpfs-ng-rpm

Compile [afpfs-ng](https://github.com/simonvetter/afpfs-ng) into a native package for your distro: **.deb** for Debian/Ubuntu, or **.rpm** for Fedora/RHEL/CentOS.

afpfs-ng / libafpclient is an open source client for the Apple Filing Protocol.

This is a fork of [rc2dev/afpfs-ng-deb](https://github.com/rc2dev/afpfs-ng-deb) that adds Fedora/RPM packaging alongside the original Debian build.

## Purpose

afpfs-ng is no longer packaged in most distros, but it remains useful - for example, [to mount Apple Time Capsule shares](https://rafaelc.org/posts/mounting-airport-time-capsule-on-linux-in-2025/).

This repository provides a clean and reproducible way to build afpfs-ng inside a Docker container and generate an installable package, without needing a full development toolchain on your own machine.

## Fedora support

Both packages are built from the same pinned upstream source and patches, so they get identical behavior. Critically, both build images install `libgcrypt`, which afpfs-ng needs at compile time to enable the `DHCAST128` and `DHX2` authentication methods. Without it, the binary silently falls back to cleartext/no-auth login only - which most real AFP servers, including Time Capsule, refuse. You can confirm this on either distro after installing:

```bash
afp_client status
# UAMs compiled in: Cleartxt Passwrd, No User Authent, Randnum Exchange, 2-Way Randnum Exchange, DHCAST128, DHX2
```

If `DHCAST128`/`DHX2` are missing from that list, something built without `libgcrypt` present.

## Requirements

- Docker
- Make

## Usage

To build the Fedora/RPM package, run:

```bash
make rpm
```

To build the Debian package, run:

```bash
make deb
```

Running `make` with no target builds the `.deb`, for backwards compatibility with the original repo. Both packages are written to the `./dist` directory; `make rpm` also produces `-debuginfo` and `-debugsource` RPMs alongside the main one.

## Installing the package

Fedora/RHEL:

```bash
sudo dnf install ./dist/afpfs-ng-<version>.fc<release>.<arch>.rpm
```

Debian/Ubuntu:

```bash
sudo apt install ./dist/afpfs-ng_<version>_<arch>_<codename>.deb
```

## License

Licensed under [GPLv3](LICENSE)

Copyright (C) 2025 [Rafael Cavalcanti](https://rafaelc.org/dev)

# Freshsnakes-void

New and old Python versions for [Void Linux](https://voidlinux.org/).
Inspired by -- but unaffiliated with --
[deadsnakes](https://github.com/deadsnakes).

Currently available Pythons:

- 3.10 [.20]
- 3.11 [.15]
- 3.12 [.9]
- 3.13 [.14]
- 3.14 [.6]

## Usage

Download the .xbps package of the version of Python
you need from the
[releases page](https://github.com/stratal-systems/freshsnakes-void/releases)
and install it using `xdowngrade` from the
xtools package.

Example for Python3.12:

```sh
sudo xbps-install -Syu xtools

wget https://github.com/maybeetree/freshsnakes-void-fork/releases/latest/download/freshsnakes-python3.12-3.12.9_1.x86_64.xbps

sudo xdowngrade ./freshsnakes-python3.12-3.12.9_1.x86_64.xbps
```

Unlike Void's standard python package, which integrates deeply
with both the filesystem and the package manager,
the freshsnakes packages strive to be more or less isolated
to avoid conflicts.
Everything is installed under `/opt/freshsnakes-python$version`:

```sh
/opt/freshsnakes-python3.12/bin/python3 --version
Python 3.12.13
```

Uninstalling can be done like any other xbps package:

```sh
sudo xbps-remove freshsnakes-python3.12
```

Alternatively, it is possible to install the .xbps tarballs directly with
`tar`:

```sh
sudo tar xf ./freshsnakes-python3.12-3.12.9_1.x86_64.xbps --directory /
```

Since the freshsnakes installation is confined entirely to `/opt`,
removing this "out-of-band" installation is also trivial:

```sh
sudo rm -rf /opt/freshsnakes-python3.12
```

## Building locally

The packages can be built locally using `./scripts/doit.sh`.
This script will clone a copy of the upstream `void-packages`
repo and use
an overlayfs mount to combine it with our own `void-packages`
directory containing the python package templates.
This should "just work" on any normal-ish install of Linux.

On non-Void distros, it is also possible to build the packages
using a Void Linux docker container.
This is automated using the `./scripts/doit-in-docker.sh`
script.
The container is spawned with `SYS_ADMIN` capability in order
to allow creating overlayfs mounts.



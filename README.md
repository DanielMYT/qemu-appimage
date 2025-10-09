# qemu-appimage
QEMU as an AppImage for almost any GNU/Linux distribution (unofficial).

# About
This is an AppImage for [QEMU](https://www.qemu.org/) - a general purpose
machine emulation and virtualization software.

This is primary designed as an easy way to access and use the latest version of
QEMU on almost any GNU/Linux distribution. It is particularly useful for
distributions that don't provide native packages in their repositories, or for
ones that provide an unacceptably outdated version. This is because there are
very few, if any, official generic binaries of QEMU available on the internet.
Builds of the AppImage are provided for x86_64 and aarch64; other architectures
(including 32-bit architectures) are unsupported and no support is planned for
them.

It should be noted that this project is **UNOFFICIAL**, and is not affiliated
with or endorsed by the developers of QEMU in any way. As such, all bugs and
issues with the AppImage should be reported to the developers of this project,
**NOT** the upstream QEMU developers. You can report a bug using our
[GitHub issue tracker](https://github.com/DanielMYT/qemu-appimage/issues).
If it is later discovered that the issue exists in QEMU itself, and is not
specific to this AppImage, then and only then may we forward the issue onto the
QEMU developers.

The AppImage is built under Debian 11, and should therefore be compatible with
all reasonably modern distributions. Building on Ubuntu 20.04 is not possible
(at least without unconventional and complex workarounds), due to the fact that
the software it provides is too outdated. By contrast, building the AppImage
under Ubuntu 22.04 would have the possibility of alienating some older distros,
because it's still fairly recent (at the time of writing). Therefore, the
decision was made to use Debian 11, which can be thought of as essentially
in-between Ubuntu 20.04 and Ubuntu 22.04. It should be noted, however, that
this may change in the future.

The build scripts in this repository are [MIT licensed](LICENSE). The output
binaries produced by the script are licensed under the same license terms as
QEMU itself. All relevant license files from the QEMU source tree will be
included in the AppImage, accessible by passing the `--appimage-extract`
argument when running the AppImage file. The author(s) of the scripts in this
repo make no additional claims of authorship or copyright over the software
used by and/or produced from the scripts.

# Running
**NOTE:** AppImages require FUSE version 2.x to run. Many modern distributions
don't include this by default, and it therefore may need to be installed
manually. The official AppImage documentation has details about this. Please
see [here](https://docs.appimage.org/user-guide/troubleshooting/fuse.html).

The AppImage may be launched graphically from a desktop session, or via the
command-line. To launch it graphically, you may need to first right-click the
AppImage file in your file manager, go to the "Properties" tab, and then check
the box labelled "Allow this file to be executed as a program.", or something
similar. By default, `qemu-system-x86_64` will launch.

On the other hand, running from the command-line gives you more flexibility. As
well as allowing you to pass various command-line arguments, it also allows you
to specify which program from the AppImage you want to run, as this AppImage
provides the entire toolset from the QEMU package. First, you need to make the
AppImage executable (remember to always replace `X.Y.Z` with the actual version
number):
```
chmod +x qemu-X.Y.Z-x86_64.AppImage
```

Now you can launch the AppImage as an executable, which will by default launch
`qemu-system-x86_64` (regardless of your host system's architecture):
```
./qemu-X.Y.Z-x86_64.AppImage
```

Command-line arguments can be passed directory to the AppImage, and they will
be forwarded on to the program that runs from within the AppImage. For example:
```
./qemu-X.Y.Z-x86_64.AppImage -enable-kvm -m 4G -smp 2 -vga qxl -hda example.qcow2 -cdrom livecd.iso
```

To instead launch a different program within the AppImage, you can make use of
the `APPIMAGE_EXE` environment variable. For example, running `qemu-img` to
convert a raw disk image to QEMU's QCOW2 format:
```
APPIMAGE_EXE=qemu-img ./qemu-X.Y.Z-x86_64.AppImage convert -f raw -O qcow2 example.img example.qcow2
```

To see the full list of executables in the AppImage, set `APPIMAGE_EXE` to
`list`, as follows:
```
APPIMAGE_EXE=list ./qemu-X.Y.Z-x86_64.AppImage
```

# Building
The AppImage is built inside an isolated Docker container, so as to ensure that
builds are not influenced in any way by the system they are built from, as well
as to ensure the build process (specifically when it comes to the dependencies
that need to be installed) does not taint the host system in any way. You can
build it using the following command:
```
docker build --no-cache --target artifact --output type=local,dest=. .
```
The build process may take a while, especially if you are on weak hardware.
However, once it finishes, it will produce the AppImage file in a subdirectory
named `artifact` in your current path.

**NOTE:** If you are using the snap version of Docker, the package is confined
and is not allowed to write into most directories. This will cause a permission
denied error to occur at the end of the build process. To resolve this, you can
use the following modified command instead:
```
docker build --no-cache --target artifact --output type=local,dest=/tmp .
```
This will instead place the `artifact` directory under `/tmp`, which all snap
packages are allowed to write to. You can then move the directory back to your
current directory with the following command (may need to be run as root):
```
mv /tmp/snap-private-tmp/snap.docker/tmp/artifact .
```

**NOTE:** The Docker build cache remains on your system even after a build is
completed. This can waste disk space, especially if you build multiple times.
To cleanup this cache, run the following command (answering `y` when prompted).
```
docker system prune
```

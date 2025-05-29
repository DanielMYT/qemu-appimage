# We use Debian 11 for building, since Ubuntu 20.04's packages are too old.
# Debian 11 can be thought of as a middle ground between 20.04 and 22.04.
FROM debian:11 AS builder

# Work in a subdirectory, instead of the root directory.
WORKDIR /work

# Be careful when updating the version of QEMU.
# It may require modification of the build arguments below.
ARG VER_QEMU=10.0.2

# Specify the name of the final AppImage.
ENV LDAI_OUTPUT="qemu-${VER_QEMU}-x86_64.AppImage"

# Prevent apt-get from showing interactive prompts even with -y.
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies from APT/DPKG.
RUN apt-get update && apt-get -y install \
    bash-completion \
    bison \
    build-essential \
    curl \
    file \
    flex \
    gettext \
    git \
    libaio-dev \
    libblockdev-mpath-dev \
    libbrlapi-dev \
    libbz2-dev \
    libcacard-dev \
    libcap-ng-dev \
    libcapstone-dev \
    libcurl4-gnutls-dev \
    libcmocka-dev \
    libdaxctl-dev \
    libdw-dev \
    libfuse3-dev \
    libgbm-dev \
    libglib2.0-dev \
    libglusterfs-dev \
    libgnutls28-dev \
    libgtk-3-dev \
    libiscsi-dev \
    libjpeg-dev \
    libjson-c-dev \
    libkeyutils-dev \
    liblzo2-dev \
    libncurses-dev \
    libnfs-dev \
    libnuma-dev \
    libpmem-dev \
    librbd-dev \
    librdmacm-dev \
    libsasl2-dev \
    libsdl2-dev \
    libsdl2-image-dev \
    libseccomp-dev \
    libspice-server-dev \
    libssh-dev \
    libslirp-dev \
    libsnappy-dev \
    liburing-dev \
    libusb-1.0-0-dev \
    libusbredirparser-dev \
    libvdeplug-dev \
    libvirglrenderer-dev \
    libvte-2.91-dev \
    libzstd-dev \
    ninja-build \
    patchelf \
    pkg-config \
    python3-pip

# Install additional dependencies from PIP.
# These are either missing from APT/DPKG, or the APT/DPKG version is too old.
RUN pip3 install meson==1.5.0 pycotap==1.2.0 tomli==2.1.0

# Download and extract the source.
# Retry liberally to prevent a GitHub workflow fail if the server is buggy.
RUN curl --retry 10 --retry-delay 3 -fLO \
    "https://download.qemu.org/qemu-${VER_QEMU}.tar.xz" && \
    mkdir -p src pkg && \
    tar -xf "qemu-${VER_QEMU}.tar.xz" -C src --strip-components=1

# Compile QEMU and install it to the staging directory.
RUN cd src && ./configure \
    --prefix=/usr \
    --libdir=lib \
    --disable-af-xdp \
    --enable-alsa \
    --enable-attr \
    --disable-auth-pam \
    --enable-avx2 \
    --enable-avx512bw \
    --disable-blkio \
    --enable-bochs \
    --disable-bpf \
    --enable-brlapi \
    --disable-bsd-user \
    --enable-bzip2 \
    --disable-canokey \
    --enable-cap-ng \
    --enable-capstone \
    --enable-cloop \
    --disable-cocoa \
    --enable-colo-proxy \
    --disable-coreaudio \
    --enable-crypto-afalg \
    --enable-curl \
    --enable-curses \
    --enable-dbus-display \
    --enable-dmg \
    --disable-docs \
    --disable-dsound \
    --enable-fuse \
    --enable-fuse-lseek \
    --disable-gcrypt \
    --enable-gettext \
    --enable-gio \
    --enable-glusterfs \
    --enable-gnutls \
    --enable-gtk \
    --disable-gtk-clipboard \
    --enable-guest-agent \
    --disable-guest-agent-msi \
    --disable-hv-balloon \
    --disable-hvf \
    --enable-iconv \
    --disable-jack \
    --enable-keyring \
    --enable-kvm \
    --enable-l2tpv3 \
    --disable-libcbor \
    --enable-libdaxctl \
    --enable-libdw \
    --enable-libiscsi \
    --enable-libkeyutils \
    --enable-libnfs \
    --enable-libpmem \
    --enable-libssh \
    --enable-libudev \
    --enable-libusb \
    --enable-libvduse \
    --enable-linux-aio \
    --enable-linux-io-uring \
    --enable-linux-user \
    --disable-lzfse \
    --enable-lzo \
    --enable-malloc-trim \
    --disable-membarrier \
    --disable-modules \
    --enable-mpath \
    --enable-multiprocess \
    --disable-netmap \
    --enable-nettle \
    --enable-numa \
    --disable-nvmm \
    --enable-opengl \
    --enable-oss \
    --enable-pa \
    --enable-parallels \
    --enable-pie \
    --disable-pipewire \
    --enable-pixman \
    --enable-plugins \
    --enable-png \
    --enable-pvg \
    --disable-qatzip \
    --enable-qcow1 \
    --enable-qed \
    --disable-qga-vss \
    --disable-qpl \
    --enable-rbd \
    --enable-rdma \
    --enable-replication \
    --disable-rust \
    --disable-rutabaga-gfx \
    --enable-sdl \
    --enable-sdl-image \
    --enable-seccomp \
    --disable-selinux \
    --enable-slirp \
    --disable-slirp-smbd \
    --enable-smartcard \
    --enable-snappy \
    --disable-sndio \
    --disable-sparse \
    --enable-spice \
    --enable-spice-protocol \
    --enable-stack-protector \
    --enable-strip \
    --enable-system \
    --enable-tcg \
    --enable-tools \
    --enable-tpm \
    --disable-u2f \
    --disable-uadk \
    --enable-usb-redir \
    --enable-user \
    --enable-vde \
    --enable-vdi \
    --enable-vduse-blk-export \
    --enable-vfio-user-server \
    --enable-vhdx \
    --enable-vhost-crypto \
    --enable-vhost-kernel \
    --enable-vhost-net \
    --enable-vhost-user \
    --enable-vhost-user-blk-server \
    --enable-vhost-vdpa \
    --enable-virglrenderer \
    --enable-virtfs \
    --enable-vmdk \
    --disable-vmnet \
    --enable-vnc \
    --enable-vnc-jpeg \
    --enable-vnc-sasl \
    --enable-vpc \
    --enable-vte \
    --enable-vvfat \
    --disable-werror \
    --disable-whpx \
    --disable-xen \
    --disable-xen-pci-passthrough \
    --enable-xkbcommon \
    --enable-zstd \
    && make -j$(nproc) \
    && make DESTDIR=/work/pkg/AppDir install \
    && install -t /work/pkg/AppDir -Dm644 COPYING COPYING.LIB LICENSE

# Miscellaneous housekeeping tasks.
# 1. Strip symbols from binaries and libraries.
# 2. Set relative rpath for binaries, to improve portability.
# 3. Do the same thing for the libraries, if any.
# 4. Remove all unneeded files from the distribution.
# 5. Add exec and category entries to desktop file.
RUN find pkg/AppDir/usr/bin -type f \
    -exec strip --strip-all {} ';' && \
    find pkg/AppDir/usr/lib -type f -name \*.so\* \
    -exec strip --strip-unneeded {} ';' && \
    find pkg/AppDir/usr/bin -type f \
    -exec patchelf --set-rpath '$ORIGIN/../lib' {} ';' && \
    find pkg/AppDir/usr/lib -type f -name \*.so\* \
    -exec patchelf --set-rpath '$ORIGIN' {} ';' && \
    rm -rf pkg/AppDir/usr/include pkg/AppDir/var \
    pkg/AppDir/usr/lib/pkgconfig pkg/AppDir/usr/lib/libfdt.a && \
    echo "Categories=System;Emulator;" >> pkg/AppDir/usr/share/applications/qemu.desktop && \
    echo "Exec=qemu-system-x86_64" >> pkg/AppDir/usr/share/applications/qemu.desktop

# Put in the AppRun file.
COPY AppRun ./pkg/

# Download and run linuxdeploy to build the AppImage.
RUN cd pkg && \
    curl -fLO https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage && \
    curl -fLO https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh && \
    chmod 755 linuxdeploy-x86_64.AppImage linuxdeploy-plugin-gtk.sh && \
    ./linuxdeploy-x86_64.AppImage --appimage-extract && \
    squashfs-root/usr/bin/linuxdeploy \
    --appdir AppDir \
    --custom-apprun AppRun \
    --desktop-file AppDir/usr/share/applications/qemu.desktop \
    --icon-file AppDir/usr/share/icons/hicolor/256x256/apps/qemu.png \
    --plugin gtk \
    --output appimage \
    && mkdir -p artifact && mv "${LDAI_OUTPUT}" artifact/

# Export the built AppImage to the staging directory.
FROM scratch AS artifact
COPY --from=builder /work/pkg/artifact /artifact

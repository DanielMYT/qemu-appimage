# See the README file for the rationale behind the build distro choice.
FROM rockylinux:9 AS builder

# Work in a subdirectory, instead of the root directory.
WORKDIR /work

# Be careful when updating the version of QEMU.
# It may require modification of the build arguments below.
# Make sure the SHA256 checksum is set correctly for the .tar.xz tarball.
ARG VER_QEMU=11.2.0-rc0
ARG SUM_QEMU=1055588c7acb8b083ca69c3f8625ca240de823e6a34b02b16fa8cabeb1be49be

# Only x86_64 and aarch64 are currently supported.
# We have no plans to support 32-bit architectures.
# If you want to try anyway (at your own risk), simply remove this check.
RUN test "$(uname -m)" = "x86_64" || test "$(uname -m)" = "aarch64" || \
    { echo "Error: QEMU AppImage does not support $(uname -m)." >&2; false; }

# Optimize binaries for size and use linker optimization.
ENV CFLAGS=-Os
ENV CXXFLAGS=-Os
ENV LDFLAGS=-Wl,-O1

# Install dependencies from DNF. This requires adding the CRB and EPEL repos.
RUN dnf -y update && dnf -y install dnf-plugins-core epel-release && \
    dnf -y config-manager --set-enabled crb && dnf -y update && \
    dnf -y --allowerasing install \
    alsa-lib-devel \
    bash-completion \
    bison \
    brlapi-devel \
    bzip2 \
    bzip2-devel \
    capstone-devel \
    cmake \
    curl \
    cyrus-sasl-devel \
    daxctl-devel \
    device-mapper-multipath-devel \
    elfutils-devel \
    file \
    flex \
    fuse3-devel \
    gcc \
    gcc-c++ \
    gcc-toolset-14 \
    gettext \
    git \
    glib2-devel \
    gnutls-devel \
    gtk3-devel \
    jack-audio-connection-kit-devel \
    json-c-devel \
    keyutils-libs-devel \
    libaio-devel \
    libbpf-devel \
    libblkio-devel \
    libcacard-devel \
    libcap-ng-devel \
    libcmocka-devel \
    libcurl-devel \
    libdrm-devel \
    libgbm-devel \
    libiscsi-devel \
    libjpeg-turbo-devel \
    libnfs-devel \
    librbd-devel \
    libseccomp-devel \
    libslirp-devel \
    libssh-devel \
    libunistring-devel \
    liburing-devel \
    libusb1-devel \
    libva-devel \
    libxdp-devel \
    libzstd-devel \
    lz4-devel \
    lzo-devel \
    make \
    ncurses-devel \
    ndctl-devel \
    ninja-build \
    numactl-devel \
    openssl-devel \
    opus-devel \
    patchelf \
    pipewire-devel \
    pkgconf-pkg-config \
    pulseaudio-libs-devel \
    python3.12-pip \
    python3.12-wheel \
    rdma-core-devel \
    SDL2-devel \
    SDL2_image-devel \
    snappy-devel \
    systemd-devel \
    usbredir-devel \
    vte291-devel \
    vulkan-devel \
    xz

# Install additional dependencies from PIP.
# These are either missing from DNF, or the DNF version is too old.
RUN pip3.12 install meson==1.9.1 pycotap==1.3.1 pyparsing==3.3.2 pyyaml==6.0.3 tomli==2.2.1

# Build vdeplug4 and its dependency s2argv-execs, as well as pmdk.
# These are not available from the DNF repositories.
RUN source /opt/rh/gcc-toolset-14/enable && \
    curl --retry 10 --retry-delay 3 -fkLO \
    "https://github.com/virtualsquare/s2argv-execs/archive/1.4/s2argv-execs-1.4.tar.gz" && \
    curl --retry 10 --retry-delay 3 -fkLO \
    "https://github.com/rd235/vdeplug4/archive/v4.0.1/vdeplug4-4.0.1.tar.gz" && \
    curl --retry 10 --retry-delay 3 -fkLO \
    "https://github.com/daos-stack/pmdk/archive/2.1.4/pmdk-2.1.4.tar.gz" && \
    echo "bcb4680560528db229c496c7f84710d3e8495ad1cc5281cc784bf0be4651823c s2argv-execs-1.4.tar.gz" | sha256sum -c && \
    echo "2299fb2f26508716b5c08d9fdae62c2516372d833540c8307d45634a2848d57a vdeplug4-4.0.1.tar.gz" | sha256sum -c && \
    echo "0fca0774441afcec114bf27745b83450f1efe6733a09c154f48867d670233210 pmdk-2.1.4.tar.gz" | sha256sum -c && \
    mkdir -p s2argv-execs vdeplug4 pmdk && \
    tar -xf s2argv-execs-1.4.tar.gz -C s2argv-execs --strip-components=1 && \
    tar -xf vdeplug4-4.0.1.tar.gz -C vdeplug4 --strip-components=1 && \
    tar -xf pmdk-2.1.4.tar.gz -C pmdk --strip-components=1 && \
    cd s2argv-execs && \
    cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -Wno-dev -G Ninja -B build && \
    ninja -C build && \
    ninja -C build install && \
    cd ../vdeplug4 && \
    cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -Wno-dev -G Ninja -B build && \
    ninja -C build && \
    ninja -C build install && \
    cd ../pmdk && \
    make -j$(nproc) prefix=/usr SRCVERSION=2.1.4 DOC=n BUILD_BENCHMARKS=n BUILD_EXAMPLES=n && \
    make prefix=/usr SRCVERSION=2.1.4 DOC=n BUILD_BENCHMARKS=n BUILD_EXAMPLES=n install

# Build spice-protocol, spice-server and virglrenderer dependencies.
# These are not available from the DNF repositories.
RUN source /opt/rh/gcc-toolset-14/enable && \
    printf "[binaries]\npython = '/usr/bin/python3.12'\npython3 = '/usr/bin/python3.12'\n" > /meson.ini && \
    curl --retry 10 --retry-delay 3 -fkLO \
    "https://www.spice-space.org/download/releases/spice-protocol-0.14.5.tar.xz" && \
    curl --retry 10 --retry-delay 3 -fkLO \
    "https://www.spice-space.org/download/releases/spice-0.16.0.tar.bz2" && \
    curl --retry 10 --retry-delay 3 -fkLO \
    "https://gitlab.freedesktop.org/virgl/virglrenderer/-/archive/1.2.0/virglrenderer-1.2.0.tar.bz2" && \
    echo "baf58449f6e89d19f475899ad5fb9196fdc46c03cc53233f4e39cf2978f9cff7 spice-protocol-0.14.5.tar.xz" | sha256sum -c && \
    echo "0a6ec9528f05371261bbb2d46ff35e7b5c45ff89bb975a99af95a5f20ff4717d spice-0.16.0.tar.bz2" | sha256sum -c && \
    echo "f4f52db11297b52b35c8c2d5bf5e21b7997b52f8bfad99ea2b1c155997cff4ad virglrenderer-1.2.0.tar.bz2" | sha256sum -c && \
    mkdir -p spice-protocol spice-server virglrenderer && \
    tar -xf spice-protocol-0.14.5.tar.xz -C spice-protocol --strip-components=1 && \
    tar -xf spice-0.16.0.tar.bz2 -C spice-server --strip-components=1 && \
    tar -xf virglrenderer-1.2.0.tar.bz2 -C virglrenderer --strip-components=1 && \
    cd spice-protocol && \
    meson setup build --prefix=/usr --native-file=/meson.ini && \
    ninja -C build && \
    ninja -C build install && \
    cd ../spice-server && \
    meson setup build --prefix=/usr --buildtype=minsize -Dgstreamer=no --native-file=/meson.ini && \
    ninja -C build && \
    ninja -C build install && \
    cd ../virglrenderer && \
    meson setup build --prefix=/usr --buildtype=minsize -Dvenus=true -Dvideo=true -Dtests=false --native-file=/meson.ini && \
    ninja -C build && \
    ninja -C build install

# Download and extract the source.
# Retry liberally to prevent a GitHub workflow fail if the server is buggy.
RUN curl --retry 10 --retry-delay 3 -fkLO \
    "https://download.qemu.org/qemu-${VER_QEMU}.tar.xz" && \
    echo "${SUM_QEMU} qemu-${VER_QEMU}.tar.xz" | sha256sum -c && \
    mkdir -p src pkg && \
    tar -xf "qemu-${VER_QEMU}.tar.xz" -C src --strip-components=1

# Compile QEMU and install it to the staging directory.
RUN source /opt/rh/gcc-toolset-14/enable && cd src && ./configure \
    --prefix=/usr \
    --libdir=lib \
    --python=/usr/bin/python3.12 \
    --enable-af-xdp \
    --enable-alsa \
    --enable-attr \
    --disable-auth-pam \
    --enable-blkio \
    --enable-bochs \
    --enable-bpf \
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
    --enable-gnutls \
    --enable-gtk \
    --enable-guest-agent \
    --disable-guest-agent-msi \
    --enable-hv-balloon \
    --disable-hvf \
    --enable-iconv \
    --disable-igvm \
    --enable-jack \
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
    --enable-pipewire \
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
RUN export LDAI_OUTPUT="qemu-${VER_QEMU}-$(uname -m).AppImage" && cd pkg && \
    curl -fkL "https://gist.githubusercontent.com/DanielMYT/9f12382c0f87aeaba7065a1d258fb3c6/raw/3199b0461842042794633801c8bef3243ea95e28/dpkg-query.sh" -o /usr/local/bin/dpkg-query && \
    chmod 755 /usr/local/bin/dpkg-query && \
    curl -fkLO "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$(uname -m).AppImage" && \
    curl -fkLO "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/4d63222/linuxdeploy-plugin-gtk.sh" && \
    chmod 755 "linuxdeploy-$(uname -m).AppImage" linuxdeploy-plugin-gtk.sh && \
    ln -sf gio-querymodules-64 /usr/bin/gio-querymodules && \
    "./linuxdeploy-$(uname -m).AppImage" --appimage-extract && \
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

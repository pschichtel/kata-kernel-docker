FROM docker.io/library/debian:bookworm AS build

RUN apt update
RUN apt install -y build-essential git curl flex bison libelf-dev bc

WORKDIR /work

ARG KATA_VERSION='3.19.0'
ARG KERNEL_VERSION='6.15.7'

ENV KATA_DIR="kata"
ENV BUILD_DIR="${KATA_DIR}/tools/packaging/kernel"

RUN git clone -b "$KATA_VERSION" --depth=1 https://github.com/kata-containers/kata-containers.git "$KATA_DIR"

COPY configs "${BUILD_DIR}/configs"
RUN kernel_minor_version="$(echo "$KERNEL_VERSION" | cut -d'.' -f1-2)" \
 && patches_dir="${BUILD_DIR}/patches/${kernel_minor_version}.x" \
 && mkdir -p "$patches_dir" \
 && touch "${patches_dir}/no_patches.txt"

ENV BUILD_OPTIONS="-a x86_64 -v ${KERNEL_VERSION} -t cloud-hypervisor"

RUN cd "$BUILD_DIR" \
 && ./build-kernel.sh ${BUILD_OPTIONS} -f setup

RUN cd "$BUILD_DIR" \
 && ./build-kernel.sh ${BUILD_OPTIONS} -f build

RUN mv "${BUILD_DIR}/kata-linux-${KERNEL_VERSION}-"*/arch/x86/boot/bzImage vmlinux

FROM scratch

COPY --from=build /work/vmlinux /vmlinux


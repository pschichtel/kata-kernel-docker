FROM docker.io/library/debian:trixie-20260610@sha256:fe7312b5f05bf5f43fad76bcd8945642e4e47a68aefd1b73f447615899d0fac1 AS build

RUN apt update
RUN apt install -y build-essential git curl flex bison libelf-dev bc

WORKDIR /work

ARG KATA_VERSION='3.31.0'
ARG KERNEL_VERSION='7.0.10'

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


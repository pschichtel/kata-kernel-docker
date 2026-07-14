FROM docker.io/library/debian:13@sha256:fac46bff2e02f51425b6e33b0e1169f55dfb053d83511ca28aa50c09fd5ed7a4 AS build

RUN apt update
RUN apt install -y build-essential git curl flex bison libelf-dev bc

WORKDIR /work

ARG KATA_VERSION='3.32.0'
ARG KERNEL_VERSION='7.1.3'

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


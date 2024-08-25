#!/usr/bin/env bash

set -euo pipefail

kata_version="3.8.0"
kernel_version="6.10.6"
kernel_minor_version="$(cut -d'.' -f1-2 <<< "$kernel_version")"

git clone -b "$kata_version" --depth=1 https://github.com/kata-containers/kata-containers.git kata

build_dir="kata/tools/packaging/kernel"
cp -a configs "$build_dir"

patches_dir="$build_dir/patches/${kernel_minor_version}.x"
mkdir -p "$patches_dir"
touch "${patches_dir}/no_patches.txt"

pushd "$build_dir"
options=(-a x86_64 -v "$kernel_version" -t cloud-hypervisor)
./build-kernel.sh "${options[@]}" -f setup
./build-kernel.sh "${options[@]}" build
popd

mv "${build_dir}/kata-linux-${kernel_version}-"*/arch/x86/boot/bzImage vmlinux

tag="${GITHUB_REF##*/}"
image_name="ghcr.io/pschichtel/kata-kernel:${tag}"
podman build -t "$image_name" .
podman push "$image_name"


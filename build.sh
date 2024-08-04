#!/bin/bash
export RDIR=$(pwd)
export ARCH=arm64
export PLATFORM_VERSION=12
export ANDROID_MAJOR_VERSION=s

#symlinking python2
if [ ! -f "$HOME/python" ]; then
    ln -s /usr/bin/python2.7 "$HOME/python"
fi 

#proton-12
if [ ! -d "${RDIR}/toolchains" ]; then
    mkdir -p "${RDIR}/toolchains"
    git clone --depth=1 https://github.com/ravindu644/aarch64-linux-android-4.9.git --single-branch toolchains/compiler
    git clone --depth=1 https://github.com/ravindu644/llvm-arm-toolchain-ship-10.0.git --single-branch toolchains/clang
fi

export PATH=$PWD/toolchains/clang/bin:$PWD/toolchains/compiler/bin:$PATH

#output dir
if [ ! -d "${RDIR}/out" ]; then
    mkdir -p "${RDIR}/out"
fi

export ARGS="
-j$(nproc) \
-C $(pwd) \
O=$(pwd)/out \
DTC_EXT=$(pwd)/tools/dtc \
CONFIG_BUILD_ARM64_DT_OVERLAY=y \
ARCH=arm64 \
CROSS_COMPILE=aarch64-linux-android- \
REAL_CC=clang \
CLANG_TRIPLE=aarch64-linux-gnu- \
"

build_kernel(){
    make ${ARGS} sdm439_sec_a01q_swa_ins_defconfig
    make ${ARGS} menuconfig
    make ${ARGS}
}

build_kernel
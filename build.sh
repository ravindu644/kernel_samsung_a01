#!/bin/bash

#init ksu
git submodule init && git submodule update

export RDIR=$(pwd)
export ARCH=arm64
export KBUILD_BUILD_USER="@ravindu644"

#symlinking python2
if [ ! -f "$HOME/python" ]; then
    ln -s /usr/bin/python2.7 "$HOME/python"
fi 

#toolchains
if [ ! -d "${HOME}/toolchains" ]; then
    mkdir -p "${HOME}/toolchains" ; cd "${HOME}/toolchains"
    git clone --depth=1 https://github.com/ravindu644/proton-12.git --single-branch
    wget https://kali.download/nethunter-images/toolchains/linaro-aarch64-7.5.tar.xz ; tar -xvf linaro-aarch64-7.5.tar.xz ; rm linaro-aarch64-7.5.tar.xz
    cd "${RDIR}"
fi

export PATH=$HOME/toolchains/proton-12/bin:$HOME/toolchains/aarch64-linaro-7.5/bin:$PATH

#output dir
if [ ! -d "${RDIR}/out" ]; then
    mkdir -p "${RDIR}/out"
fi

#build dir
if [ ! -d "${RDIR}/build" ]; then
    mkdir -p "${RDIR}/build"
fi

export ARGS="
-j$(nproc) \
-C $(pwd) \
O=$(pwd)/out \
DTC_EXT=$(pwd)/tools/dtc \
CONFIG_BUILD_ARM64_DT_OVERLAY=y \
ARCH=arm64 \
CROSS_COMPILE=aarch64-linux-gnu- \
CC=clang \
CLANG_TRIPLE=aarch64-linux-gnu- \
"

build_kernel(){
    make ${ARGS} sdm439_sec_a01q_swa_ins_defconfig a01.config nethunter.config excludes.config
    make ${ARGS} menuconfig
    make ${ARGS} || exit 1
}

#Copy kernel modules (*.ko)
copy_modules(){
    if [ ! -d "${RDIR}/modules" ]; then
    mkdir -p "${RDIR}/modules"
    fi
    cd "${RDIR}"
    find . -type f -name "*.ko" -exec cp -n {} modules \;
    echo "Module files copied to the 'modules' folder."
    cp "${RDIR}/modules"/* "${RDIR}/nh_lkm/system/vendor/lib/modules/"
    rm -f "${RDIR}/nh_lkm/system/vendor/lib/modules/.placeholder" ; rm -f "${RDIR}/nh_lkm/system/lib/modules/.placeholder"
    cd "${RDIR}/nh_lkm" ; zip -r "Kali Nethunter Drivers - SM-A015x [MAGISK].zip" .
    mv "Kali Nethunter Drivers - SM-A015x [MAGISK].zip" "${RDIR}/build"
    cd "${RDIR}"
}

ak3(){
    cp "${RDIR}/out/arch/arm64/boot/Image" "${RDIR}/AnyKernel3"
    cd "${RDIR}/AnyKernel3"
    zip -r "Nethunter-SM-A015x.zip" * ; mv "Nethunter-SM-A015x.zip" "${RDIR}/build"
    echo -e "\n[i] Build Finished..!\n"
}

build_kernel
copy_modules
ak3
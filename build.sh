#!/bin/bash
export RDIR="$(pwd)"
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

export BUILD_CROSS_COMPILE="${HOME}/toolchains/aarch64-linaro-7.5/bin/aarch64-linux-gnu-"
export BUILD_CC="${HOME}/toolchains/proton-12/bin/clang"

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
CROSS_COMPILE=${BUILD_CROSS_COMPILE} \
CC=${BUILD_CC} \
CLANG_TRIPLE=aarch64-linux-gnu- \
"

build_kernel(){
    make ${ARGS} clean && make ${ARGS} mrproper
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

build_boot() {    
    rm -f ${RDIR}/AIK-Linux/split_img/boot.img-kernel ${RDIR}/AIK-Linux/boot.img
    cp "${RDIR}/out/arch/arm64/boot/Image" ${RDIR}/AIK-Linux/split_img/boot.img-kernel
    mkdir -p ${RDIR}/AIK-Linux/ramdisk/{debug_ramdisk,dev,metadata,mnt,proc,second_stage_resources,sys}
    cd ${RDIR}/AIK-Linux && ./repackimg.sh --nosudo && mv image-new.img boot.img
    echo -e "\n[i] Build Finished..!\n" && cd cd ${RDIR}
}

build_kernel
copy_modules
build_boot

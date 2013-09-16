#!/bin/sh
export KERNELDIR=`readlink -f .`
export RAMFS_SOURCE=`readlink -f $KERNELDIR/initramfs1`
export PARENT_DIR=`readlink -f ..`
export USE_SEC_FIPS_MODE=true
export CROSS_COMPILE=/home/kar/toolchain2/bin/arm-eabi-
export KBUILD_BUILD_VERSION="1"
export BUILD_VERSION="K2wl-SGGRAND-v1.0.2"

if [ "${1}" != "" ];then
  export KERNELDIR=`readlink -f ${1}`
fi

RAMFS_TMP="/tmp/ramfs-source"

if [ ! -f $KERNELDIR/.config ];
then
  make i9082_defconfig
fi

. $KERNELDIR/.config

export ARCH=arm

cd $KERNELDIR/
nice -n 10 make -j4 || exit 1

#remove previous ramfs files
rm -rf $RAMFS_TMP
rm -rf $RAMFS_TMP.cpio
rm -rf $RAMFS_TMP.cpio.gz
#copy ramfs files to tmp directory
cp -ax $RAMFS_SOURCE $RAMFS_TMP
# clear git repositories in initramfs
if [ -e $RAMFS_TMP/.git ]; then
rm -rf /tmp/ramfs-source/.git
fi;
#remove empty directory placeholders
find $RAMFS_TMP -name EMPTY_DIRECTORY -exec rm -rf {} \;
rm -rf $RAMFS_TMP/tmp/*
#remove mercurial repository
rm -rf $RAMFS_TMP/.hg
#copy modules into ramfs
mkdir -p $RAMFS/lib/modules
mkdir -p $RAMFS_TMP/lib/modules
find -name '*.ko' -exec cp -av {} $RAMFS_TMP/lib/modules/ \;
find -name '*.ko' -exec cp -av {} /$KERNELDIR/k2wl/customize/expmodules/ \;
${CROSS_COMPILE}strip --strip-debug $RAMFS_TMP/lib/modules/*.ko
chmod 755 $INITRAMFS_TMP/lib/modules/*
${CROSS_COMPILE}strip --strip-unneeded $RAMFS_TMP/lib/modules/*

cd $RAMFS_TMP
find | fakeroot cpio -H newc -o > $RAMFS_TMP.cpio 2>/dev/null
ls -lh $RAMFS_TMP.cpio
gzip -9 $RAMFS_TMP.cpio
cd -

#nice -n 10 make -j2 zImage || exit 1

./mkbootimg --kernel $KERNELDIR/arch/arm/boot/zImage --ramdisk $RAMFS_TMP.cpio.gz --board baffin --base 0x50000000 --pagesize 4096 -o $KERNELDIR/boot.img

# copy all needed to k2wl kernel folder.
stat $KERNELDIR/boot.img
cp $KERNELDIR/boot.img /$KERNELDIR/k2wl/
cd $KERNELDIR/k2wl/
zip -r $BUILD_VERSION.zip *
rm $KERNELDIR/boot.img
rm $KERNELDIR/k2wl/boot.img

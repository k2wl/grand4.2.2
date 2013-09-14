#!/system/bin/sh

# kernelevolution: deploy modules and misc files
mount -o remount,rw /system
rm -f /system/lib/modules/*
cp -fR /lib/modules/*  /system/lib/modules
chmod -R 0644 system/lib/modules
chown 0:0 /system/lib/modules/scsi_wait_scan.ko
chown 0:0 /system/lib/modules/dhd.ko
chown 0:0 /system/lib/modules/gist.ko
chown 0:0 /system/lib/modules/sigmorph.ko

# make sure init.d is ok
chgrp -R 2000 /system/etc/init.d
chmod -R 777 /system/etc/init.d
sync

# force insert modules that are required
insmod /system/lib/modules/dhd.ko
insmod /system/lib/modules/scsi_wait_scan.ko
insmod /system/lib/modules/gist.ko
insmod /system/lib/modules/sigmorph.ko
touch /data/local/em_modules_deployed
mount -o remount,ro /system



#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread
MIRRDIR=/dev/magisk/mirror
LOGFILE=/cache/magisk.log
DISABLE=/data/data/de.robv.android.xposed.installer/conf/disabled

log_print() {
  echo "Xposed: $1"
  echo "Xposed: $1" >> $LOGFILE
  log -p i -t Xposed "$1"
}

grep_prop() {
  REGEX="s/^$1=//p"
  shift
  FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

bind_mount() {
  if [ -e "$1" -a -e "$2" ]; then
    mount -o bind $1 $2
    if [ "$?" -eq "0" ]; then log_print "bind_mount: $1 -> $2";
    else log_print "bind_mount failed: $1 -> $2"; fi
  fi
}

find $MODDIR/system -type f 2>/dev/null | while read f; do
  TARGET=${f#$MODDIR}
  bind_mount $f $TARGET
done

find $MODDIR/system/bin -type f 2>/dev/null | while read f; do
  TARGET=$MIRRDIR${f#$MODDIR}
  bind_mount $f $TARGET
done

if [ -f $DISABLE ]; then
  ABILONG=`grep_prop ro.product.cpu.abi`
  umount /system/bin/app_process32
  [ "$ABILONG" = "arm64-v8a" ] && umount /system/bin/app_process64
  umount $MIRRDIR/system/bin/app_process32
  [ "$ABILONG" = "arm64-v8a" ] && umount $MIRRDIR/system/bin/app_process64
fi

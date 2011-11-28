#!/bin/bash
#
# Script to build MOSLO as a kernel and initrd combination which can be loaded
# to RAM
#
# Copyright 2010, Nokia Corporation
#
# Janne Lääkkö <janne.laakko@nokia.com>
# 08/2010
# Peter Antoniac <peter.antoniac@nokia.com>
#       * Fix the ldd issues in OBS transcoding
# 05/2011


print_usage()
{
echo    "Usage: $0 -w <build-dir> -k <kernel-image> -m <modules-dir>" \
	"-v <software version> [-o <output-image>] [-t <tar-archive-name>"
}


#TODO find a way to automatically detect dlopen library dependencies

is_elf()
{
	local FILE_INFO=$(file -L $1)

	if [ "ELF" == "$(echo $FILE_INFO | \
		sed 's/.*\(ELF\)\(.*\)/\1/')" ] ; then
		return 1
	else
		return 0
	fi
}

is_dynamic()
{
	local FILE_INFO=$(file -L $1)

	if [ "dynamically" == "$(echo $FILE_INFO | \
		sed 's/.*\(dynamically\)\(.*\)/\1/')" ] ; then
		return 1
	else
		return 0
	fi
}

DEBUG=0

debug()
{
	if [ $DEBUG -eq 1 ] ; then
		echo -e "DEBUG: $@"
	fi
}

add_dependencies()
{
	local INPUT_FILE=$1
	local OUTPUT_FILE=$2

	local CHECK=$(cat $INPUT_FILE | sort | uniq)
	local DEP_FILE=$(mktemp -t ldout.XXXX)
	local LIBC=$(find /lib/ -name "libc.*")
	local LD=""
	local LD_LINUX=""
	local DEP=""

	#Get correct ld-linux
	for ld in /lib/ld-linux* ; do
		if [ -x $ld ]; then
			$ld --verify $LIBC
			if [ $? -eq 0 ] ; then
				LD=$ld
				break
			fi
		fi
	done

	#Loop through all files in input list
	for i in $CHECK ; do
		debug "CHECKING FILE $i"
		#Check that the file is ELF
		if is_elf $i ; then
			debug "Not an ELF file!"
			continue
		else
			debug "Is ELF file!"
		fi

		#Check that the file exist
		if [ ! -f $i ] ; then
			echo "ERROR: $i does not exist!"
			echo "Check build dependencies!"
			exit 1
		fi

		#Check that the file is dynamically linked
		if is_dynamic $i ; then
			debug "Not a dynamically linked file!"
			continue
		else
			debug "Is dynamically linked file!"
		fi

		#Use ld-linux for libraries
		$($LD --verify $i)
		if [ "$?" -ne "2" ] ; then
			LD_LINUX=""
		else
			LD_LINUX=$LD
		fi

		#Get dependencies
		DEP=$(LD_TRACE_LOADED_OBJECTS=1 $LD_LINUX $i \
			| sed -ne "s/.*[\t ]\(\/.*\) (.*/\1/gp")

		debug "Dependencies:"
		if [ "$DEBUG" -eq "1" ] ; then
			echo "$DEP" | sed -e "s/ /\n/g"
		fi

		echo $DEP | sed -e "s/ /\n/g"  >> $DEP_FILE
	done

	#Add input file content and their dependencies to output file
	cat $DEP_FILE $INPUT_FILE | sort | uniq > $OUTPUT_FILE
	rm -f $DEP_FILE
}

#
# get commandline parameters
#
echo
echo "Options:"
while getopts "w:k:m:v:o:t:" opt; do
    case $opt in
	w)
	    WORK_DIR=$OPTARG
	    echo "Working directory: $WORK_DIR"
	    ;;
	k)
	    KERNEL_ZIMAGE=$OPTARG
	    echo "Kernel location: $KERNEL_ZIMAGE"
	    ;;
	m)
	    KERNEL_MOD_DIR=$OPTARG
	    echo "Modules directory: $KERNEL_MOD_DIR"
	    ;;
	v)
	    BUILD_VERSION=$OPTARG
	    echo "Version $BUILD_VERSION"
	    ;;
	o)
	    BUILD_FILE=$OPTARG
	    echo "Build file $BUILD_FILE"
	    ;;
        t)
	    TAR_FILE=$OPTARG
	    echo "Output tar file $TAR_FILE"
            ;;
	\?)
	    print_usage
	    exit 1
	    ;;
    esac
done
echo

[ -z "$WORK_DIR" ] && {
	print_usage
	exit 1
}

[ -d "$WORK_DIR" ] || {
	echo Working directory must exist
	exit 1
}

#
# check and cleanup
#
BUILD_SRC=$WORK_DIR/initfs/skeleton
SCRIPTS_PATH=$WORK_DIR/initfs/scripts
TOOLS_PATH=$WORK_DIR/initfs/tools
PATH=$PATH:$SCRIPTS_PATH:$WORK_DIR/usr/bin:$TOOLS_PATH
ROOT_DIR=$WORK_DIR/rootfs
BUILD_VERSION_DIR=$ROOT_DIR/usr/share/moslo

KERNEL_MODS="g_nokia g_file_storage sep_driver twl4030_keypad"
KERNEL_MOD_DEP=$KERNEL_MOD_DIR/modules.dep

UTIL_LIST=$BUILD_SRC/util-list
SKEL_LIST=$BUILD_SRC/skeleton-list

[ -f "$KERNEL_ZIMAGE" ] || {
	echo Cannot find kernel image $KERNEL_ZIMAGE
	exit 1
}

[ -d "$KERNEL_MOD_DIR" ] || {
	echo Cannot find kernel modules directory $KERNEL_MOD_DIR
	exit 1
}

( [ -h "$KERNEL_MOD_DIR" ] && {
	KERNEL_MOD_DIR_NAME=$(basename $(readlink $KERNEL_MOD_DIR))
} ) || {
	KERNEL_MOD_DIR_NAME=$(basename $KERNEL_MOD_DIR)
}


[ -z "$BUILD_FILE" ] && {
	BUILD_FILE=$WORK_DIR/build.bin
	NO_BUILD_FILE_REQ=1
}

rm -rf $ROOT_DIR $WORK_DIR/rootfs.cpio

mkdir -p $ROOT_DIR

#install init
install -m 755 $BUILD_SRC/init $ROOT_DIR/init || exit 1

mkdir -p $BUILD_VERSION_DIR
echo "Version: $BUILD_VERSION" > $BUILD_VERSION_DIR/build-release

mkdir -p $ROOT_DIR/etc
touch $ROOT_DIR/etc/mtab
mkdir -p $ROOT_DIR/bin
mkdir -p $ROOT_DIR/sbin
mkdir -p $ROOT_DIR/usr/bin
mkdir -p $ROOT_DIR/usr/sbin
mkdir -p $ROOT_DIR/dev/shm

# Install other files
install -m644 $BUILD_SRC/fstab $ROOT_DIR/etc/fstab || exit 1

#
# create busybox links
#
ln -s ../sbin/busybox $ROOT_DIR/bin/sh
ln -s ../sbin/busybox $ROOT_DIR/sbin/nice
ln -s ../sbin/busybox $ROOT_DIR/sbin/getty
ln -s ../sbin/busybox $ROOT_DIR/sbin/echo
ln -s ../sbin/busybox $ROOT_DIR/sbin/mount
ln -s ../sbin/busybox $ROOT_DIR/sbin/umount
ln -s ../sbin/busybox $ROOT_DIR/sbin/cat
ln -s ../sbin/busybox $ROOT_DIR/sbin/sleep
ln -s ../sbin/busybox $ROOT_DIR/sbin/sed
ln -s ../sbin/busybox $ROOT_DIR/sbin/mknod
ln -s ../sbin/busybox $ROOT_DIR/sbin/mkdir
ln -s ../sbin/busybox $ROOT_DIR/sbin/ls
ln -s ../sbin/busybox $ROOT_DIR/sbin/cp
ln -s ../sbin/busybox $ROOT_DIR/sbin/ln
ln -s ../sbin/busybox $ROOT_DIR/sbin/ps
ln -s ../sbin/busybox $ROOT_DIR/sbin/uname
ln -s ../sbin/busybox $ROOT_DIR/sbin/ifconfig
ln -s ../sbin/busybox $ROOT_DIR/sbin/ip
ln -s ../sbin/busybox $ROOT_DIR/sbin/mdev
ln -s ../sbin/busybox $ROOT_DIR/sbin/modprobe

#
# Fix Harmattan preinit
#
ln -s /init $ROOT_DIR/sbin/preinit

#
# check library dependencies
#
rm -f /tmp/build-tmp-*
TMPFILE=$(mktemp /tmp/build-tmp-XXXXXX) || exit 1
add_dependencies $UTIL_LIST $TMPFILE
LIBS=$(cat $TMPFILE)

#
# Show to be installed binaries
#
echo "All needed binaries and libraries:"
for i in $LIBS ; do
	echo $i
done

#
# Store libraries information for debugging purposes
#
cp $TMPFILE libraries.txt

#
# install binaries from util-list and needed libraries
#
echo "Copying files to initrd root..."
for i in $(cat $TMPFILE) ; do
	if [ -f "$i" ] ; then
		debug "adding $i"
		DEST_DIR=$(dirname "$i" | sed  "s/^\///")
		d="$ROOT_DIR/$DEST_DIR"
		[ -d "$d" ] || mkdir -p "$d" || ( echo Fail to create dir $d;\
			exit 1 ) # We exit if we fail
		debug cp -rL "$i" "$d"
		cp -rL "$i" "$d" || ( echo Fail to copy $i to $d; exit 1 )
	else
		echo "ERROR: file $i is missing!"
		exit 1
	fi
done
echo "done"
rm -f $TMPFILE

#
# install kernel modules
#
echo
echo "Installing Kernel modules"

TMPFILE=$(mktemp /tmp/build-tmp-XXXXXX) || exit 1

TARGET_KERNEL_MOD_DIR=$ROOT_DIR/lib/modules/$KERNEL_MOD_DIR_NAME

mkdir -p $TARGET_KERNEL_MOD_DIR

[ -a $KERNEL_MOD_DEP ] && {
	cp -p $KERNEL_MOD_DEP $TARGET_KERNEL_MOD_DIR/
} || {
    KERNEL_MOD_DEP="$TARGET_KERNEL_MOD_DIR/modules.dep"
    depmod -an $KERNEL_VERSION > $KERNEL_MOD_DEP
}
{
	for i in $KERNEL_MODS ; do \
		KERNEL_MOD=$(sed -n "s/\(.*$i.ko\)\(:.*\)/\1/p" < \
		$KERNEL_MOD_DEP)
	[ -n "$KERNEL_MOD" ] && {
		echo $KERNEL_MOD >> $TMPFILE
	}
	done
	LOOP=1

	while [ "$LOOP" -eq "1" ] ; do
	LOOP=0
	CHECK=$(cat $TMPFILE | sort | uniq)
	for d in $CHECK ; do
	AUX_MOD=$(sed -n "s/^$(echo $d | sed 's:/:\\/:g'): //p" \
	    < $KERNEL_MOD_DEP)
	[ -z "$AUX_MOD" ] || {
		for m in $AUX_MOD ; do
			grep $m $TMPFILE > /dev/null
			[ "$?" -eq "1" ] && {
			echo $m >> $TMPFILE
			LOOP=1
			}
		done
		}
	done
	done

	MODULES=$(cat $TMPFILE)
	for m in $MODULES ; do
		BASENAME_TMP=$(basename $m)
		TEMP_MOD_DIR=$(echo $m | sed "s/$BASENAME_TMP//")
		install -d $TARGET_KERNEL_MOD_DIR/$TEMP_MOD_DIR
		cp -p $KERNEL_MOD_DIR/$m $TARGET_KERNEL_MOD_DIR/$TEMP_MOD_DIR
	done
}


#
# create initrd (we need it to build the skeleton)
#
[ -z $NO_BUILD_FILE_REQ ] && \
	gen_initramfs_list.sh -o $WORK_DIR/rootfs.cpio \
		-u squash -g squash $SKEL_LIST $ROOT_DIR

#
# create tar of rootfs
#
if [ -n $TAR_FILE ]; then
        ROOT_SED=$(echo $ROOT_DIR|sed "s/\\//\\\\\\//g")
        mkdir -p -m777 $(cat $SKEL_LIST|\
          sed -ne "s/.*\(\/[a-z/]*\).*/${ROOT_SED}\1/p")
	tar -cf $WORK_DIR/$TAR_FILE $ROOT_DIR
        debug "$(tar -tf $WORK_DIR/$TAR_FILE)"
fi

[ -z $NO_BUILD_FILE_REQ ] && \
	gzip  $WORK_DIR/rootfs.cpio

#
# create bootable image with cmdline, bootstub, kernel image and initrd
#
if [ -z $NO_BUILD_FILE_REQ ]; then
    cat $KERNEL_ZIMAGE > zImage
    cat $WORK_DIR/rootfs.cpio.gz > initrd.img
	cat $KERNEL_ZIMAGE > $BUILD_FILE
	cat $WORK_DIR/rootfs.cpio.gz >> $BUILD_FILE
	echo Build is ready at $BUILD_FILE
else
	echo Build is ready
fi


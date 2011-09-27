# Make moslo image

# Janne Lääkkö <janne.laakko@nokia.com>
# 08/2010

# paths must be absolute!

ifndef BOARD_HWID
BOARD_HWID=rm-581-s1.2-hs
endif

WORK_DIR=$(PWD)

ROOTFS_DIR=$(WORK_DIR)/rootfs
SOURCES_DIR=$(WORK_DIR)/../sources

COLDLINUX_DIR=$(SOURCES_DIR)/coldlinux
SOFTUPD_DIR=$(SOURCES_DIR)/softupd
LINUX_DIR=$(SOURCES_DIR)/linux-flash
NOLO_DIR=$(SOURCES_DIR)/nolo-h
INIT_SCRIPT=$(WORK_DIR)/init

BUSYBOX_DEB=$(wildcard $(SOURCES_DIR)/busybox*_armel.deb)
LIBBB5_SECBINS_DEB=$(shell ls -t1 $(SOURCES_DIR)/libbb5-secbins*_armel.deb | head -1)

ZIMAGE=uzImage
ZIMAGE_SRC=$(LINUX_DIR)/arch/arm/boot/$(ZIMAGE)
SKELETON_LIST=$(WORK_DIR)/skeleton-list
UTIL_LIST=$(WORK_DIR)/util-list
SOFTUPD_LIST=$(WORK_DIR)/softupd-list

GEN_INITRAMFS_LIST_ORIG=$(LINUX_DIR)/scripts/gen_initramfs_list.sh
GEN_INITRAMFS_LIST=$(WORK_DIR)/gen_initramfs_list.sh
GEN_INIT_CPIO_ORIG=$(LINUX_DIR)/usr/gen_init_cpio

ROOTFS_CPIO=$(WORK_DIR)/rootfs.cpio
ROOTFS_CPIO_GZ=$(ROOTFS_CPIO).gz

BUSYBOX=$(ROOTFS_DIR)/bin/busybox
LIBBB5_SECBINS=$(ROOTFS_DIR)/lib/firmware/omap3430_pafmt.bin
SOFTUPD=$(ROOTFS_DIR)/usr/sbin/softupd

LINUX_MODULES:=$(shell grep -q ^CONFIG_MODULES=y $(LINUX_DIR)/.config && echo 1)

.PHONY: rootfs_dir skeleton kernel_modules utilities busybox-clean nolo

all: kroot.img

kroot.img: $(ZIMAGE) $(ROOTFS_CPIO)
	cat $(ZIMAGE) $(ROOTFS_CPIO) > kroot.img


$(ROOTFS_CPIO): rootfs_dir $(SKELETON_LIST) $(GEN_INITRAMFS_LIST)
	PATH=$$PATH:$(WORK_DIR) \
	$(GEN_INITRAMFS_LIST) -o $(ROOTFS_CPIO) -u squash -g squash \
		$(SKELETON_LIST) $(ROOTFS_DIR)

$(ZIMAGE_SRC):
	cd $(LINUX_DIR) && \
	make -j3 $(ZIMAGE)

$(LINUX_DIR)/modules.order:
	cd $(LINUX_DIR) && \
	make -j3 modules

$(ZIMAGE): $(ZIMAGE_SRC)
	cp $< $@

$(UTIL_LIST): $(COLDLINUX_DIR)/initfs/skeleton/util-list
	cp $< $@

$(SKELETON_LIST): $(COLDLINUX_DIR)/initfs/skeleton/skeleton-list
	cp $< $@

$(SOFTUPD_LIST): $(SOFTUPD)
	ldd $< | sed -n 's/.*=> //p' | sed 's/ (.*)$$//' > $@

gen_init_cpio: $(GEN_INIT_CPIO_ORIG)
	cp $< $@

$(GEN_INITRAMFS_LIST): $(GEN_INITRAMFS_LIST_ORIG) gen_init_cpio
	patch -o $@ < $(COLDLINUX_DIR)/initfs/scripts/gen_initramfs_list.patch  $< && \
	chmod u+x $(GEN_INITRAMFS_LIST)

rootfs_dir: skeleton $(BUSYBOX) $(LIBBB5_SECBINS) $(SOFTUPD) kernel_modules utilities


skeleton: $(ROOTFS_DIR) $(ROOTFS_DIR)/init
	cd $(ROOTFS_DIR) && mkdir -p etc; \
	touch etc/mtab


$(ROOTFS_DIR):
	mkdir $(ROOTFS_DIR)

$(BUSYBOX): $(BUSYBOX_DEB)
	rm -f $(BUSYBOX)
	cd $(ROOTFS_DIR) && mkdir -p bin sbin usr/bin && \
		find bin sbin usr/bin -type l -exec rm \{\} \;
	dpkg -x $(BUSYBOX_DEB) $(ROOTFS_DIR)

$(LIBBB5_SECBINS): $(LIBBB5_SECBINS_DEB)
	dpkg -x $(LIBBB5_SECBINS_DEB) $(ROOTFS_DIR)


$(ROOTFS_DIR)/init: $(INIT_SCRIPT)
	install -m 755 $< $(ROOTFS_DIR)/init

softupd_build:
	cd $(SOFTUPD_DIR) && \
	KERNEL_DIR=$(LINUX_DIR) make

$(SOFTUPD): softupd_build
	mkdir -p $(ROOTFS_DIR)/usr/sbin
	install -s $(SOFTUPD_DIR)/softupd $(SOFTUPD)


ifeq ($(LINUX_MODULES),1)
kernel_modules: $(LINUX_DIR)/modules.order
	rm -rf $(ROOTFS_DIR)/lib/modules
	cd $(LINUX_DIR) && \
	make INSTALL_MOD_PATH=$(ROOTFS_DIR) INSTALL_MOD_STRIP=1 modules_install
else
kernel_modules:
	rm -rf $(ROOTFS_DIR)/lib/modules
endif

# cleanup first
utilities: $(UTIL_LIST) $(SOFTUPD_LIST)
	rm -f $(UTIL_LIST).tmp
	cat $(UTIL_LIST) $(SOFTUPD_LIST) | sort | uniq > $(UTIL_LIST).tmp
	tar chf - -T $(UTIL_LIST).tmp | tar xfp - -C $(ROOTFS_DIR)

busybox-clean:
	rm -f $(ROOTFS_DIR)/bin/busybox
	cd $(ROOTFS_DIR) && find bin sbin usr/bin -type l -exec rm \{\} \;

$(NOLO_DIR)/config.mak:
	cd $(NOLO_DIR) && ./configure.pl -b $(BOARD_HWID) -k $(LINUX_DIR)

nolo: $(NOLO_DIR)/config.mak
	cd $(NOLO_DIR) && make

kernel:
	cd $(LINUX_DIR) && make -j2 $(ZIMAGE)

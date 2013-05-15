default: all

include initfs/tools/Makefile

rootfs.tar: tools
	./initfs/scripts/moslo-build.sh \
		-c $(CONFIG_DIR) \
		-w  . \
		-k $(SOURCE_DIR)/boot/vmlinuz-$(KERNEL_VERSION) \
		-m $(SOURCE_DIR)/lib/modules/$(KERNEL_VERSION) \
		-v $(VERSION) \
		-o moslo.img \
		-t rootfs.tar 

all: rootfs.tar

clean: tools_clean
	rm -f libraries.txt
	rm -f rootfs.tar
	rm -Rf rootfs


default: all

include initfs/tools/Makefile

rootfs.tar: tools
	./initfs/scripts/moslo-build.sh \
		-w  . \
		-k /boot/vmlinuz-$(KERNEL_VERSION) \
		-m /lib/modules/$(KERNEL_VERSION) \
		-v $(VERSION) \
		-t rootfs.tar 

all: rootfs.tar

clean: tools_clean
	rm -f libraries.txt
	rm -f rootfs.tar
	rm -Rf rootfs

install:
	install -d $(DESTDIR)/$(B_NAME)


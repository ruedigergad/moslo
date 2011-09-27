TOOLS_PATH=./initfs/tools

tools: gen_init_cpio reboot2 install_util

install_util:
	install -d ./sbin
	install -d ./bin
	install -m 755 $(TOOLS_PATH)/reboot2 ./sbin

gen_init_cpio: $(TOOLS_PATH)/gen_init_cpio.c
	gcc -Wall -O2 $(TOOLS_PATH)/gen_init_cpio.c -o $(TOOLS_PATH)/gen_init_cpio -Wl,--no-as-needed

reboot2: $(TOOLS_PATH)/reboot2.c
	gcc -Wall -O2 $(TOOLS_PATH)/reboot2.c -o $(TOOLS_PATH)/reboot2 -Wl,--no-as-needed

tools_clean:
	rm -f gen_init_cpio reboot2 *~

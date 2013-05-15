TOOLS_PATH=./initfs/tools

tools: gen_init_cpio reboot2 evkey install_util install_configs

install_configs:
	install -d ./sbin
	install -m 755 $(CONFIG_DIR)/init_preps.sh ./sbin
	install -m 755 $(CONFIG_DIR)/moslo.config ./moslo.config

install_util:
	install -d ./sbin
	install -d ./bin
	install -d ./tools
	install -m 755 $(TOOLS_PATH)/reboot2 ./sbin
	install -m 755 $(TOOLS_PATH)/evkey ./sbin
	install -m 755 $(TOOLS_PATH)/gen_init_cpio ./tools

gen_init_cpio: $(TOOLS_PATH)/gen_init_cpio.c
	gcc -Wall -O2 $(TOOLS_PATH)/gen_init_cpio.c -o $(TOOLS_PATH)/gen_init_cpio -Wl,--no-as-needed

reboot2: $(TOOLS_PATH)/reboot2.c
	gcc -Wall -O2 $(TOOLS_PATH)/reboot2.c -o $(TOOLS_PATH)/reboot2 -Wl,--no-as-needed

evkey: $(TOOLS_PATH)/evkey.c
	gcc -Wall -O2 $(TOOLS_PATH)/evkey.c -o $(TOOLS_PATH)/evkey -Wl,--no-as-needed

tools_clean:
	rm -f gen_init_cpio reboot2 *~

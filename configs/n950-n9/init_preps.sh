# Load modules
modprobe twl4030_keypad
modprobe g_nokia  # load g_nokia to make bme function properly

#Start services
bme_RX-71 -n -c usr/lib/hwi/hw/rx71.so -d


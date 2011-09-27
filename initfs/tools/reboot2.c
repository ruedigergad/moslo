#include <linux/reboot.h>
#include <sys/syscall.h>

int sys_reboot(const char *cmd)
{
	return syscall(SYS_reboot, LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2C,
			LINUX_REBOOT_CMD_RESTART2, cmd);
}

int main(int argc, char *argv[])
{
  const char *cmd = "";
  if(argc > 1) {
    cmd = argv[1];
  }
  sys_reboot(cmd);

}

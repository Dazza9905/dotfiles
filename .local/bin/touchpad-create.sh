cat > / tmp / usb - toggle - direct.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

          int main(int argc, char *argv[]) {
  const char *interface = "3-6:1.3";
  const char *driver_path = "/sys/bus/usb/drivers/usbhid";
  char bind_path[256], unbind_path[256], interface_path[256];
  struct stat st;
  FILE *f;

  // Must run as root
  if (setuid(0) != 0) {
    perror("setuid failed");
    return 1;
  }

  snprintf(bind_path, sizeof(bind_path), "%s/bind", driver_path);
  snprintf(unbind_path, sizeof(unbind_path), "%s/unbind", driver_path);
  snprintf(interface_path, sizeof(interface_path), "%s/%s", driver_path,
           interface);

  const char *action = (argc > 1) ? argv[1] : "toggle";

  if (strcmp(action, "status") == 0) {
    printf("%s is %s\n", interface,
           (stat(interface_path, &st) == 0) ? "bound" : "unbound");
    return 0;
  }

  if (strcmp(action, "on") == 0 || strcmp(action, "bind") == 0) {
    printf("Binding %s...\n", interface);
    f = fopen(bind_path, "w");
    if (f) {
      fprintf(f, "%s\n", interface);
      fclose(f);
    }
  } else if (strcmp(action, "off") == 0 || strcmp(action, "unbind") == 0) {
    printf("Unbinding %s...\n", interface);
    f = fopen(unbind_path, "w");
    if (f) {
      fprintf(f, "%s\n", interface);
      fclose(f);
    }
  } else if (strcmp(action, "toggle") == 0) {
    if (stat(interface_path, &st) == 0) {
      printf("Interface bound, unbinding...\n");
      f = fopen(unbind_path, "w");
      if (f) {
        fprintf(f, "%s\n", interface);
        fclose(f);
      }
    } else {
      printf("Interface unbound, binding...\n");
      f = fopen(bind_path, "w");
      if (f) {
        fprintf(f, "%s\n", interface);
        fclose(f);
      }
    }
  } else {
    printf("Usage: %s [on|off|toggle|status]\n", argv[0]);
    return 1;
  }

  return 0;
}
EOF

#Compile and set permissions
        gcc -
    o ~/ bin / usb - toggle / tmp / usb - toggle -
    direct.c sudo chown root : root ~/ bin / usb -
    toggle sudo chmod 4755 ~/ bin / usb -
    toggle

#Clean up
            rm /
        tmp / usb -
    toggle - *.c

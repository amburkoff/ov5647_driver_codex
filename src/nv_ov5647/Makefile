obj-m += nv_ov5647.o

ccflags-y += -I/usr/src/nvidia/nvidia-oot/include
KBUILD_EXTRA_SYMBOLS += /usr/src/nvidia/nvidia-oot/Module.symvers

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

PROJECT=template


LSCRIPT=core/STM32F429ZI_FLASH.ld

OPTIMIZATION = -O2

#test: -mapcs-float

#########################################################################

SRC=$(wildcard  *.c libs/mcugui/*.c libs/*.c) \
	core/stm32f4xx_it.c core/system_stm32f4xx.c core/syscalls.c core/mallocext.c \

ASRC=core/startup_stm32f429_439xx.s
OBJECTS= $(SRC:.c=.o) $(ASRC:.s=.o)
LSTFILES= $(SRC:.c=.lst)
HEADERS=$(wildcard core/*.h *.h)

#  Compiler Options
GCFLAGS = -ffreestanding -std=gnu99 -mcpu=cortex-m4 -mthumb $(OPTIMIZATION) -I. -Icore -DARM_MATH_CM4 -DUSE_STDPERIPH_DRIVER 
GCFLAGS+= -mfpu=fpv4-sp-d16 -mfloat-abi=hard -falign-functions=16 
# Warnings
GCFLAGS += -Wno-strict-aliasing -Wstrict-prototypes -Wundef -Wall -Wextra -Wunreachable-code  
# Optimizazions
GCFLAGS += -fstrict-aliasing -fsingle-precision-constant -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums -fno-builtin -ffunction-sections -fno-common -fdata-sections 
# Debug stuff
GCFLAGS += -Wa,-adhlns=$(<:.c=.lst),-gstabs -g 

GCFLAGS+= -ISTM32F4xx_StdPeriph_Driver/inc



LDFLAGS = -mcpu=cortex-m4 -mthumb $(OPTIMIZATION) -T$(LSCRIPT) 
LDFLAGS+= -mfpu=fpv4-sp-d16 -mfloat-abi=hard -falign-functions=16
LDFLAGS+= -LSTM32F4xx_StdPeriph_Driver/build -lSTM32F4xx_StdPeriph_Driver -lm -lnosys -lc -specs=nano.specs -Wl,--gc-section


#  Compiler/Assembler Paths
GCC = arm-none-eabi-gcc
AS = arm-none-eabi-as
OBJCOPY = arm-none-eabi-objcopy
REMOVE = rm -f
SIZE = arm-none-eabi-size

#########################################################################

all: STM32F4xx_StdPeriph_Driver/build/libSTM32F4xx_StdPeriph_Driver.a $(PROJECT).bin Makefile 
	@$(SIZE) $(PROJECT).elf -A | grep 'text\|data\|section\|bss\|ccm'

STM32F4xx_StdPeriph_Driver/build/libSTM32F4xx_StdPeriph_Driver.a:
	@make -C STM32F4xx_StdPeriph_Driver/build

$(PROJECT).bin: $(PROJECT).elf Makefile
	@echo "generating $(PROJECT).bin"
	@$(OBJCOPY)  -g -S -R .stack -O binary $(PROJECT).elf $(PROJECT).bin

$(PROJECT).elf: $(OBJECTS) Makefile $(LSCRIPT)
	@echo "  LD $(PROJECT).elf"
	@$(GCC) $(OBJECTS) $(LDFLAGS)  -o $(PROJECT).elf

clean:
	$(REMOVE) $(OBJECTS)
	$(REMOVE) $(LSTFILES)
	$(REMOVE) $(PROJECT).bin
	$(REMOVE) $(PROJECT).elf

#########################################################################

%.o: %.c Makefile $(HEADERS)
	@echo "  GCC $<"
	@$(GCC) $(GCFLAGS) -o $@ -c $<

%.o: %.s Makefile 
	@echo "  AS $<"
	@$(AS) $(ASFLAGS) -o $@  $< 

#########################################################################

tools/flash/st-flash:
	make -C tools
tools/gdbserver/st-util:
	make -C tools/gdbserver

debug: tools/gdbserver/st-util
	arm-none-eabi-gdb template.elf -ex 'shell tools/gdbserver/st-util &'  -ex 'tar ext :4242'


flash: tools/flash/st-flash all

	tools/flash/st-flash write $(PROJECT).bin 0x08000000 

.PHONY : clean all flash

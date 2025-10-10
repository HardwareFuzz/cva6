CV_SW_PREFIX ?= riscv64-unknown-elf-
RISCV ?=

GCC     ?= $(if $(RISCV),$(RISCV)/bin/$(CV_SW_PREFIX)gcc,$(CV_SW_PREFIX)gcc)
OBJDUMP ?= $(if $(RISCV),$(RISCV)/bin/$(CV_SW_PREFIX)objdump,$(CV_SW_PREFIX)objdump)

ELF  := skip_trap.elf
DUMP := skip_trap.dump

all: $(ELF)

$(ELF): skip_trap.S link.ld
	$(GCC) -march=rv64imac_zicsr -mabi=lp64 -nostdlib -nostartfiles -T link.ld $< -o $@

$(DUMP): $(ELF)
	$(OBJDUMP) -d $< > $@

clean:
	rm -f $(ELF) $(DUMP)

.PHONY: all clean

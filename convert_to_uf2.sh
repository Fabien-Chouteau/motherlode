#!/bin/sh

arm-none-eabi-objcopy -O binary obj_target/motherlode.elf obj_target/motherlode.bin

if ! test -f uf2conv.py; then
	wget https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2conv.py
fi

python2 uf2conv.py -b 16384 -c -o motherlode.uf2 obj_target/motherlode.bin

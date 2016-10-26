#!/bin/bash


name=`echo "$1" | cut -d"." -f1`


nasm -f elf32 -o $name.o $name.nasm

ld -o $name $name.o

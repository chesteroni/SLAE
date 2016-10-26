#!/bin/bash

gcc -g -fno-stack-protector -z execstack shellcode.c -o shellcode

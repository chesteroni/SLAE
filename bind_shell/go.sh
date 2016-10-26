#!/bin/bash

TARGETBASE="shellcode"
TARGET="$TARGETBASE.c"
DEFAULTPORT="4444"
PORT="4444"

if [ "$#" -eq 0 ]; then
  echo "You must specify the input file without extenstion"
  echo "eg. for hello.nasm run:"
  echo "$0 hello"
  exit
fi

#switch port to the given one
if [ "$#" -eq 2 ]; then
  PORT=$2
  sed -i "s/$DEFAULTPORT/$PORT/g" "$1.nasm"
fi

./asm.sh $1

#restore original port
if [ "$#" -eq 2 ]; then
  PORT=$2
  sed -i "s/$PORT/$DEFAULTPORT/g" "$1.nasm"
fi

COUNT=`./dump.sh $1 | grep -c 00`

if [ $COUNT == "1" ]; then
  echo "Sorry, but there is at least one NULL byte"
  echo "press ENTER for objdump output:"
  read
  objdump -d $1
  exit
fi

SHELLCODE=`./dump.sh $1`
echo '#include <stdio.h>' > $TARGET
echo '#include <string.h>' >> $TARGET
echo >> $TARGET
echo 'unsigned char code[] = \' >> $TARGET
echo $SHELLCODE >> $TARGET
echo ';' >> $TARGET
echo >> $TARGET
echo 'int main()' >> $TARGET
echo '{' >> $TARGET
echo '  printf("Shellcode len: %d\n", strlen(code));' >> $TARGET
echo '  int (*ret)() = (int(*)())code;' >> $TARGET
echo '  ret();' >> $TARGET
echo '}' >> $TARGET

./comp.sh

echo
echo $SHELLCODE

echo 
echo "ready to run but do it manually!"
echo "./$TARGETBASE"
echo 

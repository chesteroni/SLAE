##SLAE - Securitytube Linux Assembly Expert SLAE-769

This repository contains solutions to the exam assignments.
All the solutions do have their dedicated blog posts on my [personal blog](https://chesteroni.blogspot.com)

##Bind shell
This task's goal is to create a bind shell that will open the TCP port and wait for incoming connection. When the client connects, they should receive an interactive shell.
Shellcode generator should be easy configurable so changing the port should be no problem.

####Files:
asm.sh - compiles the assembly code and links it

dump.sh - echoes the shellcode in hex form so it may be put as a payload wherever you would like

comp.sh - compiles the file "shellcode.c" into executable "shellcode". The purpose is to test the shellcode.

go.sh - runs all the files above so you can give the nasm file and port as arguments and receive both bind shell and a binary

bind.nasm - the assemply code of the bind shell. It is heavily documented so you should know what is where and why


####Example usage:
Create the shellcode binaries (ld and gcc):
```
./go.sh bind [4444]
```
The port number is optional and the default is 4444 if omitted.

Then you need two terminals for the client and the server (e.g. 192.168.0.1). On the server side you run `./shellcode`
On the client part you run `nc 192.168.0.1 4444`
And that's it - now you have shell and you can issue some code, e.g. MadCow to get root :-)


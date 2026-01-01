; CONSTANTS

ENOENT equ -2  ; file did not find error
EACCES equ -13 ; could not access file

; syscalls
SYS_WRITE  equ 1
SYS_READ   equ 0   
SYS_EXIT   equ 60 
SYS_OPENAT equ 257 

; fd (file descripters)
STDOUT     equ 1
AT_FDCWD   equ -100 

section .data

    file_not_found db "File not found, good luck bro", 10
    file_not_found_len equ $-file_not_found ; Length of the msg

    specify_filename db "Please for the sake of the God specify the file name to read", 10
    specify_filename_len equ $-specify_filename 

    no_file_access db "Please check your file permissions! ", 10
    no_file_access_len equ $-no_file_access

    hint db "hint: does your file contains read permissions?", 10
    hint_len equ $-hint

section .text
    global _start

_start:
    ; [rsp] = agrc, [rsp+8] = argv[0](filename), [rsp+16] = argv[1](filename to open)-> second arg
    mov rcx, [rsp] ; now rcx = argc
    cmp rcx, 2 ; compare rcx with 2
    ; if rcx < 2
    jb no_arg ; (jump if below) to no_arg
    ; else
    mov rsi, [rsp+16]   ; pathname | point rsi to first character of the filename(argv[1])

    mov rax, SYS_OPENAT ; int openat(int dirfd, const char *pathname, int flags, mode_t mode);
    mov rdi, AT_FDCWD   ; dirfd    | AT_FDCWD (relativce to curent working dir)
    mov rdx, 0          ; flags    | R_DONLY
    mov r9,  0          ; mode
    syscall

    mov r9, rax ; syscall returns fd in rax so save it in r9
    cmp rax, ENOENT  ; -2 = ENOENT (file not found) error
    ; if r9 == ENOENT(-2) 
    je FNF ; file not found 
    
    ; elif r9 = EACCES(-13)
    cmp rax, EACCES 
    je permissions_denied

    ; else:
    jmp read_loop

read_loop:
    ; Read and save to the buffer
    mov rax, SYS_READ  ; sys_read
    mov rdi, r9        ; fd
    mov rsi, file_info ; save the 1024(specified in rdx reg) bytes to the buffer(file_info)
    mov rdx, 1024      ; upto 1024 bytes to read
    syscall

    ; if rax == 0:
    cmp rax, 0 ; check if read returned 0 bytes (EOF) 
    jle pass_exit

    ; else:
    mov rdx, rax       ; mov the total bytes read in rdx 

    ; Write
    mov rax, SYS_WRITE  ; sys_read
    mov rdi, STDOUT    ; standard_out
    mov rsi, file_info
    syscall
    jmp read_loop
    
no_arg:
    mov rax, SYS_WRITE ; sys_write
    mov rdi, STDOUT    ; stdout
    mov rsi, specify_filename
    mov rdx, specify_filename_len
    syscall
    jmp failure_exit

FNF:
    mov rax, SYS_WRITE
    mov rdi, STDOUT 
    mov rsi, file_not_found
    mov rdx, file_not_found_len
    syscall
    jmp failure_exit

permissions_denied:
    ; write no file access msg
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, no_file_access
    mov rdx, no_file_access_len
    syscall

    ; write hint msg
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, hint
    mov rdx, hint_len
    syscall
    jmp failure_exit

pass_exit:
    ; exit
    mov rax, SYS_EXIT ; sys_exit
    xor rdi, rdi ; fd = 0, success
    syscall

failure_exit:
    mov rax, SYS_EXIT
    mov rdi, 1 ; fd = 1, failure
    syscall

section .bss
    file_info resb 1024

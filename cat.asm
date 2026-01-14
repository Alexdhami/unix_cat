; CONSTANTS

; errors
ENOENT     equ -2  ; file did not find error
EACCES     equ -13 ; could not access file

; syscalls
SYS_WRITE  equ 1
SYS_READ   equ 0   
SYS_CLOSE  equ 3
SYS_EXIT   equ 60 
SYS_OPENAT equ 257 

; fd (file descripters)
STDOUT     equ 1
AT_FDCWD   equ -100 

%macro printf 2 ; 1 = pointer to str, 2 = len(str)
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

section .data
    msg_not_found db "File not found :(", 10
    len_not_found equ $-msg_not_found

    msg_no_access db "Please check your file permissions! ", 10
    len_no_access equ $-msg_no_access

    msg_hint db "Hint: does your file contains read permissions?", 10
    len_hint equ $-msg_hint

    msg_generic_error db "Could not open the file :(", 10
    len_generic_error equ $-msg_generic_error

section .text
    global _start

_start:
    check_argc:
        ; [rsp] = agrc, [rsp + 8] = argv[0], [rsp + 16] = argv[1]
        mov rcx, [rsp]

        cmp rcx, 2    ; compare rcx with 2
        jb read_stdin     ; jump if below

        jmp open_file


    open_file:
        mov rax, SYS_OPENAT   ; size_t openat(dir_fd, pathname, flag(O_RDONLY, O_RDWR), mode )
        mov rdi, AT_FDCWD     ; first arguement
        mov rsi, [rsp+16]     ; second arguement  -> rsi points to argv[1]
        mov rdx, 0            ; third arguement   ->  R_DONLY
        mov r10, 0            ; used only when creating a new file (e.g., 0666 for read/write permissions). Not used here
        syscall

        cmp rax, ENOENT
        je file_not_found     ; jmp if equal
        
        cmp rax, EACCES 
        je permissions_denied ; jmp if equal

        test rax, rax
        js generic_error     ; jump if signed bit

        mov r12, rax          ; syscall returns fd in rax. So, save it in r12
        jmp read_loop

    read_stdin:
        mov r12, 0
        jmp read_loop

    read_loop:
        ; Read and save to the buffer
        mov rax, SYS_READ      
        mov rdi, r12          ; fd
        mov rsi, file_content 
        mov rdx, 8192
        syscall

        ; rax returns how many bytes it read from the file
        cmp rax, 0 
        jle successful_exit   ; <= 0 bytes read then completed reading

        mov r13, rax          ; mov the total bytes read in r13 
        printf file_content, r13 
        jmp read_loop
        

    file_not_found:
        printf msg_not_found, len_not_found
        jmp failure_exit

    permissions_denied:
        printf msg_no_access, len_no_access
        printf msg_hint, len_hint
        jmp failure_exit
    
    generic_error:
        printf msg_generic_error, len_generic_error
        jmp failure_exit

    failure_exit:
        mov rax, SYS_EXIT
        mov rdi, 1       ; fd = non-zero -> failure     
        syscall

    successful_exit:
        .close_file:
            mov rax, SYS_CLOSE 
            mov rdi, r12 ; rdi needs fd
            syscall

        .exit:
            mov rax, SYS_EXIT 
            xor rdi, rdi ; fd =   zero   -> success
            syscall
section .bss
    file_content resq 8192

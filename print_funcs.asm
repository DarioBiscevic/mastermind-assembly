section .text

; *****************************************************************************

; Function that prints several digits taken from a not-stack-based array
; and a newline (LF) is printed at the end
; NOTE: Values increase (going from lowest address to highest address)
; Arguments:
;   rdi: pointer to array
;   rsi: number of digits
global println_num_array
println_num_array:
    ; Prologue
    push rbp
    mov rbp, rsp
    
    xor rcx, rcx ; Reset rcx

    mov rcx, rsi
    println_num_array_loop:

        push rcx
        push rdi
        push rsi

        ; Prepare address of value to print
        xor rbx, rbx
        add rbx, rdi
        add rbx, rsi
        sub rbx, rcx

        mov rax, qword[rbx]
        add al, "0"
        mov byte[temp], al
        mov rax, 1 ; sys_write
        mov rdi, 1 ; stout
        mov rdx, 1 ; length of character
        mov rsi, temp
        syscall

        pop rsi
        pop rdi
        pop rcx

    loop println_num_array_loop

    mov byte[temp], 10
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    mov rsi, temp
    syscall

    ; Epilogue
    pop rbp
    ret

; *****************************************************************************


; Function that prints a single character without LF at the end
; Arguments: 
;   rdi: character to print
global put_char
put_char:
    ; Prologue
    push rbp
    mov rbp, rsp

    push rdi
    mov rax, 1 ; sys_write
    mov rdi, 1 ; stdout
    mov rdx, 1 ; length of character
    mov rsi, rsp
    syscall
    pop rdi

    ; Epilogue
    pop rbp
    ret

; *****************************************************************************

section .bss
    temp resb 1
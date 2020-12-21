; TITLE: mastermind.asm
; AUTHOR: Dario Biscevic
; GOAL: Replicate the classic "Mastermind" game in assembly
; REQ: None
; VERSION: 1.0

%include "print_funcs.asm"
extern print_funcs

section .text
global _start

_start:
    ; To have a random seed at each execution,
    ; the initial state is defined as the address pointed from rsp
    mov qword[state], rsp

    call generate_number


    game_loop:

        ; Read player's input
        call read_guess

        mov rdi, ":"
        call put_char
        mov rdi, " "
        call put_char

        
        ; Check player's guess
        call check_guess

        push rax ; "put_char" changes the value of rax

        mov rdi, 10 ; Linefeed
        call put_char

        pop rax

        ; If the players guess is equal to the solution, rax is 1,
        ; then it jumps outside to finish the game
        cmp rax, 1
        je outside

        jmp game_loop

    outside:

    ; Print final message
    mov rax, 1
    mov rdi, 1
    mov rsi, final_message
    mov rdx, fm_len
    syscall

    mov rdi, num
    mov rsi, 4
    call println_num_array


    ; Exit program
    mov rax, 60 ; sys_exit
    mov rdi, 0  ; Return value
    syscall


; Function that generates a random number using xorshift
; Arguments:
;   rdi: upper bound
global prng
prng: 
    ; Prologue
    push rbp
    mov rbp, rsp

    ; Load state into temporary register
    mov r10, qword[state]

    ; Left-shift
    mov r11, r10
    shl r11, 13
    xor r10, r11

    ; Right-shift
    mov r11, r10
    shr r11, 7
    xor r10, r11

    ; Left-shift again
    mov r11, r10
    shl r11, 5
    xor r10, r11

    ; Update state
    mov qword[state], r10
    mov rax, r10

    ; Limit value to bound
    div rdi 

    ; Set return value, since the remainder is inside rdx
    mov rax, rdx

    ; Epilogue
    pop rbp
    ret


; Function that generates a random number between 1000 and 9999
; with all four figures different from eachother
; Arguments: None
global generate_number
generate_number:
    ; Prologue
    push rbp
    mov rbp, rsp

    gen:

    ; Register r8 is used as a temporary register
    mov r8, 0

    ; A number between 0 and 9999 is created
    mov rdi, 10000
    call prng

    ; Then, the generated number must be checked
    ; if it is valid (i.e. all figures are different)
    mov rcx, 4
    mov rbx, 10
    split_num:
        mov rdx, 0
        div rbx

        mov byte[num+rcx-1], dl
    loop split_num


    ; whether the number is valid or not
    mov rcx, 3
    check_val_1:
        mov r8b, byte[num+rcx-1]
        cmp byte[num+rcx], r8b
        jne after_check
            jmp gen
        after_check:
    loop check_val_1

    mov r8b, byte[num]
    cmp r8b, byte[num+2]
    jne check1
        jmp gen
    check1:

    cmp r8b, byte[num+3]
    jne check2
        jmp gen
    check2:

    mov r8b, byte[num+1]
    cmp r8b, byte[num+3]
    jne check3
        jmp gen
    check3:

    ; Epilogue
    pop rbp
    ret

; Function that reads from stdin and stores the string inside the guess array,
; already converted from ASCII to decimal numbers
; Arguments: None (in theory we should put the array's pointer, but hey, no)
global read_guess
read_guess:
    ; Prologue
    push rbp
    mov rbp, rsp
    push rbx

    mov r10, 0 ; Counter for how many characters are read
    mov rbx, guess ; Index where to place the character
    read_characters:
        mov rax, 0            ; sys_read
        mov rdi, 0            ; stdin
        mov rsi, tmpChar      ; Address of the temporary variable
        mov rdx, 1            ; Length of what to read
        syscall

        mov al, byte[tmpChar]
        cmp al, 10            ; Check if the read byte is linefeed (newline)
        je read_done

        sub rax, "0"          ; What is read is stored as an ASCII character

        inc r10
        cmp r10, guess_length ; Stop placing in buffer if count > length
        jg read_characters

        mov byte[rbx], al
        inc rbx

        jmp read_characters
    read_done:

    ; Epilogue
    pop rbx
    pop rbp
    ret

; Function that checks the figures of the guess
; Arguments: None
global check_guess
check_guess:
    ; Prologue
    push rbp
    mov rbp, rsp

    xor r11, r11  ; Reset r11

    mov rcx, guess_length
    mov r8, guess ; Address of guess
    mov r9, num   ; Address of the solution
    mov r11b, 0   ; Right-number counter
    check_right_right:

        push rcx

        mov r10b, byte[r8]
        cmp r10b, byte[r9]
        jne not_right_right
            mov rdi, "1"
            push r11
            call put_char
            pop r11
            inc r11b
        not_right_right:
        inc r8
        inc r9
        pop rcx

    loop check_right_right

    cmp r11b, guess_length
    jne not_win
        mov rax, 1
        jmp after_win_check
    not_win:
        mov rax, 0
    after_win_check:

    push rax

    mov rcx, guess_length
    mov r8, guess
    mov r9, num
    outer_check:
        mov r11, rcx
        push rcx
        mov rcx, guess_length
        inner_check:
            mov r10b, byte[r8+rcx-1]
            cmp r10b, byte[r9+r11-1]
            jne not_right_wrong
                cmp rcx, r11
                je not_right_wrong
                    mov rdi, "0"
                    push rcx
                    push r11
                    call put_char
                    pop r11
                    pop rcx

            not_right_wrong:
        loop inner_check
        pop rcx
    loop outer_check

    mov rdi, 10
    call put_char

    pop rax

    ; Epilogue
    pop rbp
    ret

section .data
    guess_length  equ 4
    final_message db "The number was: "
    fm_len        equ $-final_message

section .bss
    state   resq 1 ; Seed for the PRNG
    num     resb 4 ; Array where to store the number to guess
    guess   resb 4 ; Array where to store the player's guess
    tmpChar resb 1 ; Temporary variable used in read function

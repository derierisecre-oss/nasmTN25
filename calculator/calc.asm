%macro print 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

%macro read 1
    mov eax, 3
    mov ebx, 0
    mov ecx, %1
    mov edx, 4
    int 0x80
%endmacro

%macro load_numbers 0
    mov eax, 0
    mov al, [num1]
    mov ebx, 0
    mov bl, [num2]
    sub eax, '0'
    sub ebx, '0'
%endmacro

section .data
    clear_screen db 27, '[2J', 27, '[H'
    clear_len    equ $ - clear_screen

    menu         db "----------------------------------", 10
                 db "MENU", 10
                 db "[A]dd", 10
                 db "[S]ubtract", 10
                 db "[M]ultiply", 10
                 db "[D]ivide", 10
                 db "----------------------------------", 10
    menu_len     equ $ - menu

    msg_choice   db "Enter your choice: "
    msg_choice_len equ $ - msg_choice

    msg_first    db 10, "Enter first number: "
    msg_first_len equ $ - msg_first

    msg_second   db "Enter second number: "
    msg_second_len equ $ - msg_second

    msg_sum      db "The sum is "
    msg_sum_len  equ $ - msg_sum

    msg_diff     db "The difference is "
    msg_diff_len equ $ - msg_diff

    msg_prod     db "The product is "
    msg_prod_len equ $ - msg_prod

    msg_quo      db "The quotient is "
    msg_quo_len  equ $ - msg_quo

    msg_again    db 10, "Do you want to try again (Y/N) "
    msg_again_len equ $ - msg_again

section .bss
    choice  resb 4
    num1    resb 4
    num2    resb 4
    answer  resb 4
    result  resb 3

section .text
    global _start

_start:

show_menu:
    print clear_screen, clear_len
    print menu, menu_len

    print msg_choice, msg_choice_len
    read choice

    print msg_first, msg_first_len
    read num1

    print msg_second, msg_second_len
    read num2

    cmp byte [choice], 'A'
    je  do_add
    cmp byte [choice], 'S'
    je  do_subtract
    cmp byte [choice], 'M'
    je  do_multiply
    cmp byte [choice], 'D'
    je  do_divide
    jmp ask_again

do_add:
    print msg_sum, msg_sum_len
    load_numbers
    add eax, ebx
    call show_result
    jmp ask_again

do_subtract:
    print msg_diff, msg_diff_len
    load_numbers
    sub eax, ebx
    call show_result
    jmp ask_again

do_multiply:
    print msg_prod, msg_prod_len
    load_numbers
    imul eax, ebx
    call show_result
    jmp ask_again

do_divide:
    print msg_quo, msg_quo_len
    load_numbers
    mov edx, 0
    div ebx
    call show_result
    jmp ask_again

ask_again:
    print msg_again, msg_again_len
    read answer

    cmp byte [answer], 'Y'
    je  show_menu

    mov eax, 1
    mov ebx, 0
    int 0x80

show_result:
    mov edx, 0
    mov ebx, 10
    div ebx
    add al, '0'
    add dl, '0'
    mov [result], al
    mov [result + 1], dl
    mov byte [result + 2], 10

    mov ecx, result
    mov edx, 3
    cmp byte [result], '0'
    jne .show
    inc ecx
    dec edx
.show:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

    
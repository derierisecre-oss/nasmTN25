section .data
    title db "========== Georgette EATERY ==========", 10, 0

    menu db "A. Rice : Plain Rice       Php 5.00", 10
         db "B. Rice : Java Rice        Php 10.00", 10
         db "C. Ulam 1: (Fish)          Php 35.00", 10
         db "D. Ulam 2: (Pork)          Php 50.00", 10
         db "E. Ulam 3: (Vegetables)    Php 20.00", 10
         db "F. Dessert: Saging con yelo Php 60.00", 10, 0

    prompt db "Enter your order: ", 0
    again db "Do you want to order again? [Y/N]: ", 0

    invalid db "Invalid choice! Please try again.", 10, 0
    thanks db "Thank you! Please come again!", 10, 0

    ordered db "You ordered ", 0

    plain db "Plain Rice: Php 5.00", 10, 0
    java db "Java Rice: Php 10.00", 10, 0
    fish db "Fish: Php 35.00", 10, 0
    pork db "Pork: Php 50.00", 10, 0
    vegetables db "Vegetables: Php 20.00", 10, 0
    dessert db "Saging con yelo: Php 60.00", 10, 0

    receipt_name db "receipt.txt", 0
    receipt_title db "Receipt", 10, 0

    newline db 10, 0

section .bss
    choice resb 2
    answer resb 2
    fd resd 1
    buffer resb 512
    total resd 1

section .text
    global _start

; MACRO: Print string
%macro PRINT 1
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    call strlen
    mov edx, eax
    mov eax, 4
    mov ebx, 1
    int 0x80
%endmacro

; PROCEDURE: Calculate string length
strlen:
    push ecx
    xor eax, eax
.next:
    cmp byte [ecx + eax], 0
    je .done
    inc eax
    jmp .next
.done:
    pop ecx
    ret

; PROCEDURE: Print menu
display_menu:
    PRINT title
    PRINT menu
    ret

; PROCEDURE: Write receipt entry
write_receipt:
    push eax
    push ebx
    push ecx
    push edx

    mov eax, 4
    mov ebx, [fd]
    mov ecx, esi
    call strlen
    mov edx, eax
    mov eax, 4
    mov ebx, [fd]
    mov ecx, esi
    int 0x80

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

_start:

    ; Create receipt file
    mov eax, 5
    mov ebx, receipt_name
    mov ecx, 577
    mov edx, 0644
    int 0x80
    mov [fd], eax

    ; Write receipt heading
    mov esi, receipt_title
    call write_receipt

order_loop:

    call display_menu

    PRINT prompt

    ; Read choice
    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 2
    int 0x80

    mov al, [choice]
    cmp al, 'a'
    jb check_choice
    cmp al, 'f'
    ja check_choice
    sub al, 32

check_choice:

    cmp al, 'A'
    je order_plain
    cmp al, 'B'
    je order_java
    cmp al, 'C'
    je order_fish
    cmp al, 'D'
    je order_pork
    cmp al, 'E'
    je order_vegetables
    cmp al, 'F'
    je order_dessert

    PRINT invalid
    jmp order_loop

order_plain:
    mov esi, plain
    jmp process_order

order_java:
    mov esi, java
    jmp process_order

order_fish:
    mov esi, fish
    jmp process_order

order_pork:
    mov esi, pork
    jmp process_order

order_vegetables:
    mov esi, vegetables
    jmp process_order

order_dessert:
    mov esi, dessert

process_order:

    PRINT ordered

    ; Display selected item
    mov ecx, esi
    call strlen
    mov edx, eax
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    int 0x80

    ; Write selected item to receipt
    call write_receipt

    PRINT again

    ; Read Y/N
    mov eax, 3
    mov ebx, 0
    mov ecx, answer
    mov edx, 2
    int 0x80

    mov al, [answer]
    cmp al, 'Y'
    je order_loop
    cmp al, 'y'
    je order_loop
    cmp al, 'N'
    je exit_program
    cmp al, 'n'
    je exit_program

    PRINT invalid
    jmp order_loop

exit_program:

    PRINT thanks

    ; Close receipt file
    mov eax, 6
    mov ebx, [fd]
    int 0x80

    ; Open receipt for reading
    mov eax, 5
    mov ebx, receipt_name
    mov ecx, 0
    int 0x80

    mov [fd], eax

    ; Read receipt
    mov eax, 3
    mov ebx, [fd]
    mov ecx, buffer
    mov edx, 512
    int 0x80

    ; Display receipt
    mov edx, eax
    mov eax, 4
    mov ebx, 1
    mov ecx, buffer
    int 0x80

    ; Close file
    mov eax, 6
    mov ebx, [fd]
    int 0x80

    ; Exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

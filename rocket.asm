section .data
    title db "Rocket - NASM32", 10
    titleLen equ $ - title

    stars  db "  *       .     *   ", 10
    starsLen equ $ - stars
    nose1  db "         /\         ", 10
    nose1Len equ $ - nose1
    nose2  db "        /  \        ", 10
    nose2Len equ $ - nose2
    nose3  db "       /    \       ", 10
    nose3Len equ $ - nose3
    cap    db "      /######\      ", 10
    capLen equ $ - cap
    window db "      |  @@  |      ", 10
    windowLen equ $ - window
    body   db "      |  CD  |      ", 10
    bodyLen equ $ - body
    fin1   db "     /|  @@  |\     ", 10
    fin1Len equ $ - fin1
    fin2   db "    / |      | \    ", 10
    fin2Len equ $ - fin2
    fin3   db "   /__|______|__\   ", 10
    fin3Len equ $ - fin3
    nozzle db "      \------/      ", 10
    nozzleLen equ $ - nozzle
    flame1 db "       \****/       ", 10
    flame1Len equ $ - flame1
    flame2 db "        \**/        ", 10
    flame2Len equ $ - flame2
    flame3 db "         \/         ", 10
    flame3Len equ $ - flame3

    padChar db "_"
    newline db 10

section .text
    global _start

_start:
    mov ecx, title
    mov edx, titleLen
    call printString
    mov ecx, stars
    mov edx, starsLen
    call printString
    mov ecx, nose1
    mov edx, nose1Len
    call printString
    mov ecx, nose2
    mov edx, nose2Len
    call printString
    mov ecx, nose3
    mov edx, nose3Len
    call printString
    mov ecx, cap
    mov edx, capLen
    call printString

    mov ecx, window
    mov edx, windowLen
    call printString

    mov esi, 3
bodyLoop:
    mov ecx, body
    mov edx, bodyLen
    call printString
    dec esi
    jnz bodyLoop

    mov ecx, fin1
    mov edx, fin1Len
    call printString
    mov ecx, fin2
    mov edx, fin2Len
    call printString
    mov ecx, fin3
    mov edx, fin3Len
    call printString

    mov ecx, nozzle
    mov edx, nozzleLen
    call printString
    mov ecx, flame1
    mov edx, flame1Len
    call printString
    mov ecx, flame2
    mov edx, flame2Len
    call printString
    mov ecx, flame3
    mov edx, flame3Len
    call printString

    mov ecx, padChar
    mov ebx, 20
    call printRepeat
    mov ecx, newline
    mov ebx, 1
    call printRepeat

    mov eax, 1
    xor ebx, ebx
    int 0x80

printString:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

printRepeat:
    mov edi, ebx
.again:
    mov eax, 4
    mov ebx, 1
    mov edx, 1
    int 0x80
    dec edi
    jnz .again
    ret

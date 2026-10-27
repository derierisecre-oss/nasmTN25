
%macro printLine 2
    mov ecx, %1
    mov edx, %2
    call printString
%endmacro

section .data
    title db "Christmas Tree - NASM32", 10
    titleLen equ $ - title

    line1 db "             I", 10
    line1Len equ $ - line1

    line2 db "           wrote", 10
    line2Len equ $ - line2

    line3 db "          a poem", 10
    line3Len equ $ - line3

    line4 db "        in the shape", 10
    line4Len equ $ - line4

    line5 db "       of a Christmas", 10
    line5Len equ $ - line5

    line6 db "     Tree but then forgot", 10
    line6Len equ $ - line6

    line7 db "   to water it and only a few", 10
    line7Len equ $ - line7

    line8 db "           days", 10
    line8Len equ $ - line8

    line9 db "           later", 10
    line9Len equ $ - line9

    line10 db "   there", 10
    line10Len equ $ - line10

    line11 db "                    were", 10
    line11Len equ $ - line11

    line12 db "    words", 10
    line12Len equ $ - line12

    line13 db "  all       ", 10
    line13Len equ $ - line13

    line14 db "                  over  ", 10
    line14Len equ $ - line14

    line15 db "the  ", 10
    line15Len equ $ - line15

    line16 db "          carpet  ", 10
    line16Len equ $ - line16

section .text
    global _start

_start:
    call printPoem
    call exitProgram


printPoem:
    printLine title, titleLen
    printLine line1, line1Len
    printLine line2, line2Len
    printLine line3, line3Len
    printLine line4, line4Len
    printLine line5, line5Len
    printLine line6, line6Len
    printLine line7, line7Len
    printLine line8, line8Len
    printLine line9, line9Len
    printLine line10, line10Len
    printLine line11, line11Len
    printLine line12, line12Len
    printLine line13, line13Len
    printLine line14, line14Len
    printLine line15, line15Len
    printLine line16, line16Len
    ret


printString:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret


exitProgram:
    mov eax, 1
    xor ebx, ebx
    int 0x80

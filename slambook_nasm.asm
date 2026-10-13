; ==========================================================================
;  SLAMBOOK - "About Me" form          (NASM, 32-bit Linux, elf32)
;
;  Build : nasm -f elf32 slambook_nasm.asm -o slambook_nasm.o
;  Link  : ld -m elf_i386 slambook_nasm.o -o slambook_nasm
;  Run   : ./slambook_nasm
;
;  Row/column positioning : ANSI escape code  ESC [ row ; col H
;  Colors                 : ANSI escape code  ESC [ nn m
;  Screen / keyboard      : Linux system calls (int 0x80): write, read, exit
; ==========================================================================

; --------------------------------------------------------------------------
;  MACROS
; --------------------------------------------------------------------------

; SHOW row, col, string, color : go to (row,col), set color, print string
%macro SHOW 4
    mov eax, %1                 ; EAX = row   (0 = top line)
    mov ebx, %2                 ; EBX = column (0 = left edge)
    call gotoxy                 ; move the cursor there (row/column code)
    mov esi, %4                 ; ESI = color code string
    call print_z                ; apply the color
    mov esi, %3                 ; ESI = text to print
    call print_z                ; print it
%endmacro

; INPUTF row, col, slot, max : go to a blank and read the user's typing
%macro INPUTF 4
    mov eax, %1                 ; row of the blank
    mov ebx, %2                 ; column of the blank
    call gotoxy                 ; move the cursor onto the blank
    mov esi, cWhite             ; typed text will be white
    call print_z
    mov ecx, buffers + %3 * 64  ; ECX = this field's storage slot (64 bytes each)
    mov edx, %4                 ; EDX = maximum characters
    call read_field             ; read the line the user types
%endmacro

; --------------------------------------------------------------------------
;  DATA
; --------------------------------------------------------------------------
section .data

; ----- color codes (ANSI) -----
cGreen   db 27, "[92m", 0       ; light green
cYellow  db 27, "[93m", 0       ; yellow
cGray    db 27, "[37m", 0       ; light gray
cDark    db 27, "[90m", 0       ; dark gray
cCyan    db 27, "[96m", 0       ; light cyan
cMag     db 27, "[95m", 0       ; light magenta
cRed     db 27, "[91m", 0       ; light red
cBrown   db 27, "[33m", 0       ; brown / dark yellow
cWhite   db 27, "[97m", 0       ; white
cReset   db 27, "[0m", 0        ; back to normal

clrscr   db 27, "[2J", 27, "[H", 0   ; clear screen + cursor to top-left
newline  db 10, 0

; ----- border (UTF-8 box characters) -----
topB     db 0xE2,0x95,0x94                      ; corner
         times 77 db 0xE2,0x95,0x90             ; 77 horizontal bars
         db 0xE2,0x95,0x97, 0                   ; corner
botB     db 0xE2,0x95,0x9A
         times 77 db 0xE2,0x95,0x90
         db 0xE2,0x95,0x9D, 0
vbar     db 0xE2,0x95,0x91, 0                   ; vertical bar

; ----- blank lines -----
line30   times 30 db "_"
         db 0
line50   times 50 db "_"
         db 0
line20   times 20 db "_"
         db 0

; ----- page 1 -----
ti1      db "+-----------+", 0
ti2      db "| ABOUT  ME |", 0
ti3      db "+-----------+", 0
lName    db "Name:", 0
lEmail   db "Email:", 0
lBlog    db "Blog/Website:", 0

ph1      db "+---------+", 0
ph2      db "|         |", 0
ph3      db "|  PHOTO  |", 0

tFirst   db "~~ MY FIRST ~~", 0
lAchieve db "First big achievement:", 0
lWish    db "First wish I ever took:", 0
lHappy   db "First time I felt completely happy:", 0

tFaves   db "** MY FAVES **", 0
lColor   db "Color/s:", 0
lPerf    db "Perfume:", 0
lMusic   db "Music:", 0
lSinger  db "Singer/s:", 0
lSong    db "Song:", 0
lFood    db "Food:", 0

ht1      db " .:::.   .:::. ", 0
ht2      db ":::::::.:::::::", 0
ht3      db "':::::::::::::'", 0
ht4      db "  ':::::::::'  ", 0
ht5      db "    ':::::'    ", 0
ht6      db "      ':'      ", 0

; ----- page 2 -----
tHob     db "<< HOBBIES >>", 0
lWeek    db "Weekend activity:", 0
lTV      db "TV Show:", 0
lMovie   db "Movie:", 0
lBook    db "Book:", 0
lCeleb   db "Celebrity:", 0
lRole    db "Role model:", 0
tAmb     db "^^ AMBITION ^^", 0

cup1     db "   ( (   ", 0
cup2     db "    ) )  ", 0
cup3     db "  ........", 0
cup4     db "  |      |]", 0
cup5     db "  \      /", 0
cup6     db "   `----' ", 0

mo1      db " .------------------------------.", 0
mo2      db "(  MOTTO:                        )", 0
mo3      db " '------.-----------------------'", 0
mo4      db "        /", 0
mo5      db "       /", 0

; ----- messages -----
msgType  db "Type your answer, then press ENTER to go to the next field.", 0
msgNext  db "[ Press ENTER for next page ]", 0
msgEnd   db "[ Press ENTER to exit ]", 0

; --------------------------------------------------------------------------
;  UNINITIALIZED MEMORY
; --------------------------------------------------------------------------
section .bss
buffers  resb 23 * 64           ; 22 answer slots + 1 spare for the "press ENTER" waits
posbuf   resb 16                ; holds the cursor escape code being built
junk     resb 4                 ; used to throw away extra typed characters

; --------------------------------------------------------------------------
;  CODE
; --------------------------------------------------------------------------
section .text
global _start

_start:
    ; ======================= PAGE 1 =======================
    call clear_screen           ; blank screen
    call draw_border            ; red double-line frame

    ; --- title box ---
    SHOW 2, 3, ti1, cGreen
    SHOW 3, 3, ti2, cGreen
    SHOW 4, 3, ti3, cGreen

    ; --- name / email / blog ---
    SHOW 2, 20, lName,  cYellow
    SHOW 2, 34, line30, cGray
    SHOW 3, 20, lEmail, cYellow
    SHOW 3, 34, line30, cGray
    SHOW 4, 20, lBlog,  cYellow
    SHOW 4, 34, line30, cGray

    ; --- photo box ---
    SHOW 2, 64, ph1, cCyan
    SHOW 3, 64, ph2, cCyan
    SHOW 4, 64, ph3, cCyan
    SHOW 5, 64, ph2, cCyan
    SHOW 6, 64, ph1, cCyan

    ; --- MY FIRST ---
    SHOW 7,  3, tFirst,   cMag
    SHOW 8,  4, lAchieve, cYellow
    SHOW 8, 40, line30,   cGray
    SHOW 9,  4, lWish,    cYellow
    SHOW 9, 40, line30,   cGray
    SHOW 10, 4, lHappy,   cYellow
    SHOW 10,40, line30,   cGray

    ; --- MY FAVES ---
    SHOW 12, 3, tFaves, cRed
    SHOW 13, 4, lColor, cYellow
    SHOW 13,18, line30, cGray
    SHOW 14, 4, lPerf,  cYellow
    SHOW 14,18, line30, cGray
    SHOW 15, 4, lMusic, cYellow
    SHOW 15,18, line30, cGray
    SHOW 16, 4, lSinger,cYellow
    SHOW 16,18, line30, cGray
    SHOW 17, 4, lSong,  cYellow
    SHOW 17,18, line30, cGray
    SHOW 18, 4, lFood,  cYellow
    SHOW 18,18, line30, cGray

    ; --- heart ASCII art ---
    SHOW 13, 58, ht1, cRed
    SHOW 14, 58, ht2, cRed
    SHOW 15, 58, ht3, cRed
    SHOW 16, 58, ht4, cRed
    SHOW 17, 58, ht5, cRed
    SHOW 18, 58, ht6, cRed

    ; --- instructions + input (slots 0-11) ---
    SHOW 21, 10, msgType, cDark
    INPUTF 2, 34, 0, 25         ; Name
    INPUTF 3, 34, 1, 25         ; Email
    INPUTF 4, 34, 2, 25         ; Blog/Website
    INPUTF 8, 40, 3, 30         ; First big achievement
    INPUTF 9, 40, 4, 30         ; First wish
    INPUTF 10, 40, 5, 30        ; First time completely happy
    INPUTF 13, 18, 6, 30        ; Color/s
    INPUTF 14, 18, 7, 30        ; Perfume
    INPUTF 15, 18, 8, 30        ; Music
    INPUTF 16, 18, 9, 30        ; Singer/s
    INPUTF 17, 18, 10, 30       ; Song
    INPUTF 18, 18, 11, 30       ; Food

    SHOW 22, 24, msgNext, cDark
    call pause                  ; wait for ENTER

    ; ======================= PAGE 2 =======================
    call clear_screen
    call draw_border

    ; --- HOBBIES ---
    SHOW 2, 3, tHob, cCyan
    SHOW 3, 4, lWeek,  cYellow
    SHOW 3, 24, line30, cGray
    SHOW 4, 4, lTV,    cYellow
    SHOW 4, 24, line30, cGray
    SHOW 5, 4, lMovie, cYellow
    SHOW 5, 24, line30, cGray
    SHOW 6, 4, lBook,  cYellow
    SHOW 6, 24, line30, cGray
    SHOW 7, 4, lCeleb, cYellow
    SHOW 7, 24, line30, cGray
    SHOW 8, 4, lRole,  cYellow
    SHOW 8, 24, line30, cGray

    ; --- coffee cup ASCII art ---
    SHOW 3, 62, cup1, cBrown
    SHOW 4, 62, cup2, cBrown
    SHOW 5, 62, cup3, cBrown
    SHOW 6, 62, cup4, cBrown
    SHOW 7, 62, cup5, cBrown
    SHOW 8, 62, cup6, cBrown

    ; --- AMBITION ---
    SHOW 10, 3, tAmb, cRed
    SHOW 11, 4, line50, cGray
    SHOW 12, 4, line50, cGray
    SHOW 13, 4, line50, cGray

    ; --- MOTTO bubble ---
    SHOW 15, 4, mo1, cMag
    SHOW 16, 4, mo2, cMag
    SHOW 16, 14, line20, cGray
    SHOW 17, 4, mo3, cMag
    SHOW 18, 4, mo4, cMag
    SHOW 19, 4, mo5, cMag

    ; --- instructions + input (slots 12-21) ---
    SHOW 21, 10, msgType, cDark
    INPUTF 3, 24, 12, 30        ; Weekend activity
    INPUTF 4, 24, 13, 30        ; TV Show
    INPUTF 5, 24, 14, 30        ; Movie
    INPUTF 6, 24, 15, 30        ; Book
    INPUTF 7, 24, 16, 30        ; Celebrity
    INPUTF 8, 24, 17, 30        ; Role model
    INPUTF 11, 4, 18, 50        ; Ambition line 1
    INPUTF 12, 4, 19, 50        ; Ambition line 2
    INPUTF 13, 4, 20, 50        ; Ambition line 3
    INPUTF 16, 14, 21, 20       ; Motto

    SHOW 22, 26, msgEnd, cDark
    call pause                  ; wait for ENTER

    ; --- finish: reset color, park the cursor under the frame, exit ---
    mov esi, cReset
    call print_z
    mov eax, 23
    mov ebx, 0
    call gotoxy
    mov esi, newline
    call print_z
    mov eax, 1                  ; syscall 1 = exit
    xor ebx, ebx                ; exit code 0
    int 0x80

; ==========================================================================
;  print_z : print a 0-terminated string
;  Input   : ESI = address of the string
; ==========================================================================
print_z:
    pusha                       ; save all registers
    mov edx, 0                  ; EDX = length counter
.len:
    cmp byte [esi + edx], 0     ; reached the 0 terminator?
    je .go
    inc edx                     ; no -> count the character
    jmp .len
.go:
    mov ecx, esi                ; ECX = address of the text
    mov ebx, 1                  ; EBX = 1 -> standard output (the screen)
    mov eax, 4                  ; syscall 4 = write
    int 0x80                    ; write(1, text, length)
    popa                        ; restore registers
    ret

; ==========================================================================
;  gotoxy : move the cursor to a row and column (the "row/column code")
;  Input  : EAX = row (0-based), EBX = column (0-based)
;  Builds the text  ESC [ row ; col H  and writes it to the screen
; ==========================================================================
gotoxy:
    pusha
    mov edi, posbuf             ; EDI = where we build the escape code
    mov byte [edi], 27          ; ESC character
    mov byte [edi + 1], '['     ; '['
    add edi, 2
    inc eax                     ; terminals count rows from 1
    call put_num                ; write the row number as text
    mov byte [edi], ';'
    inc edi
    mov eax, ebx                ; EAX = column
    inc eax                     ; terminals count columns from 1
    call put_num                ; write the column number as text
    mov byte [edi], 'H'         ; 'H' = "move cursor" command
    inc edi
    mov edx, edi
    sub edx, posbuf             ; EDX = length of the code we built
    mov ecx, posbuf             ; ECX = address of the code
    mov ebx, 1                  ; stdout
    mov eax, 4                  ; write
    int 0x80
    popa
    ret

; put_num : write EAX (0-99) as decimal text at [EDI], advance EDI
put_num:
    xor edx, edx
    mov ecx, 10
    div ecx                     ; EAX = tens digit, EDX = ones digit
    cmp eax, 0
    je .ones                    ; skip a leading zero
    add al, '0'
    mov [edi], al
    inc edi
.ones:
    add dl, '0'
    mov [edi], dl
    inc edi
    ret

; ==========================================================================
;  read_field : read what the user types (one line) into a buffer
;  Input : ECX = buffer address, EDX = maximum characters
;  The text is SAVED in the buffer. Extra characters beyond the maximum
;  are thrown away.
; ==========================================================================
read_field:
    pusha
    inc edx                     ; leave room for the ENTER character
    mov eax, 3                  ; syscall 3 = read
    mov ebx, 0                  ; stdin (the keyboard)
    int 0x80                    ; EAX = number of bytes read
    cmp eax, 0
    jle .done                   ; nothing read -> finished
    cmp byte [ecx + eax - 1], 10 ; did the line end with ENTER?
    je .done                    ; yes -> all good
.flush:                         ; user typed too much: discard the rest of the line
    mov eax, 3
    mov ebx, 0
    mov ecx, junk
    mov edx, 1
    int 0x80
    cmp eax, 1
    jne .done
    cmp byte [junk], 10
    jne .flush
.done:
    popa
    ret

; ==========================================================================
;  pause : wait until the user presses ENTER
; ==========================================================================
pause:
    pusha
    mov ecx, buffers + 22 * 64  ; spare slot
    mov edx, 60
    call read_field
    popa
    ret

; ==========================================================================
;  clear_screen : clear the terminal and put the cursor at the top-left
; ==========================================================================
clear_screen:
    mov esi, clrscr
    call print_z
    ret

; ==========================================================================
;  draw_border : double-line frame (rows 0-23, columns 0-78)
; ==========================================================================
draw_border:
    SHOW 0, 0, topB, cRed       ; top edge
    SHOW 23, 0, botB, cRed      ; bottom edge
    mov edi, 1                  ; EDI = current row, start at row 1
.side:
    mov eax, edi
    mov ebx, 0                  ; column 0 = left edge
    call gotoxy
    mov esi, vbar
    call print_z                ; left bar
    mov eax, edi
    mov ebx, 78                 ; column 78 = right edge
    call gotoxy
    mov esi, vbar
    call print_z                ; right bar
    inc edi                     ; next row
    cmp edi, 23                 ; reached the bottom edge?
    jb .side                    ; not yet -> repeat
    ret

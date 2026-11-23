BITS 32
section .data
header db 10,'========== MONTHLY EXPENSE MANAGER ==========',10
headerLen equ $-header
menu db '1 Add expense',10,'2 View expenses',10,'3 Edit expense',10,'4 Delete expense',10,'5 Generate receipt',10,'6 Change month/year',10,'7 Exit',10,'8 Verify saved files',10,'Choice: '
menuLen equ $-menu
askMonth db 'Month (1-12): '
askMonthLen equ $-askMonth
askYear db 'Year (2000-2099): '
askYearLen equ $-askYear
askName db 'Expense name: '
askNameLen equ $-askName
askAmount db 'Amount PHP (e.g. 125.50): '
askAmountLen equ $-askAmount
askId db 'Expense ID: '
askIdLen equ $-askId
askConfirm db 'Delete this expense? (Y/N): '
askConfirmLen equ $-askConfirm
msgSaved db 'Saved.',10
msgSavedLen equ $-msgSaved
msgEdited db 'Updated.',10
msgEditedLen equ $-msgEdited
msgDeleted db 'Deleted.',10
msgDeletedLen equ $-msgDeleted
msgInvalid db 'Invalid input or selection.',10
msgInvalidLen equ $-msgInvalid
msgFull db 'Storage full (100 records).',10
msgFullLen equ $-msgFull
msgFile db 'File operation failed.',10
msgFileLen equ $-msgFile
msgReceipt db 'Receipt written to receipt.txt',10
msgReceiptLen equ $-msgReceipt
msgEmpty db 'No expenses for this month.',10
msgEmptyLen equ $-msgEmpty
labelMonth db 'Month/year: '
labelMonthLen equ $-labelMonth
labelId db 'ID '
labelIdLen equ $-labelId
sep db ' | '
sepLen equ $-sep
moneyPrefix db 'PHP '
moneyPrefixLen equ $-moneyPrefix
totalLabel db 'TOTAL: PHP '
totalLabelLen equ $-totalLabel
receiptTitle db 10,'      /\_/\        /\_/\',10,'     ( o.o )      ( ^.^ )',10,'      > ^ <        > ^ <',10,'========== MONTHLY RECEIPT ==========',10
receiptTitleLen equ $-receiptTitle
receiptEnd db '============= END =============',10,'          / \__',10,'         (    @\___',10,'         /         O',10,'        /   (_____/',10,'       /_____/   U',10
receiptEndLen equ $-receiptEnd
slash db '/'
dot db '.'
newline db 10
space db ' '
fileName db 'expenses.dat',0
receiptName db 'receipt.txt',0
verifyHeading db 10,'--- VERIFY RECEIPT FILE (READ BACK) ---',10
verifyHeadingLen equ $-verifyHeading
verifyDataHeading db 10,'--- VERIFY EXPENSE DATA FILE ---',10
verifyDataHeadingLen equ $-verifyDataHeading
verifyOK db 'Expense data file opened and record count read: ',0
verifyOKLen equ $-verifyOK-1
verifyMissing db 'File missing or unreadable.',10
verifyMissingLen equ $-verifyMissing
verifyEnd db 10,'--- END FILE VERIFICATION ---',10
verifyEndLen equ $-verifyEnd
section .bss
; record: name[32], amount in centavos[4], month[4], year[4]
records resb 4400
recordCount resd 1
month resd 1
year resd 1
selected resd 1
amount resd 1
total resd 1
outfd resd 1
fd resd 1
buffer resb 128
nameTemp resb 32
numBuffer resb 16
oneChar resb 1
found resd 1
verifyBuffer resb 1024
verifyFd resd 1
verifyCount resd 1
section .text
global _start
%macro SAY 2
 mov ecx,%1
 mov edx,%2
 call write_out
%endmacro
_start:
 mov dword [outfd],1
 mov dword [month],11
 mov dword [year],2026
 mov dword [recordCount],0
 call load_data
main:
 SAY header,headerLen
 SAY labelMonth,labelMonthLen
 mov eax,[month]
 call print_uint
 SAY slash,1
 mov eax,[year]
 call print_uint
 SAY newline,1
 SAY menu,menuLen
 call read_line
 jc exit_app
 call parse_uint
 jc invalid
 cmp eax,1
 je add_record
 cmp eax,2
 je view_records
 cmp eax,3
 je edit_record
 cmp eax,4
 je delete_record
 cmp eax,5
 je receipt
 cmp eax,6
 je change_month
 cmp eax,7
 je exit_app
 cmp eax,8
 je verify_files
invalid:
 SAY msgInvalid,msgInvalidLen
 jmp main

; write_out preserves all registers; outfd is 1 or receipt file
write_out:
 pushad
 mov eax,4
 mov ebx,[outfd]
 int 0x80
 popad
 ret

; read line one byte at a time, EAX=length; CF=1 on EOF/too long
read_line:
 push ebx
 push ecx
 push edx
 push esi
 xor esi,esi
 xor ebx,ebx
.read:
 mov eax,3
 push ebx
 xor ebx,ebx
 mov ecx,oneChar
 mov edx,1
 int 0x80
 pop ebx
 cmp eax,1
 jne .eof
 mov al,[oneChar]
 cmp al,10
 je .done
 cmp al,13
 je .read
 cmp esi,127
 jae .overflow
 mov [buffer+esi],al
 inc esi
 jmp .read
.overflow:
 mov ebx,1
 jmp .read
.eof:
 cmp esi,0
 jne .done
 mov ebx,1
.done:
 mov byte [buffer+esi],0
 mov eax,esi
 test ebx,ebx
 jz .ok
 stc
 jmp .return
.ok:
 clc
.return:
 pop esi
 pop edx
 pop ecx
 pop ebx
 ret

; unsigned decimal buffer -> EAX, CF error
parse_uint:
 push esi
 push ebx
 push edx
 xor eax,eax
 xor esi,esi
 cmp byte [buffer],0
 je .bad
.loop:
 movzx edx,byte [buffer+esi]
 test edx,edx
 jz .ok
 cmp edx,'0'
 jb .bad
 cmp edx,'9'
 ja .bad
 sub edx,'0'
 mov ebx,10
 mul ebx
 test edx,edx
 jnz .bad
 movzx edx,byte [buffer+esi]
 sub edx,'0'
 add eax,edx
 jc .bad
 inc esi
 jmp .loop
.ok:
 clc
 jmp .ret
.bad:
 stc
.ret:
 pop edx
 pop ebx
 pop esi
 ret

; money decimal -> cents in EAX; 1, 1.5, 1.50 accepted
parse_money:
 push ebx
 push ecx
 push edx
 push esi
 xor eax,eax
 xor esi,esi
 xor ecx,ecx
 xor ebx,ebx
 cmp byte [buffer],0
 je .bad
.loop:
 movzx edx,byte [buffer+esi]
 test edx,edx
 jz .finish
 cmp edx,'.'
 je .decimal
 cmp edx,'0'
 jb .bad
 cmp edx,'9'
 ja .bad
 sub edx,'0'
 cmp ebx,0
 je .integer
 cmp ecx,2
 jae .bad
 inc ecx
.integer:
 push edx
 mov edx,10
 mul edx
 test edx,edx
 pop edx
 jnz .bad
 add eax,edx
 jc .bad
 inc esi
 jmp .loop
.decimal:
 cmp ebx,0
 jne .bad
 cmp esi,0
 je .bad
 mov ebx,1
 inc esi
 jmp .loop
.finish:
 cmp esi,0
 je .bad
 cmp ebx,0
 jne .fraction
 mov edx,100
 mul edx
 test edx,edx
 jnz .bad
 jmp .positive
.fraction:
 cmp ecx,0
 je .bad
 cmp ecx,1
 jne .positive
 mov edx,10
 mul edx
 test edx,edx
 jnz .bad
.positive:
 test eax,eax
 jz .bad
 clc
 jmp .ret
.bad:
 stc
.ret:
 pop esi
 pop edx
 pop ecx
 pop ebx
 ret

; output unsigned EAX
print_uint:
 pushad
 lea edi,[numBuffer+16]
 mov ebx,10
 xor esi,esi
.loop:
 xor edx,edx
 div ebx
 add dl,'0'
 dec edi
 mov [edi],dl
 inc esi
 test eax,eax
 jnz .loop
 mov ecx,edi
 mov edx,esi
 call write_out
 popad
 ret

; output cents EAX as 123.45
print_money:
 pushad
 mov ebx,100
 xor edx,edx
 div ebx
 push edx
 call print_uint
 SAY dot,1
 pop edx
 mov eax,edx
 cmp eax,10
 jae .two
 SAY zero,1
.two:
 call print_uint
 popad
 ret
section .data
zero db '0'
section .text

; record address from zero-based index EAX -> EDI
record_ptr:
 imul eax,eax,44
 lea edi,[records+eax]
 ret

; input name into nameTemp, CF error
get_name:
 SAY askName,askNameLen
 call read_line
 jc .bad
 cmp eax,0
 je .bad
 cmp eax,31
 ja .bad
 push esi
 push edi
 mov esi,buffer
 mov edi,nameTemp
 mov ecx,32
 xor eax,eax
 rep stosb
 mov edi,nameTemp
.copy:
 lodsb
 stosb
 test al,al
 jnz .copy
 pop edi
 pop esi
 clc
 ret
.bad:
 stc
 ret

get_amount:
 SAY askAmount,askAmountLen
 call read_line
 jc .bad
 call parse_money
 ret
.bad:
 stc
 ret

add_record:
 cmp dword [recordCount],100
 jae full
 call get_name
 jc invalid
 call get_amount
 jc invalid
 mov [amount],eax
 mov eax,[recordCount]
 call record_ptr
 mov esi,nameTemp
 mov ecx,32
 rep movsb
 mov eax,[amount]
 mov [edi],eax
 mov eax,[month]
 mov [edi+4],eax
 mov eax,[year]
 mov [edi+8],eax
 inc dword [recordCount]
 call save_data
 jc file_fail
 SAY msgSaved,msgSavedLen
 jmp main
full:
 SAY msgFull,msgFullLen
 jmp main

; display selected month, IDs are global record IDs
view_records:
 mov dword [found],0
 xor esi,esi
.loop:
 cmp esi,[recordCount]
 jae .done
 mov eax,esi
 call record_ptr
 cmp dword [edi+36],[month]
 jne .next
 cmp dword [edi+40],[year]
 jne .next
 inc dword [found]
 SAY labelId,labelIdLen
 mov eax,esi
 inc eax
 call print_uint
 SAY sep,sepLen
 mov eax,edi
 call print_name
 SAY sep,sepLen
 SAY moneyPrefix,moneyPrefixLen
 mov eax,[edi+32]
 call print_money
 SAY newline,1
.next:
 inc esi
 jmp .loop
.done:
 cmp dword [found],0
 jne .return
 SAY msgEmpty,msgEmptyLen
.return:
 jmp main

; EAX points to zero-terminated name (max 32)
print_name:
 pushad
 mov ecx,eax
 xor edx,edx
.len:
 cmp byte [ecx+edx],0
 je .out
 inc edx
 cmp edx,32
 jb .len
.out:
 call write_out
 popad
 ret

; read ID, check exists and belongs to selected month
get_id:
 SAY askId,askIdLen
 call read_line
 jc .bad
 call parse_uint
 jc .bad
 test eax,eax
 jz .bad
 cmp eax,[recordCount]
 ja .bad
 dec eax
 mov [selected],eax
 call record_ptr
 cmp dword [edi+36],[month]
 jne .bad
 cmp dword [edi+40],[year]
 jne .bad
 clc
 ret
.bad:
 stc
 ret

edit_record:
 call get_id
 jc invalid
 call get_name
 jc invalid
 call get_amount
 jc invalid
 mov [amount],eax
 mov eax,[selected]
 call record_ptr
 mov esi,nameTemp
 mov ecx,32
 rep movsb
 mov eax,[amount]
 mov [edi],eax
 call save_data
 jc file_fail
 SAY msgEdited,msgEditedLen
 jmp main

delete_record:
 call get_id
 jc invalid
 SAY askConfirm,askConfirmLen
 call read_line
 jc invalid
 cmp eax,1
 jne invalid
 mov al,[buffer]
 cmp al,'Y'
 je .yes
 cmp al,'y'
 je .yes
 jmp main
.yes:
 mov eax,[selected]
 call record_ptr
 mov esi,edi
 add esi,44
 mov eax,[recordCount]
 sub eax,[selected]
 dec eax
 imul ecx,eax,44
 ; forward copy to close gap
 rep movsb
 dec dword [recordCount]
 call save_data
 jc file_fail
 SAY msgDeleted,msgDeletedLen
 jmp main

change_month:
 SAY askMonth,askMonthLen
 call read_line
 jc invalid
 call parse_uint
 jc invalid
 cmp eax,1
 jb invalid
 cmp eax,12
 ja invalid
 mov [selected],eax
 SAY askYear,askYearLen
 call read_line
 jc invalid
 call parse_uint
 jc invalid
 cmp eax,2000
 jb invalid
 cmp eax,2099
 ja invalid
 mov [year],eax
 mov eax,[selected]
 mov [month],eax
 jmp main

; receipt prints to file, then switches output back to console
receipt:
 mov eax,5
 mov ebx,receiptName
 mov ecx,577
 mov edx,0644o
 int 0x80
 test eax,eax
 js file_fail
 mov [outfd],eax
 SAY receiptTitle,receiptTitleLen
 SAY labelMonth,labelMonthLen
 mov eax,[month]
 call print_uint
 SAY slash,1
 mov eax,[year]
 call print_uint
 SAY newline,1
 mov dword [total],0
 xor esi,esi
.loop:
 cmp esi,[recordCount]
 jae .done
 mov eax,esi
 call record_ptr
 cmp dword [edi+36],[month]
 jne .next
 cmp dword [edi+40],[year]
 jne .next
 mov eax,edi
 call print_name
 SAY sep,sepLen
 SAY moneyPrefix,moneyPrefixLen
 mov eax,[edi+32]
 call print_money
 SAY newline,1
 mov eax,[edi+32]
 add [total],eax
 jc .overflow
.next:
 inc esi
 jmp .loop
.done:
 SAY totalLabel,totalLabelLen
 mov eax,[total]
 call print_money
 SAY newline,1
 SAY receiptEnd,receiptEndLen
 mov eax,6
 mov ebx,[outfd]
 int 0x80
 mov dword [outfd],1
 SAY msgReceipt,msgReceiptLen
 jmp main
.overflow:
 mov eax,6
 mov ebx,[outfd]
 int 0x80
 mov dword [outfd],1
 jmp invalid

; binary file: 4-byte count + count*44 bytes
save_data:
 mov eax,5
 mov ebx,fileName
 mov ecx,577
 mov edx,0644o
 int 0x80
 test eax,eax
 js .bad
 mov [fd],eax
 mov eax,4
 mov ebx,[fd]
 mov ecx,recordCount
 mov edx,4
 int 0x80
 cmp eax,4
 jne .close_bad
 mov eax,[recordCount]
 imul edx,eax,44
 test edx,edx
 jz .close_ok
 mov eax,4
 mov ebx,[fd]
 mov ecx,records
 int 0x80
 cmp eax,edx
 jne .close_bad
.close_ok:
 mov eax,6
 mov ebx,[fd]
 int 0x80
 clc
 ret
.close_bad:
 mov eax,6
 mov ebx,[fd]
 int 0x80
.bad:
 stc
 ret

load_data:
 mov eax,5
 mov ebx,fileName
 xor ecx,ecx
 int 0x80
 test eax,eax
 js .return
 mov [fd],eax
 mov eax,3
 mov ebx,[fd]
 mov ecx,recordCount
 mov edx,4
 int 0x80
 cmp eax,4
 jne .reset
 cmp dword [recordCount],100
 ja .reset
 mov eax,[recordCount]
 imul edx,eax,44
 test edx,edx
 jz .close
 mov eax,3
 mov ebx,[fd]
 mov ecx,records
 int 0x80
 cmp eax,edx
 je .close
.reset:
 mov dword [recordCount],0
.close:
 mov eax,6
 mov ebx,[fd]
 int 0x80
.return:
 ret

; Option 8: independently read back both files using sys_open/sys_read.
verify_files:
 SAY verifyDataHeading,verifyDataHeadingLen
 mov eax,5
 mov ebx,fileName
 xor ecx,ecx
 int 0x80
 test eax,eax
 js .missing_data
 mov [verifyFd],eax
 mov eax,3
 mov ebx,[verifyFd]
 mov ecx,verifyCount
 mov edx,4
 int 0x80
 cmp eax,4
 jne .close_data_bad
 SAY verifyOK,verifyOKLen
 mov eax,[verifyCount]
 call print_uint
 SAY newline,1
 mov eax,6
 mov ebx,[verifyFd]
 int 0x80
 jmp .receipt
.close_data_bad:
 mov eax,6
 mov ebx,[verifyFd]
 int 0x80
.missing_data:
 SAY verifyMissing,verifyMissingLen
.receipt:
 SAY verifyHeading,verifyHeadingLen
 mov eax,5
 mov ebx,receiptName
 xor ecx,ecx
 int 0x80
 test eax,eax
 js .missing_receipt
 mov [verifyFd],eax
.read_receipt:
 mov eax,3
 mov ebx,[verifyFd]
 mov ecx,verifyBuffer
 mov edx,1024
 int 0x80
 test eax,eax
 js .close_receipt_bad
 jz .close_receipt
 mov ecx,verifyBuffer
 mov edx,eax
 call write_out
 jmp .read_receipt
.close_receipt_bad:
 SAY verifyMissing,verifyMissingLen
.close_receipt:
 mov eax,6
 mov ebx,[verifyFd]
 int 0x80
 jmp .done
.missing_receipt:
 SAY verifyMissing,verifyMissingLen
.done:
 SAY verifyEnd,verifyEndLen
 jmp main

file_fail:
 SAY msgFile,msgFileLen
 jmp main
exit_app:
 mov eax,1
 xor ebx,ebx
 int 0x80

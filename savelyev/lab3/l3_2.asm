TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN

; Данные
   AVAILEBLEMEM db 'Available memory in bytes:                                    ',0DH,0AH,'$'
   EXTENDEDMEM  db 'Expanded memory in kilobytes:                                     ',0DH,0AH,'$'
   STR          db 0DH,0AH,'$'
   ADDRESS      db 'address:       ','$'
   MCB          db 'MCB ','$'
   ADDRESSPSP   db 'PSP address:       ','$'
   SIZEEE       db 'Size:           ','$'
   SC_SD        db 'SC/SD:','$'
   PRSIZE       db 0
; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   ;xor AH,AH
   ;xor DX,DX
   mov CX,10
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP

MYPRINT PROC near
   push ax
   mov AH,09h
   int 21h
   pop ax
   ret
MYPRINT ENDP

AVAILABLE_MEM PROC near
   push ax
   push bx
   push dx
   push si
   mov ah, 4ah
   mov bx, 0FFFFh
   int 21h
   mov ax, 16
   mul bx
   mov si, offset AVAILEBLEMEM
   add si, 32
   call BYTE_TO_DEC
   mov dx, offset AVAILEBLEMEM
   call MYPRINT
   pop si
   pop dx
   pop bx
   pop ax
   ret
AVAILABLE_MEM ENDP

EXЕTENDED_MEM PROC near
   push ax
   push bx
   push dx
   push si
   xor dx, dx
   mov AL,30h
   out 70h,AL
   in AL,71h
   mov BL,AL;
   mov AL,31h
   out 70h,AL
   in AL,71h
   mov ah, al
   mov si, offset EXTENDEDMEM
   add si, 34
   call BYTE_TO_DEC
   mov dx, offset EXTENDEDMEM
   call MYPRINT
   pop si
   pop dx
   pop bx
   pop ax
   ret
EXЕTENDED_MEM ENDP

MCB_FUNCTION PROC near
   push ax
   push bx
   push es
   push dx
   push cx
   mov dx, offset MCB
   call MYPRINT
   mov di, offset ADDRESS
   add di, 12
   call WRD_TO_HEX
   mov dx, offset ADDRESS
   call MYPRINT
   mov ax, es:[1h]
   mov di, offset ADDRESSPSP
   add di, 16
   call WRD_TO_HEX
   mov dx, offset ADDRESSPSP
   call MYPRINT
   mov ax, es:[3h]
   mov bx, 10h
   mul bx
   mov si, offset SIZEEE
   add si, 11
   call BYTE_TO_DEC
   mov dx, offset SIZEEE
   call MYPRINT
   mov dx, offset SC_SD
   call MYPRINT
   mov bx, 8
   mov cx, 7
work_work:
   mov dl, es:[bx]
   mov ah, 02h
   int 21h
   inc bx
   loop work_work
   pop cx
   pop dx
   pop es
   pop bx
   pop ax
ret
MCB_FUNCTION ENDP

BLOCK_CHAIN PROC near
   push ax
   push bx
   push es
   push dx
   push cx
   mov ah, 52h
   int 21h
   mov es, es:[bx-2]
   mov ax, es
work:
   call MCB_FUNCTION
   mov dx, offset STR
   call MYPRINT
   mov al, es:[0h]
   cmp al, 5ah
je exit
   mov bx, es:[3h]
   mov ax, es
   add ax, bx
   inc ax
   mov es, ax
   jmp work
exit:
   pop cx
   pop dx
   pop es
   pop bx
   pop ax
   ret
BLOCK_CHAIN ENDP

BEGIN:
   call AVAILABLE_MEM
   call EXЕTENDED_MEM
   mov bx,offset PRSIZE
   mov ah,4ah
   int 21h
   call BLOCK_CHAIN
   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START

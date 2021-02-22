TESTPC SEGMENT
	ASSUME CS:TESTPC, ds:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H

START: jmp BEGIN

; Данные

UNAVAILABLE_MEM_STR         db 'Segment address of inaccessible memory:     h',0DH,0AH,'$'
ENVIROMENT_STR              db 'ENVIROMENT segment address:     h',0DH,0AH,'$'
TAIL_COMMAND_STR	          db 'Command tail:                  ',0DH,0AH,'$'
PATH_STR 				            db 'Path:                             ',0DH,0AH,'$'
EMPTY_TAIL_STR              db 'Command line tail is empty!',0DH,0AH,'$'
NEW_STR                     db                                       0DH, 0AH, '$'
ENVIROMENT_CONTENT_STR      db      'Environment content: ',                   '$'

; Процедуры

TETR_TO_HEX PROC near
    and al,0Fh
    cmp al,09
    jbe next
    add al,07
next:
    add al,30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    ;байт в al переводится в два символа шест. числа в ax
    push CX
    mov AH,al
    call TETR_TO_HEX
    xchg al,AH
    mov CL,4
    shr al,CL
    call TETR_TO_HEX ;в al старшая цифра
    pop CX ;в AH младшая
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
    ;перевод в 16 с/с 16-ти разрядного числа
    ; в ax - число, DI - адрес последнего символа
   	push BX
    mov BH,AH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],al
    dec DI
    mov al,BH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],al
    pop BX
    ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near
    ; перевод в 10с/с, si - адрес поля младшей цифры
   	push CX
	push dx
	xor AH,AH
	xor dx,dx
	mov CX,10
loop_bd:
    div CX
	or dl,30h
	mov [si],dl
	dec si
	xor dx,dx
	cmp ax,10
	jae loop_bd
	cmp al,00h
	je end_l
	or al,30h
	mov [si],al
end_l:
    pop dx
   	pop CX
   	ret
BYTE_TO_DEC ENDP

MYPRINTS PROC near
	  push ax
   	mov ah, 09h
   	int 21h
	  pop ax
   	ret
MYPRINTS ENDP

MYPRINT PROC near
	  push ax
   	mov ah, 02h
   	int 21h
	  pop ax
   	ret
MYPRINT ENDP

UNAVAILABLE_MEM PROC near
   	mov ax, ds:[02h]
   	mov di, offset UNAVAILABLE_MEM_STR
   	add di, 43
   	call WRD_TO_HEX
   	mov dx, offset UNAVAILABLE_MEM_STR
   	call MYPRINTS
   	ret
UNAVAILABLE_MEM ENDP

ENVIROMENT PROC near
	mov ax, ds:[2Ch]
   	mov di, offset ENVIROMENT_STR
   	add di, 31
   	call WRD_TO_HEX
   	mov dx, offset ENVIROMENT_STR
   	call MYPRINTS
   	ret
ENVIROMENT ENDP

TAIL proc near
    push cx
    xor cx, cx
	  mov cl, ds:[80h]
	  mov si, offset TAIL_COMMAND_STR
	  add si, 13
    cmp cl, 0h
    je empty
	  xor di, di
	  xor ax, ax

tail_loop:
	  mov al, ds:[81h+di]
    inc di
    mov [si], al
	  inc si
	  loop tail_loop
	  mov dx, offset TAIL_COMMAND_STR
	  jmp end_tail

empty:
	  mov dx, offset EMPTY_TAIL_STR

end_tail:
    call MYPRINTS
    pop cx
    ret
TAIL ENDP


ENVIROMENT_CONTENT PROC near
    push dx
    push ax
    push si
    push ds
    xor si, si
    mov dx, offset ENVIROMENT_CONTENT_STR
    call MYPRINTS
    mov dx, offset NEW_STR
    call MYPRINTS
    mov ds,ds:[2CH]

read_enviroment:
    mov dl,[si]
    cmp dl,0
    je end_line
    call MYPRINT
    inc si
    jmp read_enviroment

end_line:
    inc si
    mov dl,[si]
    cmp dl,0
    je end_read

    pop ds
    mov dx, offset NEW_STR
    call MYPRINTS
    push ds
    mov ds,ds:[2Ch]

    jmp read_enviroment

end_read:
    pop ds
    mov dx, offset NEW_STR
    call MYPRINTS
    mov dx, offset PATH_STR
    call MYPRINTS
    push ds
    mov ds,ds:[2Ch]
    add si, 3

read_pth:
    mov dl,[si]
    cmp dl,0
    je leave_point

    call MYPRINT
    inc si
    jmp read_pth

leave_point:
    pop ds
    pop si
    pop ax
    pop dx
    ret

ENVIROMENT_CONTENT ENDP

; КОД
BEGIN:
   	call UNAVAILABLE_MEM
   	call ENVIROMENT
   	call TAIL
    call ENVIROMENT_CONTENT

		xor		al,al
		mov		AH,4Ch
		int		21H
TESTPC		ENDS
			END 	START

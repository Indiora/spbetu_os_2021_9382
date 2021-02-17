
AStack    SEGMENT  STACK
          DW 128 DUP(?)
AStack    ENDS


DATA SEGMENT
; Данные PC
    TYPE_PC 			db 'Type: PC',0DH,0AH,'$'
    XT_TYP 			db 'Type: PC/XT',0DH,0AH,'$'
    AT_TYP 			db 'Type: AT',0DH,0AH,'$'
    PS2_MODEL_M_30 		db 'Type: PS2 model 30',0DH,0AH,'$'
    PS2_MODEL_M_50_60 	db 'Type: PS2 model 50 or 60',0DH,0AH,'$'
    PS2_MODEL_M_80 		db 'Type: PS2 model 80',0DH,0AH,'$'
    JR_TYP 			db 'Type: PСjr',0DH,0AH,'$'
    CONV_TYP 			db 'Type: PC Convertible',0DH,0AH,'$'

; Данные MS_DOS
    VERSIONS 			db 'MS-DOS version:  .  ',0DH,0AH,'$'
    SERIAL_NUM 			db 'Serial OEM:  ',0DH,0AH,'$'
    USER_NUM 			db 'User Serial:       H',0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE,DS:DATA,SS:AStack

; Процедуры

TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe next
    add AL,07
next:
    add AL,30h
    ret
TETR_TO_HEX ENDP

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

BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   	push CX
	push DX
	xor AH,AH
	xor DX,DX
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
    mov AH,09h
    int 21h
	ret
MYPRINT ENDP

DEFINE_PC_TYP PROC near
   	mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0ffh
	je pc_type

	cmp al, 0feh
	je xt_type

	cmp al, 0fbh
	je xt_type

	cmp al, 0fch
	je at_type

	cmp al, 0fah
	je ps2_m30

	cmp al, 0f8h
	je ps2_m80

	cmp al, 0fdh
	je jr_type

	cmp al, 0f9h
	je conv_type

pc_type:
	mov dx, offset TYPE_PC
	jmp writetype

xt_type:
	mov dx, offset XT_TYP
	jmp writetype

at_type:
	mov dx, offset AT_TYP
	jmp writetype

ps2_m30:
	mov dx, offset PS2_MODEL_M_30
	jmp writetype

pc_ps2_m50_60:
	mov dx, offset PS2_MODEL_M_50_60
	jmp writetype

ps2_m80:
	mov dx, offset PS2_MODEL_M_80
	jmp writetype

jr_type:
	mov dx, offset JR_TYP
	jmp writetype
conv_type:
	mov dx, offset CONV_TYP
	jmp writetype

writetype:
	call MYPRINT
	ret
DEFINE_PC_TYP ENDP

DEFINE_OS_VER PROC near
	mov ah, 30h
	int 21h
	push ax

	mov si, offset VERSIONS
	add si, 16
	call BYTE_TO_DEC
    	pop ax
    	mov al, ah
    	add si, 3
	call BYTE_TO_DEC
	mov dx, offset VERSIONS
	call MYPRINT

	mov si, offset SERIAL_NUM
	add si, 12
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset SERIAL_NUM
	call MYPRINT

	mov di, offset USER_NUM
	add di, 18
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset USER_NUM
	call MYPRINT
	ret
DEFINE_OS_VER ENDP

MAIN PROC FAR
    sub   AX,AX
    push  AX
    mov   AX,DATA
    mov   DS,AX
    call DEFINE_PC_TYP
    call DEFINE_OS_VER
    xor AL,AL
    mov AH,4Ch
    int 21H
MAIN ENDP

CODE ENDS
END MAIN

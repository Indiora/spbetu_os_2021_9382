DATA segment
    FLAGL           db                                            0
    FLAGUN          db                                            0
    LOADMSG         db      "Interruption was loaded.",          0dh, 0ah, "$"
    ALREDYLOADMSG   db      "Interruption has been already loaded",      0dh, 0ah, "$"
    UNLOADMSG       db      "Interruption was unloaded.",        0dh, 0ah, "$"
    NOTLOADEDMSG    db      "Interruption is not loaded.",       0dh, 0ah, "$"
DATA ends

ASTACK  segment stack
 dw  256 dup(0)
ASTACK  ends

CODE segment
assume  cs:CODE, ds:DATA, ss:ASTACK

MYINTERRUPTION PROC FAR
    jmp  GOO

IDATA:
    keep_ip dw 0
    keep_cs dw 0
    keep_psp dw 0
    keep_ax dw 0
    keep_ss dw 0
    keep_sp dw 0
    key_value db 0
    new_stack dw 256 dup(0)
    sign dw 1388h

GOO:
    mov keep_ax, ax
    mov keep_sp, sp
    mov keep_ss, ss
    mov ax, seg new_stack
    mov ss, ax
    mov ax, offset new_stack
    add ax, 256
    mov sp, ax

    push ax
    push bx
    push cx
    push dx
    push si
    push es
    push ds
    mov ax, seg key_value
    mov ds, ax

    in al, 60h
    cmp al, 20h  ;d
    je FLAG_D
    cmp al, 1Fh  ;s
    je FLAG_S
    cmp al, 1Eh  ;a
    je FLAG_A

    pushf
    call dword ptr cs:keep_ip
    jmp ENDMYINTERRUPTION

FLAG_D:
    mov key_value, '#'
    jmp NEXTKEY
FLAG_S:
    mov key_value, '$'
    jmp NEXTKEY
FLAG_A:
    mov key_value, '%'

NEXTKEY:
    in al, 61h
    mov ah, al
    or 	al, 80h
    out 61h, al
    xchg al, al
    out 61h, al
    mov al, 20h
    out 20h, al

PRINTKEY:
    mov ah, 05h
    mov cl, key_value
    mov ch, 00h
    int 16h
    or 	al, al
    jz 	ENDMYINTERRUPTION
    mov ax, 40h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp PRINTKEY

ENDMYINTERRUPTION:
    pop  ds
    pop  es
    pop	 si
    pop  dx
    pop  cx
    pop  bx
    pop	 ax

    mov sp, keep_sp
    mov ax, keep_ss
    mov ss, ax
    mov ax, keep_ax

    mov  al, 20h
    out  20h, al
    iret
MYINTERRUPTION endp
 LAST:

CHECKMYI proc
    push ax
    push bx
    push si

    mov  ah, 35h
    mov  al, 09h
    int  21h
    mov  si, offset sign
    sub  si, offset MYINTERRUPTION
    mov  ax, es:[bx + si]
    cmp	 ax, sign
    jne  LEAVEEE
    mov  FLAGL, 1

LEAVEEE:
    pop  si
    pop  bx
    pop  ax
    ret

CHECKMYI endp

ILOAD  proc
    push ax
    push bx
    push cx
    push dx
    push es
    push ds

    mov ah, 35h
    mov al, 09h
    int 21h
    mov keep_cs, es
    mov keep_ip, bx
    mov ax, seg MYINTERRUPTION
    mov dx, offset MYINTERRUPTION
    mov ds, ax
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds

    mov dx, offset LAST
    mov cl, 4h
    shr dx, cl
    add	dx, 10fh
    inc dx
    xor ax, ax
    mov ah, 31h
    int 21h

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ILOAD  endp


UNLOADD proc
    cli
    push ax
    push bx
    push dx
    push ds
    push es
    push si
    mov ah, 35h
    mov al, 09h
    int 21h
    mov si, offset keep_ip
    sub si, offset MYINTERRUPTION
    mov dx, es:[bx + si]
    mov ax, es:[bx + si + 2]
    push ds
    mov ds, ax
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds
    mov ax, es:[bx + si + 4]
    mov es, ax
    push es
    mov ax, es:[2ch]
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h
    sti
    pop si
    pop es
    pop ds
    pop dx
    pop bx
    pop ax

ret
UNLOADD endp

CHECK_UN  proc
    push ax
    push es
    mov ax, keep_psp
    mov es, ax
    cmp byte ptr es:[82h], '/'
    jne LEAVEE
    cmp byte ptr es:[83h], 'u'
    jne LEAVEE
    cmp byte ptr es:[84h], 'n'
    jne LEAVEE
    mov FLAGUN, 1

LEAVEE:
    pop es
    pop ax
    ret

CHECK_UN endp


MYPRINT proc near
    push ax
    mov ah, 9h
    int 21h
    pop ax
    ret
MYPRINT endp


MAIN proc
    push ds
    xor ax, ax
    push ax
    mov ax, DATA
    mov ds, ax
    mov keep_psp, es

    call CHECKMYI
    call CHECK_UN
    cmp FLAGUN, 1
    je UNLOAD
    mov al, FLAGL
    cmp al, 1
    jne LOAD
    mov dx, offset ALREDYLOADMSG
    call MYPRINT
    jmp EXIT

LOAD:
    mov dx, offset LOADMSG
    call MYPRINT
    call ILOAD
    jmp  EXIT

UNLOAD:
    cmp  FLAGL, 1
    jne  MOTLOADED
    mov dx, offset UNLOADMSG
    call MYPRINT
    call UNLOADD
    jmp  EXIT

MOTLOADED:
    mov  dx, offset NOTLOADEDMSG
    call MYPRINT

EXIT:
    xor al, al
    mov ah, 4ch
    int 21h

MAIN endp
CODE ends
end MAIN

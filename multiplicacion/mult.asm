;──────────────────────────────────────────────────────────────
;  mult.asm  —  Multiplica dos enteros de 8 bits en modo DOS
;                 (lee, guarda, multiplica y muestra)
;  Ensamblar:  nasm mult.asm -o mult.com
;──────────────────────────────────────────────────────────────
org 100h

section .data
prompt1 db 13,10,'Ingresa el primer numero (0-255): $'
prompt2 db 13,10,'Ingresa el segundo numero (0-255): $'
msgRes  db 13,10,'Producto: $'

buffer  db 4,0,0,0,0        ; buffer para INT 21h, func 0Ah

section .bss
num1    resb 1              ; operandos de 8 bits
num2    resb 1
result  resw 1              ; producto de 16 bits

section .text
_start:
    ; ── Leer primer número ──────────────────────────────
    call ClearBuffer
    mov  ah,9
    mov  dx,prompt1
    int  21h
    call ReadByte           ; AL ← valor
    mov  [num1],al

    ; ── Leer segundo número ─────────────────────────────
    call ClearBuffer
    mov  ah,9
    mov  dx,prompt2
    int  21h
    call ReadByte
    mov  [num2],al

    ; ── Multiplicación 8×8 → 16 bits ───────────────────
    mov  al,[num1]
    mov  bl,[num2]
    mul  bl                ; AX = AL × BL
    mov  [result],ax

    ; ── Mostrar resultado ──────────────────────────────
    mov  ah,9
    mov  dx,msgRes
    int  21h
    mov  ax,[result]
    call PrintNumber

    ; Salir
    mov  ax,4C00h
    int  21h

;──────────────────────────────────────────────────────────────
;  ReadByte  –  Lee entero 0-255 (devuelve AL)
;──────────────────────────────────────────────────────────────
ReadByte:
    call ClearBuffer
    mov  ah,0Ah
    lea  dx,buffer
    int  21h

    movzx cx,byte [buffer+1]    ; CX = longitud
    cmp  cx,0
    je   error_exit

    xor  ax,ax
    mov  si,buffer+2

.conv:
    movzx dx,byte [si]
    cmp  dx,0Dh
    je   .done
    sub  dx,'0'
    imul ax,ax,10
    add  ax,dx
    inc  si
    loop .conv

.done:
    cmp  ax,255
    ja   error_exit            ; fuera de rango 0-255
    xor  ah,ah                 ; ← corrección: limpiar AH, AL ya es el valor
    ret

;──────────────────────────────────────────────────────────────
;  PrintNumber – Imprime AX en decimal y CR/LF
;──────────────────────────────────────────────────────────────
PrintNumber:
    mov  bx,10
    xor  cx,cx
.convOut:
    xor  dx,dx
    div  bx
    add  dl,'0'
    push dx
    inc  cx
    test ax,ax
    jnz  .convOut
.print:
    pop  dx
    mov  ah,2
    int  21h
    loop .print
    mov  dl,13
    int  21h
    mov  dl,10
    int  21h
    ret

;──────────────────────────────────────────────────────────────
;  ClearBuffer – Reinicia buffer 0Ah
;──────────────────────────────────────────────────────────────
ClearBuffer:
    mov  byte [buffer+1],0
    mov  byte [buffer+2],0
    mov  byte [buffer+3],0
    mov  byte [buffer+4],0
    ret

;──────────────────────────────────────────────────────────────
error_exit:
    mov  ax,4C01h
    int  21h

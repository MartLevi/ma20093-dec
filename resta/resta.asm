;─────────────────────────────────────────────────────────────────────────
;  resta.asm  —  Lee 3 numeros (0-999) y calcula  A − B − C
;                * Modo real 16-bits   * DOS INT 21h
;                * Registros de 16 bits (AX,BX,CX,DX,SI)
;
;  Flujo principal
;     1. Leer num1, num2, num3  (subrutina ReadNumber)
;     2. Calcular  result = num1 − num2 − num3
;     3. Mostrar resultado      (subrutina PrintNumber)
;     4. Salir al DOS
;
;  Ensamblar y ejecutar (en DOSBox):
;       nasm resta.asm -o resta.com
;─────────────────────────────────────────────────────────────────────────

org 100h                   ; Programa .COM ⇒ punto de entrada = 0100h

;──────────────────────────
section .data
; Cadenas de texto (estan terminadas en '$' para AH=9)
prompt1 db 13,10,'Ingresa el primer numero (0-999): $'
prompt2 db 13,10,'Ingresa el segundo numero (0-999): $'
prompt3 db 13,10,'Ingresa el tercer numero (0-999): $'
msg     db 13,10,'Resultado: $'

; Buffer para INT 21h, funcion 0Ah  (primer byte = tamaño máx)
; → tamaño = 3 digitos + CR  (4)   + byte de longitud  = 5 bytes totales
buffer  db 4, 0, 0, 0, 0

;──────────────────────────
section .bss
num1   resw 1
num2   resw 1
num3   resw 1
result resw 1              ; Almacena  num1 − num2 − num3

;──────────────────────────
section .text

_start:
    ; ─── Leer primer numero ───────────────────────────────
    call ClearBuffer
    mov  ah,9
    mov  dx,prompt1
    int  21h                 ; Mostrar prompt1
    call ReadNumber          ; AX ← numero leido
    mov  [num1],ax

    ; ─── Leer segundo numero ──────────────────────────────
    call ClearBuffer
    mov  ah,9
    mov  dx,prompt2
    int  21h
    call ReadNumber
    mov  [num2],ax

    ; ─── Leer tercer numero ───────────────────────────────
    call ClearBuffer
    mov  ah,9
    mov  dx,prompt3
    int  21h
    call ReadNumber
    mov  [num3],ax

    ; ─── Calcular  num1 − num2 − num3  ─────────────────────
    mov  ax,[num1]
    sub  ax,[num2]
    sub  ax,[num3]
    mov  [result],ax

    ; ─── Mostrar resultado ─────────────────────────────────
    mov  ah,9
    mov  dx,msg
    int  21h                 ; Imprime literal "Resultado: "
    mov  ax,[result]         ; AX = valor a imprimir
    call PrintNumber
    ; (PrintNumber agrega LF al final)

    ; ─── Salir al DOS ──────────────────────────────────────
    mov  ax,4C00h
    int  21h

;=======================================================================
;  ReadNumber
;  ----------
;  Lee desde teclado (INT 21h funcion 0Ah) un numero de hasta 3 digitos
;  Devuelve: AX = valor numérico (0-999)
;  Registros alterados: AX, BX, CX, DX, SI
;=======================================================================
ReadNumber:
    call ClearBuffer
    mov  ah,0Ah              ; funcion leer cadena con buffer 0Ah
    lea  dx,buffer
    int  21h

    ; CX = numero de caracteres tecleados (byte [buffer+1])
    movzx cx,byte [buffer+1]
    cmp  cx,0
    je   error_exit          ; Enter

    xor  ax,ax               ; AX = acumulador = 0
    mov  si,buffer+2         ; SI → primer digito en el buffer

convertir:
    movzx dx,byte [si]       ; DX = caracter actual
    cmp  dx,0Dh              ; Enter
    je   fin_conversion
    sub  dx,'0'              ; ASCII → valor 0-9
    imul ax,ax,10            ; AX = AX*10  (desplazar)
    add  ax,dx               ; AX = AX + digito
    inc  si
    loop convertir           ; CX se decrementa hasta 0

fin_conversion:
    ret

;=======================================================================
;  PrintNumber
;  -----------
;  Imprime el valor que está en AX en formato decimal
;  Algoritmo: divide sucesivamente entre 10, guarda los restos
;             en la pila, luego los imprime en orden inverso.
;=======================================================================
PrintNumber:
    mov  bx,10               ; Divisor (base 10)
    xor  cx,cx               ; CX = contador de digitos

convertir_impresion:
    xor  dx,dx
    div  bx                  ; AX = AX/10 ,  DL = resto
    add  dl,'0'              ; digito → ASCII
    push dx                  ; Guardar en pila
    inc  cx                  ; Aumentar contador
    test ax,ax
    jnz  convertir_impresion

imprimir_digitos:
    pop  dx
    mov  ah,2
    int  21h                 ; Imprime DL
    loop imprimir_digitos

    ; Imprimir salto de línea
    mov  dl,13
    int  21h                 ; CR
    mov  dl,10
    int  21h                 ; LF
    ret

;=======================================================================
;  ClearBuffer
;  -----------
;  Reinicia la parte dinamica del buffer (longitud y datos)
;=======================================================================
ClearBuffer:
    mov byte [buffer+1],0    ; longitud = 0
    mov byte [buffer+2],0    ; limpiar byte 1
    mov byte [buffer+3],0    ; limpiar byte 2
    mov byte [buffer+4],0    ; limpiar byte 3
    ret

;=======================================================================
;  error_exit
;  ----------
;  Termina el programa con código de error 01h
;=======================================================================
error_exit:
    mov  ax,4C01h
    int  21h

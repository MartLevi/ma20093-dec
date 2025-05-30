; ───────────────────────────────────────────────────────────────────────
;  div32.asm
;  ------------
;  Programa en NASM (Linux 32-bits) que:
;     1. Lee dos enteros sin signo desde teclado
;     2. Realiza la división  (dividendo ÷ divisor)
;     3. Muestra el cociente y el residuo (módulo)
;
;  · Usa únicamente registros de 32 bits (EAX, EBX, ECX, EDX).
;  · Emplea las syscalls de Linux:  sys_read (EAX=3) y sys_write (EAX=4).
;  · Compilación:
;        nasm -f elf32 div.asm -o div.o
;        ld   -m elf_i386 div.o -o div
;        ./div
; ───────────────────────────────────────────────────────────────────────

section .data
    ; Mensajes de entrada
    prompt1    db "Ingresa el dividendo: ",0
    p1len      equ $-prompt1
    prompt2    db "Ingresa el divisor  : ",0
    p2len      equ $-prompt2

    ; mensajes de salida
    msg_q      db "Cociente = ",0
    qlen       equ $-msg_q
    msg_r      db "Residuo  = ",0
    rlen       equ $-msg_r

    ; Mensaje de error (unicamente cuando el divisor es 0)
    err0       db "Error: division por cero",10,0
    err0len    equ $-err0
    nl         db 10                ; caracter LF -> '\n'

section .bss
    ; Buffers de entrada (máx 19 dígitos + LF)
    buf1       resb 20
    buf2       resb 20

    ; Buffer temporal para imprimir números
    outbuf     resb 12              ; 10 dígitos + LF

    ; Variables en memoria
    num1       resd 1
    num2       resd 1

section .text
    global _start

; ------------------------------------------------------------
;  Wrapper: write_str
;  Entrada: EBX = fd (1 stdout), ECX = ptr, EDX = len
; ------------------------------------------------------------
write_str:                   ; EBX=fd, ECX=ptr, EDX=len
    mov eax,4
    int 0x80
    ret

; ------------------------------------------------------------
;  Wrapper: read_line
;  Lee hasta 'max' bytes o hasta Enter.
;  Entrada : ECX = buffer destino,  EDX = max bytes
;               (se descarta el resto del input si es mayor)
;  Salida  : EAX = bytes leídos
; ------------------------------------------------------------
read_line:                   ; ECX=buf, EDX=max
    mov eax,3
    xor ebx,ebx              ; stdin
    int 0x80
    ret

; ============================================================
;                        P R O G R A M A
; ============================================================
_start:
    ; ─── Leer DIVIDENDO ─────────────────────────────────────
    mov ebx,1                   ; stdout
    mov ecx,prompt1
    mov edx,p1len
    call write_str              ; imprimir prompt

    mov ecx,buf1
    mov edx,20
    call read_line              ; leer linea

    mov ecx,buf1
    call str_to_int             ; EAX = dividendo
    mov [num1],eax              ; guardar

     ; ─── Leer DIVISOR ───────────────────────────────────────
    mov ecx,prompt2
    mov edx,p2len
    mov ebx,1
    call write_str

    mov ecx,buf2
    mov edx,20
    call read_line

    mov ecx,buf2
    call str_to_int             ; EAX = divisor
    mov [num2],eax

    ; ─── Validar divisor ≠ 0 ───────────────────────────────
    cmp dword [num2],0
    je  div_zero

    ; ─── Division ──────────────────────────────────────────
    mov eax,[num1]            ; EDX:EAX / dword [num2]
    xor edx,edx
    div dword [num2]          ; / divisor
    ; Resultado:
    ;   EAX = cociente
    ;   EDX = residuo
    mov [num1],eax            ; reutilizamos num1 -> cociente
    mov [num2],edx            ; reutilizamos num2 -> residuo

    ; ─── Imprimir COCIENTE ─────────────────────────────────
    mov ebx,1
    mov ecx,msg_q
    mov edx,qlen
    call write_str

    mov eax,[num1]
    call int_to_str             ; prepara outbuf y len
    mov ebx,1
    mov edx,eax                 ; len
    call write_str              ; imprime cociente

     ; ─── Imprimir RESIDUO ─────────────────────────────────
    mov ebx,1
    mov ecx,msg_r
    mov edx,rlen
    call write_str

    mov eax,[num2]
    call int_to_str
    mov ebx,1
    mov edx,eax
    call write_str              ; imprime residuo

    ; salto de línea final
    mov ebx,1
    mov ecx,nl
    mov edx,1
    call write_str

    ; ─── Salir ────────────────────────────────────────────
exit_ok:
    mov eax,1
    xor ebx,ebx
    int 0x80

; ------------------------------------------------------------
;  Manejo de división por cero
; ------------------------------------------------------------
div_zero:
    mov ebx,1
    mov ecx,err0
    mov edx,err0len
    call write_str
    jmp exit_ok

; ------------------------------------------------------------
;  Rutina: str_to_int
;  Convierte una cadena ASCII (en ECX) terminada en LF
;  → EAX = valor entero sin signo (32 bits)
; ------------------------------------------------------------
str_to_int:
    xor eax,eax         ; resultado
.next:
    mov bl,[ecx]        ; leer byte
    cmp bl,10           ; LF?
    je  .done
    sub bl,'0'          ; convertir ASCII → dígito
    cmp bl,9
    ja  .done           ; si no es dígito, termina
    imul eax,eax,10     ; resultado *= 10
    add eax,ebx         ; resultado += dígito
    inc ecx
    jmp .next
.done: ret

; ------------------------------------------------------------
;  Rutina: int_to_str
;  Convierte EAX (sin signo) → cadena ASCII + LF
;  Salida:
;     ECX -> outbuf
;     EAX = longitud en bytes (incluye LF)
; ------------------------------------------------------------
int_to_str:
    mov ecx,outbuf              ; puntero de escritura

    ; Caso especial: número = 0
    cmp eax,0
    jne .conv
    mov byte [ecx],'0'
    mov byte [ecx+1],10         ; LF
    mov eax,2                   ; Longitud
    ret

.conv:
    mov ebx,10                  ; base 10
    xor esi,esi                 ; Contador de digitos en la pila

.push:                          ; genera dígitos al revés
    xor edx,edx
    div ebx                     ; EDX = dígito, EAX = quo
    add dl,'0'                  ; dígito ASCII
    push dx                     ; guardamos en la pila
    inc esi
    test eax,eax
    jnz .push

.pop:                           ; Volvamos el buffer en orden correcto
    pop dx
    mov [ecx],dl
    inc ecx
    dec esi
    jnz .pop

    mov byte [ecx],10           ; LF final
    sub ecx,outbuf
    inc ecx                     ; incluir LF en la longitud
    mov eax,ecx                 ; EAX = longitud
    mov ecx,outbuf              ; ECX listo para write_str
    ret

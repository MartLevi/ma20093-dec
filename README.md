# README – Documentación de Programas en Ensamblador

Este repositorio contiene **tres** programas en ensamblador x86 escritos para distintos entornos (DOS modo real y Linux 32 bits).  
Cada uno incluye:

* una **descripción general por bloque de código**, y  
* el **razonamiento** detrás de las decisiones de diseño (registros elegidos, formato de entrada/salida, etc.).

---

## Tabla de Contenidos

1. [Entorno de compilación](#entorno-de-compilación)  
2. [Programa 1 – `resta.asm`](#programa-1--restaasm)  
3. [Programa 2 – `mult.asm`](#programa-2--multasm)  
4. [Programa 3 – `div.asm`](#programa-3--divasm)  
5. [Consideraciones comunes](#consideraciones-comunes)

---

## Entorno de compilación

| Fuente       | CPU / Modo           | Comando sugerido                                     |
|--------------|----------------------|------------------------------------------------------|
| `resta.asm`  | 8086 – DOS (COM)     | `nasm -f bin resta.asm -o resta.com`                 |
| `mult.asm`   | 8086 – DOS (COM)     | `nasm -f bin mult.asm  -o mult.com`                  |
| `div.asm`    | i386 – Linux 32 bits | `nasm -f elf32 div.asm -o div.o && ld -m elf_i386 div.o -o div` |

> **Nota:** Los programas DOS se ejecutan cómodamente en **DOSBox**.

---

## Programa 1 – `resta.asm`

### Descripción general de bloques

| Bloque | Función | Detalles |
|--------|---------|----------|
| **Encabezado + `org 100h`** | Declara .COM; punto de entrada 0100h. | Simplifica la carga en DOS; un único segmento. |
| **`section .data`** | Cadenas de prompts y buffer para `INT 21h, func 0Ah`. | AH = 9 imprime cadenas terminadas en `$`; 0Ah usa formato `[max][len][data]`. |
| **`section .bss`** | Variables `num1..num3` (word) y `result` (word). | Cada número (0-999) cabe en 16 bits. |
| **`_start`** | Flujo principal: leer × 3 → restar → mostrar. | Subrutinas reutilizadas para mantener claridad. |
| **`ReadNumber`** | Convierte la cadena (0-999) en AX. | Multiplica por 10 y suma dígitos (clásico). |
| **`PrintNumber`** | Imprime AX decimal dividiendo por 10 y usando la pila. | No requiere bibliotecas externas. |
| **`ClearBuffer / error_exit`** | Gestiona el buffer y termina con código 1 si la entrada es inválida. | Evita caracteres residuales. |

#### Razonamiento

* Se usan registros **16 bits**: rango 0-999 excede un byte pero no justifica 32 bits.  
* `.COM` (segmento único) simplifica el modelo de memoria en DOS.  
* Separar las subrutinas evita duplicación.

---

## Programa 2 – `mult.asm`

### Descripción general de bloques

| Bloque | Función | Detalles |
|--------|---------|----------|
| Prompts + buffer | Entrada limitada a 0-255. | Compatible con `INT 21h, func 0Ah`. |
| Variables | `num1`, `num2` (byte) y `result` (word). | Producto máximo 65 025. |
| `ReadByte` | Convierte la cadena, valida `≤ 255`; deja AL limpio (AH = 0). | Corrige el bug original que ponía AL = 0. |
| **Multiplicación** | `AL × BL` → `AX` usando **`mul BL`**. | Operandos de 8 bits; producto en 16 bits. |
| Rutina de impresión | Mismo algoritmo que en `resta.asm`. | Cohesión entre programas. |

#### Razonamiento

* Se respeta la restricción “operandos en **registros de 8 bits**”.  
* Permitir resultado de 16 bits evita truncar datos (255 × 255 = 65 025).  
* Reutilizar rutinas ahorra espacio y asegura coherencia.

---

## Programa 3 – `div.asm`

### Descripción general de bloques

| Bloque | Función | Detalles |
|--------|---------|----------|
| `.data` | Prompts y mensajes terminados en NUL. | Convención Linux. |
| `.bss` | Buffers de entrada (`buf1`, `buf2`) + `outbuf`; variables `num1`, `num2`. | `outbuf` permite hasta 10 dígitos + LF. |
| `write_str` / `read_line` | Wrappers ligeros sobre `sys_write` / `sys_read`. | Facilitan un flujo limpio.|
| `str_to_int` | ASCII → EAX (32 bits). | Maneja todo el rango `unsigned`. |
| `int_to_str` | EAX → cadena decimal (en `outbuf`). | Una sola syscall para imprimir. |
| Flujo principal | Leer → convertir → validar → `xor edx,edx ; div`. | Requiere limpiar EDX antes de la división. |
| División por 0 | Mensaje y `exit(0)`. | Previene excepción del kernel. |

#### Razonamiento

* Linux 32 bits facilita usar registros de 32 bits nativos (`EDX:EAX`).  
* Mantener la lógica de E/S separada de la aritmética mejora la legibilidad.  
* `int 0x80` es la vía directa sin depender de `libc`.

---

## Consideraciones comunes

| Tema | Elección | Motivo |
|------|----------|--------|
| **Entrada** | DOS: `INT 21h, func 0Ah` / Linux: `sys_read` | Evita BIOS y `stdio`. |
| **Conversión ASCII → decimal** | Multiplicador × 10 + suma dígitos | Simple, portable y sin tablas. |
| **Impresión decimal** | División entre 10 + pila | No requiere otras funciones. |
| **Errores** | `int 21h / 4C01h` en DOS; mensaje + `exit` en Linux | Señaliza al SO que algo falló. |

---

### Uso rápido

```bash
# DOS (.COM) – dentro de DOSBox
nasm -f bin resta.asm -o resta.com
resta

nasm -f bin mult.asm -o mult.com
mult

# Linux 32-bit
nasm -f elf32 div.asm -o div.o
ld -m elf_i386 div.o -o div
./div

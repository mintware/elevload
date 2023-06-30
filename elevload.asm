;
; Loader for Elevators from Hell 1.1s (1992)
;
; Copyright (c) 2023 Vitaly Sinilin
;
; 30 June 2023
;

cpu 8086
[map all elevload.map]

%macro res_fptr 0
.off		resw	1
.seg		resw	1
%endmacro

PSP_SZ		equ	100h
STACK_SZ	equ	64

section .text

		org	PSP_SZ

		jmp	short main
byemsg		db	0Dh,"Visit http://sinil.in/mintware/elevatorsfromhell/$"

main:		mov	sp, __stktop
		mov	bx, sp
		mov	cl, 4
		shr	bx, cl				; new size in pars
		mov	ah, 4Ah				; resize memory block
		int	21h

		mov	bx, __bss_size
.zero_bss:	dec	bx
		mov	byte [__bss + bx], bh
		jnz	.zero_bss

		mov	[cmdtail.seg], cs		; pass cmd tail from
		mov	word [cmdtail.off], 80h		; our PSP

		mov	ax, 3521h			; read int 21h vector
		int	21h				; es:bx <- cur handler
		mov	[int21.seg], es			; save original
		mov	[int21.off], bx			; int 21h vector

		mov	dx, int_handler			; setup our own
		mov	ax, 2521h			; handler for int 21h
		int	21h				; ds:dx -> new handler

		mov	dx, exe
		push	ds
		pop	es
		mov	bx, parmblk
		mov	ax, 4B00h			; exec
		int	21h

		jnc	.success
		call	uninstall
		mov	dx, errmsg
		jmp	short .exit

.success:	mov	dx, byemsg
.exit:		mov	ah, 9
		int	21h
		mov	ah, 4Dh				; read errorlevel
		int	21h				; errorlevel => AL
		mov	ah, 4Ch				; exit
		int	21h

;------------------------------------------------------------------------------

int_handler:	cmp	ah, 25h
		jne	.legacy
		push	ax
		push	dx

		; Skip shareware screen.
		mov	byte [6079h], 0B8h   ; mov ax, 2353 (_out)
		mov	word [607Ah], 2353h
		mov	word [607Ch], 0E0FFh ; jmp ax

		call	uninstall	; restore original vector of int 21h
		pop	dx
		pop	ax

.legacy:	jmp	far [cs:int21]

;------------------------------------------------------------------------------

uninstall:	push	ds
		lds	dx, [cs:int21]
		mov	ax, 2521h
		pushf
		call	far [cs:int21]
		pop	ds
		ret

;------------------------------------------------------------------------------

errmsg		db	"Unable to exec original "
exe		db	"elevhell.exe",0,"$"


section .bss follows=.text nobits

__bss		equ	$
int21		res_fptr
parmblk		resw	1				; environment seg
cmdtail		res_fptr				; cmd tail
		resd	1				; first FCB address
		resd	1				; second FCB address
__bss_size	equ	$-__bss


section .stack align=16 follows=.bss nobits

		resb	(STACK_SZ+15) & ~15		; make sure __stktop
__stktop	equ	$				; is on segment boundary

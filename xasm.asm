; X-Assembler

	IDEAL
	P386
	MODEL	TINY
	CODESEG
	ORG	100h
start:
	db	3072 dup(0)	;for packing

l_lab	=	50000
l_org	=	1000*2
l_icl	=	16*6

;北北北北北北北北北北北北北北北北北北北北北

eol	equ	13,10
eot	equ	13,10,'$'

MACRO	lda	_rg
	xchg	ax, _rg	; in meaning 'mov ax, _rg', but xchg is shorter
	ENDM

MACRO	sta	_rg
	xchg	_rg, ax	; in meaning 'mov _rg, ax', but xchg is shorter
	ENDM

MACRO	dos	_func
IFNB	<_func>
IF	_func and 0ff00h
	mov	ax, _func
ELSE
	mov	ah, _func
ENDIF
ENDIF
	int	21h
	ENDM

MACRO	file	_func, _errtx
	mov	bp, offset _errtx
IFNB	<_func>
IF	_func and 0ff00h
	mov	ax, _func
ELSE
	mov	ah, _func
ENDIF
ENDIF
	call	xdisk
	ENDM


MACRO	print	_text
IFNB	<_text>
	mov	dx, offset _text
ENDIF
	dos	9
	ENDM

MACRO	dtext	_text
	db	'&_text'
	ENDM

MACRO	cmd	_oper
_tp	SUBSTR	<_oper>, 1, 3
	dtext	%_tp
_tp	SUBSTR	<_oper>, 4, 2
_tp	CATSTR	<0>, &_tp, <h>
	db	&_tp
_tp	SUBSTR	<_oper>, 6
	dw	_tp
	ENDM

;北北北北北北北北北北北北北北北北北北北北北

	print	hello
	mov	di, 81h
	movzx	cx, [di-1]
	jcxz	usg
	mov	al, ' '
	repe	scasb
	je	usg
	dec	di
	inc	cx
	mov	[fnad], di
	mov	al, '?'
	repne	scasb
	jne	nousg

usg:	print	usgtxt
	dos	4c01h

nousg:	mov	si, di
srchex:	dec	si
	cmp	[byte si], '\'
	je	addext
	cmp	[byte si], '.'
	je	extexs
	cmp	si, 82h
	jnb	srchex
addext:	mov	si, di
	mov	ax, 'a.'
	stosw
	mov	ax, 'xs'
	stosw
extexs:	inc	si
	mov	[fnen], si
	mov	[di], ch	;0

begin:	mov	si, [fnad]
	mov	di, offset fname
ldname:	lodsb
	stosb
	test	al, al
	jnz	ldname
	cmp	[pass], 1
	jb	pass1

	mov	di, [fnen]
	mov	[dword di], 'moc'
	mov	dx, [fnad]
	xor	cx, cx
	file	3ch, e_creat
	mov	[ohand], ax
	mov	ax, 0ffffh
	call	putwor
	mov	[orgvec], offset t_org
	xor	ax, ax
	call	pheadr
	mov	ax, [laben]
	mov	[p1laben], ax
	mov	[pslaben], offset t_lab

pass1:	mov	[origin], 0

opfile:	mov	bx, [filidx]
	cmp	bx, offset t_icl+l_icl-6
	mov	ax, offset e_icl
	jnb	panica
	mov	[dword bx+6+2], 0
	add	[filidx], 6
	mov	dx, offset fname
	file	3d00h, e_open
	mov	bx, [filidx]
	mov	[bx], ax

main:	test	[eoflag], 0ffh
	jnz	filend
	mov	bx, [filidx]
	inc	[dword bx+2]
	inc	[lines]
	mov	di, offset line-1

gline1:	cmp	di, offset line+255
	jnb	linlon
	mov	bx, [filidx]
	mov	bx, [bx]
	mov	cx, 1
	lea	dx, [di+1]
	push	dx
	file	3fh, e_read
	pop	di
	test	ax, ax
	jz	eof
	cmp	[byte di], 0ah
	jne	gline1
	jmp	syntax

eof:	inc	[eoflag]
	mov	[word di+1], 0a0dh

syntax:	mov	si, offset line

	mov	al, [si]
	cmp	al, 0dh
	je	main
	cmp	al, '*'
	je	main
	cmp	al, ';'
	je	main
	cmp	al, '|'
	je	main
	mov	[labvec], 0
	cmp	al, ' '
	je	s_cmd
	cmp	al, 9
	je	s_cmd
	call	rlabel
	jc	asilab
	cmp	bx, [p1laben]
	jnb	ltwice
	mov	[pslaben], bx
	inc	[labvec]
	jmp	s_cmd
ltwice:	mov	ax, offset e_twice
	jmp	panica
asilab:	push	si
	mov	si, offset tlabel
	mov	di, [laben]
	scasw
	mov	[labvec], di
	mov	ax, [origin]
	stosw
	mov	ax, di
	add	ax, dx
	cmp	ax, offset t_lab+l_lab
	jnb	tmlab
	mov	cx, dx
	rep	movsb
	mov	ax, di
	xchg	ax, [laben]
	stosw
	pop	si

s_cmd:	call	spaces
	lodsw
	and	ax, 0dfdfh
	mov	dx, ax
	lodsb
	and	al, 0dfh
	mov	di, offset comtab
	mov	bx, 32*6
sfcmd1:	mov	ah, al
	mov	cx, dx
	sub	ah, [di+bx+2]
	sbb	ch, [di+bx+1]
	sbb	cl, [di+bx]
	jb	sfcmd3
	or	ah, ch
	or	ah, cl
	jnz	sfcmd2

	mov	al, [di+bx+3]
	mov	[cod], al
	call	[word di+4+bx]
	lodsb
	cmp	al, 0dh
	je	main
	cmp	al, ' '
	je	main
	cmp	al, 9
	je	main
	mov	ax, offset e_xtra
	jmp	panica

sfcmd2:	add	di, bx
	cmp	di, offset comend
	jb	sfcmd3
	sub	di, bx
sfcmd3:	shr	bx, 1
	cmp	bl, 3
	ja	sfcmd1
	mov	bl, 0
	je	sfcmd1
	mov	ax, offset e_inst
	jmp	panica

uneol:	mov	ax, offset e_uneol
	jmp	panica

ilchar:	mov	ax, offset e_char
	jmp	panica

filend:	mov	[eoflag], 0
	cmp	[pass], 1
	jnb	noforg
	call	putorg
noforg:	mov	bx, [filidx]
	mov	bx, [bx]
	file	3eh, e_read
	sub	[filidx], 6
	cmp	[filidx], offset t_icl
	jnb	main
	inc	[pass]
	cmp	[pass], 2
	jb	begin

	mov	bx, [ohand]
	file	3eh, e_writ
	mov	eax, [lines]
	shr	eax, 1
	call	pridec
	print	lintxt
	mov	eax, [bytes]
	call	pridec
	print	byttxt
	dos	4c00h

tmlab:	mov	ax, offset e_tlab
	jmp	panica

linlon:	mov	ax, offset e_long
panica:	mov	[errad], ax
panic:	cmp	[errad], offset lislin
	jb	panifn
	mov	si, offset line-1
prilin:	inc	si
	mov	dl, [si]
	dos	2
	cmp	[byte si], 0ah
	jne	prilin
panifn:	mov	dx, offset fname
	mov	di, dx
	mov	ch, -1
	xor	al, al
	repne	scasb
	mov	[byte di-1], ' '
	mov	[word di], '$('
	print
	mov	bx, [filidx]
	mov	eax, [bx+2]
	call	pridec
	print	errtxt
	mov	dx, [errad]
	print
	dos	4c01h

xdisk:	mov	[errad], bp
	dos
	jc	panic
	ret

putwor:	push	ax
	call	putbyt
	pop	ax
	mov	al, ah
putbyt:	mov	cx, 1
	cmp	[pass], cx
	jb	putx
	mov	[obyte], al
	mov	dx, offset obyte
	mov	bx, [ohand]
	file	40h, e_writ
	inc	[bytes]
putx:	ret

savwor:	inc	[origin]
	inc	[origin]
	jmp	putwor

savbyt:	inc	[origin]
	jmp	putbyt

; Wyswietla dziesietnie EAX
pridec:	mov	di, offset dectxt+10
	mov	ebx, 10
pride1:	cdq
	div	ebx
	add	dl, '0'
	dec	di
	mov	[di], dl
	test	eax, eax
	jnz	pride1
	mov	dx, di
	print
	ret

; Omija spacje i tabulatory
spaces:	lodsb
	cmp	al, ' '
	je	spaces
	cmp	al, 9
	je	spaces
	cmp	al, 0dh
	je	uneol
	dec	si
rstret:	ret

; Czyta lancuch i zapisuje do [di]
rstr:	lodsb
	cmp	al, "'"
	jne	strer
	push	di
rstr1:	lodsb
	cmp	al, 0dh
	je	uneol
	stosb
	cmp	al, "'"
	jne	rstr1
	lodsb
	cmp	al, "'"
	je	rstr1
	dec	si
	lea	cx, [di-1]
	pop	di
	sub	cx, di
	jnz	rstret

strer:	mov	ax, offset e_str
	jmp	panica

; Przepisuje etykiete do tlabel, szuka w t_lab
; na wyjsciu: dx-dlugosc etykiety
; C=0: znaleziona, bx=adres wpisu
; C=1: nie ma jej
rlabel:	mov	di, offset tlabel
	mov	[byte di], 0
ldlab1:	lodsb
	cmp	al, '0'
	jb	sflab0
	cmp	al, '9'
	jbe	ldlab2
	cmp	al, 'A'
	jb	sflab0
	cmp	al, 'Z'
	jbe	ldlab2
	cmp	al, '_'
	je	ldlab2
	cmp	al, 'a'
	jb	sflab0
	cmp	al, 'z'
	ja	sflab0
	add	al, 'A'-'a'
ldlab2:	stosb
	jmp	ldlab1
sflab0:	mov	dx, di
	mov	di, offset tlabel
	cmp	[byte di], 'A'
	jb	ilchar
	sub	dx, di
	dec	si
	push	si
	mov	bx, [laben]
sflab1:	cmp	bx, offset t_lab+4
	jb	sflabn
	lea	cx, [bx-4]
	mov	bx, [bx]
	sub	cx, bx
	cmp	cx, dx
	jne	sflab1
	lea	si, [bx+4]
	mov	di, offset tlabel
	repe	cmpsb
	jne	sflab1
	clc
sflabn:	pop	si
	ret

getval:	call	spaces
; Czyta wyrazenie i zwraca jego wartosc w [val] (C=1 wartosc nieokreslona)
value:	mov	[val], 0
	mov	[undef], 0
	lodsb
	cmp	al, '-'
	je	valuem
	dec	si
	mov	al, '+'

valuem:	mov	[oper], al
	xor	dx, dx
	mov	ch, -1
	lodsb
	cmp	al, 0dh
	je	uneol
	cmp	al, '*'
	je	valorg
	cmp	al, "'"
	je	valchr
	mov	bx, 16
	cmp	al, '$'
	je	rdnum3
	mov	bl, 2
	cmp	al, '%'
	je	rdnum3
	mov	bl, 10
	cmp	al, '0'
	jb	ilchar
	cmp	al, '9'
	ja	vlabel

rdnum1:	cmp	al, 'A'
	jb	rdnum2
	and	al, 0dfh
	cmp	al, 'A'
	jb	value0
	add	al, '0'+10-'A'
rdnum2:	sub	al, '0'
	cmp	al, bl
	jnb	value0
	movzx	cx, al
	mov	ax, dx
	mul	bx
	add	ax, cx
	adc	dx, dx
	jnz	toobig
	sta	dx
rdnum3:	lodsb
	jmp	rdnum1

vlabel:	dec	si
	call	rlabel
	jnc	vlabkn
	cmp	[pass], 1
	jb	vlabun
	jmp	unknow
vlabkn:	mov	dx, [bx+2]
	cmp	bx, [pslaben]
	jbe	value1
vlabun:	mov	[undef], 0ffh
	jmp	value1

valchr:	lodsb
	cmp	al, 0dh
	je	uneol
	cmp	al, "'"
	jne	valch1
	lodsb
	cmp	al, "'"
	jne	strer
valch1:	movzx	dx, al
	lodsb
	cmp	al, "'"
	jne	strer
	cmp	[byte si], '*'
	jne	value1
	inc	si
	xor	dl, 80h
	jmp	value1

valorg:	mov	dx, [origin]
	jmp	value1

value0:	dec	si
	test	ch, ch
	jnz	ilchar
value1:	cmp	[oper], '-'
	jne	value2
	neg	dx
value2:	add	[val], dx
	
	lodsb
	cmp	al, '+'
	je	valuem
	cmp	al, '-'
	je	valuem
	dec	si
	add	[undef], 1
	ret

toobig:	mov	ax, offset e_nbig
	jmp	panica

; Pobiera operand rozkazu i rozpoznaje tryb adresowania
getadr:	call	spaces
	lodsb
	xor	dl, dl
	cmp	al, '@'
	je	getadx
	inc	dx
	cmp	al, '#'
	je	getad1
	mov	dl, 10
	cmp	al, '<'
	je	getad1
	inc	dx
	cmp	al, '>'
	je	getad1
	mov	dl, 8
	cmp	al, '('
	je	getad1
	dec	si
	mov	dl, 2
getad1:	mov	[amod], dl
	call	value
	mov	al, [byte high val]
	jnc	getad2
	sbb	al, al
getad2:	mov	dl, [amod]
	cmp	dl, 1
	je	getart
	cmp	dl, 10
	jnb	getalh
	cmp	dl, 8
	je	getaid
	cmp	al, 1
	adc	dl, 0
	lodsw
	and	ah, 0dfh
	cmp	ax, 'X,'
	je	getaxi
	cmp	ax, 'Y,'
	je	getayi
	dec	si
	dec	si
	jmp	getadx
getalh:	mov	bx, offset val
	je	getal1
	inc	bx
getal1:	movzx	ax, [bx]
	mov	[val], ax
	mov	dl, 1
	jmp	getadx
getaid:	lodsb
	cmp	al, ','
	je	getaix
	cmp	al, ')'
	jne	mbrack
	lodsw
	and	ah, 0dfh
	cmp	ax, 'Y,'
	je	getaiy
	mov	dl, 10
	dec	si
	dec	si
	jmp	getadx
getaix:	lodsw
	and	al, 0dfh
	cmp	ax, ')X'
	je	getart
	jmp	ilchar
getayi:	inc	dx
	inc	dx
getaxi:	inc	dx
getaiy:	inc	dx
getadx:	mov	[amod], dl
getart:	mov	al, [amod]
putret:	ret
	
p_imp	=	savbyt

p_acc:	call	getadr
	cmp	al, 7
	jne	acc1
	dec	ax
	mov	[amod], al
acc1:	mov	bx, offset acctab
	xlat
	test	al, al
	jz	ilamod
	or	al, [cod]
	cmp	al, 89h
	jne	putcmd
ilamod:	mov	ax, offset e_amod
	jmp	panica

p_srt:	call	getadr
	cmp	al, 6
	jnb	ilamod
	cmp	al, 1
	je	ilamod
	mov	bx, offset srttab
	xlat
	or	al, [cod]
	cmp	al, 0c0h
	je	ilamod
	cmp	al, 0e0h
	je	ilamod
	jmp	putcmd
	
p_ldi:	call	getadr
	cmp	al, 1
	jb	ilamod
	cmp	al, 4
	jb	ldi1
	and	al, 0feh
	xor	al, [cod]
	cmp	al, 0a4h
	jne	ilamod
	mov	al, [amod]
ldi1:	mov	bx, offset lditab
	xlat
putcod:	or	al, [cod]
putcmd:	call	savbyt
	mov	al, [amod]
	mov	bx, offset lentab
	xlat
	cmp	al, 2
	jb	putret
	mov	ax, [val]
	jne	savwor
	cmp	[pass], 1
	jb	putcm1
	test	ah, ah
	jnz	toobig
putcm1:	jmp	savbyt

p_sti:	call	getadr
	cmp	al, 2
	jb	ilamod
	cmp	al, 3
	jb	cod8
	je	cod0
	and	al, 0feh
	xor	al, [cod]
	cmp	al, 80h
	jne	ilamod
	or	[amod], 1
	mov	al, 10h
	jmp	putcod
cod8:	mov	al, 8
	jmp	putcod
cod0:	xor	al, al
	jmp	putcod

p_cpi:	call	getadr
	cmp	al, 1
	jb	ilamod
	cmp	al, 4
	jnb	ilamod
	cmp	al, 2
	jb	cod0
	je	cod8
	mov	al, 4
	jmp	putcod

p_bra:	call	getadr
	cmp	[pass], 1
	jb	bra1
	mov	ax, [val]
	sub	ax, [origin]
	add	ax, 7eh
	test	ah, ah
	jnz	toofar
	add	al, 80h
	mov	[byte val], al
	mov	al, [cod]
bra1:	call	savbyt
	mov	al, [byte val]
	jmp	savbyt

toofar:	mov	ax, offset e_bra
	jmp	panica

p_jsr:	call	getadr
	and	al, 0feh
	mov	[amod], al
	cmp	al, 2
	jne	ilamod
	mov	al, 20h
	jmp	putcmd

p_bit:	call	getadr
	cmp	al, 2
	mov	al, 2ch
	je	putcmd
	cmp	[amod], 3
	jne	ilamod
	mov	al, 24h
	jmp	putcmd

p_jmp:	call	getadr
	cmp	al, 10
	mov	al, 6ch
	je	putcmd
	and	[amod], 0feh
	cmp	[amod], 2
	jne	ilamod
	mov	al, 4ch
	jmp	putcmd

p_opt:	call	getval
	jc	unknow
	mov	ax, [val]
	test	ah, ah
	jnz	toobig
	ret

p_equ:	mov	di, [labvec]
	cmp	di, 1
	jb	nolabl
	je	equret
	mov	[word di], 0
	call	getval
	mov	di, [labvec]
	jc	lbund
	mov	ax, [val]
	stosw
equret:	ret

lbund:	cmp	[pass], 1
	jnb	unknow
	lea	ax, [di-2]
	mov	[laben], ax
	ret

nolabl:	mov	ax, offset e_label
	jmp	panica

p_org:	call	getval
	jc	unknow
	cmp	[pass], 1
	jnb	org1
	call	putorg
	stc
org1:	mov	ax, [val]
	mov	[origin], ax
	jc	pheart
pheadr:	mov	bx, [orgvec]
	cmp	ax, [bx]
	je	pheart
	call	putwor
	mov	bx, [orgvec]
	mov	ax, [bx]
	dec	ax
	call	putwor
pheart:	add	[orgvec], 2
	ret

putorg:	mov	bx, [orgvec]
	cmp	bx, offset t_org+l_org-2
	jnb	tmorgs
	mov	ax, [origin]
	mov	[bx], ax
	ret

tmorgs:	mov	ax, offset e_orgs
	jmp	panica

p_dta:	call	spaces
dta1:	lodsb
	cmp	al, 0dh
	je	uneol
	and	al, 0dfh
	mov	[cod], al
	cmp	al, 'A'
	je	dtan1
	cmp	al, 'B'
	je	dtan1
	cmp	al, 'L'
	je	dtan1
	cmp	al, 'H'
	je	dtan1
	cmp	al, 'C'
	je	dtat1
	cmp	al, 'D'
	je	dtat1
	jmp	ilchar

dtan1:	lodsb
	cmp	al, '('
	jne	mbrack

dtan2:	call	value
	jc	dtan3
	cmp	[pass], 1
	jb	dtan4
	mov	al, [cod]
	cmp	al, 'B'
	je	dtanb
	cmp	al, 'L'
	je	dtanl
	cmp	al, 'H'
	je	dtanh
	mov	ax, [val]
	call	savwor
	jmp	dtanx

dtanb:	mov	ax, [val]
	test	ah, ah
	jz	dtans
	jmp	toobig

dtanl:	mov	al, [byte low val]
	jmp	dtans

dtanh:	mov	al, [byte high val]

dtans:	call	savbyt
	jmp	dtanx

dtan3:	cmp	[pass], 1
	jnb	unknow

dtan4:	cmp	[cod], 'A'+1
	adc	[origin], 1
	
dtanx:	lodsb
	cmp	al, ','
	je	dtan2
	cmp	al, ')'
	je	dtanxt

mbrack:	mov	ax, offset e_brack
	jmp	panica

unknow:	mov	ax, offset e_uknow
	jmp	panica

dtat1:	mov	di, offset tlabel
	call	rstr
	lodsb
	mov	ah, 80h
	cmp	al, '*'
	je	dtat2
	dec	si
	xor	ah, ah
dtat2:	push	si
	mov	si, di
dtatm:	lodsb
	xor	al, ah
	cmp	[cod], 'D'
	jne	ascinx
	mov	dl, 60h
	and	dl, al
	jz	ascin1
	cmp	dl, 60h
	je	ascinx
	sub	al, 60h
ascin1:	add	al, 40h
ascinx:	push	ax cx si
	call	savbyt
	pop	si cx ax
	loop	dtatm
	pop	si
dtanxt:	lodsb
	cmp	al, ','
	je	dta1
	dec	si
	ret

p_icl:	call	spaces
	mov	di, offset fname
	call	rstr
	mov	[byte di], 0
	jmp	opfile

p_end:	pop	ax
	jmp	filend

lentab	db	1,2,3,2,3,2,3,2,2,2,3
acctab	db	0,9,0dh,5,1dh,15h,19h,19h,1,11h,0
srttab	db	0ah,0,0eh,6,1eh,16h
lditab	db	0,0,0ch,4,1ch,14h,1ch,14h

comtab:	cmd	ADC60p_acc
	cmd	AND20p_acc
	cmd	ASL00p_srt
	cmd	BCC90p_bra
	cmd	BCSb0p_bra
	cmd	BEQf0p_bra
	cmd	BIT2cp_bit
	cmd	BMI30p_bra
	cmd	BNEd0p_bra
	cmd	BPL10p_bra
	cmd	BRK00p_imp
	cmd	BVC50p_bra
	cmd	BVS70p_bra
	cmd	CLC18p_imp
	cmd	CLDd8p_imp
	cmd	CLI58p_imp
	cmd	CLVb8p_imp
	cmd	CMPc0p_acc
	cmd	CPXe0p_cpi
	cmd	CPYc0p_cpi
	cmd	DECc0p_srt
	cmd	DEXcap_imp
	cmd	DEY88p_imp
	cmd	DTA00p_dta
	cmd	END00p_end
	cmd	EOR40p_acc
	cmd	EQU00p_equ
	cmd	ICL00p_icl
	cmd	INCe0p_srt
	cmd	INXe8p_imp
	cmd	INYc8p_imp
	cmd	JMP4cp_jmp
	cmd	JSR20p_jsr
	cmd	LDAa0p_acc
	cmd	LDXa2p_ldi
	cmd	LDYa0p_ldi
	cmd	LSR40p_srt
	cmd	NOPeap_imp
	cmd	OPT00p_opt
	cmd	ORA00p_acc
	cmd	ORG00p_org
	cmd	PHA48p_imp
	cmd	PHP08p_imp
	cmd	PLA68p_imp
	cmd	PLP28p_imp
	cmd	ROL20p_srt
	cmd	ROR60p_srt
	cmd	RTI40p_imp
	cmd	RTS60p_imp
	cmd	SBCe0p_acc
	cmd	SEC38p_imp
	cmd	SEDf8p_imp
	cmd	SEI78p_imp
	cmd	STA80p_acc
	cmd	STX86p_sti
	cmd	STY84p_sti
	cmd	TAXaap_imp
	cmd	TAYa8p_imp
	cmd	TSXbap_imp
	cmd	TXA8ap_imp
	cmd	TXS9ap_imp
	cmd	TYA98p_imp
comend:

hello	db	'X-Assembler 1.0 by Fox/Taquart',eot
usgtxt	db	'Give a source filename. Default extension is .ASX.',eol
	db	'Destination will have the same name and .COM extension.',eot
lintxt	db	' lines assembled',eot
byttxt	db	' bytes written',eot
dectxt	db	10 dup(' '),'$'
errtxt	db	') ERROR: $'
e_open	db	'Can''t open file',eot
e_read	db	'Disk read error',eot
e_creat	db	'Can''t write destination',eot
e_writ	db	'Disk write error',eot
e_icl	db	'Too many files nested',eot
e_long	db	'Line too long',eot
lislin:
e_uneol	db	'Unexpected eol',eot
e_char	db	'Illegal character',eot
e_twice	db	'Label declared twice',eot
e_inst	db	'Illegal instruction',eot
e_nbig	db	'Number too big',eot
e_uknow	db	'Unknown value',eot
e_xtra	db	'Extra characters on line',eot
e_label	db	'Label name required',eot
e_str	db	'String error',eot
e_orgs	db	'Too many ORGs',eot
e_brack	db	'Missing bracket',eot
e_tlab	db	'Too many labels',eot
e_amod	db	'Illegal adressing mode',eot
e_bra	db	'Branch too far',eot

pass	dw	0
lines	dd	0
bytes	dd	0
filidx	dw	t_icl-6
laben	dw	t_lab
p1laben	dw	0
pslaben	dw	-1
orgvec	dw	t_org
eoflag	db	0
ohand	dw	?
errad	dw	?
val	dw	?
oper	db	?
cod	db	?
amod	db	?
origin	dw	?
obyte	db	?
undef	db	?
labvec	dw	?
fnad	dw	?
fnen	dw	?

fname	db	80 dup(?)
line	db	258 dup(?)
tlabel	db	256 dup(?)
t_icl	db	l_icl dup(?)
t_org	db	l_org dup(?)
t_lab	db	l_lab+4 dup(?)

	ENDS
	END	start
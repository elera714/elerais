;************************************************************************
;
;       Kodlayan: Fatih KILI�
;       Telif Bilgisi: haklar.txt dosyas�na bak�n�z
;
;       Dosya Ad�: write.inc
;       Dosya ��levi: ger�ek modda ekrana yaz�m i�levlerini i�erir
;
;       G�ncelleme Tarihi: 17/10/2012
;
;************************************************************************

;========================================================================
;
;i�lev  : print_char
;tan�m  : text modunda ekrana karakter yazar
;giri�  : al = karakter
;��k��  : yok
;
;========================================================================
align 4
print_char:
	mov	ah,0xe
	int	0x10
	ret

;========================================================================
;
;i�lev  : print_text
;tan�m  : text modunda ekrana string de�eri yazar
;giri�  : si = string adresi
;��k��  : yok
;
;========================================================================
align 4
print_text:
@@:
	lodsb
	or	al,al
	jz	@f
	mov	ah,0x0e
	int	0x10
	jmp	@b
@@:
ret

;========================================================================
;
;i�lev  : print_crlf
;tan�m  : text modunda sat�r ba�� yapar
;giri�  : yok
;��k��  : yok
;
;========================================================================
align 4
print_crlf:
	mov	ax,0x0e0d
	int	0x10
	mov	ax,0x0e0a
	int	0x10
	ret

;========================================================================
;
;i�lev  : print_hex
;tan�m  : text modunda ekrana hexadesimal de�er yazar
;giri�  : eax = hexadesimal de�er, cx = yaz�lacak hane say�s� (1..8)
;��k��  : yok
;
;========================================================================
align 4
print_hex:

	;yaz�lacak hane (dijit) say�s�n� kontrol et (1..8 aras�)
	;----------------------------------------------------------------
	mov	edx,eax
	and	cx,1111b
	cmp	cx,0
	ja	@f
	mov	cx,8
	jmp	.shift_number
@@:
	cmp	cx,8
	jbe	.shift_number
	mov	cx,8

	;yaz�lmayacak haneleri atla
	;----------------------------------------------------------------
.shift_number:
	push	cx
	mov	ax,8
	sub	ax,cx
	mov	cx,ax
	shl	cx,2
	rol	edx,cl
	pop	cx

	;say�sal de�eri ascii de�ere �evir
	;----------------------------------------------------------------
.conv_ascii:
	rol	edx,4
	mov	al,dl
	and	al,0xf

	cmp	al,9
	jbe	.value09
.valueAF:
	add	al,55
	jmp	.print
.value09:
	add	al,48
.print:
	mov	ah,0x0e
	int	0x10
	loop	.conv_ascii
	ret
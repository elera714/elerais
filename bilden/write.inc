;************************************************************************
;
;       Kodlayan: Fatih KILIÇ
;       Telif Bilgisi: haklar.txt dosyasýna bakýnýz
;
;       Dosya Adý: write.inc
;       Dosya Ýþlevi: gerçek modda ekrana yazým iþlevlerini içerir
;
;       Güncelleme Tarihi: 17/10/2012
;
;************************************************************************

;========================================================================
;
;iþlev  : print_char
;taným  : text modunda ekrana karakter yazar
;giriþ  : al = karakter
;çýkýþ  : yok
;
;========================================================================
align 4
print_char:
	mov	ah,0xe
	int	0x10
	ret

;========================================================================
;
;iþlev  : print_text
;taným  : text modunda ekrana string deðeri yazar
;giriþ  : si = string adresi
;çýkýþ  : yok
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
;iþlev  : print_crlf
;taným  : text modunda satýr baþý yapar
;giriþ  : yok
;çýkýþ  : yok
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
;iþlev  : print_hex
;taným  : text modunda ekrana hexadesimal deðer yazar
;giriþ  : eax = hexadesimal deðer, cx = yazýlacak hane sayýsý (1..8)
;çýkýþ  : yok
;
;========================================================================
align 4
print_hex:

	;yazýlacak hane (dijit) sayýsýný kontrol et (1..8 arasý)
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

	;yazýlmayacak haneleri atla
	;----------------------------------------------------------------
.shift_number:
	push	cx
	mov	ax,8
	sub	ax,cx
	mov	cx,ax
	shl	cx,2
	rol	edx,cl
	pop	cx

	;sayýsal deðeri ascii deðere çevir
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
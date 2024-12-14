;************************************************************************
;
;       Kodlayan: Fatih KILIÇ
;       Telif Bilgisi: haklar.txt dosyasýna bakýnýz
;
;       Dosya Adý: a20.asm
;       Dosya Ýþlevi: a20 adres hattý iþlevlerini içerir
;
;       Güncelleme Tarihi: 17/10/2012
;
;************************************************************************

;========================================================================
;
;iþlev  : enable_a20
;taným  : adres yolunun 20. bitini aktifleþtirir
;çýkýþ  : yok
;
;========================================================================
align 4
enable_a20:

	;kesmeleri pasifleþtir
	;----------------------------------------------------------------
	cli

	;keyboard kontrolleri pasifleþtir
	;----------------------------------------------------------------
	call	wait_ibf
	mov	al,0xad
	out	0x64,al

	;keyboard kontroller'i oku komutu gönder
	;----------------------------------------------------------------
	call	wait_ibf
	mov	al,0xd0
	out	0x64,al

	;data'yý oku & sakla
	;----------------------------------------------------------------
	call	wait_obf
	in	al,0x60
	push	eax

	;keyboard kontroller'e yaz komutu gönder
	;----------------------------------------------------------------
	call	wait_ibf
	mov	al,0xd1
	out	0x64,al

	;okunan data'nýn 1. biti'ni (a20 biti) set et ve data'yý gönder
	;----------------------------------------------------------------
	call	wait_ibf
	pop	eax
	or	al,10b
	out	0x60,al

	;keyboard kontroller'i aktifleþtir
	;----------------------------------------------------------------
	call	wait_ibf
	mov	al,0xae
	out	0x64,al

	;kontroller'in giriþ buffer'ýnýn 0 olmasýný bekle
	;----------------------------------------------------------------
	call	wait_ibf

	;kesmeleri aktifleþtir & çýk
	;----------------------------------------------------------------
	sti
	ret

;========================================================================
;
;iþlev  : wait_ibf
;taným  : keyboard kontroller'in giriþ buffer'ýnýn hazýr olmasýný bekler
;         (komut göndermek için)
;çýkýþ  : yok
;
;========================================================================
align 4
wait_ibf:
@@:
	in	al,0x64
	test	al,10b
	jnz	@b
	ret

;========================================================================
;
;iþlev  : wait_obf
;taným  : keyboard kontroller'in çýkýþ buffer'ýnýn hazýr olmasýný bekler
;         (data okumak için)
;çýkýþ  : yok
;
;========================================================================
align 4
wait_obf:
@@:
	in	al,0x64
	test	al,1b
	jz	@b
	ret
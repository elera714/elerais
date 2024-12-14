;************************************************************************
;
;	Kodlayan: Fatih KILIÇ
;	Telif Bilgisi: haklar.txt dosyasýna bakýnýz
;
;	Dosya Adý: video.inc
;	Dosya Ýþlevi: gerçek modda video iþlevlerini içerir
;
;	Güncelleme Tarihi: 17/10/2012
;
;************************************************************************

;========================================================================
;
;iþlev	: get_video_info
;taným	: video kartý genel bilgilerini alýr (ver. memory vs)
;giriþ	: yok
;çýkýþ	: BAÞARI : Carry Yok (NC) HATA : Carry (CY)
;
;========================================================================
align 4
get_video_info:

	;bilgilerin yerleþtirileceði adres (es:di = 0x800:0)
	;----------------------------------------------------------------
	push	es
	push	0x800
	pop	es

	xor	di,di
	mov	ax,0x4f00
	int	0x10
	cmp	ax,0x004f
	jz	.success

	;carry flaðýný set et & çýk
	;----------------------------------------------------------------
	pop	es
	stc
	ret

.success:

	;video bellek miktarýný al
	;----------------------------------------------------------------
	mov	ax,[es:di+0x12] 	;ax = 64K'lýk blok sayýsý
;	 shl	 eax,16 		 ;eax = byte olarak uzunluk
;	 shr	 eax,20 		 ;eax = MB olarak uzunluk
	mov	[video_mem_size],ax

	;carry flaðýný temizle & çýk
	;----------------------------------------------------------------
	pop	es
	clc
	ret

;========================================================================
;
;iþlev	: get_video_mode
;taným	: video mod bilgilerini alýr
;giriþ	: yok
;çýkýþ	: BAÞARI : Carry Yok (NC) HATA : Carry (CY)
;
;========================================================================
align 4
get_video_mode:

	;bilgilerin yerleþtirileceði adres (es:di = 0x800:0)
	;----------------------------------------------------------------
	push	es
	push	0x800
	pop	es

	movzx	ecx,word[video_mode]
	xor	di,di
	mov	ax,0x4f01
	int	0x10
	cmp	ax,0x004f
	jz	.success

	;carry flaðýný set et & çýk
	;----------------------------------------------------------------
	pop	es
	stc
	ret

.success:

	;video lfb addresi
	;----------------------------------------------------------------
	mov	eax,[es:di+0x28]
	mov	[video_lfb_addr],eax

	;video bpp deðeri (bpp = bits per pixel)
	;----------------------------------------------------------------
	movzx	eax,byte[es:di+0x19]
	mov	[video_bpp],al ;eax

	;video bpsl deðeri (bpsl = bir satýrdaki toplam bit sayýsý)
	;----------------------------------------------------------------
	movzx	eax,word[es:di+0x10]
	mov	[video_bpsl],ax

	;carry flaðýný temizle & çýk
	;----------------------------------------------------------------
	pop	es
	clc
	ret

;========================================================================
;
;iþlev	: set_video_mode
;taným	: belirtilen mod'da grafiksel ekrana geçer
;giriþ	: yok
;çýkýþ	: BAÞARI : Carry Yok (NC) HATA : Carry (CY)
;
;========================================================================
align 4
set_video_mode:

	;belirtilen video moduna geç
	;----------------------------------------------------------------
	movzx	ebx,word[video_mode]
	or	ebx,0x4000		;bit 14 = use lfb
	mov	ax,0x4f02
	int	0x10
	cmp	ax,0x004f
	je	.success

	;carry flaðýný set et & çýk
	;----------------------------------------------------------------
	stc
	ret

.success:

	;carry flaðýný temizle & çýk
	;----------------------------------------------------------------
	clc
	ret
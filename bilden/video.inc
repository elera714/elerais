;************************************************************************
;
;	Kodlayan: Fatih KILI�
;	Telif Bilgisi: haklar.txt dosyas�na bak�n�z
;
;	Dosya Ad�: video.inc
;	Dosya ��levi: ger�ek modda video i�levlerini i�erir
;
;	G�ncelleme Tarihi: 17/10/2012
;
;************************************************************************

;========================================================================
;
;i�lev	: get_video_info
;tan�m	: video kart� genel bilgilerini al�r (ver. memory vs)
;giri�	: yok
;��k��	: BA�ARI : Carry Yok (NC) HATA : Carry (CY)
;
;========================================================================
align 4
get_video_info:

	;bilgilerin yerle�tirilece�i adres (es:di = 0x800:0)
	;----------------------------------------------------------------
	push	es
	push	0x800
	pop	es

	xor	di,di
	mov	ax,0x4f00
	int	0x10
	cmp	ax,0x004f
	jz	.success

	;carry fla��n� set et & ��k
	;----------------------------------------------------------------
	pop	es
	stc
	ret

.success:

	;video bellek miktar�n� al
	;----------------------------------------------------------------
	mov	ax,[es:di+0x12] 	;ax = 64K'l�k blok say�s�
;	 shl	 eax,16 		 ;eax = byte olarak uzunluk
;	 shr	 eax,20 		 ;eax = MB olarak uzunluk
	mov	[video_mem_size],ax

	;carry fla��n� temizle & ��k
	;----------------------------------------------------------------
	pop	es
	clc
	ret

;========================================================================
;
;i�lev	: get_video_mode
;tan�m	: video mod bilgilerini al�r
;giri�	: yok
;��k��	: BA�ARI : Carry Yok (NC) HATA : Carry (CY)
;
;========================================================================
align 4
get_video_mode:

	;bilgilerin yerle�tirilece�i adres (es:di = 0x800:0)
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

	;carry fla��n� set et & ��k
	;----------------------------------------------------------------
	pop	es
	stc
	ret

.success:

	;video lfb addresi
	;----------------------------------------------------------------
	mov	eax,[es:di+0x28]
	mov	[video_lfb_addr],eax

	;video bpp de�eri (bpp = bits per pixel)
	;----------------------------------------------------------------
	movzx	eax,byte[es:di+0x19]
	mov	[video_bpp],al ;eax

	;video bpsl de�eri (bpsl = bir sat�rdaki toplam bit say�s�)
	;----------------------------------------------------------------
	movzx	eax,word[es:di+0x10]
	mov	[video_bpsl],ax

	;carry fla��n� temizle & ��k
	;----------------------------------------------------------------
	pop	es
	clc
	ret

;========================================================================
;
;i�lev	: set_video_mode
;tan�m	: belirtilen mod'da grafiksel ekrana ge�er
;giri�	: yok
;��k��	: BA�ARI : Carry Yok (NC) HATA : Carry (CY)
;
;========================================================================
align 4
set_video_mode:

	;belirtilen video moduna ge�
	;----------------------------------------------------------------
	movzx	ebx,word[video_mode]
	or	ebx,0x4000		;bit 14 = use lfb
	mov	ax,0x4f02
	int	0x10
	cmp	ax,0x004f
	je	.success

	;carry fla��n� set et & ��k
	;----------------------------------------------------------------
	stc
	ret

.success:

	;carry fla��n� temizle & ��k
	;----------------------------------------------------------------
	clc
	ret
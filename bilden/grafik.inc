;************************************************************************
;
;       Kodlayan: Fatih KILIÇ
;       Telif Bilgisi: haklar.txt dosyasýna bakýnýz
;
;       Dosya Adý: grafik.inc
;       Dosya Ýþlevi: gerçek modda grafik iþlevlerini içerir
;
;       Güncelleme Tarihi: 23/07/2026
;
;************************************************************************

;========================================================================
;
;iþlev  : kart_bilgisi_al
;taným  : grafik kartý genel bilgilerini alýr (ver. memory vs)
;giriþ  : yok
;çýkýþ  : BAÞARI : Carry Yok (NC) HATA : Carry (CY)
;
;========================================================================
align 4
kart_bilgisi_al:

        ;bilgilerin yerleþtirileceði adres (es:di = 0x800:0)
        ;----------------------------------------------------------------
        push    es
        push    0x800
        pop     es

        xor     di,di
        mov     ax,0x4F00
        int     0x10
        cmp     ax,0x004F
        jz      .success

        ;carry flaðýný set et & çýk
        ;----------------------------------------------------------------
        pop     es
        stc
        ret

.success:

        ;grafik kart bellek miktarýný al
        ;----------------------------------------------------------------
        mov     ax,[es:di+0x12]         ;ax = 64K'lýk blok sayýsý
;        shl     eax,16                  ;eax = byte olarak uzunluk
;        shr     eax,20                  ;eax = MB olarak uzunluk
        mov     [grafik_bellek_uzunlugu],ax

        ;carry flaðýný temizle & çýk
        ;----------------------------------------------------------------
        pop     es
        clc
        ret

;========================================================================
;
;iþlev  : mod_bilgisi_al
;taným  : grafik kart mod bilgilerini alýr
;giriþ  : yok
;çýkýþ  : BAÞARI : Carry Yok (NC) HATA : Carry (CY)
;
;========================================================================
align 4
mod_bilgisi_al:

        ;bilgilerin yerleþtirileceði adres (es:di = 0x800:0)
        ;----------------------------------------------------------------
        push    es
        push    0x800
        pop     es

        movzx   ecx,word[grafik_ekran_mod]
        xor     di,di
        mov     ax,0x4F01
        int     0x10
        cmp     ax,0x004F
        jz      .success

        ;carry flaðýný set et & çýk
        ;----------------------------------------------------------------
        pop     es
        stc
        ret

.success:

        ;grafik kart lfb addresi
        ;----------------------------------------------------------------
        mov     eax,[es:di+0x28]
        mov     [grafik_bellek_adresi],eax

        ;grafik kart bpp deðeri (bpp = bits per pixel)
        ;----------------------------------------------------------------
        movzx   eax,byte[es:di+0x19]
        mov     [grafik_px_basina_bit],al ;eax

        ;grafik kart bpsl deðeri (bpsl = bir satýrdaki toplam bit sayýsý)
        ;----------------------------------------------------------------
        movzx   eax,word[es:di+0x10]
        mov     [grafik_satir_byte_uz],ax

        ;carry flaðýný temizle & çýk
        ;----------------------------------------------------------------
        pop     es
        clc
        ret

;========================================================================
;
;iþlev  : mod_bilgisi_yaz
;taným  : belirtilen mod'da grafiksel ekrana geçer
;giriþ  : yok
;çýkýþ  : BAÞARI : Carry Yok (NC) HATA : Carry (CY)
;
;========================================================================
align 4
mod_bilgisi_yaz:

        ;belirtilen grafik moduna geç
        ;----------------------------------------------------------------
        movzx   ebx,word[grafik_ekran_mod]
        or      ebx,0x4000              ;bit 14 = use lfb
        mov     ax,0x4F02
        int     0x10
        cmp     ax,0x004F
        je      .success

        ;carry flaðýný set et & çýk
        ;----------------------------------------------------------------
        stc
        ret

.success:

        ;carry flaðýný temizle & çýk
        ;----------------------------------------------------------------
        clc
        ret
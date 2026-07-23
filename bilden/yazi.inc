;************************************************************************
;
;       Kodlayan: Fatih KILIÇ
;       Telif Bilgisi: haklar.txt dosyasýna bakýnýz
;
;       Dosya Adý: yazi.inc
;       Dosya Ýþlevi: gerçek modda ekrana yazým iþlevlerini içerir
;
;       Güncelleme Tarihi: 23/07/2026
;
;************************************************************************

;========================================================================
;
;iþlev  : karakter_yaz
;taným  : yazý modunda ekrana karakter yazar
;giriþ  : al = karakter
;çýkýþ  : yok
;
;========================================================================
align 4
karakter_yaz:
        mov     ah,0xe
        int     0x10
        ret

;========================================================================
;
;iþlev  : yazi_yaz
;taným  : yazý modunda ekrana karakter katarý deðeri yazar
;giriþ  : si = string adresi
;çýkýþ  : yok
;
;========================================================================
align 4
yazi_yaz:
@@:
        lodsb
        or      al,al
        jz      @f
        mov     ah,0x0e
        int     0x10
        jmp     @b
@@:
ret

;========================================================================
;
;iþlev  : satirbasi_yap
;taným  : yazý modunda satýr baþý yapar
;giriþ  : yok
;çýkýþ  : yok
;
;========================================================================
align 4
satirbasi_yap:
        mov     ax,0x0e0d
        int     0x10
        mov     ax,0x0e0a
        int     0x10
        ret

;========================================================================
;
;iþlev  : sayi16_yaz
;taným  : yazý modunda ekrana 16lý sayý sistemde (hexadesimal) deðer yazar
;giriþ  : eax = hexadesimal deðer, cx = yazýlacak hane sayýsý (1..8)
;çýkýþ  : yok
;
;========================================================================
align 4
sayi16_yaz:

        ;yazýlacak hane (dijit) sayýsýný kontrol et (1..8 arasý)
        ;----------------------------------------------------------------
        mov     edx,eax
        and     cx,1111b
        cmp     cx,0
        ja      @f
        mov     cx,8
        jmp     .cevir
@@:
        cmp     cx,8
        jbe     .cevir
        mov     cx,8

        ;yazýlmayacak haneleri atla
        ;----------------------------------------------------------------
.cevir:
        push    cx
        mov     ax,8
        sub     ax,cx
        mov     cx,ax
        shl     cx,2
        rol     edx,cl
        pop     cx

        ;sayýsal deðeri ascii deðere çevir
        ;----------------------------------------------------------------
.yaz:
        rol     edx,4
        mov     al,dl
        and     al,0xf

        cmp     al,9
        jbe     .D_09
.D_AF:
        add     al,55
        jmp     .ekran
.D_09:
        add     al,48
.ekran:
        mov     ah,0x0e
        int     0x10
        loop    .yaz
        ret
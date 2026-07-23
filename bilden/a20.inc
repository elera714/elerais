;************************************************************************
;
;       Kodlayan: Fatih KILIÇ
;       Telif Bilgisi: haklar.txt dosyasýna bakýnýz
;
;       Dosya Adý: a20.asm
;       Dosya Ýþlevi: a20 adres hattý iþlevlerini içerir
;
;       Güncelleme Tarihi: 23/07/2026
;
;************************************************************************

;========================================================================
;
;iþlev  : a20_aktiflestir
;taným  : adres yolunun 20. bitini aktifleþtirir
;çýkýþ  : yok
;
;========================================================================
align 4
a20_aktiflestir:

        ;kesmeleri pasifleþtir
        ;----------------------------------------------------------------
        cli

        ;keyboard kontrolleri pasifleþtir
        ;----------------------------------------------------------------
        call    giris_hazirmi
        mov     al,0xAD
        out     0x64,al

        ;keyboard kontroller'i oku komutu gönder
        ;----------------------------------------------------------------
        call    giris_hazirmi
        mov     al,0xD0
        out     0x64,al

        ;data'yý oku & sakla
        ;----------------------------------------------------------------
        call    cikis_hazirmi
        in      al,0x60
        push    eax

        ;keyboard kontroller'e yaz komutu gönder
        ;----------------------------------------------------------------
        call    giris_hazirmi
        mov     al,0xD1
        out     0x64,al

        ;okunan data'nýn 1. biti'ni (a20 biti) set et ve data'yý gönder
        ;----------------------------------------------------------------
        call    giris_hazirmi
        pop     eax
        or      al,10b
        out     0x60,al

        ;keyboard kontroller'i aktifleþtir
        ;----------------------------------------------------------------
        call    giris_hazirmi
        mov     al,0xAE
        out     0x64,al

        ;kontroller'in giriþ buffer'ýnýn 0 olmasýný bekle
        ;----------------------------------------------------------------
        call    giris_hazirmi

        ;kesmeleri aktifleþtir & çýk
        ;----------------------------------------------------------------
        sti
        ret

;========================================================================
;
;iþlev  : giris_hazirmi
;taným  : klavye kontrolcüsünün giriþ tamponunun hazýr olmasýný bekler
;         (komut göndermek için)
;çýkýþ  : yok
;
;========================================================================
align 4
giris_hazirmi:
@@:
        in      al,0x64
        test    al,10b
        jnz     @b
        ret

;========================================================================
;
;iþlev  : cikis_hazirmi
;taným  : klavye kontrolcüsünün çýkýþ tamponunun hazýr olmasýný bekler
;         (veri okumak için)
;çýkýþ  : yok
;
;========================================================================
align 4
cikis_hazirmi:
@@:
        in      al,0x64
        test    al,1b
        jz      @b
        ret
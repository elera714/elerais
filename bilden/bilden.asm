;************************************************************************
;
;       Kodlayan: Fatih KILIÇ
;       Telif Bilgisi: haklar.txt dosyasýna bakýnýz
;
;       Program Adý: bilden.asm
;       Güncelleme Tarihi: 23/07/2026
;
;       program aþaðýdaki iþlevleri gerçekleþtirir
;       -----------------------------------------------------------------
;       1. gerçek modda grafiksel ekrana geçer
;       2. çekirdek yazýlýmýný CEKIRDEK_YUKLEME_ADRES adresine yükler
;       3. korumalý mod için 3 adet selektör oluþturur, yüklemesini yapar
;          ve korumalý moda geçiþ yaparak kontrolü çekirdek yazýlýmýna devreder
;
;************************************************************************
        use16
        org     0

        ;BELLEK BÝLGÝLERÝ
        ;----------------------------------------------------------------
        ;0x10000..0x11000 - (bu) programýn bellek çalýþma alaný
        ;0x13000..0x15000 - geçici sektörlerin okunduðu bellek bölgesi
        ;0x15000...       - geçici bellek olarak kullanýlan alan
        ;0x100000...      - çekirdeðin yükleneceði bellek adresi

        SEKTOR_YUKLEME_ADRES    equ     0x1300
        CEKIRDEK_GECICI_ADRES   equ     0x1500
        GDT_BELLEK_ADRESI       equ     0x8000
        CEKIRDEK_YUKLEME_ADRES  equ     0x10000

        GrafikModSN             equ     1               ; grafik mod sýra no deðeri

        ;gerçek mod kod baþlangýç alanýna dallan
        ;----------------------------------------------------------------
        jmp     basla

align 8

        ;yerel deðiþkenler
        ;----------------------------------------------------------------
        ; veriler bellekte 0x10000+8 adresinde
        DEGERLER:
        grafik_bellek_uzunlugu  dw      0
        grafik_ekran_mod        dw      0
        grafik_cozunurluk_x     dw      0
        grafik_cozunurluk_y     dw      0
        grafik_bellek_adresi    dd      0
        grafik_px_basina_bit    db      0
        grafik_satir_byte_uz    dw      0
        cekirdek_bas_adresi     dd      CEKIRDEK_YUKLEME_ADRES shl 4
        cekirdek_uzunluk        dd      0

        bilden_surum            db      13,10,"BILDEN Surum: 0.0.2",0
        cekirdek_dosya_adi      db      "CEKIRDEKBIN"
        s_bil_inceleniyor       db      13,10,"Bilgisayariniz inceleniyor...",0
        s_grafik_mod_geciliyor  db      13,10,"Grafik ekrana gecis yapiliyor...",0
        s_grafik_kart_hatasi    db      13,10,13,10,"Desteklenmeyen Grafik Karti!",0
        s_grafik_mod_hatasi     db      13,10,13,10,"Desteklenmeyen Grafik Modu!",0
        s_yeniden_baslatiliyor  db      13,10,13,10,"Yeniden baslatmak icin bir tusa basiniz...",0
        s_dosya_yok             db      13,10,"HATA: dosya bulunamadi!",0
        s_sektor_okuma_hatasi   db      13,10,"HATA: sektor okuma hatasi!",0

;************************************************************************
;       katarlar(strings) - deðiþkenler(vars)                           *
;************************************************************************
lba_silindir    db      0
lba_kafa        db      0
lba_sektor      db      0
sektor_sayisi   db      0
tekrar_sayisi   db      0
kume_no         dw      0

grafik_modlari:
        ;       mod    gen. yük. rezerv
        ;----------------------------------------------------------------
        dd      0x11B, 1280, 1024, 0     ;1280x1024 - 24/32 bit
        dd      0x118, 1024, 768, 0      ;1024x768 - 24/32 bit
        dd      0x115, 800, 600, 0       ;800x600 - 24/32 bit
        dd      0x114, 800, 600, 0       ;800x600 - 16 bit
        dd      0x112, 640, 480, 0       ;640x480 - 24/32 bit
        dd      0x111, 640, 480, 0       ;640x480 - 16 bit

;ek dosyalar
;------------------------------------------------------------------------
include "a20.inc"               ;a20 iþlevlerini içerir.
include "yazi.inc"              ;yazý (text) mod yazým iþlevlerini içerir.
include "grafik.inc"            ;grafik iþlevlerini içerir.

;************************************************************************
;       GERÇEK MOD (REAL-MODE) KOD ALANI                                *
;************************************************************************
align 4
basla:

        ;program boot yazýlýmý tarafýndan 0x10000 adresine yüklenmektedir
        ;----------------------------------------------------------------

        ;cs = ds = es = 0x10000
        ;----------------------------------------------------------------
        mov     ax,0x1000
        mov     ds,ax
        mov     es,ax
        mov     ss,ax
        mov     sp,0x1000       ;ss:sp = 0x1000:0x1000 = 0x11000

        ;bilgisayar denetim programýnýn bilgilerini ekrana yaz
        ;----------------------------------------------------------------
        call    satirbasi_yap
        mov     si,bilden_surum
        call    yazi_yaz

        ;bilgisayar denetleme mesajýný ekrana yaz
        ;----------------------------------------------------------------
        call    satirbasi_yap
        mov     si,s_bil_inceleniyor
        call    yazi_yaz

        ;grafik kart genel bilgilerini al
        ;----------------------------------------------------------------
        call    kart_bilgisi_al
        jnc     grafik_kart_gecis

        mov     si,s_grafik_kart_hatasi

grafik_kart_hatasi:

        ;grafik kart hata mesajýný görüntüle
        ;----------------------------------------------------------------
        call    yazi_yaz

        ;sistemi yeniden baþlatma mesajýný ekrana yaz
        ;----------------------------------------------------------------
        mov     si,s_yeniden_baslatiliyor
        call    yazi_yaz

        ;kullanýcýdan bir tuþa basmasýný bekle ve sistemi yeniden baþlat
        ;----------------------------------------------------------------
        xor     ah,ah
        int     0x16
        int     0x19
        jmp     $

grafik_kart_gecis:

        ;grafik moda geçiþ mesajýný ver
        ;----------------------------------------------------------------
        mov     si,s_grafik_mod_geciliyor
        call    yazi_yaz

        ;otomatik olarak grafik moda geçme rutini
        ;----------------------------------------------------------------
        mov     ax,GrafikModSN          ;ilk video modu

grafik_mod_kontrol:

        push    ax              ; mod bilgisini sakla
        mov     si,ax
        shl     si,4
        add     si,grafik_modlari

        ;grafik modu
        ;----------------------------------------------------------------
        mov     eax,[ds:si+0]
        mov     [grafik_ekran_mod],ax

        ;grafik x & y çözünürlüðü
        ;----------------------------------------------------------------
        mov     eax,[ds:si+4]
        mov     [grafik_cozunurluk_x],ax
        mov     eax,[ds:si+8]
        mov     [grafik_cozunurluk_y],ax

        ;grafik kart mod bilgilerini al
        ;----------------------------------------------------------------
        call    mod_bilgisi_al
        jnc     grafik_mod_tamam

        ;eðer grafik kart moduna geçiþ hatasý varsa bir sonraki modu dene
        ;ta ki en son mod (3) test edilene kadar
        ;----------------------------------------------------------------
        pop     ax
        inc     ax
        cmp     ax,4
        jb      grafik_mod_kontrol

        ;grafik kart mod hata mesajý
        ;----------------------------------------------------------------
        mov     si,s_grafik_mod_hatasi
        jmp     grafik_kart_hatasi

grafik_mod_tamam:

        pop     ax              ; grafik kart mod bilgisi

        ;grafiksel ekrana geç
        ;----------------------------------------------------------------
        call    mod_bilgisi_yaz
        jc      grafik_kart_hatasi

        ;adres yolunun 20. bitini aktifleþtirir
        ;----------------------------------------------------------------
        call    a20_aktiflestir

        ;dizin/dosya giriþleri 20. sektörden baþlar. toplam 14 sektör
        ;----------------------------------------------------------------
        push    word SEKTOR_YUKLEME_ADRES
        pop     es
        xor     bx,bx
        mov     [lba_silindir],0
        mov     [lba_kafa],1
        mov     [lba_sektor],2
        mov     [sektor_sayisi],14
        call    sektor_oku
        jc      sektor_okuma_hatasi

        ;çekirdek dosyasý mevcut mu ? ara.
        ;----------------------------------------------------------------
        mov     si,cekirdek_dosya_adi
        xor     di,di
        cld
@@:
        push    si di
        mov     cx,11
        rep     cmpsb
        pop     di si
        je      fat_yukle
        add     di,32
        cmp     di,(14 * 512)
        jb      @b

        ;cekirdek.bin dosyasý mevcut deðilse,
        ;hata mesajý ver ve sistemi kilitle.
        ;----------------------------------------------------------------
        mov     si,s_dosya_yok
        call    yazi_yaz
        jmp     $

sektor_okuma_hatasi:
        mov     si,s_sektor_okuma_hatasi
        call    yazi_yaz
        jmp     $

fat_yukle:

        ;dosya uzunluðu
        ;----------------------------------------------------------------
        mov     eax,[es:di+0x1c]
        mov     [ds:cekirdek_uzunluk],eax

        ;cekirdek.bin dosyasýnýn bulunduðu ilk küme numarasý
        ;----------------------------------------------------------------
        mov     ax,[es:di+0x1a]
        mov     [ds:kume_no],ax

        ;ilk FAT tablosunu geçici bellek alanýna yükle
        ;----------------------------------------------------------------
        push    word SEKTOR_YUKLEME_ADRES
        pop     es
        xor     bx,bx
        mov     [lba_silindir],0
        mov     [lba_kafa],0
        mov     [lba_sektor],2
        mov     [sektor_sayisi],9
        call    sektor_oku
        jc      sektor_okuma_hatasi

        ;çekirdek yazýlýmýnýn geçici olarak yükleneceði bellek alaný
        ;----------------------------------------------------------------
        mov     bx,CEKIRDEK_GECICI_ADRES
        mov     es,bx
        xor     bx,bx

cekirdek_yukle:

        ;floppy sürücü sektör okuma göstergesi ..................
        ;----------------------------------------------------------------
        mov     al,'.'
        call    karakter_yaz

        ;küme deðerini c,h,s biçimine çevir ve sektörü oku
        ;----------------------------------------------------------------
        call    lba2chs

        call    sektor_oku
        jc      sektor_okuma_hatasi

        ;es:bx deðerini 512 byte artýr
        ;----------------------------------------------------------------
        mov     bx,es
        add     bx,0x20         ;0x20 shl 4 = 0x200 (512)
        mov     es,bx
        xor     bx,bx

        ;küme deðerini 1.5 ile çarp ve bir sonraki cluster deðerini al
        ;----------------------------------------------------------------
        mov     si,[ds:kume_no]
        shr     si,1
        pushf
        add     si,[ds:kume_no]
        add     si,(SEKTOR_YUKLEME_ADRES shl 4) - (0x1000 shl 4)
        mov     ax,[ds:si]
        popf
        jc      .tek_deger

.cift_deger:
        and     ax,0x0FFF       ;alt 12 bit
        jmp     .bir_sonraki_kume
.tek_deger:
        shr     ax,4            ;üst 12 bit

.bir_sonraki_kume:
        cmp     ax,0x0FF8
        jae     cekirdek_calistir

        mov     [ds:kume_no],ax
        jmp     cekirdek_yukle

;========================================================================
;
;iþlev  : lba2chs
;taným  : mantýksal sektör deðerini c,h,s biçimine çevirir
;giriþ  : ax = maktýksal sektor
;çýkýþ  : yok
;
;========================================================================
align 4
lba2chs:

        push    bx
        pushf

        mov     ax,[ds:kume_no]
        add     ax,31
        push    ax
        mov     bl,18*2
        div     bl
        mov     [ds:lba_silindir],al

        mov     al,ah
        mov     ah,0
        mov     bl,18
        div     bl
        mov     [ds:lba_kafa],al

        pop     ax
        mov     bl,18
        div     bl
        inc     ah
        mov     [ds:lba_sektor],ah
        mov     [ds:sektor_sayisi],1

        popf
        pop     bx
        ret

;========================================================================
;
;iþlev  : sektor_oku
;taným  : floppy sürücüsünden sektör okuma iþlemini gerçekleþtirir
;giriþ  : yok
;çýkýþ  : yok
;
;========================================================================
align 4
sektor_oku:
        mov     [ds:tekrar_sayisi],10
.tekrar:
        mov     ah,2
        mov     al,[ds:sektor_sayisi]
        mov     dl,0 ;[boot_drv]
        mov     ch,[ds:lba_silindir]
        mov     dh,[ds:lba_kafa]
        mov     cl,[ds:lba_sektor]
        int     0x13
        jnc     .tamam

        dec     [ds:tekrar_sayisi]
        jnz     .tekrar
.hata:
        stc
        ret
.tamam:
        clc
        ret

cekirdek_calistir:

        ;tüm irq isteklerini pasifleþtir
        ;----------------------------------------------------------------
        cli
        mov     al,0xFF
        out     0xA1,al
        out     0x21,al

        ;sistem selektörlerini oluþtur. null/code/data selectors
        ;----------------------------------------------------------------
        push    es

        ;gdtr_mem_addr -> segment:offset
        push    GDT_BELLEK_ADRESI
        pop     es
        xor     edi,edi

        ;GDTR yazmacýnýn limit ve baþlangýç (base address) adresini belirle
        ;----------------------------------------------------------------
        mov     word[es:edi+00],0xFFFF-1                        ;limit = limit-1
        mov     dword[es:edi+02],(GDT_BELLEK_ADRESI shl 4)+8    ;baþlangýç adresi

@@:
        ;null, sistem kod / sistem data seçicisi (selector)
        ;----------------------------------------------------------------
        mov     ecx,1 ;0
        add     edi,8
        mov     dword[es:edi+00],0
        mov     dword[es:edi+04],0
        dec     ecx
        jnz     @b

        ; kod seçicisi (CS) - (0x08)
        ;----------------------------------------------------------------
        add     edi,8
        mov     word[es:edi+00],0xFFFF                  ; limit 00..15
        mov     word[es:edi+02],0                       ; baþlangýç adresi 00..15
        mov     byte[es:edi+04],0                       ; baþlangýç adresi 16..23
        mov     byte[es:edi+05],10011010b               ; 1 = 1 = mevcut, 00 = DPL0, 11 = kod yazmaç, 0 = dallanýlamaz, 1 = okunabilir, 0 = eriþilmedi
        mov     byte[es:edi+06],11011111b               ; 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
        mov     byte[es:edi+07],0                       ; baþlangýç adresi 24..31

        ; veri seçicisi (DS) - (0x10)
        ;----------------------------------------------------------------
        add     edi,8
        mov     word[es:edi+00],0xFFFF                  ; limit 00..15
        mov     word[es:edi+02],0                       ; baþlangýç adresi 00..15
        mov     byte[es:edi+04],0                       ; baþlangýç adresi 16..23
        mov     byte[es:edi+05],10010010b               ; 1 = mevcut, 00 = DPL0, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazýlabilir, 0 = eriþilmedi
        mov     byte[es:edi+06],11001111b               ; 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
        mov     byte[es:edi+07],0                       ; baþlangýç adresi 24..31

        pop     es

        ;sistem selektörlerini yükle. GDT
        ;----------------------------------------------------------------
        push    es
        push    word GDT_BELLEK_ADRESI
        pop     es
        xor     edi,edi
        lgdt    [es:edi]
        pop     es

        ;korumalý mod'a geç
        ;----------------------------------------------------------------
        mov     eax,cr0
        or      eax,1
        mov     cr0,eax
        jmp     pword 0x08:korumali_mod_basla

        use32
        org     $+0x10000

korumali_mod_basla:

        ;korumalý moddayýz
        ;----------------------------------------------------------------
        mov     eax,0x10
        mov     ds,ax
        mov     es,ax
        mov     ss,ax
        mov     fs,ax
        mov     gs,ax

        mov     esp,0x400000-0x100

        ;çekirdeðin kod baþlangýç adresini al
        ;----------------------------------------------------------------
        mov     eax,[(CEKIRDEK_GECICI_ADRES shl 4)+0x18]
        mov     [adres],eax

        mov     esi,(CEKIRDEK_GECICI_ADRES shl 4)+0x1000
        mov     edi,CEKIRDEK_YUKLEME_ADRES shl 4
        mov     ecx,[cekirdek_uzunluk+0x10000]
        ;deðeri 4ün katýna tamamla
        add     ecx,3
        and     ecx,-4
        cld
        rep     movsd

        ;bilden (bu) programýn topladýðý bilgileri çekirdeðe eax yazmacýyla aktar
        ;----------------------------------------------------------------
        mov     eax,DEGERLER+0x10000

        ;çekirdeðin kod baþlangýç adresine dallan
        ;----------------------------------------------------------------
kod     db      0xEA
adres   dd      0x00000000
sel     dw      0x08
        jmp     $
;************************************************************************
;
;       Kodlayan: Fatih KILIÇ
;       Telif Bilgisi: haklar.txt dosyasýna bakýnýz
;
;       Program Adý: bilden.asm
;       Güncelleme Tarihi: 03/08/2017
;
;       Program Aþaðýdaki Ýþlevleri Gerçekleþtirir
;       -----------------------------------------------------------------
;       1. Gerçek modda grafiksel ekrana geçer
;       2. Çekirdek yazýlýmýný KERNEL_LOAD_ADDR adresine yükler
;       3. Korumalý mod için 3 adet selektör oluþturur, yüklemesini yapar
;          ve korumalý moda geçiþ yaparak kontrolü çekirdek yazýlýmýna devreder
;
;************************************************************************
        use16
        org     0

        ;BELLEK BÝLGÝLERÝ
        ;----------------------------------------------------------------
        ;0x10000..0x11000 - program bellek çalýþma alaný
        ;0x11000..0x13000 - geçici sektörlerin okunduðu bellek bölgesi
        ;KERNEL_LOAD_ADDR...       - çekirdeðin yükleneceði bellek adresi

        ;gdt deðerlerinin yerleþtirileceði adres
        ;çekirdek yazýlýmý bu deðeri kullandýðý için deðiþtirilmesi
        ;durumunda çekirdek yazýlýmýndaki deðerin de deðiþtirilmesi gerekir
        ;----------------------------------------------------------------
        GDT_MEM_ADDR            equ     0x80000
        KERNEL_TEMP_ADDR        equ     0x13000
        KERNEL_LOAD_ADDR        equ     0x100000

        VModeIndex              equ     0               ; video mod index deðeri

        ;gerçek mod kod baþlangýç alanýna dallan
        ;----------------------------------------------------------------
        jmp     start

align 8

        ;yerel deðiþkenler
        ;----------------------------------------------------------------
        ; veriler bellekte 0x10000+8 adresinde
        parameters:
        video_mem_size          dw      0
        video_mode              dw      0
        video_res_x             dw      0
        video_res_y             dw      0
        video_lfb_addr          dd      0
        video_bpp               db      0
        video_bpsl              dw      0
        kernel_start_addr       dd      KERNEL_LOAD_ADDR
        kernel_size             dd      0

        bilden_ver              db      13,10,"BILDEN Surum: 0.0.1",0
        file_kernel             db      "CEKIRDEKBIN"
        comp_review             db      13,10,"Bilgisayariniz inceleniyor...",0
        str_video_starting      db      13,10,"Grafik ekrana gecis yapiliyor...",0
        str_video_error         db      13,10,13,10,"Desteklenmeyen Grafik Karti!",0
        str_video_mode_error    db      13,10,13,10,"Desteklenmeyen Grafik Modu!",0
        str_reboot_msg          db      13,10,13,10,"Yeniden baslatmak icin bir tusa basiniz.",0
        file_not_found          db      13,10,"HATA: dosya bulunamadi.",0
        sec_read_error          db      13,10,"HATA: sektor okuma hatasi.",0

video_modes:
        ;       mod    gen. yük. rezerv
        ;----------------------------------------------------------------
        ;dd      0x11B, 1280, 1024, 0     ;1280x1024 - 24/32 bit
        dd      0x118, 1024, 768, 0      ;1024x768 - 24/32 bit
        dd      0x115, 800, 600, 0       ;800x600 - 24/32 bit
        dd      0x114, 800, 600, 0       ;800x600 - 16 bit
        dd      0x112, 640, 480, 0       ;640x480 - 24/32 bit
        dd      0x111, 640, 480, 0       ;640x480 - 16 bit

;ek dosyalar
;------------------------------------------------------------------------
include "a20.inc"               ;a20 iþlevlerini içerir.
include "write.inc"             ;text yazým iþlevlerini içerir.
include "video.inc"             ;video iþlevlerini içerir.

;************************************************************************
;       GERÇEK MOD (REAL-MODE) KOD ALANI                                *
;************************************************************************
align 4
start:

        ;program boot yazýlýmý tarafýndan 0x10000 adresine yüklenmektedir
        ;----------------------------------------------------------------

        ;cs = ds = es = 0x10000
        ;----------------------------------------------------------------
        mov     ax,cs
        mov     ds,ax
        mov     es,ax
        mov     ss,ax
        mov     sp,0x1000       ;ss:sp = 0x11000

        ;bilgisayar denetim programýnýn bilgilerini ekrana yaz
        ;----------------------------------------------------------------
        call    print_crlf
        mov     si,bilden_ver
        call    print_text

        ;bilgisayar denetleme mesajýný ekrana yaz
        ;----------------------------------------------------------------
        call    print_crlf
        mov     si,comp_review
        call    print_text

kernel_g:


        ;video kart genel bilgilerini al
        ;----------------------------------------------------------------
        call    get_video_info
        jnc     start_video_mode

        ;video hata mesaj adresi
        ;----------------------------------------------------------------
        mov     si,str_video_error

video_error:

        ;video hata mesajýný ekrana yaz
        ;----------------------------------------------------------------
        call    print_text

        ;sistemi yeniden baþlatma mesajýný ekrana yaz
        ;----------------------------------------------------------------
        mov     si,str_reboot_msg
        call    print_text

        ;kullanýcýdan bir tuþa basmasýný bekle ve sistemi yeniden baþlat
        ;----------------------------------------------------------------
        xor     ah,ah
        int     0x16
        int     0x19
        jmp     $

start_video_mode:

        ;video moda geçiþ mesajýný ver
        ;----------------------------------------------------------------
        mov     si,str_video_starting
        call    print_text

        ;otomatik olarak video moda geçme rutini
        ;----------------------------------------------------------------
        mov     ax,VModeIndex   ; ilk video modu

check_mode:

        push    ax              ; mod bilgisini sakla
        mov     si,ax
        shl     si,4
        add     si,video_modes

        ;video modu
        ;----------------------------------------------------------------
        mov     eax,[ds:si+0]
        mov     [ds:video_mode],ax

        ;video x & y çözünürlüðü
        ;----------------------------------------------------------------
        mov     eax,[ds:si+4]
        mov     [video_res_x],ax
        mov     eax,[ds:si+8]
        mov     [video_res_y],ax

        ;video kart mod bilgilerini al
        ;----------------------------------------------------------------
        call    get_video_mode
        jnc     set_mode

        ;eðer moda geçiþ hatasý varsa bir sonraki modu dene
        ;taki en son mod (3) test edilene kadar
        ;----------------------------------------------------------------
        pop     ax
        inc     ax
        cmp     ax,4
        jb      check_mode

        ;video hata mesaj adresi
        ;----------------------------------------------------------------
        mov     si,str_video_mode_error
        jmp     video_error

set_mode:

        pop     ax              ; mod bilgisi

        ;grafiksel ekrana geç
        ;----------------------------------------------------------------
        call    set_video_mode
        jc      video_error

kernel_selection_ok:

        ;adres yolunun 20. bitini aktifleþtirir
        ;----------------------------------------------------------------
        call    enable_a20

        ;es:bx (0x7c00+0x400=0x8000) dizin/dosya giriþlerini yükle
        ;dizin/dosya giriþleri 20. sektörden baþlar. toplam 14 sektör
        ;----------------------------------------------------------------
        push    es              ; --> es sakla1
        push    0x1100
        pop     es
        xor     bx,bx
        mov     [lba_c],0
        mov     [lba_h],1
        mov     [lba_s],2
        mov     [num_sec2read],14
        call    read_sector
        jc      show_read_error

        ;çekirdek dosyasý mevcut mu ? ara.
        ;----------------------------------------------------------------
        mov     si,file_kernel

kernel_file_ok:
        xor     di,di
        cld
@@:
        push    si di
        mov     cx,11
        rep     cmpsb
        pop     di si
        je      load_fat
        add     di,32
        cmp     di,(14*512)
        jb      @b

        ;bilden.bin dosyasý mevcut deðilse,
        ;hata mesajý ver ve sistemi kilitle.
        ;----------------------------------------------------------------
        mov     si,file_not_found
        call    print_text
        jmp     $

show_read_error:
        mov     si,sec_read_error
        call    print_text
        jmp     $

load_fat:

        ;dosya uzunluðu
        ;----------------------------------------------------------------
        mov     eax,[es:di+0x1c]
        mov     [ds:kernel_size],eax

        ;bilden.bin dosyasýnýn bulunduðu ilk cluster'ý sakla
        ;----------------------------------------------------------------
        mov     ax,[es:di+0x1a]
        mov     [ds:cluster],ax

        ;ilk FAT tablosunu geçici bellek alanýna yükle
        ;----------------------------------------------------------------
        mov     bx,0x1100
        mov     es,bx
        xor     bx,bx
        mov     [lba_c],0
        mov     [lba_h],0
        mov     [lba_s],2
        mov     [num_sec2read],9
        call    read_sector
        jc      show_read_error

        pop     es              ; --> es getir1

        ;çekirdek yazýlýmýnýn yükleneceði bellek alaný KERNEL_LOAD_ADDR
        ;----------------------------------------------------------------
        mov     bx,(KERNEL_TEMP_ADDR shr 4)
        mov     es,bx
        xor     bx,bx

load_kernel:

        ;floppy okuma göstergesi ..................
        ;----------------------------------------------------------------
        mov     al,'.'
        call    print_char

        ;cluster deðerini c,h,s formatýna çevir ve sektörü oku
        ;----------------------------------------------------------------
        call    lba2chs

        call    read_sector
        jc      show_read_error

        ;es:bx deðerini 512 byte artýr
        ;----------------------------------------------------------------
        mov     bx,es
        add     bx,0x20         ;0x20 shl 4 = 0x200 (512)
        mov     es,bx
        xor     bx,bx

        ;cluster deðerini 1.5 ile çarp ve bir sonraki cluster deðerini al
        ;----------------------------------------------------------------
        mov     si,[ds:cluster]
        shr     si,1
        pushf
        add     si,[ds:cluster]
        add     si,0x1000
        mov     ax,[ds:si]
        popf
        jc      .odd_cluster

.even_cluster:
        and     ax,0xfff        ;alt 12 bit
        jmp     .clus_calc_done
.odd_cluster:
        shr     ax,4            ;üst 12 bit

.clus_calc_done:
        cmp     ax,0xff8
        jae     exec_kernel

        mov     [ds:cluster],ax
        jmp     load_kernel
        jmp     exec_kernel

;========================================================================
;
;iþlev  : lba2chs
;taným  : mantýksal sektör deðerini c,h,s formatýna çevirir
;giriþ  : ax = maktýksal sektor
;çýkýþ  : yok
;
;========================================================================
align 4
lba2chs:

        push    bx
        pushf

        mov     ax,[ds:cluster]
        add     ax,31
        push    ax
        mov     bl,18*2
        div     bl
        mov     [ds:lba_c],al

        mov     al,ah
        mov     ah,0
        mov     bl,18
        div     bl
        mov     [ds:lba_h],al

        pop     ax
        mov     bl,18
        div     bl
        inc     ah
        mov     [ds:lba_s],ah
        mov     [ds:num_sec2read],1

        popf
        pop     bx
        ret

;========================================================================
;
;iþlev  : read_sector
;taným  : floppy sürücüsünden sektör içeriðini okur
;giriþ  : yok
;çýkýþ  : yok
;
;========================================================================
align 4
read_sector:
        mov     [ds:read_retry],10
.retry:
        mov     ah,2
        mov     al,[ds:num_sec2read]
        mov     dl,0 ;[boot_drv]
        mov     ch,[ds:lba_c]
        mov     dh,[ds:lba_h]
        mov     cl,[ds:lba_s]
        int     0x13
        jnc     .success

        dec     [ds:read_retry]
        jnz     .retry
.error:
        stc
        ret
.success:
        clc
        ret

;************************************************************************
;       katarlar(strings) - deðiþkenler(vars)                           *
;************************************************************************
lba_c           db      0
lba_h           db      0
lba_s           db      0
num_sec2read    db      0
read_retry      db      0
cluster         dw      0

exec_kernel:

        ;tüm irq isteklerini pasifleþtir
        ;----------------------------------------------------------------
        cli
        mov     al,0xff
        out     0xa1,al
        out     0x21,al

        ;sistem selektörlerini oluþtur. null/code/data selectors
        ;----------------------------------------------------------------
        push    es

        push    (GDT_MEM_ADDR shr 4)   ;gdtr_mem_addr -> segment:offset
        pop     es
        xor     edi,edi

        ;GDTR yazmacýnýn limit ve baþlangýç (base address) adresini belirle
        ;----------------------------------------------------------------
        mov     word[es:edi+00],0xFFFF-1                  ;limit = limit-1
        mov     dword[es:edi+02],GDT_MEM_ADDR+8           ;baþlangýç adresi

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
        push    word (GDT_MEM_ADDR shr 4)
        pop     es
        xor     edi,edi
        lgdt    [es:edi]
        pop     es

        ;korumalý mod'a geç
        ;----------------------------------------------------------------
        mov     eax,cr0
        or      eax,1
        mov     cr0,eax
        jmp     pword 0x8:pmode_start

        use32
        org $+0x10000
pmode_start:

        ;korumalý moddayýz
        ;----------------------------------------------------------------
        mov     eax,0x10
        mov     ds,ax
        mov     es,ax
        mov     ss,ax
        mov     fs,ax
        mov     gs,ax

        ;GDT adresinin baþlangýcý ayný zamanda
        ;çekirdek yazýlýmýn yýðýn adresinin geriye doðru baþlangýcýdýr
        ;----------------------------------------------------------------
        mov     esp,0x500000

        ;çekirdeðin kod baþlangýç adresini al
        ;----------------------------------------------------------------
        mov     eax,KERNEL_LOAD_ADDR
        mov     [_offs],eax

        mov     esi,KERNEL_TEMP_ADDR
        mov     edi,KERNEL_LOAD_ADDR
        mov     ecx,500000/4
        cld
        rep     movsd

        mov     esi,KERNEL_TEMP_ADDR+0x18
        mov     eax,[esi]
        mov     [_offs],eax

        mov     esi,KERNEL_TEMP_ADDR+0x1000
        mov     edi,KERNEL_LOAD_ADDR
        mov     ecx,500000/4
        cld
        rep     movsd

jump_addr:

        ;parametrenin adresini çekirdeðe eax yazmacýyla aktar
        ;----------------------------------------------------------------
        mov     eax,parameters ;+0x10000

        ;çekirdeðin kod baþlangýç adresine dallan
        ;----------------------------------------------------------------
_code   db      0xEA
_offs   dd      0
_sel    dw      0x8
        jmp     $
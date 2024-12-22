;************************************************************************
;
;       Kodlayan: Fatih KILI�
;       Telif Bilgisi: haklar.txt dosyas�na bak�n�z
;
;       Program Ad�: bilden.asm
;       G�ncelleme Tarihi: 03/08/2017
;
;       Program A�a��daki ��levleri Ger�ekle�tirir
;       -----------------------------------------------------------------
;       1. Ger�ek modda grafiksel ekrana ge�er
;       2. �ekirdek yaz�l�m�n� KERNEL_LOAD_ADDR adresine y�kler
;       3. Korumal� mod i�in 3 adet selekt�r olu�turur, y�klemesini yapar
;          ve korumal� moda ge�i� yaparak kontrol� �ekirdek yaz�l�m�na devreder
;
;************************************************************************
        use16
        org     0

        ;BELLEK B�LG�LER�
        ;----------------------------------------------------------------
        ;0x10000..0x11000 - program bellek �al��ma alan�
        ;0x11000..0x13000 - ge�ici sekt�rlerin okundu�u bellek b�lgesi
        ;KERNEL_LOAD_ADDR...       - �ekirde�in y�klenece�i bellek adresi

        ;gdt de�erlerinin yerle�tirilece�i adres
        ;�ekirdek yaz�l�m� bu de�eri kulland��� i�in de�i�tirilmesi
        ;durumunda �ekirdek yaz�l�m�ndaki de�erin de de�i�tirilmesi gerekir
        ;----------------------------------------------------------------
        GDT_MEM_ADDR            equ     0x80000
        KERNEL_TEMP_ADDR        equ     0x13000
        KERNEL_LOAD_ADDR        equ     0x100000

        VModeIndex              equ     1               ; video mod index de�eri

        ;ger�ek mod kod ba�lang�� alan�na dallan
        ;----------------------------------------------------------------
        jmp     start

align 8

        ;yerel de�i�kenler
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
        ;       mod    gen. y�k. rezerv
        ;----------------------------------------------------------------
        ;dd      0x11B, 1280, 1024, 0     ;1280x1024 - 24/32 bit
        dd      0x118, 1024, 768, 0      ;1024x768 - 24/32 bit
        dd      0x115, 800, 600, 0       ;800x600 - 24/32 bit
        dd      0x114, 800, 600, 0       ;800x600 - 16 bit
        dd      0x112, 640, 480, 0       ;640x480 - 24/32 bit
        dd      0x111, 640, 480, 0       ;640x480 - 16 bit

;ek dosyalar
;------------------------------------------------------------------------
include "a20.inc"               ;a20 i�levlerini i�erir.
include "write.inc"             ;text yaz�m i�levlerini i�erir.
include "video.inc"             ;video i�levlerini i�erir.

;************************************************************************
;       GER�EK MOD (REAL-MODE) KOD ALANI                                *
;************************************************************************
align 4
start:

        ;program boot yaz�l�m� taraf�ndan 0x10000 adresine y�klenmektedir
        ;----------------------------------------------------------------

        ;cs = ds = es = 0x10000
        ;----------------------------------------------------------------
        mov     ax,cs
        mov     ds,ax
        mov     es,ax
        mov     ss,ax
        mov     sp,0x1000       ;ss:sp = 0x11000

        ;bilgisayar denetim program�n�n bilgilerini ekrana yaz
        ;----------------------------------------------------------------
        call    print_crlf
        mov     si,bilden_ver
        call    print_text

        ;bilgisayar denetleme mesaj�n� ekrana yaz
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

        ;video hata mesaj�n� ekrana yaz
        ;----------------------------------------------------------------
        call    print_text

        ;sistemi yeniden ba�latma mesaj�n� ekrana yaz
        ;----------------------------------------------------------------
        mov     si,str_reboot_msg
        call    print_text

        ;kullan�c�dan bir tu�a basmas�n� bekle ve sistemi yeniden ba�lat
        ;----------------------------------------------------------------
        xor     ah,ah
        int     0x16
        int     0x19
        jmp     $

start_video_mode:

        ;video moda ge�i� mesaj�n� ver
        ;----------------------------------------------------------------
        mov     si,str_video_starting
        call    print_text

        ;otomatik olarak video moda ge�me rutini
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

        ;video x & y ��z�n�rl���
        ;----------------------------------------------------------------
        mov     eax,[ds:si+4]
        mov     [video_res_x],ax
        mov     eax,[ds:si+8]
        mov     [video_res_y],ax

        ;video kart mod bilgilerini al
        ;----------------------------------------------------------------
        call    get_video_mode
        jnc     set_mode

        ;e�er moda ge�i� hatas� varsa bir sonraki modu dene
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

        ;grafiksel ekrana ge�
        ;----------------------------------------------------------------
        call    set_video_mode
        jc      video_error

kernel_selection_ok:

        ;adres yolunun 20. bitini aktifle�tirir
        ;----------------------------------------------------------------
        call    enable_a20

        ;es:bx (0x7c00+0x400=0x8000) dizin/dosya giri�lerini y�kle
        ;dizin/dosya giri�leri 20. sekt�rden ba�lar. toplam 14 sekt�r
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

        ;�ekirdek dosyas� mevcut mu ? ara.
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

        ;bilden.bin dosyas� mevcut de�ilse,
        ;hata mesaj� ver ve sistemi kilitle.
        ;----------------------------------------------------------------
        mov     si,file_not_found
        call    print_text
        jmp     $

show_read_error:
        mov     si,sec_read_error
        call    print_text
        jmp     $

load_fat:

        ;dosya uzunlu�u
        ;----------------------------------------------------------------
        mov     eax,[es:di+0x1c]
        mov     [ds:kernel_size],eax

        ;bilden.bin dosyas�n�n bulundu�u ilk cluster'� sakla
        ;----------------------------------------------------------------
        mov     ax,[es:di+0x1a]
        mov     [ds:cluster],ax

        ;ilk FAT tablosunu ge�ici bellek alan�na y�kle
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

        ;�ekirdek yaz�l�m�n�n y�klenece�i bellek alan� KERNEL_LOAD_ADDR
        ;----------------------------------------------------------------
        mov     bx,(KERNEL_TEMP_ADDR shr 4)
        mov     es,bx
        xor     bx,bx

load_kernel:

        ;floppy okuma g�stergesi ..................
        ;----------------------------------------------------------------
        mov     al,'.'
        call    print_char

        ;cluster de�erini c,h,s format�na �evir ve sekt�r� oku
        ;----------------------------------------------------------------
        call    lba2chs

        call    read_sector
        jc      show_read_error

        ;es:bx de�erini 512 byte art�r
        ;----------------------------------------------------------------
        mov     bx,es
        add     bx,0x20         ;0x20 shl 4 = 0x200 (512)
        mov     es,bx
        xor     bx,bx

        ;cluster de�erini 1.5 ile �arp ve bir sonraki cluster de�erini al
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
        shr     ax,4            ;�st 12 bit

.clus_calc_done:
        cmp     ax,0xff8
        jae     exec_kernel

        mov     [ds:cluster],ax
        jmp     load_kernel
        jmp     exec_kernel

;========================================================================
;
;i�lev  : lba2chs
;tan�m  : mant�ksal sekt�r de�erini c,h,s format�na �evirir
;giri�  : ax = makt�ksal sektor
;��k��  : yok
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
;i�lev  : read_sector
;tan�m  : floppy s�r�c�s�nden sekt�r i�eri�ini okur
;giri�  : yok
;��k��  : yok
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
;       katarlar(strings) - de�i�kenler(vars)                           *
;************************************************************************
lba_c           db      0
lba_h           db      0
lba_s           db      0
num_sec2read    db      0
read_retry      db      0
cluster         dw      0

exec_kernel:

        ;t�m irq isteklerini pasifle�tir
        ;----------------------------------------------------------------
        cli
        mov     al,0xff
        out     0xa1,al
        out     0x21,al

        ;sistem selekt�rlerini olu�tur. null/code/data selectors
        ;----------------------------------------------------------------
        push    es

        push    (GDT_MEM_ADDR shr 4)   ;gdtr_mem_addr -> segment:offset
        pop     es
        xor     edi,edi

        ;GDTR yazmac�n�n limit ve ba�lang�� (base address) adresini belirle
        ;----------------------------------------------------------------
        mov     word[es:edi+00],0xFFFF-1                  ;limit = limit-1
        mov     dword[es:edi+02],GDT_MEM_ADDR+8           ;ba�lang�� adresi

@@:
        ;null, sistem kod / sistem data se�icisi (selector)
        ;----------------------------------------------------------------
        mov     ecx,1 ;0
        add     edi,8
        mov     dword[es:edi+00],0
        mov     dword[es:edi+04],0
        dec     ecx
        jnz     @b

        ; kod se�icisi (CS) - (0x08)
        ;----------------------------------------------------------------
        add     edi,8
        mov     word[es:edi+00],0xFFFF                  ; limit 00..15
        mov     word[es:edi+02],0                       ; ba�lang�� adresi 00..15
        mov     byte[es:edi+04],0                       ; ba�lang�� adresi 16..23
        mov     byte[es:edi+05],10011010b               ; 1 = 1 = mevcut, 00 = DPL0, 11 = kod yazma�, 0 = dallan�lamaz, 1 = okunabilir, 0 = eri�ilmedi
        mov     byte[es:edi+06],11011111b               ; 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
        mov     byte[es:edi+07],0                       ; ba�lang�� adresi 24..31

        ; veri se�icisi (DS) - (0x10)
        ;----------------------------------------------------------------
        add     edi,8
        mov     word[es:edi+00],0xFFFF                  ; limit 00..15
        mov     word[es:edi+02],0                       ; ba�lang�� adresi 00..15
        mov     byte[es:edi+04],0                       ; ba�lang�� adresi 16..23
        mov     byte[es:edi+05],10010010b               ; 1 = mevcut, 00 = DPL0, 10 = veri yazma�, 0 = artarak b�y�yen, 1 = yaz�labilir, 0 = eri�ilmedi
        mov     byte[es:edi+06],11001111b               ; 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
        mov     byte[es:edi+07],0                       ; ba�lang�� adresi 24..31

        pop     es

        ;sistem selekt�rlerini y�kle. GDT
        ;----------------------------------------------------------------
        push    es
        push    word (GDT_MEM_ADDR shr 4)
        pop     es
        xor     edi,edi
        lgdt    [es:edi]
        pop     es

        ;korumal� mod'a ge�
        ;----------------------------------------------------------------
        mov     eax,cr0
        or      eax,1
        mov     cr0,eax
        jmp     pword 0x8:pmode_start

        use32
        org $+0x10000
pmode_start:

        ;korumal� modday�z
        ;----------------------------------------------------------------
        mov     eax,0x10
        mov     ds,ax
        mov     es,ax
        mov     ss,ax
        mov     fs,ax
        mov     gs,ax

        ;GDT adresinin ba�lang�c� ayn� zamanda
        ;�ekirdek yaz�l�m�n y���n adresinin geriye do�ru ba�lang�c�d�r
        ;----------------------------------------------------------------
        mov     esp,0x500000

        ;�ekirde�in kod ba�lang�� adresini al
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

        ;parametrenin adresini �ekirde�e eax yazmac�yla aktar
        ;----------------------------------------------------------------
        mov     eax,parameters ;+0x10000

        ;�ekirde�in kod ba�lang�� adresine dallan
        ;----------------------------------------------------------------
_code   db      0xEA
_offs   dd      0
_sel    dw      0x8
        jmp     $
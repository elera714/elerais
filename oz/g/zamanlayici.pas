{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: zamanlayici.pas
  Dosya ��levi: zamanlay�c� y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 05/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit zamanlayici;

interface

uses paylasim, port, gorselnesne;

const
  AZAMI_ZAMANLAYICI_SAYISI = 32;

type
  TZamanlayiciDurum = (zdBos, zdCalisiyor, zdDurduruldu);

type
  PZamanlayici = ^TZamanlayici;
  TZamanlayici = object
  private
    FZamanlayiciDurum: TZamanlayiciDurum;
    FKimlik: TKimlik;
    FGorevKimlik: TKimlik;
    FTetiklemeSuresi, FGeriSayimSayaci: TSayi4;
  public
    FOlayYonlendirmeAdresi: TOlaylariIsle;
    procedure Yukle;
    function Olustur(AMiliSaniye: TISayi4): PZamanlayici;
    function BosZamanlayiciBul: PZamanlayici;
    procedure YokEt;
    property Durum: TZamanlayiciDurum read FZamanlayiciDurum write FZamanlayiciDurum;
    property Kimlik: TKimlik read FKimlik;
    property GorevKimlik: TKimlik read FGorevKimlik write FGorevKimlik;
    property TetiklemeSuresi: TSayi4 read FTetiklemeSuresi write FTetiklemeSuresi;
    property GeriSayimSayaci: TSayi4 read FGeriSayimSayaci write FGeriSayimSayaci;
  end;

var
  ZamanlayiciYapiBellekAdresi: Isaretci;
  OlusturulanZamanlayiciSayisi: TSayi4 = 0;
  ZamanlayiciListesi: array[1..AZAMI_ZAMANLAYICI_SAYISI] of PZamanlayici;

procedure ZamanlayicilariKontrolEt;
procedure ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
procedure BekleMS(AMilisaniye: TSayi4);
procedure TekGorevZamanlayiciIslevi;
procedure OtomatikGorevDegistir;
procedure ElleGorevDegistir;

implementation

uses genel, gorev, src_disket, arp, idt, irq, pit, pic;

{==============================================================================
  zamanlay�c� nesnelerinin ana y�kleme i�levlerini i�erir
 ==============================================================================}
procedure TZamanlayici.Yukle;
var
  Zamanlayici: PZamanlayici;
  BellekAdresi: Isaretci;
  ZamanlayiciU, i: TSayi4;
begin

  // kesmeleri durdur
  cli;

  IRQPasiflestir(0);

  // IRQ0 giri� noktas�n� yeniden belirle
  // %10001110 = 1 = mevcut, 00 = DPL0, 0, 1 = 32 bit kod, 110 - kesme kap�s�
  KesmeGirisiBelirle($20, @OtomatikGorevDegistir, SECICI_SISTEM_KOD * 8, %10001110);

  // saat vuru� frekans�n� d�zenle. 100 tick = 1 saniye
  ZamanlayiciFrekansiniDegistir(100);

  ZamanlayiciU := SizeOf(TZamanlayici);

  // uygulamalar i�in zamanlay�c� bilgilerinin yerle�tirilece�i bellek olu�tur
  ZamanlayiciYapiBellekAdresi := GGercekBellek.Ayir(AZAMI_ZAMANLAYICI_SAYISI * ZamanlayiciU);

  // bellek giri�lerini zamanlay�c� yap�lar�yla e�le�tir
  BellekAdresi := ZamanlayiciYapiBellekAdresi;
  for i := 1 to AZAMI_ZAMANLAYICI_SAYISI do
  begin

    Zamanlayici := BellekAdresi;
    ZamanlayiciListesi[i] := Zamanlayici;

    Zamanlayici^.FZamanlayiciDurum := zdBos;
    Zamanlayici^.FKimlik := i;
    Zamanlayici^.FOlayYonlendirmeAdresi := nil;

    BellekAdresi += ZamanlayiciU;
  end;

  // �al��an zamanlay�c� say�s�n� s�f�rla
  OlusturulanZamanlayiciSayisi := 0;

  // IRQ0'� etkinle�tir
  IRQEtkinlestir(0);

  // kesmeleri aktifle�tir
  sti;
end;

{==============================================================================
  zamanlay�c� nesnesi olu�turur
 ==============================================================================}
function TZamanlayici.Olustur(AMiliSaniye: TISayi4): PZamanlayici;
var
  Zamanlayici: PZamanlayici;
begin

  // bo� bir zamanlay�c� nesnesi bul
  Zamanlayici := BosZamanlayiciBul;
  if(Zamanlayici <> nil) then
  begin

    Zamanlayici^.FGorevKimlik := CalisanGorev;
    Zamanlayici^.FTetiklemeSuresi := AMiliSaniye;
    Zamanlayici^.FGeriSayimSayaci := AMiliSaniye;
    Zamanlayici^.FOlayYonlendirmeAdresi := nil;

    Inc(OlusturulanZamanlayiciSayisi);

    Exit(Zamanlayici);
  end;

  // geri d�n�� de�eri
  Result := nil;
end;

{==============================================================================
  bo� zamanlay�c� bulur
 ==============================================================================}
function TZamanlayici.BosZamanlayiciBul: PZamanlayici;
var
  i: TSayi4;
begin

  // t�m zamanlay�c� nesnelerini ara
  for i := 1 to AZAMI_ZAMANLAYICI_SAYISI do
  begin

    // zamanlay�c� nesnesinin durumu bo� ise
    if(ZamanlayiciListesi[i]^.FZamanlayiciDurum = zdBos) then
    begin

      // durduruldu olarak i�aretle ve �a��ran i�leve geri d�n
      ZamanlayiciListesi[i]^.FZamanlayiciDurum := zdDurduruldu;
      Result := ZamanlayiciListesi[i];
      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  zamanlay�c� nesnesini yok eder.
 ==============================================================================}
procedure TZamanlayici.YokEt;
begin

  // e�er zamanlay�c� nesnesinin durumu bo� de�il ise
  if(FZamanlayiciDurum <> zdBos) then
  begin

    // bo� olarak i�aretle
    FZamanlayiciDurum := zdBos;

    // zamanlay�c� nesnesini bir azalt
    Dec(OlusturulanZamanlayiciSayisi);
  end;
end;

{==============================================================================
  zamanlay�c�lar� tetikler (IRQ00 taraf�ndan �a�r�l�r)
 ==============================================================================}
procedure ZamanlayicilariKontrolEt;
var
  Gorev: PGorev;
  Olay: TOlay;
  GeriSayimSayaci, i: TISayi4;
begin

  // zamanlay�c� nesnesi yok ise ��k
  if(OlusturulanZamanlayiciSayisi = 0) then Exit;

  // t�m zamanlay�c� nesnelerini denetle
  for i := 1 to AZAMI_ZAMANLAYICI_SAYISI do
  begin

    // e�er �al���yorsa
    if(ZamanlayiciListesi[i]^.FZamanlayiciDurum = zdCalisiyor) then
    begin

      // zamanlay�c� sayac�n� 1 azalt
      GeriSayimSayaci := ZamanlayiciListesi[i]^.GeriSayimSayaci;
      Dec(GeriSayimSayaci);
      ZamanlayiciListesi[i]^.GeriSayimSayaci := GeriSayimSayaci;

      // saya� 0 de�erini bulmu�sa
      if(GeriSayimSayaci = 0) then
      begin

        // yeni say�m i�in geri say�m de�erini yeniden y�kle
        ZamanlayiciListesi[i]^.GeriSayimSayaci := ZamanlayiciListesi[i]^.TetiklemeSuresi;

        Olay.Kimlik := i;
        Olay.Olay := CO_ZAMANLAYICI;
        Olay.Deger1 := 0;
        Olay.Deger2 := 0;

        if not(ZamanlayiciListesi[i]^.FOlayYonlendirmeAdresi = nil) then

          ZamanlayiciListesi[i]^.FOlayYonlendirmeAdresi(nil, Olay)
        else
        begin

          Gorev := GorevListesi[ZamanlayiciListesi[i]^.GorevKimlik];
          Gorev^.OlayEkle(Gorev^.GorevKimlik, Olay);
        end;
      end;
    end;
  end;
end;

{==============================================================================
  bir s�re�e ait t�m zamanlay�c� nesnelerini yok eder.
 ==============================================================================}
procedure ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
var
  Zamanlayici: PZamanlayici = nil;
  i: TISayi4;
begin

  // t�m zamanlay�c� nesnelerini ara
  for i := 1 to AZAMI_ZAMANLAYICI_SAYISI do
  begin

    Zamanlayici := ZamanlayiciListesi[i];

    // zamanlay�c� nesnesi aranan i�leme mi ait
    if(Zamanlayici^.GorevKimlik = AGorevKimlik) then
    begin

      // nesneyi yok et
      Zamanlayici^.YokEt;
    end;
  end;
end;

{==============================================================================
  milisaniye cinsinden bekleme i�lemi yapar
  100 milisaniye = 1 saniye
 ==============================================================================}
{ TODO : �nemli bilgi: bu i�lev ana thread'� bekletmekte, dolay�s�yla sistemi
  belirtilen s�re kadar kilitlemektedir. bu problemin �n�ne ge�mek i�in thread
  �al��mas� ger�ekle�tirilecek }
procedure BekleMS(AMilisaniye: TSayi4);
var
  Sayac: TSayi4;
begin

  // AMilisaniye * 100 saniye bekle
  Sayac := ZamanlayiciSayaci + AMilisaniye;
  while (Sayac > ZamanlayiciSayaci) do begin asm int $20; end; end;
end;

{==============================================================================
  tek g�revli ortamda (�oklu ortama ge�meden �nce) �al��an zamanlay�c� i�levi
 ==============================================================================}
procedure TekGorevZamanlayiciIslevi;
begin

  { TODO : �al��abilirli�i test edilecek }
  Inc(ZamanlayiciSayaci);
end;

{==============================================================================
  donan�m taraf�ndan g�rev de�i�tirme i�levlerini yerine getirir.
 ==============================================================================}
procedure OtomatikGorevDegistir; nostackframe; assembler;
asm

  cli

  // de�i�ime u�rayacak yazma�lar� sakla
  pushad
  pushfd

  // �al��an g�revin DS yazmac�n� sakla
  // not : ds = es = ss = fs = gs oldu�u i�in tek yazmac�n saklanmas� yeterlidir.
  mov   ax,ds
  push  eax

  // yazma�lar� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  // zamanlay�c� sayac�n� art�r.
  mov ecx,ZamanlayiciSayaci
  inc ecx
  mov ZamanlayiciSayaci,ecx

  mov eax,GorevDegisimBayragi
  cmp eax,0
  je  @@cik

  mov   eax,CokluGorevBasladi
  cmp   eax,1
  je    @@kontrol1

@@cik:
  // �al��an proses'in segment yazma�lar�n� eski konumuna geri d�nd�r
  pop   eax
  mov   ds,ax
  mov   es,ax

  mov   al,$20
  out   PIC1_KOMUT,al

  // genel yazma�lar� geri y�kle ve kesmeden ��k
  popfd
  popad
  sti
  iretd

@@kontrol1:

  { rutin i�lev kontrollerinin ger�ekle�tirildi�i k�s�m }

  // uygulamalar taraf�ndan olu�turulan zamanlay�c� nesnelerini denetle
  call  ZamanlayicilariKontrolEt

  // her 1 saniyede kontrol edilecek dahili i�levler
  mov edx,0
  mov eax,ZamanlayiciSayaci
  mov ecx,100
  div ecx
  cmp edx,0
  jg  @@yenigorev

  // ARP tablosunu g��ncelle
  call  ARPTablosunuGuncelle

@@yenigorev:

  // tek bir g�rev �al���yorsa g�rev de�i�ikli�i yapma, ��k
  mov ecx,CalisanGorevSayisi
  cmp ecx,1
  je  @@cik

  // ge�i� yap�lacak bir sonraki g�revi bul
  call  CalistirilacakBirSonrakiGoreviBul
  mov CalisanGorev,eax

  // aktif g�revin bellek ba�lang�� adresini al
  dec eax
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,[esi + TGorev.FBellekBaslangicAdresi]
  mov CalisanGorevBellekAdresi,eax

  // g�rev de�i�iklik sayac�n� bir art�r
  mov eax,[esi + TGorev.FGorevSayaci]
  inc eax
  mov [esi + TGorev.FGorevSayaci],eax

  // GorevDegisimSayisi = kilitlenmeleri denetleyebilmek i�in eklenen de�i�ken
  mov eax,GorevDegisimSayisi
  inc eax
  mov GorevDegisimSayisi,eax

  // g�revin devredilece�i TSS giri�ini belirle
  mov   ecx,CalisanGorev
  cmp   ecx,1
  je    @@TSS_SISTEM
  cmp   ecx,2
  je    @@TSS_CAGRI
  cmp   ecx,3
  je    @@TSS_GRAFIK

@@TSS_UYGULAMA:
  sub   ecx,AYRILMIS_GOREV_SAYISI + 1
  imul  ecx,3
  add   ecx,AYRILMIS_SECICISAYISI + 2
  imul  ecx,8
  add   ecx,3                             // DPL3 - uygulama
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_SISTEM:
  mov   ecx,SECICI_SISTEM_TSS * 8         // DPL0 - sistem
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_CAGRI:
  mov   ecx,SECICI_CAGRI_TSS * 8          // DPL0 - sistem
//  add   ecx,3
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_GRAFIK:
  mov   ecx,SECICI_GRAFIK_TSS * 8         // DPL0 - sistem
//  add   ecx,3
  mov   @@SECICI,cx

@@son:

  // �al��an g�revin se�ici (selector) yazma�lar�n� eski konumuna geri d�nd�r
  pop   eax
  mov   ds,ax
  mov   es,ax

  // EOI - kesme sonu
  mov   al,$20
  out   PIC1_KOMUT,al

  // �al��an g�revin genel yazma�lar�n� eski konumuna geri d�nd�r
  popfd
  popad

  sti

// i�lemi belirtilen proses'e devret
@@JMPKOD: db  $EA
@@ADRES:  dd  0       // donan�m destekli g�rev de�i�imlerinde ADRES (offset) g�zard� edilir
@@SECICI: dw  0
  iretd
end;

{==============================================================================
  yaz�l�m taraf�ndan g�rev de�i�tirme i�levlerini yerine getirir.
 ==============================================================================}
procedure ElleGorevDegistir; nostackframe; assembler;
asm

  int $20
  ret

  { TODO - a�a��daki kodlar ge�ici olarak devre d��� }

  // alttaki kodlar iptal edilebilir mi? test edilecek - 10.11.2019
  cli
  pushad
  pushfd

  mov   eax,CokluGorevBasladi
  cmp   eax,1
  je    @@kontrol1

  // genel yazma�lar� geri y�kle ve i�levden ��k
  popfd
  popad
  sti
  ret

@@kontrol1:

  mov ecx,CalisanGorevSayisi
  cmp ecx,1
  jg  @@yenigorev

  popfd
  popad
  sti
  ret

@@yenigorev:

  call  CalistirilacakBirSonrakiGoreviBul
  mov CalisanGorev,eax

  // aktif g�revin bellek ba�lang�� adresini al
  mov eax,CalisanGorev
  dec eax
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,[esi + TGorev.FBellekBaslangicAdresi]
  mov CalisanGorevBellekAdresi,eax

  // g�rev de�i�iklik sayac�n� bir art�r
  mov eax,CalisanGorev
  dec eax
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,[esi + TGorev.FGorevSayaci]
  inc eax
  mov [esi + TGorev.FGorevSayaci],eax

  // g�revin devredilece�i TSS giri�ini belirle
  mov   ecx,CalisanGorev
  cmp   ecx,1
  je    @@TSS_SISTEM
  cmp   ecx,2
  je    @@TSS_CAGRI
  cmp   ecx,3
  je    @@TSS_GRAFIK

@@TSS_UYGULAMA:
  sub   ecx,AYRILMIS_GOREV_SAYISI + 1
  imul  ecx,3
  add   ecx,AYRILMIS_SECICISAYISI + 2
  imul  ecx,8
  add   ecx,3                             // DPL3 - uygulama
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_SISTEM:
  mov   ecx,SECICI_SISTEM_TSS * 8         // DPL0 - sistem
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_CAGRI:
  mov   ecx,SECICI_CAGRI_TSS * 8          // DPL0 - sistem
//  add   ecx,3
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_GRAFIK:
  mov   ecx,SECICI_GRAFIK_TSS * 8         // DPL0 - sistem
//  add   ecx,3
  mov   @@SECICI,cx

@@son:
  popfd
  popad

@@JMPKOD: db  $EA
@@ADRES:  dd  0
@@SECICI: dw  0
  sti
  ret
end;

end.

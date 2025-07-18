{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: zamanlayici.pas
  Dosya ��levi: zamanlay�c� y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 05/07/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit zamanlayici;

interface

uses paylasim, port, gorselnesne;

const
  AZAMI_ZAMANLAYICI_SAYISI = 64;

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
  ZamanlayiciBellekAdresi: Isaretci;
  OlusturulanZamanlayiciSayisi: TSayi4 = 0;
  GZamanlayiciListesi: array[0..AZAMI_ZAMANLAYICI_SAYISI - 1] of PZamanlayici;

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
  Z: PZamanlayici;
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

  // zamanlay�c� bilgilerinin yerle�tirilece�i bellek b�lgesini olu�tur
  ZamanlayiciBellekAdresi := GetMem(AZAMI_ZAMANLAYICI_SAYISI * ZamanlayiciU);

  // bellek b�lgesini zamanlay�c� yap�lar�yla e�le�tir
  BellekAdresi := ZamanlayiciBellekAdresi;
  for i := 0 to AZAMI_ZAMANLAYICI_SAYISI - 1 do
  begin

    Z := BellekAdresi;
    GZamanlayiciListesi[i] := Z;

    Z^.FZamanlayiciDurum := zdBos;
    Z^.FKimlik := i;
    Z^.FOlayYonlendirmeAdresi := nil;

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
  Z: PZamanlayici;
begin

  // bo� bir zamanlay�c� nesnesi bul
  Z := BosZamanlayiciBul;
  if(Z <> nil) then
  begin

    Z^.FGorevKimlik := FAktifGorev;
    Z^.FTetiklemeSuresi := AMiliSaniye;
    Z^.FGeriSayimSayaci := AMiliSaniye;
    Z^.FOlayYonlendirmeAdresi := nil;

    Inc(OlusturulanZamanlayiciSayisi);

    Exit(Z);
  end;

  // geri d�n�� de�eri
  Result := nil;
end;

{==============================================================================
  bo� (kullan�lmayan) zamanlay�c� bulur
 ==============================================================================}
function TZamanlayici.BosZamanlayiciBul: PZamanlayici;
var
  i: TSayi4;
begin

  // t�m zamanlay�c� nesnelerini ara
  for i := 0 to AZAMI_ZAMANLAYICI_SAYISI - 1 do
  begin

    // zamanlay�c� nesnesinin durumu bo� ise
    if(GZamanlayiciListesi[i]^.FZamanlayiciDurum = zdBos) then
    begin

      // durduruldu olarak i�aretle ve �a��ran i�leve geri d�n
      GZamanlayiciListesi[i]^.FZamanlayiciDurum := zdDurduruldu;
      Result := GZamanlayiciListesi[i];
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
  for i := 0 to AZAMI_ZAMANLAYICI_SAYISI - 1 do
  begin

    // e�er �al���yorsa
    if(GZamanlayiciListesi[i]^.FZamanlayiciDurum = zdCalisiyor) then
    begin

      // zamanlay�c� sayac�n� 1 azalt
      GeriSayimSayaci := GZamanlayiciListesi[i]^.GeriSayimSayaci;
      Dec(GeriSayimSayaci);
      GZamanlayiciListesi[i]^.GeriSayimSayaci := GeriSayimSayaci;

      // saya� 0 de�erini bulmu�sa
      if(GeriSayimSayaci = 0) then
      begin

        // yeni say�m i�in geri say�m de�erini yeniden y�kle
        GZamanlayiciListesi[i]^.GeriSayimSayaci := GZamanlayiciListesi[i]^.TetiklemeSuresi;

        Olay.Kimlik := i;
        Olay.Olay := CO_ZAMANLAYICI;
        Olay.Deger1 := 0;
        Olay.Deger2 := 0;

        if not(GZamanlayiciListesi[i]^.FOlayYonlendirmeAdresi = nil) then

          GZamanlayiciListesi[i]^.FOlayYonlendirmeAdresi(nil, Olay)
        else
        begin

          Gorev := GorevAl(GZamanlayiciListesi[i]^.GorevKimlik);
          GGorevler.OlayEkle(Gorev^.GorevKimlik, Olay);
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
  Z: PZamanlayici = nil;
  i: TSayi4;
begin

  // t�m zamanlay�c� nesnelerini ara
  for i := 0 to AZAMI_ZAMANLAYICI_SAYISI - 1 do
  begin

    Z := GZamanlayiciListesi[i];

    // zamanlay�c� nesnesi aranan i�leme mi ait
    if(Z^.GorevKimlik = AGorevKimlik) then
    begin

      // nesneyi yok et
      Z^.YokEt;
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
  while (Sayac > ZamanlayiciSayaci) do;
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
  mov   ecx,ZamanlayiciSayaci
  inc   ecx
  mov   ZamanlayiciSayaci,ecx

  mov   eax,GorevDegisimBayragi
  cmp   eax,0
  je    @@cik

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

  // uygulamalar taraf�ndan olu�turulan zamanlay�c� nesnelerini denetle
  call  ZamanlayicilariKontrolEt

  // her 1 saniyede kontrol edilecek dahili i�levler - (�u a�amada gerekli de�il)
{  mov edx,0
  mov eax,ZamanlayiciSayaci
  mov ecx,100
  div ecx
  cmp edx,0
  jg  @@yenigorev }

@@yenigorev:

  // tek bir g�rev �al���yorsa g�rev de�i�ikli�i yapma, ��k
  mov   ecx,CalisanGorevSayisi
  cmp   ecx,1
  je    @@cik
{
  // g�revin belirlenen s�re kadar �al��mas�n� sa�la
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,GorevListesi[eax]
  mov   eax,[esi + TGorev.FCalismaSuresiSayacMS]
  dec   eax
  jz    @@bir_sonraki_gorev
  mov   [esi + TGorev.FCalismaSuresiSayacMS],eax
  jmp   @@cik

@@bir_sonraki_gorev:

  // sayac� �nde�ere e�itle
  mov   eax,[esi + TGorev.FCalismaSuresiMS]
  mov   [esi + TGorev.FCalismaSuresiSayacMS],eax
}
  // ge�i� yap�lacak bir sonraki g�revi bul
  call  CalistirilacakBirSonrakiGoreviBul
  mov   FAktifGorev,eax

  // aktif g�revin bellek ba�lang�� adresini al
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,GorevListesi[eax]
  mov   esi,[esi + TGorev.G0]
  mov   eax,[esi + TGorev0.FBellekBaslangicAdresi]
  mov   FAktifGorevBellekAdresi,eax

  // g�rev de�i�iklik sayac�n� bir art�r
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,GorevListesi[eax]
  mov   esi,[esi + TGorev.G0]
  mov   eax,[esi + TGorev0.FGorevSayaci]
  inc   eax
  mov   [esi + TGorev0.FGorevSayaci],eax

  // GorevDegisimSayisi = kilitlenmeleri denetleyebilmek i�in eklenen de�i�ken
  mov   eax,GorevDegisimSayisi
  inc   eax
  mov   GorevDegisimSayisi,eax

  // g�revin �ncelik seviyesine g�re g�rev ge�i�ini ger�ekle�tir
  mov   ecx,FAktifGorev
  mov   eax,ecx
  shl   eax,2
  mov   esi,GorevListesi[eax]
  mov   esi,[esi + TGorev.G0]
  mov   eax,[esi + TGorev0.FSeviyeNo]
  cmp   eax,CALISMA_SEVIYE0
  jz    @@TSS_SEVIYE0

// DPL3 - uygulama yaz�l�mlar� i�in (ring3)
@@TSS_SEVIYE3:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
  add   ecx,3
  mov   @@SECICI,cx
  jmp   @@son

// DPL0 - sistem yaz�l�mlar� i�in (ring0)
@@TSS_SEVIYE0:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
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

// i�lemi belirtilen g�reve devret
@@JMPKOD:
  db  $EA
// donan�m destekli g�rev de�i�imlerinde ADRES (offset) g�zard� edilir
@@ADRES:
  dd  0
@@SECICI:
  dw  0

  iretd
end;

{==============================================================================
  yaz�l�m taraf�ndan g�rev de�i�tirme i�levlerini yerine getirir.
 ==============================================================================}
procedure ElleGorevDegistir; nostackframe; assembler;
asm

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

  mov   ecx,CalisanGorevSayisi
  cmp   ecx,1
  jg    @@yenigorev

  popfd
  popad
  sti
  ret

@@yenigorev:

  call  CalistirilacakBirSonrakiGoreviBul
//  mov   eax,0
  mov   FAktifGorev,eax

  // aktif g�revin bellek ba�lang�� adresini al
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,GorevListesi[eax]
  mov   esi,[esi + TGorev.G0]
  mov   eax,[esi + TGorev0.FBellekBaslangicAdresi]
  mov   FAktifGorevBellekAdresi,eax

  // g�rev de�i�iklik sayac�n� bir art�r
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,GorevListesi[eax]
  mov   esi,[esi + TGorev.G0]
  mov   eax,[esi + TGorev0.FGorevSayaci]
  inc   eax
  mov   [esi + TGorev0.FGorevSayaci],eax

  // g�revin �ncelik seviyesine g�re g�rev ge�i�ini ger�ekle�tir
  mov   ecx,FAktifGorev
  mov   eax,ecx
  shl   eax,2
  mov   esi,GorevListesi[eax]
  mov   esi,[esi + TGorev.G0]
  mov   eax,[esi + TGorev0.FSeviyeNo]
  cmp   eax,CALISMA_SEVIYE0
  jz    @@TSS_SEVIYE0

// DPL3 - uygulama yaz�l�mlar� i�in (ring3)
@@TSS_SEVIYE3:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
  add   ecx,3
  mov   @@SECICI,cx
  jmp   @@son

// DPL0 - sistem yaz�l�mlar� i�in (ring0)
@@TSS_SEVIYE0:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
  mov   @@SECICI,cx

@@son:
  popfd
  popad

// i�lemi belirtilen g�reve devret
@@JMPKOD:
  db  $EA
// donan�m destekli g�rev de�i�imlerinde ADRES (offset) g�zard� edilir
@@ADRES:
  dd  0
@@SECICI:
  dw  0

  sti
  ret
end;

end.

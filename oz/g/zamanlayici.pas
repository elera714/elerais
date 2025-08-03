{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: zamanlayici.pas
  Dosya ��levi: zamanlay�c� y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 23/07/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit zamanlayici;

interface

uses paylasim, port, gorselnesne;

const
  USTSINIR_ZAMANLAYICI = 128;

type
  //  TODO             zdIptal buradan ve api i�levlerinden ��kar�larak iptal edilecek
  TZamanlayiciDurum = (zdIptal, zdCalisiyor, zdDurduruldu);

type
  PZamanlayici = ^TZamanlayici;
  TZamanlayici = record
    Kimlik: TKimlik;
    GorevKimlik: TKimlik;
    ZamanlayiciDurum: TZamanlayiciDurum;
    TetiklemeSuresi, GeriSayimSayaci: TSayi4;
    OlayYonlendirmeAdresi: TOlaylariIsle;
  end;

type
  PZamanlayicilar = ^TZamanlayicilar;
  TZamanlayicilar = object
  private
    FOlusturulanZamanlayici: TSayi4;
    FZamanlayiciListesi: array[0..USTSINIR_ZAMANLAYICI - 1] of PZamanlayici;
    function ZamanlayiciAl(ASiraNo: TSayi4): PZamanlayici;
    procedure ZamanlayiciYaz(ASiraNo: TSayi4; AZamanlayici: PZamanlayici);
  public
    procedure Yukle;
    function Olustur(AMiliSaniye: TSayi4): PZamanlayici;
    function BosZamanlayiciBul: PZamanlayici;
    procedure YokEt(AZamanlayici: PZamanlayici);
    property Zamanlayici[ASiraNo: TSayi4]: PZamanlayici read ZamanlayiciAl write ZamanlayiciYaz;
    property OlusturulanZamanlayici: TSayi4 read FOlusturulanZamanlayici write FOlusturulanZamanlayici;
  end;

var
  Zamanlayicilar0: TZamanlayicilar;
  ZamanlayicilarKilit: TSayi4 = 0;

procedure ZamanlayicilariKontrolEt;
procedure ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
procedure BekleMS(AMilisaniye: TSayi4);
procedure TekGorevZamanlayiciIslevi;
procedure OtomatikGorevDegistir;
procedure ElleGorevDegistir;

implementation

uses gorev, idt, irq, pit, pic;

{==============================================================================
  zamanlay�c� nesnelerinin ana y�kleme i�levlerini i�erir
 ==============================================================================}
procedure TZamanlayicilar.Yukle;
var
  i: TSayi4;
begin

  // kesmeleri durdur
  cli;

  IRQPasiflestir(0);

  // IRQ0 giri� noktas�n� yeniden belirle
  // %10001110 = 1 = mevcut, 00 = DPL0, 0, 1 = 32 bit kod, 110 - kesme kap�s�
  KesmeGirisiBelirle($20, @OtomatikGorevDegistir, SECICI_SISTEM_KOD * 8, %10001110);

  // saat vuru� frekans�n� d�zenle. 100 tick = 1 saniye
  ZamanlayiciFrekansiniDegistir(100);

  // �al��an zamanlay�c� say�s�n� s�f�rla
  OlusturulanZamanlayici := 0;

  // bellek b�lgesini zamanlay�c� yap�lar�yla e�le�tir
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do Zamanlayici[i] := nil;

  // IRQ0'� etkinle�tir
  IRQEtkinlestir(0);

  // kesmeleri aktifle�tir
  sti;
end;

function TZamanlayicilar.ZamanlayiciAl(ASiraNo: TSayi4): PZamanlayici;
begin

  // istenen verinin belirtilen aral�kta olup olmad���n� kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_ZAMANLAYICI) then
    Result := FZamanlayiciListesi[ASiraNo]
  else Result := nil;
end;

procedure TZamanlayicilar.ZamanlayiciYaz(ASiraNo: TSayi4; AZamanlayici: PZamanlayici);
begin

  // istenen verinin belirtilen aral�kta olup olmad���n� kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_ZAMANLAYICI) then
    FZamanlayiciListesi[ASiraNo] := AZamanlayici;
end;

{==============================================================================
  zamanlay�c� nesnesi olu�turur
 ==============================================================================}
function TZamanlayicilar.Olustur(AMiliSaniye: TSayi4): PZamanlayici;
var
  Z: PZamanlayici;
  i: TSayi4;
begin

  // bo� bir zamanlay�c� nesnesi bul
  Z := BosZamanlayiciBul;
  if(Z <> nil) then
  begin

    Z^.TetiklemeSuresi := AMiliSaniye;
    Z^.GeriSayimSayaci := AMiliSaniye;
    Z^.OlayYonlendirmeAdresi := nil;

    i := OlusturulanZamanlayici;
    Inc(i);
    OlusturulanZamanlayici := i;

    Exit(Z);
  end;

  // geri d�n�� de�eri
  Result := Z;
end;

{==============================================================================
  bo� (kullan�lmayan) zamanlay�c� bulur
 ==============================================================================}
function TZamanlayicilar.BosZamanlayiciBul: PZamanlayici;
var
  Z: PZamanlayici;
  i: TSayi4;
begin

  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // t�m zamanlay�c� nesnelerini ara
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := Zamanlayici[i];
    if(Z = nil) then
    begin

      // nesne i�in bellekte yer ay�r ve nesne i�aret�isini listeye ekle
      Z := GetMem(SizeOf(TZamanlayici));
      Zamanlayici[i] := Z;

      // ilk de�er atamalar�
      Z^.Kimlik := i;
      Z^.GorevKimlik := FAktifGorev;
      Z^.ZamanlayiciDurum := zdDurduruldu;

      KritikBolgedenCik(ZamanlayicilarKilit);
      Exit(Z);
    end;
  end;

  KritikBolgedenCik(ZamanlayicilarKilit);

  Result := nil;
end;

{==============================================================================
  zamanlay�c� nesnesini yok eder.
 ==============================================================================}
procedure TZamanlayicilar.YokEt(AZamanlayici: PZamanlayici);
var
  i: TSayi4;
begin

  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // e�er zamanlay�c� nesnesinin durumu bo� de�il ise
  if not(AZamanlayici = nil) then
  begin

    // zamanlay�c nesnesini listeden ��kar
    Zamanlayici[AZamanlayici^.Kimlik] := nil;

    // zamanlay�c� i�in bellekte ayr�lan yeri yok et
    FreeMem(AZamanlayici, SizeOf(TZamanlayici));

    // zamanlay�c� nesnesini bir azalt
    i := OlusturulanZamanlayici;
    Dec(i);
    OlusturulanZamanlayici := i;
  end;

  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  zamanlay�c�lar� tetikler (IRQ00 taraf�ndan �a�r�l�r)
 ==============================================================================}
procedure ZamanlayicilariKontrolEt;
var
  G: PGorev;
  Z: PZamanlayici;
  Olay: TOlay;
  GeriSayimSayaci, i: TISayi4;
begin

  // zamanlay�c� nesnesi yok ise ��k
  if(Zamanlayicilar0.OlusturulanZamanlayici = 0) then Exit;

  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // t�m zamanlay�c� nesnelerini denetle
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := Zamanlayicilar0.Zamanlayici[i];

    // e�er �al���yorsa
    if not(Z = nil) and (Z^.ZamanlayiciDurum = zdCalisiyor) then
    begin

      // zamanlay�c� sayac�n� 1 azalt
      GeriSayimSayaci := Z^.GeriSayimSayaci;
      Dec(GeriSayimSayaci);
      Z^.GeriSayimSayaci := GeriSayimSayaci;

      // saya� 0 de�erini bulmu�sa
      if(GeriSayimSayaci = 0) then
      begin

        // yeni say�m i�in geri say�m de�erini yeniden y�kle
        Z^.GeriSayimSayaci := Z^.TetiklemeSuresi;

        Olay.Kimlik := i;
        Olay.Olay := CO_ZAMANLAYICI;
        Olay.Deger1 := 0;
        Olay.Deger2 := 0;

        if not(Z^.OlayYonlendirmeAdresi = nil) then

          Z^.OlayYonlendirmeAdresi(nil, Olay)
        else
        begin

          G := GorevAl(Z^.GorevKimlik);
          Gorevler0.OlayEkle(G^.Kimlik, Olay);
        end;
      end;
    end;
  end;

  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  bir s�re�e ait t�m zamanlay�c� nesnelerini yok eder.
 ==============================================================================}
procedure ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
var
  Z: PZamanlayici;
  i: TSayi4;
begin

  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // t�m zamanlay�c� nesnelerini ara
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := Zamanlayicilar0.Zamanlayici[i];

    // zamanlay�c� nesnesi aranan i�leme mi ait
    if not(Z = nil) and (Z^.GorevKimlik = AGorevKimlik) then
    begin

      // nesneyi yok et
      Zamanlayicilar0.YokEt(Z);
    end;
  end;

  KritikBolgedenCik(ZamanlayicilarKilit);
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

  mov   eax,GorevDegistirme
  cmp   eax,1
  je    @@cik

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
  mov   ecx,FCalisanGorevSayisi
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
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.BellekBaslangicAdresi]
  mov   FAktifGorevBellekAdresi,eax

  // g�rev de�i�iklik sayac�n� bir art�r
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.GorevSayaci]
  inc   eax
  mov   [esi + TGorev.GorevSayaci],eax

  // GorevDegisimSayisi = kilitlenmeleri denetleyebilmek i�in eklenen de�i�ken
  mov   eax,GorevDegisimSayisi
  inc   eax
  mov   GorevDegisimSayisi,eax

  // g�revin �ncelik seviyesine g�re g�rev ge�i�ini ger�ekle�tir
  mov   ecx,FAktifGorev
  mov   eax,ecx
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.SeviyeNo]
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

  mov   ecx,FCalisanGorevSayisi
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
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.BellekBaslangicAdresi]
  mov   FAktifGorevBellekAdresi,eax

  // g�rev de�i�iklik sayac�n� bir art�r
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.GorevSayaci]
  inc   eax
  mov   [esi + TGorev.GorevSayaci],eax

  // g�revin �ncelik seviyesine g�re g�rev ge�i�ini ger�ekle�tir
  mov   ecx,FAktifGorev
  mov   eax,ecx
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.SeviyeNo]
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

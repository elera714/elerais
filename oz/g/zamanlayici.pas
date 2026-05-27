{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: zamanlayici.pas
  Dosya Ýþlevi: zamanlayýcý yönetim iþlevlerini içerir

  Güncelleme Tarihi: 23/04/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit zamanlayici;

interface

uses paylasim, port, gorselnesne;

const
  USTSINIR_ZAMANLAYICI = 128;

type
  //  TODO             zdIptal buradan ve api iþlevlerinden çýkarýlarak iptal edilecek
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
    function ZamanlayiciAl(ASiraNo: TISayi4): PZamanlayici;
    procedure ZamanlayiciYaz(ASiraNo: TISayi4; AZamanlayici: PZamanlayici);
  public
    procedure Yukle;
    function Olustur(AMiliSaniye: TSayi4): PZamanlayici;
    function BosZamanlayiciBul: PZamanlayici;
    procedure YokEt(AZamanlayici: PZamanlayici);
    property Zamanlayici[ASiraNo: TISayi4]: PZamanlayici read ZamanlayiciAl write ZamanlayiciYaz;
    property OlusturulanZamanlayici: TSayi4 read FOlusturulanZamanlayici write FOlusturulanZamanlayici;
  end;

var
  Zamanlayicilar0: TZamanlayicilar;
  ZamanlayicilarKilit: TSayi4 = 0;

procedure ZamanlayicilariKontrolEt;
procedure ZamanlayicilariDurdur(AGorevKimlik: TKimlik);
procedure ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
procedure BekleMS(AMilisaniye: TSayi4);
procedure TekGorevZamanlayiciIslevi;
procedure OtomatikGorevDegistir;
procedure ElleGorevDegistir;

implementation

uses gorev, idt, irq, pit, pic, sistemmesaj;

{==============================================================================
  zamanlayýcý nesnelerinin ana yükleme iþlevlerini içerir
 ==============================================================================}
procedure TZamanlayicilar.Yukle;
var
  i: TSayi4;
begin

  // kesmeleri durdur
  cli;

  IRQPasiflestir(0);

  // IRQ0 giriþ noktasýný yeniden belirle
  // %10001110 = 1 = mevcut, 00 = DPL0, 0, 1 = 32 bit kod, 110 - kesme kapýsý
  KesmeGirisiBelirle($20, @OtomatikGorevDegistir, SECICI_SISTEM_KOD * 8, %10001110);

  // saat vuruþ frekansýný düzenle. 100 tick = 1 saniye
  ZamanlayiciFrekansiniDegistir(100);

  // çalýþan zamanlayýcý sayýsýný sýfýrla
  OlusturulanZamanlayici := 0;

  // bellek bölgesini zamanlayýcý yapýlarýyla eþleþtir
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do Zamanlayici[i] := nil;

  // IRQ0'ý etkinleþtir
  IRQEtkinlestir(0);

  // kesmeleri aktifleþtir
  sti;
end;

function TZamanlayicilar.ZamanlayiciAl(ASiraNo: TISayi4): PZamanlayici;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_ZAMANLAYICI) then
    Result := FZamanlayiciListesi[ASiraNo]
  else Result := nil;
end;

procedure TZamanlayicilar.ZamanlayiciYaz(ASiraNo: TISayi4; AZamanlayici: PZamanlayici);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_ZAMANLAYICI) then
    FZamanlayiciListesi[ASiraNo] := AZamanlayici;
end;

{==============================================================================
  zamanlayýcý nesnesi oluþturur
 ==============================================================================}
function TZamanlayicilar.Olustur(AMiliSaniye: TSayi4): PZamanlayici;
var
  Z: PZamanlayici;
  i: TSayi4;
begin

  // boþ bir zamanlayýcý nesnesi bul
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

  // geri dönüþ deðeri
  Result := Z;
end;

{==============================================================================
  boþ (kullanýlmayan) zamanlayýcý bulur
 ==============================================================================}
function TZamanlayicilar.BosZamanlayiciBul: PZamanlayici;
var
  Z: PZamanlayici;
  i: TSayi4;
begin

//  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // tüm zamanlayýcý nesnelerini ara
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := Zamanlayici[i];
    if(Z = nil) then
    begin

      // nesne için bellekte yer ayýr ve nesne iþaretçisini listeye ekle
      Z := GetMem(SizeOf(TZamanlayici));
      Zamanlayici[i] := Z;

      // ilk deðer atamalarý
      Z^.Kimlik := i;
      Z^.GorevKimlik := FAktifGorev;
      Z^.ZamanlayiciDurum := zdDurduruldu;

//      KritikBolgedenCik(ZamanlayicilarKilit);
      Exit(Z);
    end;
  end;

//  KritikBolgedenCik(ZamanlayicilarKilit);

  Result := nil;
end;

{==============================================================================
  zamanlayýcý nesnesini yok eder.
 ==============================================================================}
procedure TZamanlayicilar.YokEt(AZamanlayici: PZamanlayici);
var
  i: TSayi4;
begin

//  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // eðer zamanlayýcý nesnesinin durumu boþ deðil ise
  if not(AZamanlayici = nil) then
  begin

    // zamanlayýc nesnesini listeden çýkar
    Zamanlayici[AZamanlayici^.Kimlik] := nil;

    // zamanlayýcý için bellekte ayrýlan yeri yok et
    FreeMem(AZamanlayici, SizeOf(TZamanlayici));

    // zamanlayýcý nesnesini bir azalt
    i := OlusturulanZamanlayici;
    Dec(i);
    OlusturulanZamanlayici := i;
  end;

//  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  zamanlayýcýlarý tetikler (IRQ00 tarafýndan çaðrýlýr)
 ==============================================================================}
procedure ZamanlayicilariKontrolEt;
var
  G: PGorev;
  Z: PZamanlayici;
  Olay: TOlay;
  GeriSayimSayaci, i: TISayi4;
begin

  // zamanlayýcý nesnesi yok ise çýk
  if(Zamanlayicilar0.OlusturulanZamanlayici = 0) then Exit;

//  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // tüm zamanlayýcý nesnelerini denetle
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := Zamanlayicilar0.Zamanlayici[i];

    // eðer çalýþýyorsa
    if not(Z = nil) and (Z^.ZamanlayiciDurum = zdCalisiyor) then
    begin

      // zamanlayýcý sayacýný 1 azalt
      GeriSayimSayaci := Z^.GeriSayimSayaci;
      Dec(GeriSayimSayaci);
      Z^.GeriSayimSayaci := GeriSayimSayaci;

      // sayaç 0 deðerini bulmuþsa
      if(GeriSayimSayaci = 0) then
      begin

        // yeni sayým için geri sayým deðerini yeniden yükle
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

//  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  bir süreçe ait tüm zamanlayýcý nesnelerini durdurur
 ==============================================================================}
procedure ZamanlayicilariDurdur(AGorevKimlik: TKimlik);
var
  Z: PZamanlayici;
  i: TSayi4;
begin

//  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // tüm zamanlayýcý nesnelerini ara
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := Zamanlayicilar0.Zamanlayici[i];

    // zamanlayýcý nesnesi aranan iþleme mi ait
    if not(Z = nil) and (Z^.GorevKimlik = AGorevKimlik) then
    begin

      // nesneyi yok et
      Z^.ZamanlayiciDurum := zdDurduruldu;
    end;
  end;

//  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  bir süreçe ait tüm zamanlayýcý nesnelerini yok eder.
 ==============================================================================}
procedure ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
var
  Z: PZamanlayici;
  i: TSayi4;
begin

//  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // tüm zamanlayýcý nesnelerini ara
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := Zamanlayicilar0.Zamanlayici[i];

    // zamanlayýcý nesnesi aranan iþleme mi ait
    if not(Z = nil) and (Z^.GorevKimlik = AGorevKimlik) then
    begin

      // nesneyi yok et
      Zamanlayicilar0.YokEt(Z);
    end;
  end;

//  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  milisaniye cinsinden bekleme iþlemi yapar
  100 milisaniye = 1 saniye
 ==============================================================================}
{ TODO : önemli bilgi: bu iþlev ana thread'ý bekletmekte, dolayýsýyla sistemi
  belirtilen süre kadar kilitlemektedir. bu problemin önüne geçmek için thread
  çalýþmasý gerçekleþtirilecek }
procedure BekleMS(AMilisaniye: TSayi4);
var
  Sayac: TSayi4;
begin

  // AMilisaniye * 100 saniye bekle
  Sayac := ZamanlayiciSayaci + AMilisaniye;
  while (Sayac > ZamanlayiciSayaci) do;
end;

{==============================================================================
  tek görevli ortamda (çoklu ortama geçmeden önce) çalýþan zamanlayýcý iþlevi
 ==============================================================================}
procedure TekGorevZamanlayiciIslevi;
begin

  { TODO : çalýþabilirliði test edilecek }
  Inc(ZamanlayiciSayaci);
end;

{==============================================================================
  donaným tarafýndan görev deðiþtirme iþlevlerini yerine getirir.
 ==============================================================================}
procedure OtomatikGorevDegistir; nostackframe; assembler;
asm

  cli

  // deðiþime uðrayacak yazmaçlarý sakla
  pushad
  pushfd

  // çalýþan görevin DS yazmacýný sakla
  // not : ds = es = ss = fs = gs olduðu için tek yazmacýn saklanmasý yeterlidir.
  mov   ax,ds
  push  eax

  // yazmaçlarý sistem yazmaçlarýna ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov   eax,GorevDegistirme
  cmp   eax,1
  je    @@cik

  // zamanlayýcý sayacýný artýr.
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
  // çalýþan proses'in segment yazmaçlarýný eski konumuna geri döndür
  pop   eax
  mov   ds,ax
  mov   es,ax

  mov   al,$20
  out   PIC1_KOMUT,al

  // genel yazmaçlarý geri yükle ve kesmeden çýk
  popfd
  popad
  sti
  iretd

@@kontrol1:

  // uygulamalar tarafýndan oluþturulan zamanlayýcý nesnelerini denetle
  call  ZamanlayicilariKontrolEt

  // her 1 saniyede kontrol edilecek dahili iþlevler - (þu aþamada gerekli deðil)
{  mov edx,0
  mov eax,ZamanlayiciSayaci
  mov ecx,100
  div ecx
  cmp edx,0
  jg  @@yenigorev }

@@yenigorev:

  // tek bir görev çalýþýyorsa görev deðiþikliði yapma, çýk
  mov   ecx,FCalisanGorevSayisi
  cmp   ecx,1
  je    @@cik
{
  // görevin belirlenen süre kadar çalýþmasýný saðla
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,GorevListesi[eax]
  mov   eax,[esi + TGorev.FCalismaSuresiSayacMS]
  dec   eax
  jz    @@bir_sonraki_gorev
  mov   [esi + TGorev.FCalismaSuresiSayacMS],eax
  jmp   @@cik

@@bir_sonraki_gorev:

  // sayacý öndeðere eþitle
  mov   eax,[esi + TGorev.FCalismaSuresiMS]
  mov   [esi + TGorev.FCalismaSuresiSayacMS],eax
}
  // geçiþ yapýlacak bir sonraki görevi bul
  call  CalistirilacakBirSonrakiGoreviBul
  mov   FAktifGorev,eax

  // aktif görevin bellek baþlangýç adresini al
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.BellekBaslangicAdresi]
  mov   FAktifGorevBellekAdresi,eax

  // görev deðiþiklik sayacýný bir artýr
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.GorevSayaci]
  inc   eax
  mov   [esi + TGorev.GorevSayaci],eax

  // GorevDegisimSayisi = kilitlenmeleri denetleyebilmek için eklenen deðiþken
  mov   eax,GorevDegisimSayisi
  inc   eax
  mov   GorevDegisimSayisi,eax

  // görevin öncelik seviyesine göre görev geçiþini gerçekleþtir
  mov   ecx,FAktifGorev
  mov   eax,ecx
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.SeviyeNo]
  cmp   eax,CALISMA_SEVIYE0
  jz    @@TSS_SEVIYE0

// DPL3 - uygulama yazýlýmlarý için (ring3)
@@TSS_SEVIYE3:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
//  add   ecx,3
  mov   @@SECICI,cx
  jmp   @@son

// DPL0 - sistem yazýlýmlarý için (ring0)
@@TSS_SEVIYE0:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
  mov   @@SECICI,cx

@@son:

  // çalýþan görevin seçici (selector) yazmaçlarýný eski konumuna geri döndür
  pop   eax
  mov   ds,ax
  mov   es,ax

  // EOI - kesme sonu
  mov   al,$20
  out   PIC1_KOMUT,al

  // çalýþan görevin genel yazmaçlarýný eski konumuna geri döndür
  popfd
  popad

  sti

// iþlemi belirtilen göreve devret
@@JMPKOD:
  db  $EA
// donaným destekli görev deðiþimlerinde ADRES (offset) gözardý edilir
@@ADRES:
  dd  0
@@SECICI:
  dw  0

  iretd
end;

{==============================================================================
  yazýlým tarafýndan görev deðiþtirme iþlevlerini yerine getirir.
 ==============================================================================}
procedure ElleGorevDegistir; nostackframe; assembler;
asm

  cli

  pushad
  pushfd

  mov   eax,CokluGorevBasladi
  cmp   eax,1
  je    @@kontrol1

  // genel yazmaçlarý geri yükle ve iþlevden çýk
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

  // aktif görevin bellek baþlangýç adresini al
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.BellekBaslangicAdresi]
  mov   FAktifGorevBellekAdresi,eax

  // görev deðiþiklik sayacýný bir artýr
  mov   eax,FAktifGorev
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.GorevSayaci]
  inc   eax
  mov   [esi + TGorev.GorevSayaci],eax

  // görevin öncelik seviyesine göre görev geçiþini gerçekleþtir
  mov   ecx,FAktifGorev
  mov   eax,ecx
  shl   eax,2
  mov   esi,Gorevler0.Gorev[eax]
  mov   eax,[esi + TGorev.SeviyeNo]
  cmp   eax,CALISMA_SEVIYE0
  jz    @@TSS_SEVIYE0

// DPL3 - uygulama yazýlýmlarý için (ring3)
@@TSS_SEVIYE3:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
//  add   ecx,3
  mov   @@SECICI,cx
  jmp   @@son

// DPL0 - sistem yazýlýmlarý için (ring0)
@@TSS_SEVIYE0:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
  mov   @@SECICI,cx

@@son:
  popfd
  popad

// iþlemi belirtilen göreve devret
@@JMPKOD:
  db  $EA
// donaným destekli görev deðiþimlerinde ADRES (offset) gözardý edilir
@@ADRES:
  dd  0
@@SECICI:
  dw  0

  sti
  ret
end;

end.

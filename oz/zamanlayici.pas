{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: zamanlayici.pas
  Dosya Ýþlevi: zamanlayýcý yönetim iþlevlerini içerir

  Güncelleme Tarihi: 21/08/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit zamanlayici;

interface

uses paylasim, port, gorselnesne;

const
  USTSINIR_ZAMANLAYICI = 128;
  CALISMA_FREKANSI = 100;

type
  //  TODO             zdIptal buradan ve api iþlevlerinden çýkarýlarak iptal edilecek
  TZamanlayiciDurum = (zdIptal, zdCalisiyor, zdDurduruldu);

type
  PZamanlayici = ^TZamanlayici;
  TZamanlayici = class
    Kimlik: TKimlik;
    GrvKimlik: TKimlik;
    Durum: TZamanlayiciDurum;
    TetiklemeSuresi, GeriSayimSayaci: TSayi4;
    OlayYonlAdr: TOlaylariIsle;
  end;

type
  PZamanlayicilar = ^TZamanlayicilar;
  TZamanlayicilar = class
  private
    // çalýþan zamanlayýcý sayýsýný sýfýrla
    FToplamZamanlayiciSayisi: TSayi4;
    FZamanlayiciListesi: array[0..USTSINIR_ZAMANLAYICI - 1] of TZamanlayici;
    function Al(ASiraNo: TISayi4): TZamanlayici;
    procedure Yaz(ASiraNo: TISayi4; AZamanlayici: TZamanlayici);
  public
    // zamanlayýcý (timer) kesmesinin her bir kesme oluþumunda artan sayaç
    FZamanlayiciSayaci: TSayi4;
    constructor Create;
    function Olustur(AMiliSaniye: TSayi4): TZamanlayici;
    function BosZamanlayiciBul: TZamanlayici;
    procedure YokEt(AZamanlayici: TZamanlayici);
    procedure ZamanlayicilariKontrolEt;
    procedure ZamanlayicilariDurdur(AGorevKimlik: TKimlik);
    procedure ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
    procedure BekleMS(AMilisaniye: TSayi4);
    property Zamanlayici[ASiraNo: TISayi4]: TZamanlayici read Al write Yaz;
    property ToplamZamanlayiciSayisi: TSayi4 read FToplamZamanlayiciSayisi write FToplamZamanlayiciSayisi;
  end;

var
  GZamanlayicilar: TZamanlayicilar;
  ZamanlayicilarKilit: TSayi4 = 0;

procedure OtomatikGorevDegistir;
procedure ElleGorevDegistir;

implementation

uses gorev, idt, irq, pit, pic;

{==============================================================================
  zamanlayýcý nesnelerinin ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TZamanlayicilar.Create;
var
  i: TSayi4;
begin

  // kesmeleri durdur
  cli;

  IRQPasiflestir(0);

  // IRQ0 giriþ noktasýný yeniden belirle
  // %10001110 = 1 = mevcut, 00 = DPL0, 0, 1 = 32 bit kod, 110 - kesme kapýsý
  KesmeGirisiBelirle($20, @OtomatikGorevDegistir, SECICI_SISTEM_KOD * 8, %10001110);

  // saat vuruþ frekansýný düzenle. (saniyedeki vuruþ sayýsý)
  ZamanlayiciFrekansiniDegistir(CALISMA_FREKANSI);

  // zamanlayýcý sayacýný sýfýrla
  FZamanlayiciSayaci := 0;

  // çalýþan zamanlayýcý sayýsýný sýfýrla
  ToplamZamanlayiciSayisi := 0;

  // bellek bölgesini zamanlayýcý yapýlarýyla eþleþtir
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do Zamanlayici[i] := nil;

  // IRQ0'ý etkinleþtir
  IRQEtkinlestir(0);

  // kesmeleri aktifleþtir
  sti;
end;

function TZamanlayicilar.Al(ASiraNo: TISayi4): TZamanlayici;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_ZAMANLAYICI) then
    Result := FZamanlayiciListesi[ASiraNo]
  else Result := nil;
end;

procedure TZamanlayicilar.Yaz(ASiraNo: TISayi4; AZamanlayici: TZamanlayici);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_ZAMANLAYICI) then
    FZamanlayiciListesi[ASiraNo] := AZamanlayici;
end;

{==============================================================================
  zamanlayýcý nesnesi oluþturur
 ==============================================================================}
function TZamanlayicilar.Olustur(AMiliSaniye: TSayi4): TZamanlayici;
var
  Z: TZamanlayici;
  i: TSayi4;
begin

  Result := nil;

  // boþ bir zamanlayýcý nesnesi bul
  Z := BosZamanlayiciBul;
  if(Z <> nil) then
  begin

    Z.TetiklemeSuresi := AMiliSaniye;
    Z.GeriSayimSayaci := AMiliSaniye;
    Z.OlayYonlAdr := nil;

    i := FToplamZamanlayiciSayisi;
    Inc(i);
    FToplamZamanlayiciSayisi := i;

    Exit(Z);
  end;
end;

{==============================================================================
  boþ (kullanýlmayan) zamanlayýcý bulur
 ==============================================================================}
function TZamanlayicilar.BosZamanlayiciBul: TZamanlayici;
var
  Z: TZamanlayici;
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
      Z := TZamanlayici.Create;
      Zamanlayici[i] := Z;

      // ilk deðer atamalarý
      Z.Kimlik := i;
      Z.GrvKimlik := GGorevler.FAktifGrv;
      Z.Durum := zdDurduruldu;

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
procedure TZamanlayicilar.YokEt(AZamanlayici: TZamanlayici);
var
  i: TSayi4;
begin

//  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // eðer zamanlayýcý nesnesinin durumu boþ deðil ise
  if not(AZamanlayici = nil) then
  begin

    // zamanlayýc nesnesini listeden çýkar
    Zamanlayici[AZamanlayici.Kimlik] := nil;

    // zamanlayýcý için bellekte ayrýlan yeri yok et
    AZamanlayici.Destroy;

    // zamanlayýcý nesnesini bir azalt
    i := FToplamZamanlayiciSayisi;
    Dec(i);
    FToplamZamanlayiciSayisi := i;
  end;

//  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  zamanlayýcýlarý tetikler (IRQ00 tarafýndan çaðrýlýr)
 ==============================================================================}
procedure TZamanlayicilar.ZamanlayicilariKontrolEt;
var
  G: PGorev;
  Z: TZamanlayici;
  Olay: TOlay;
  GeriSayimSayaci, i: TISayi4;
begin

  // zamanlayýcý nesnesi yok ise çýk
  if(GZamanlayicilar.ToplamZamanlayiciSayisi = 0) then Exit;

//  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // tüm zamanlayýcý nesnelerini denetle
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := GZamanlayicilar.Zamanlayici[i];

    // eðer çalýþýyorsa
    if not(Z = nil) and (Z.Durum = zdCalisiyor) then
    begin

      // zamanlayýcý sayacýný 1 azalt
      GeriSayimSayaci := Z.GeriSayimSayaci;
      Dec(GeriSayimSayaci);
      Z.GeriSayimSayaci := GeriSayimSayaci;

      // sayaç 0 deðerini bulmuþsa
      if(GeriSayimSayaci = 0) then
      begin

        // yeni sayým için geri sayým deðerini yeniden yükle
        Z.GeriSayimSayaci := Z.TetiklemeSuresi;

        Olay.Kimlik := i;
        Olay.Olay := CO_ZAMANLAYICI;
        Olay.Deger1 := 0;
        Olay.Deger2 := 0;

        if not(Z.OlayYonlAdr = nil) then

          Z.OlayYonlAdr(nil, Olay)
        else
        begin

          G := GorevAl(Z.GrvKimlik);
          GGorevler.OlayEkle(G^.Kimlik, Olay);
        end;
      end;
    end;
  end;

//  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  bir süreçe ait tüm zamanlayýcý nesnelerini durdurur
 ==============================================================================}
procedure TZamanlayicilar.ZamanlayicilariDurdur(AGorevKimlik: TKimlik);
var
  Z: TZamanlayici;
  i: TSayi4;
begin

//  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // tüm zamanlayýcý nesnelerini ara
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := GZamanlayicilar.Zamanlayici[i];

    // zamanlayýcý nesnesi aranan iþleme mi ait
    if not(Z = nil) and (Z.GrvKimlik = AGorevKimlik) then
    begin

      // nesneyi yok et
      Z.Durum := zdDurduruldu;
    end;
  end;

//  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  bir süreçe ait tüm zamanlayýcý nesnelerini yok eder.
 ==============================================================================}
procedure TZamanlayicilar.ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
var
  Z: TZamanlayici;
  i: TSayi4;
begin

//  while KritikBolgeyeGir(ZamanlayicilarKilit) = False do;

  // tüm zamanlayýcý nesnelerini ara
  for i := 0 to USTSINIR_ZAMANLAYICI - 1 do
  begin

    Z := GZamanlayicilar.Zamanlayici[i];

    // zamanlayýcý nesnesi aranan iþleme mi ait
    if not(Z = nil) and (Z.GrvKimlik = AGorevKimlik) then
    begin

      // nesneyi yok et
      GZamanlayicilar.YokEt(Z);
    end;
  end;

//  KritikBolgedenCik(ZamanlayicilarKilit);
end;

{==============================================================================
  milisaniye cinsinden bekleme iþlemi yapar
  100 milisaniye = 1 saniye
  bilgi: bu iþlev ana çekirdek içerisinde kullanýlmamalýdýr, aksi durumda ana çalýþma kilitlenir
 ==============================================================================}
procedure TZamanlayicilar.BekleMS(AMilisaniye: TSayi4);
var
  Sayac: TSayi4;
begin

  // AMilisaniye * 100 saniye bekle
  Sayac := FZamanlayiciSayaci + AMilisaniye;
  while (Sayac > FZamanlayiciSayaci) do;
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
  // not : ds = es = ss olduðu için tek yazmacýn saklanmasý yeterlidir.
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
  mov   esi,[GZamanlayicilar]
  mov   ecx,[esi + TZamanlayicilar.FZamanlayiciSayaci]
  inc   ecx
  mov   [esi + TZamanlayicilar.FZamanlayiciSayaci],ecx

  // görev deðiþimi yapýlsýn mý?
  mov   eax,GGorevler.FGorevDegisimBayragi
  cmp   eax,1
  je    @@kontrol1

@@cik:
  // yazmaçlarý geri yükle ve kesmeden çýk
  pop   eax
  mov   ds,ax
  mov   es,ax

  mov   al,$20
  out   PIC1_KOMUT,al

  popfd
  popad
  sti
  iretd

@@kontrol1:

  // uygulamalar tarafýndan oluþturulan zamanlayýcý nesnelerini denetle
  mov eax,GZamanlayicilar
  call  TZamanlayicilar.ZamanlayicilariKontrolEt

  // her 1 saniyede kontrol edilecek dahili iþlevler - (þu aþamada gerekli deðil)
{  mov edx,0
  mov eax,ZamanlayiciSayaci
  mov ecx,100
  div ecx
  cmp edx,0
  jg  @@yenigorev }

@@yenigorev:

  // tek bir görev çalýþýyorsa görev deðiþikliði yapma, çýk
  mov   ecx,GGorevler.FCalisanGorevSayisi
  cmp   ecx,1
  je    @@cik

  // görevin belirlenen süre kadar çalýþmasýný saðla
  mov   eax,GGorevler.FAktifGrv
  mov   esi,GGorevler.Gorev[eax * 4]
  mov   eax,[esi + TGorev.CalismaSureSayac]
  dec   eax
  mov   [esi + TGorev.CalismaSureSayac],eax
  jz    @@bir_sonraki_gorev
  jmp   @@cik

@@bir_sonraki_gorev:

  // mevcut görevin sayacý sýfýrlandýðý için görevin sayacýný güncelle
  mov   eax,[esi + TGorev.CalismaSureMS]
  mov   [esi + TGorev.CalismaSureSayac],eax

  // geçiþ yapýlacak bir sonraki görevi bul
  call  CalistirilacakBirSonrakiGoreviBul
  mov   GGorevler.FAktifGrv,eax

  // aktif görevin bellek baþlangýç adresini al
  mov   eax,GGorevler.FAktifGrv
  mov   esi,GGorevler.Gorev[eax * 4]
  mov   eax,[esi + TGorev.BellekBasAdr]
  mov   GGorevler.FAktifGrvBelAdr,eax

  // görev deðiþiklik sayacýný bir artýr
  mov   eax,GGorevler.FAktifGrv
  mov   esi,GGorevler.Gorev[eax * 4]
  mov   eax,[esi + TGorev.GrvSayac]
  inc   eax
  mov   [esi + TGorev.GrvSayac],eax

  // GorevDegisimSayisi = kilitlenmeleri denetleyebilmek için eklenen deðiþken
  mov   eax,GGorevler.FGorevDegisimSayisi
  inc   eax
  mov   GGorevler.FGorevDegisimSayisi,eax

  // görevin öncelik seviyesine göre görev geçiþini gerçekleþtir
  mov   ecx,GGorevler.FAktifGrv
  mov   eax,ecx
  mov   esi,GGorevler.Gorev[eax * 4]
  mov   eax,[esi + TGorev.SeviyeNo]
  cmp   eax,CALISMA_SEVIYE0
  jz    @@TSS_SEVIYE0

// DPL3 - uygulama yazýlýmlarý için (ring3)
@@TSS_SEVIYE3:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
  add   ecx,3
  mov   @@SECICI,cx
  jmp   @@son

// DPL0 - sistem yazýlýmlarý için (ring0)
@@TSS_SEVIYE0:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
  mov   @@SECICI,cx

@@son:

  // yazmaçlarý geri yükle ve kesmeden çýk
  pop   eax
  mov   ds,ax
  mov   es,ax

  // EOI - kesme sonu
  mov   al,$20
  out   PIC1_KOMUT,al

  popfd
  popad

  sti

// iþlemi belirtilen göreve devret
@@JMPKOD:
  db  $EA
// bilgi: donaným destekli görev deðiþimlerinde ADRES (offset) gözardý edilir
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

  mov   ecx,GGorevler.FCalisanGorevSayisi
  cmp   ecx,1
  jg    @@yenigorev

  popfd
  popad
  sti
  ret

@@yenigorev:

  call  CalistirilacakBirSonrakiGoreviBul
  mov   GGorevler.FAktifGrv,eax

  // aktif görevin bellek baþlangýç adresini al
  mov   eax,GGorevler.FAktifGrv
  mov   esi,GGorevler.Gorev[eax * 4]
  mov   eax,[esi + TGorev.BellekBasAdr]
  mov   GGorevler.FAktifGrvBelAdr,eax

  // görev deðiþiklik sayacýný bir artýr
  mov   eax,GGorevler.FAktifGrv
  mov   esi,GGorevler.Gorev[eax * 4]
  mov   eax,[esi + TGorev.GrvSayac]
  inc   eax
  mov   [esi + TGorev.GrvSayac],eax

  // görevin öncelik seviyesine göre görev geçiþini gerçekleþtir
  mov   ecx,GGorevler.FAktifGrv
  mov   eax,ecx
  mov   esi,GGorevler.Gorev[eax * 4]
  mov   eax,[esi + TGorev.SeviyeNo]
  cmp   eax,CALISMA_SEVIYE0
  jz    @@TSS_SEVIYE0

// DPL3 - uygulama yazýlýmlarý için (ring3)
@@TSS_SEVIYE3:
  inc   ecx
  imul  ecx,3
  shl   ecx,3
  add   ecx,3
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
// bilgi: donaným destekli görev deðiþimlerinde ADRES (offset) gözardý edilir
@@ADRES:
  dd  0
@@SECICI:
  dw  0

  sti
  ret
end;

end.

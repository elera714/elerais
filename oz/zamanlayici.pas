{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: zamanlayici.pas
  Dosya Ýþlevi: zamanlayýcý yönetim iþlevlerini içerir

  Güncelleme Tarihi: 21/11/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit zamanlayici;

interface

uses paylasim, port, gorselnesne;

const
  USTSINIR_ZAMANLAYICI  = 128;
  CALISMA_FREKANSI      = 1000;     // 1000mhz - saniyede 1000 vuruþ

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
  G: TGorev;
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

          G := GGorevler.GorevAl(Z.GrvKimlik);
          GGorevler.OlayEkle(G.FKimlik, Olay);
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

  // deðiþime uðrayacak yazmaçlarý sakla
  pushad
  pushfd
  cld

  // çalýþan görevin DS yazmacýný sakla
  // not : ds = es = ss olduðu için tek yazmacýn saklanmasý yeterlidir.
  mov   ax,ds
  push  eax

  // yazmaçlarý sistem yazmaçlarýna ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  // çalýþan görevin çekirdek esp deðerini kaydet
  mov   esi,[GGorevler]
  mov   eax,[esi + TGorevler.FAktifGrv]
  imul  eax,SizeOf(TGorev)
  mov   esi,[esi + TGorevler.FGorevListesi + eax]
  mov   [esi + TGorev.FKayitliESP],esp

  mov   eax,GorevDegistirme
  cmp   eax,1
  je    @@cik

  // zamanlayýcý sayacýný artýr.
  mov   esi,[GZamanlayicilar]
  mov   eax,[esi + TZamanlayicilar.FZamanlayiciSayaci]
  inc   eax
  mov   [esi + TZamanlayicilar.FZamanlayiciSayaci],eax

  // görev deðiþimi yapýlsýn mý?
  mov   esi,[GGorevler]
  mov   eax,[esi + TGorevler.FGorevDegisimBayragi]
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
  iretd

@@kontrol1:

  // uygulamalar tarafýndan oluþturulan zamanlayýcý nesnelerini denetle
  mov eax,GZamanlayicilar
  call  TZamanlayicilar.ZamanlayicilariKontrolEt

  // tek bir görev çalýþýyorsa görev deðiþikliði yapma, çýk
  mov   esi,[GGorevler]
  mov   eax,[esi + TGorevler.FCalisanGorevSayisi]
  cmp   eax,1
  je    @@cik

  // görevin belirlenen süre kadar çalýþmasýný saðla
  mov   esi,[GGorevler]
  mov   eax,[esi + TGorevler.FAktifGrv]
  imul  eax, SizeOf(TGorev)
  mov   esi,[esi + TGorevler.FGorevListesi + eax]
  mov   eax,[esi + TGorev.FCalismaSureSayac]
  dec   eax
  mov   [esi + TGorev.FCalismaSureSayac],eax
  jz    @@bir_sonraki_gorev
  jmp   @@cik

  // her 1 saniyede kontrol edilecek dahili iþlevler - (þu aþamada gerekli deðil)
{  mov edx,0
  mov eax,ZamanlayiciSayaci
  mov ecx,100
  div ecx
  cmp edx,0
  jg  @@yenigorev }

@@bir_sonraki_gorev:

  // mevcut görevin sayacý sýfýrlandýðý için görevin sayacýný güncelle
  mov   eax,[esi + TGorev.FCalismaSureMS]
  mov   [esi + TGorev.FCalismaSureSayac],eax

  // geçiþ yapýlacak bir sonraki görevi bul
  mov   eax,GGorevler
  call  TGorevler.CalisacakYeniGoreviBul

  mov   esi,[GGorevler]
  mov   [esi + TGorevler.FAktifGrv],eax

  // geçilecek görevin bellek baþlangýç adresini al
  imul  eax,SizeOf(TGorev)
  mov   esi,[esi + TGorevler.FGorevListesi + eax]
  mov   eax,[esi + TGorev.FBellekBaslAdr]

  mov   esi,[GGorevler]
  mov   [esi + TGorevler.FAktifGrvBelAdr],eax

  // geçilecek görevin deðiþiklik sayacýný bir artýr
  mov   esi,[GGorevler]
  mov   eax,[esi + TGorevler.FAktifGrv]
  imul  eax,SizeOf(TGorev)
  mov   esi,[esi + TGorevler.FGorevListesi + eax]
  mov   eax,[esi + TGorev.FGrvSayac]
  inc   eax
  mov   [esi + TGorev.FGrvSayac],eax

  // GorevDegisimSayisi = kilitlenmeleri denetleyebilmek için eklenen deðiþken
  mov   esi,[GGorevler]
  mov   eax,[esi + TGorevler.FGorevDegisimSayisi]
  inc   eax
  mov   [esi + TGorevler.FGorevDegisimSayisi],eax

  // geçilecek görevin öncelik seviyesine göre görev geçiþini gerçekleþtir
  mov   esi,[GGorevler]
  mov   ecx,[esi + TGorevler.FAktifGrv]
  mov   eax,ecx
  imul  eax,SizeOf(TGorev)
  mov   esi,[esi + TGorevler.FGorevListesi + eax]

  // yýðýn 3. seviye bir göreve aitse esp0 deðerini kaydet
  cmp   DWORD[esi + TGorev.FSeviyeNo],CALISMA_SEVIYE3
  jne   @@yigin_tamam

  mov   eax,[esi + TGorev.FCekirdekYiginUst]
  mov   edi,[GorevTSSListesi]
  mov   [edi + TTSS.ESP0],eax

@@yigin_tamam:

  // yeni görevin esp deðerini kayýtlý alandan al
  mov   esp,[esi + TGorev.FKayitliESP]

  // yeni görevin ds, es yazmacýný yükle
  mov   eax,[esp]
  mov   ds,ax
  mov   es,ax

@@son:

  // yukarýdaki ds yazmacýnýn yýðýndaki deðerini ayarlar (pop iþlemi yapma!)
  add   esp,4

  // EOI - kesme sonu
  mov   al,$20
  out   PIC1_KOMUT,al

  // yýðýna atýlan deðerleri yýðýndan al
  popfd
  popad

  // iretd ile yýðýndan yazmaç deðerlerini alarak görev geçiþi gerçekleþtir
  iretd
end;

end.

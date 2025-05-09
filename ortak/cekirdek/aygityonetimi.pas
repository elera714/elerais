{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: aygityonetimi.pas
  Dosya Ýþlevi: aygýt (device) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 08/05/2025

 ==============================================================================}
{$mode objfpc}
unit aygityonetimi;

interface

uses paylasim;

const
  // aygýt tipleri
  PCIAYGIT_AG_ETHERNET            = $0200;
  PCIAYGIT_CEVREBIRIM_DIGER       = $0880;

  FD_KIMLIK_ILKDEGER              = $1000;    // fiziksel depolama
  MD_KIMLIK_ILKDEGER              = $2000;    // mantýksal depolama

var
  SistemdekiAgAygitSayisi: TSayi4 = 0;

procedure DepolamaAygitlariniYukle;
procedure AgAygitlariniYukle;
procedure AygitiSistemeKaydet(APCI: PPCI);
procedure AgAygitiEkle(APCI: PPCI);
function FizikselDepolamaAygitiOlustur(AAygitTipi: TSayi4): PFizikselDepolama;

implementation

uses src_disket, src_pcnet32, src_e1000, src_ide, donusum, vbox;

const
  DESTEKLENEN_AGAYGIT_SAYISI  = 2;
  USTSINIR_AGAYGITI           = 4;

type
  TYukle = function(APCI: PPCI): TISayi4;

type
  TAygit = packed record
    SaticiKimlik,
    AygitKimlik: TSayi2;
    Yukle: TYukle;
  end;

var
  DesteklenenAgAygitlari: array[0..DESTEKLENEN_AGAYGIT_SAYISI - 1] of TAygit = (
    (SaticiKimlik: $1022; AygitKimlik: $2000; Yukle: @src_pcnet32.Yukle),
    (SaticiKimlik: $8086; AygitKimlik: $100E; Yukle: @src_e1000.Yukle));

  AgAygitListesi: array[0..USTSINIR_AGAYGITI - 1] of PPCI = (nil, nil, nil, nil);

{ TODO : Tüm aygýt yüklemeleri buraya alýnabilir }

{==============================================================================
  sistemdeki depolama aygýtlarýný yükler
 ==============================================================================}
procedure DepolamaAygitlariniYukle;
var
  i: TSayi4;
begin

  // fiziksel sürücü deðiþkenlerini sýfýrla
  FizikselDepolamaAygitSayisi := 0;
  for i := 0 to 5 do
  begin

    FizikselDepolamaAygitListesi[i].Mevcut0 := False;
    FizikselDepolamaAygitListesi[i].FD3.Kimlik := FD_KIMLIK_ILKDEGER + i;

    // fda = fiziksel depolama aygýtý
    FizikselDepolamaAygitListesi[i].FD3.AygitAdi := 'fda' + IntToStr(i + 1);
  end;

  // floppy aygýtlarýný yükle
  src_disket.Yukle;

  // ide disk aygýtlarýný yükle
  src_ide.Yukle;
end;

{==============================================================================
  sistemde mevcut (sistem tarafýndan desteklenen) að aygýtlarýný yükler
 ==============================================================================}
procedure AgAygitlariniYukle;
var
  PCIKayit: PPCI;
  Aygit: TAygit;
  AygitSiraNo, DesteklenenAygitSiraNo,
  i: TSayi4;
begin

  AgYuklendi := False;

  // sistemde ethernet aygýtý yoksa çýk
  if(SistemdekiAgAygitSayisi = 0) then Exit;

  // desteklenen ethernet aygýtý yoksa çýk
  if(DESTEKLENEN_AGAYGIT_SAYISI > 0) then
  begin

    // sistemde mevcut, sistem tarafýndan desteklenen aygýtlarý yükle
    for AygitSiraNo := 0 to USTSINIR_AGAYGITI - 1 do
    begin

      PCIKayit := AgAygitListesi[AygitSiraNo];
      if(PCIKayit <> nil) then
      begin

        for DesteklenenAygitSiraNo := 0 to DESTEKLENEN_AGAYGIT_SAYISI - 1 do
        begin

          Aygit := DesteklenenAgAygitlari[DesteklenenAygitSiraNo];
          if(Aygit.SaticiKimlik = PCIKayit^.SaticiKimlik) and (Aygit.AygitKimlik = PCIKayit^.AygitKimlik) then
          begin

            // eðer aygýt yüklemesi baþarýlý ise að yükleme deðiþkenini aktifleþtir
            i := Aygit.Yukle(PCIKayit);
            if(i = 0) then AgYuklendi := True;
          end;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  yüklenecek aygýt listesine belirtilen aygýtý ekler
 ==============================================================================}
procedure AygitiSistemeKaydet(APCI: PPCI);
var
  AygitTipi: TSayi4;
begin

  AygitTipi := (APCI^.SinifKod shr 16) and $FFFF;

  // sistem tarafýndan tanýmlanan aygýtlarý yükle
  if(AygitTipi = PCIAYGIT_AG_ETHERNET) then
    AgAygitiEkle(APCI)
  // virtualbox sanal sürücüyü yükle
  else if(AygitTipi = PCIAYGIT_CEVREBIRIM_DIGER) then
    if(APCI^.SaticiKimlik = $80EE) and (APCI^.AygitKimlik = $CAFE) then vbox.Yukle(APCI);
end;

{==============================================================================
  yüklenecek ethernet aygýt listesine aygýtý ekler
 ==============================================================================}
procedure AgAygitiEkle(APCI: PPCI);
begin

  // sisteme eklenecek üstsýnýr að aygýt sayýsý aþýldý mý ?
  if(SistemdekiAgAygitSayisi >= USTSINIR_AGAYGITI) then Exit;

  // aygýtý listeye ekle
  AgAygitListesi[SistemdekiAgAygitSayisi] := APCI;

  // aygýt sayýsýný bir artýr
  Inc(SistemdekiAgAygitSayisi);
end;

{==============================================================================
  fiziksel depolama aygýtý için sistemde sürücü oluþturma iþlevi
 ==============================================================================}
function FizikselDepolamaAygitiOlustur(AAygitTipi: TSayi4): PFizikselDepolama;
var
  i: TSayi4;
begin

  // boþ fiziksel sürücü yapýsý bul
  for i := 0 to 5 do
  begin

    if(FizikselDepolamaAygitListesi[i].Mevcut0 = False) then
    begin

      FizikselDepolamaAygitListesi[i].Mevcut0 := True;
      FizikselDepolamaAygitListesi[i].FD3.SurucuTipi := AAygitTipi;

      // fiziksel sürücü sayýsýný artýr
      Inc(FizikselDepolamaAygitSayisi);

      Exit(@FizikselDepolamaAygitListesi[i]);
    end;
  end;

  Result := nil;
end;

end.

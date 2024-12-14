{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: aygityonetimi.pas
  Dosya Ýþlevi: aygýt (device) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 22/09/2024

 ==============================================================================}
{$mode objfpc}
unit aygityonetimi;

interface

uses paylasim;

const
  // aygýt tipleri
  PCIAYGIT_AG_ETHERNET            = $0200;
  PCIAYGIT_CEVREBIRIM_DIGER       = $0880;

var
  SistemdekiAgAygitSayisi: TSayi4 = 0;

procedure DepolamaAygitlariniYukle;
procedure AgAygitlariniYukle;
procedure AygitiSistemeKaydet(APCI: PPCI);
procedure AgAygitiEkle(APCI: PPCI);
function FizikselDepolamaAygitiOlustur(AAygitTipi: TSayi4): PFizikselSurucu;

implementation

uses src_disket, src_pcnet32, src_ide, donusum, vbox;

const
  DESTEKLENEN_AGAYGIT_SAYISI = 1;
  USTSINIR_AGAYGITI = 4;

type
  TYukle = function(APCI: PPCI): TISayi4;

type
  TAygit = packed record
    SaticiKimlik,
    AygitKimlik: TSayi2;
    Yukle: TYukle;
  end;

var
  DesteklenenAgAygitlari: array[1..DESTEKLENEN_AGAYGIT_SAYISI] of TAygit = (
    (SaticiKimlik: $1022; AygitKimlik: $2000; Yukle: @src_pcnet32.Yukle));

  AgAygitListesi: array[1..USTSINIR_AGAYGITI] of PPCI = (nil, nil, nil, nil);

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
  for i := 1 to 6 do
  begin

    FizikselDepolamaAygitListesi[i].Mevcut := False;
    FizikselDepolamaAygitListesi[i].Kimlik := i;

    // fda = fiziksel depolama aygýtý
    FizikselDepolamaAygitListesi[i].AygitAdi := 'fda' + IntToStr(i);
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
  _PCI: PPCI;
  _Aygit: TAygit;
  _AygitSiraNo, _DesteklenenAygitSiraNo,
  i: TSayi4;
begin

  AgYuklendi := False;

  // sistemde ethernet aygýtý yoksa çýk
  if(SistemdekiAgAygitSayisi = 0) then Exit;

  // desteklenen ethernet aygýtý yoksa çýk
  if(DESTEKLENEN_AGAYGIT_SAYISI > 0) then
  begin

    // sistemde mevcut, sistem tarafýndan desteklenen aygýtlarý yükle
    for _AygitSiraNo := 1 to USTSINIR_AGAYGITI do
    begin

      _PCI := AgAygitListesi[_AygitSiraNo];
      if(_PCI <> nil) then
      begin

        for _DesteklenenAygitSiraNo := 1 to DESTEKLENEN_AGAYGIT_SAYISI do
        begin

          _Aygit := DesteklenenAgAygitlari[_DesteklenenAygitSiraNo];
          if(_Aygit.SaticiKimlik = _PCI^.SaticiKimlik) and (_Aygit.AygitKimlik = _PCI^.AygitKimlik) then
          begin

            // eðer aygýt yüklemesi baþarýlý ise að yükleme deðiþkenini aktifleþtir
            i := _Aygit.Yukle(_PCI);
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

  // aygýt sayýsýný bir artýr
  Inc(SistemdekiAgAygitSayisi);

  // aygýtý listeye ekle
  AgAygitListesi[SistemdekiAgAygitSayisi] := APCI;
end;

{==============================================================================
  fiziksel depolama aygýtý için sistemde sürücü oluþturma iþlevi
 ==============================================================================}
function FizikselDepolamaAygitiOlustur(AAygitTipi: TSayi4): PFizikselSurucu;
var
  i: TSayi4;
begin

  // boþ fiziksel sürücü yapýsý bul
  for i := 1 to 6 do
  begin

    if(FizikselDepolamaAygitListesi[i].Mevcut = False) then
    begin

      FizikselDepolamaAygitListesi[i].Mevcut := True;
      FizikselDepolamaAygitListesi[i].SurucuTipi := AAygitTipi;

      // fiziksel sürücü sayýsýný artýr
      Inc(FizikselDepolamaAygitSayisi);

      Exit(@FizikselDepolamaAygitListesi[i]);
    end;
  end;

  Result := nil;
end;

end.

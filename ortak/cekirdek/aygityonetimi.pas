{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: aygityonetimi.pas
  Dosya Ýþlevi: aygýt (device) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 28/07/2026

 ==============================================================================}
{$mode objfpc}
unit aygityonetimi;

interface

uses paylasim, pci;

const
  // aygýt tipleri
  PCIAYGIT_AG_ETHERNET            = $0200;
  PCIAYGIT_CEVREBIRIM_DIGER       = $0880;

  MD_KIMLIK_ILKDEGER              = $2000;    // mantýksal depolama

var
  SistemdekiAgAygitSayisi: TSayi4 = 0;

procedure AgAygitlariniYukle;
procedure AygitiSistemeKaydet(APCIYapi: PPCIYapi);
procedure AgAygitiEkle(APCIYapi: PPCIYapi);

implementation

uses src_disket, src_pcnet32, src_e1000, src_ide, donusum, vbox;

const
  DESTEKLENEN_AGAYGIT_SAYISI  = 2;
  USTSINIR_AGAYGITI           = 4;

type
  TYukle = function(APCIYapi: PPCIYapi): TISayi4;

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

  AgAygitListesi: array[0..USTSINIR_AGAYGITI - 1] of PPCIYapi = (nil, nil, nil, nil);

{==============================================================================
  sistemde mevcut (sistem tarafýndan desteklenen) að aygýtlarýný yükler
 ==============================================================================}
procedure AgAygitlariniYukle;
var
  PCIYapi: PPCIYapi;
  Aygit: TAygit;
  AygitSiraNo, DesteklenenAygitSiraNo,
  i: TSayi4;
begin

  // sistemde ethernet aygýtý yoksa çýk
  if(SistemdekiAgAygitSayisi = 0) then Exit;

  // desteklenen ethernet aygýtý yoksa çýk
  if(DESTEKLENEN_AGAYGIT_SAYISI > 0) then
  begin

    // sistemde mevcut, sistem tarafýndan desteklenen aygýtlarý yükle
    for AygitSiraNo := 0 to USTSINIR_AGAYGITI - 1 do
    begin

      PCIYapi := AgAygitListesi[AygitSiraNo];
      if(PCIYapi <> nil) then
      begin

        for DesteklenenAygitSiraNo := 0 to DESTEKLENEN_AGAYGIT_SAYISI - 1 do
        begin

          Aygit := DesteklenenAgAygitlari[DesteklenenAygitSiraNo];
          if(Aygit.SaticiKimlik = PCIYapi^.SaticiKimlik) and (Aygit.AygitKimlik = PCIYapi^.AygitKimlik) then
          begin

            // eðer aygýt yüklemesi baþarýlý ise að yükleme deðiþkenini aktifleþtir
            i := Aygit.Yukle(PCIYapi);
            if(i = 0) then Inc(SistemdekiAgKartiSayisi);
          end;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  yüklenecek aygýt listesine belirtilen aygýtý ekler
 ==============================================================================}
procedure AygitiSistemeKaydet(APCIYapi: PPCIYapi);
var
  AygitTipi: TSayi4;
begin

  AygitTipi := (APCIYapi^.SinifKod shr 16) and $FFFF;

  // sistem tarafýndan tanýmlanan aygýtlarý yükle
  if(AygitTipi = PCIAYGIT_AG_ETHERNET) then
    AgAygitiEkle(APCIYapi)
  // virtualbox sanal sürücüyü yükle
  else if(AygitTipi = PCIAYGIT_CEVREBIRIM_DIGER) then
    if(APCIYapi^.SaticiKimlik = $80EE) and (APCIYapi^.AygitKimlik = $CAFE) then vbox.Yukle(APCIYapi);
end;

{==============================================================================
  yüklenecek ethernet aygýt listesine aygýtý ekler
 ==============================================================================}
procedure AgAygitiEkle(APCIYapi: PPCIYapi);
begin

  // sisteme eklenecek üstsýnýr að aygýt sayýsý aþýldý mý ?
  if(SistemdekiAgAygitSayisi >= USTSINIR_AGAYGITI) then Exit;

  // aygýtý listeye ekle
  AgAygitListesi[SistemdekiAgAygitSayisi] := APCIYapi;

  // aygýt sayýsýný bir artýr
  Inc(SistemdekiAgAygitSayisi);
end;

end.

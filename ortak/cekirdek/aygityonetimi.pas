{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: aygityonetimi.pas
  Dosya ��levi: ayg�t (device) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 22/09/2024

 ==============================================================================}
{$mode objfpc}
unit aygityonetimi;

interface

uses paylasim;

const
  // ayg�t tipleri
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

{ TODO : T�m ayg�t y�klemeleri buraya al�nabilir }

{==============================================================================
  sistemdeki depolama ayg�tlar�n� y�kler
 ==============================================================================}
procedure DepolamaAygitlariniYukle;
var
  i: TSayi4;
begin

  // fiziksel s�r�c� de�i�kenlerini s�f�rla
  FizikselDepolamaAygitSayisi := 0;
  for i := 1 to 6 do
  begin

    FizikselDepolamaAygitListesi[i].Mevcut := False;
    FizikselDepolamaAygitListesi[i].Kimlik := i;

    // fda = fiziksel depolama ayg�t�
    FizikselDepolamaAygitListesi[i].AygitAdi := 'fda' + IntToStr(i);
  end;

  // floppy ayg�tlar�n� y�kle
  src_disket.Yukle;

  // ide disk ayg�tlar�n� y�kle
  src_ide.Yukle;
end;

{==============================================================================
  sistemde mevcut (sistem taraf�ndan desteklenen) a� ayg�tlar�n� y�kler
 ==============================================================================}
procedure AgAygitlariniYukle;
var
  _PCI: PPCI;
  _Aygit: TAygit;
  _AygitSiraNo, _DesteklenenAygitSiraNo,
  i: TSayi4;
begin

  AgYuklendi := False;

  // sistemde ethernet ayg�t� yoksa ��k
  if(SistemdekiAgAygitSayisi = 0) then Exit;

  // desteklenen ethernet ayg�t� yoksa ��k
  if(DESTEKLENEN_AGAYGIT_SAYISI > 0) then
  begin

    // sistemde mevcut, sistem taraf�ndan desteklenen ayg�tlar� y�kle
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

            // e�er ayg�t y�klemesi ba�ar�l� ise a� y�kleme de�i�kenini aktifle�tir
            i := _Aygit.Yukle(_PCI);
            if(i = 0) then AgYuklendi := True;
          end;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  y�klenecek ayg�t listesine belirtilen ayg�t� ekler
 ==============================================================================}
procedure AygitiSistemeKaydet(APCI: PPCI);
var
  AygitTipi: TSayi4;
begin

  AygitTipi := (APCI^.SinifKod shr 16) and $FFFF;

  // sistem taraf�ndan tan�mlanan ayg�tlar� y�kle
  if(AygitTipi = PCIAYGIT_AG_ETHERNET) then
    AgAygitiEkle(APCI)
  // virtualbox sanal s�r�c�y� y�kle
  else if(AygitTipi = PCIAYGIT_CEVREBIRIM_DIGER) then
    if(APCI^.SaticiKimlik = $80EE) and (APCI^.AygitKimlik = $CAFE) then vbox.Yukle(APCI);
end;

{==============================================================================
  y�klenecek ethernet ayg�t listesine ayg�t� ekler
 ==============================================================================}
procedure AgAygitiEkle(APCI: PPCI);
begin

  // sisteme eklenecek �sts�n�r a� ayg�t say�s� a��ld� m� ?
  if(SistemdekiAgAygitSayisi >= USTSINIR_AGAYGITI) then Exit;

  // ayg�t say�s�n� bir art�r
  Inc(SistemdekiAgAygitSayisi);

  // ayg�t� listeye ekle
  AgAygitListesi[SistemdekiAgAygitSayisi] := APCI;
end;

{==============================================================================
  fiziksel depolama ayg�t� i�in sistemde s�r�c� olu�turma i�levi
 ==============================================================================}
function FizikselDepolamaAygitiOlustur(AAygitTipi: TSayi4): PFizikselSurucu;
var
  i: TSayi4;
begin

  // bo� fiziksel s�r�c� yap�s� bul
  for i := 1 to 6 do
  begin

    if(FizikselDepolamaAygitListesi[i].Mevcut = False) then
    begin

      FizikselDepolamaAygitListesi[i].Mevcut := True;
      FizikselDepolamaAygitListesi[i].SurucuTipi := AAygitTipi;

      // fiziksel s�r�c� say�s�n� art�r
      Inc(FizikselDepolamaAygitSayisi);

      Exit(@FizikselDepolamaAygitListesi[i]);
    end;
  end;

  Result := nil;
end;

end.

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: depolama.pas
  Dosya İşlevi: depolama aygıt işlevlerini yönetir

  Güncelleme Tarihi: 16/10/2019

 ==============================================================================}
{$mode objfpc}
unit depolama;

interface

uses paylasim;

function FizikselDepolamaAygitBilgisiAl(AAygitKimlik: TKimlik; AFizikselSurucu3:
  PFizikselSurucu3): TISayi4;
function FizikselDepolamaVeriOku(AAygitKimlik, ASektorNo, AOkunacakSektor: TSayi4;
  AHedefBellek: Isaretci): TISayi4;
function FizikselDepolamaVeriYaz(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
function MantiksalDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
  AMantiksalSurucu3: PMantiksalSurucu3): TISayi4;
function MantiksalDepolamaVeriOku(AAygitKimlik, ASektorNo, AOkunacakSektor: TSayi4;
  AHedefBellek: Isaretci): TISayi4;

implementation

uses sistemmesaj;

{==============================================================================
  fiziksel depolama aygıtı ile ilgili bilgiler verir
 ==============================================================================}
function FizikselDepolamaAygitBilgisiAl(AAygitKimlik: TKimlik; AFizikselSurucu3:
  PFizikselSurucu3): TISayi4;
var
  _AygitSiraNo, i: TSayi4;
begin

  if(AAygitKimlik > 0) and (AAygitKimlik <= FizikselDepolamaAygitSayisi) then
  begin

    _AygitSiraNo := 0;
    for i := 1 to 6 do
    begin

      if(FizikselDepolamaAygitListesi[i].Mevcut) then Inc(_AygitSiraNo);

      if(_AygitSiraNo = AAygitKimlik) then
      begin

        AFizikselSurucu3^.AygitAdi := FizikselDepolamaAygitListesi[i].AygitAdi;
        AFizikselSurucu3^.SurucuTipi := FizikselDepolamaAygitListesi[i].SurucuTipi;
        AFizikselSurucu3^.KafaSayisi := FizikselDepolamaAygitListesi[i].KafaSayisi;
        AFizikselSurucu3^.SilindirSayisi := FizikselDepolamaAygitListesi[i].SilindirSayisi;
        AFizikselSurucu3^.IzBasinaSektorSayisi := FizikselDepolamaAygitListesi[i].IzBasinaSektorSayisi;
        AFizikselSurucu3^.ToplamSektorSayisi := FizikselDepolamaAygitListesi[i].ToplamSektorSayisi;
        Exit(1);
      end;
    end;
  end;

  Result := 0;
end;

{==============================================================================
  fiziksel depolama aygıtından veri okur
 ==============================================================================}
function FizikselDepolamaVeriOku(AAygitKimlik, ASektorNo, AOkunacakSektor: TSayi4;
  AHedefBellek: Isaretci): TISayi4;
var
  _AygitSiraNo, i: TSayi4;
begin

  if(AAygitKimlik > 0) and (AAygitKimlik <= FizikselDepolamaAygitSayisi) then
  begin

    _AygitSiraNo := 0;
    for i := 1 to 6 do
    begin

      if(FizikselDepolamaAygitListesi[i].Mevcut) then Inc(_AygitSiraNo);

      if(_AygitSiraNo = AAygitKimlik) then
      begin

        if(FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
          ASektorNo, AOkunacakSektor, AHedefBellek) = 0) then Exit(0)
        else Exit(1);
      end;
    end;
  end;

  Result := 1;
end;

{==============================================================================
  fiziksel depolama aygıtından veri okur
 ==============================================================================}
function FizikselDepolamaVeriYaz(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
var
  _AygitSiraNo, i: TSayi4;
begin

  if(AAygitKimlik > 0) and (AAygitKimlik <= FizikselDepolamaAygitSayisi) then
  begin

    _AygitSiraNo := 0;
    for i := 1 to 6 do
    begin

      if(FizikselDepolamaAygitListesi[i].Mevcut) then Inc(_AygitSiraNo);

      if(_AygitSiraNo = AAygitKimlik) then
      begin

        if(FizikselDepolamaAygitListesi[i].SektorYaz(@FizikselDepolamaAygitListesi[i],
          ASektorNo, ASektorSayisi, ABellek) = 0) then Exit(0)
        else Exit(1);
      end;
    end;
  end;

  Result := 1;
end;

{==============================================================================
  mantıksal depolama aygıtı ile ilgili bilgiler verir
 ==============================================================================}
function MantiksalDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
  AMantiksalSurucu3: PMantiksalSurucu3): TISayi4;
var
  _AygitSiraNo, i: TSayi4;
begin

  if(AAygitKimlik > 0) and (AAygitKimlik <= MantiksalDepolamaAygitSayisi) then
  begin

    _AygitSiraNo := 0;
    for i := 1 to 6 do
    begin

      if(MantiksalDepolamaAygitListesi[i].AygitMevcut) then Inc(_AygitSiraNo);

      if(_AygitSiraNo = AAygitKimlik) then
      begin

        AMantiksalSurucu3^.AygitAdi := MantiksalDepolamaAygitListesi[i].AygitAdi;
        AMantiksalSurucu3^.SurucuTipi := MantiksalDepolamaAygitListesi[i].FizikselSurucu^.SurucuTipi;
        AMantiksalSurucu3^.DosyaSistemTipi := MantiksalDepolamaAygitListesi[i].BolumTipi;
        AMantiksalSurucu3^.BolumIlkSektor := MantiksalDepolamaAygitListesi[i].BolumIlkSektor;
        AMantiksalSurucu3^.BolumToplamSektor := MantiksalDepolamaAygitListesi[i].BolumToplamSektor;
        Exit(1);
      end;
    end;
  end;

  Result := 0;
end;

{==============================================================================
  mantıksal depolama aygıtından veri okur
 ==============================================================================}
function MantiksalDepolamaVeriOku(AAygitKimlik, ASektorNo, AOkunacakSektor: TSayi4;
  AHedefBellek: Isaretci): TISayi4;
var
  _AygitSiraNo, i: TSayi4;
begin

  if(AAygitKimlik > 0) and (AAygitKimlik <= MantiksalDepolamaAygitSayisi) then
  begin

    _AygitSiraNo := 0;
    for i := 1 to 6 do
    begin

      if(MantiksalDepolamaAygitListesi[i].AygitMevcut) then Inc(_AygitSiraNo);

      if(_AygitSiraNo = AAygitKimlik) then
      begin

        if(MantiksalDepolamaAygitListesi[i].FizikselSurucu^.SektorOku(
          MantiksalDepolamaAygitListesi[i].FizikselSurucu, MantiksalDepolamaAygitListesi[i].BolumIlkSektor +
          ASektorNo, AOkunacakSektor, AHedefBellek) = 0) then Exit(0)
        else Exit(1);
      end;
    end;
  end;

  Result := 1;
end;

end.

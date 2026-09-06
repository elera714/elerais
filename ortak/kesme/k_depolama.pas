{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_depolama.pas
  Dosya Ýþlevi: depolama aygýt kesme çaðrýlarýný yönetir

  Güncelleme Tarihi: 29/07/2025

 ==============================================================================}
{$mode objfpc}
unit k_depolama;

interface

uses paylasim, mdepolama;

function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses fdepolama, gorev, aygit;

// fiziksel depolama nesnesi - program için
type
  PFDNesne3 = ^TFDNesne3;
  TFDNesne3 = packed record
    Kimlik: TKimlik;
    SurucuTipi: TSayi4;
    AygitAdi: string[16];
    KafaSayisi: TSayi4;
    SilindirSayisi: TSayi4;
    IzBasinaSektorSayisi: TSayi4;
    ToplamSektorSayisi: TSayi4;
  end;

{==============================================================================
  depolama aygýt kesme çaðrýlarýný yönetir
 ==============================================================================}
function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  FD: TFDAygiti;
  FD3: PFDNesne3;
  MD: TMDNesne;
  p: Isaretci;
begin

  Result := HATA_ISLEV;

  // iþlev no
  IslevNo := (AIslevNo and $FF);

  //********** mantýksal aygýt iþlevleri ***********

  // toplam mantýksal depolama aygýt sayýsýný al
  if(IslevNo = 1) then
  begin

    Result := GMantiksalDepolama.AygitSayisi;
  end

  // mantýksal depolama aygýt bilgilerini al
  else if(IslevNo = 2) then
  begin

    MD := GMantiksalDepolama.SurucuAl(PSayi4(ADegiskenler + 00)^);
    if not(MD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
      PMDNesne3(p)^.Kimlik := MD.FKimlik;
      PMDNesne3(p)^.SurucuTipi := MD.FSurucuTipi;
      PMDNesne3(p)^.AygitAdi := MD.FAygitAdi;
      PMDNesne3(p)^.DST  := MD.FDST;
      PMDNesne3(p)^.BolumIlkSektor := MD.FBolumIlkSektor;
      PMDNesne3(p)^.BolumToplamSektor := MD.FBolumToplamSektor;

      Result := SizeOf(TMDNesne3);
    end else Result := 0;
  end

  // mantýksal depolama aygýtýndan veri oku
  else if(IslevNo = 3) then
  begin

    MD := GMantiksalDepolama.SurucuAl2(PKimlik(ADegiskenler + 00)^);
    if not(MD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 12)^ + GGorevler.FAktifGrvBelAdr);
      Result := GMantiksalDepolama.VeriOku(MD, PSayi4(ADegiskenler + 04)^,
        PSayi4(ADegiskenler + 08)^, p);
    end else Result := 1;
  end;

  //********** fiziksel aygýt iþlevleri ***********

  // toplam fiziksel depolama aygýt sayýsýný al
  if(IslevNo = $71) then
  begin

    Result := GFizikselDepolama.AygitSayisi;
  end

  // fiziksel depolama aygýt bilgilerini al
  else if(IslevNo = $72) then
  begin

    FD := GFizikselDepolama.SurucuAl(PSayi4(ADegiskenler + 00)^);
    if not(FD = nil) then
    begin

      FD3 := PFDNesne3(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);

      FD3^.Kimlik := FD.Kimlik;
      FD3^.SurucuTipi := FD.SurucuTipi;
      FD3^.AygitAdi := FD.FAygitAdi;
      FD3^.KafaSayisi := FD.FKafaSayisi;
      FD3^.SilindirSayisi  := FD.FSilindirSayisi;
      FD3^.IzBasinaSektorSayisi  := FD.FIzBasinaSektorSayisi;
      FD3^.ToplamSektorSayisi  := FD.FToplamSektorSayisi;
      Result := SizeOf(TFDNesne3);

    end else Result := 0;
  end

  // fiziksel depolama aygýtýndan veri oku
  else if(IslevNo = $73) then
  begin

    FD := GFizikselDepolama.SurucuAl2(PKimlik(ADegiskenler + 00)^);
    if not(FD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 12)^ + GGorevler.FAktifGrvBelAdr);
      Result := GFizikselDepolama.VeriOku(FD, PSayi4(ADegiskenler + 04)^,
        PSayi4(ADegiskenler + 08)^, p);
    end else Result := 1;
  end
  // fiziksel depolama aygýtýna veri yaz
  else if(IslevNo = $74) then
  begin

    FD := GFizikselDepolama.SurucuAl2(PKimlik(ADegiskenler + 00)^);
    if not(FD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 12)^ + GGorevler.FAktifGrvBelAdr);
      Result := GFizikselDepolama.VeriYaz(FD, PSayi4(ADegiskenler + 04)^,
        PSayi4(ADegiskenler + 08)^, p);
    end;
  end;
end;

end.

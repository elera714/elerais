{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_cizim.pas
  Dosya İşlevi: grafiksel ekrana çizim işlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit k_cizim;

interface

uses paylasim;

function CizimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gorselnesne, genel;

{==============================================================================
  görsel nesne çizim kesmelerini içerir
 ==============================================================================}
function CizimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Alan: TAlan;
  Islev: TSayi4;
  Sol, Ust, Sag, Alt,
  YariCap: TISayi4;
begin

  // işlev no
  Islev := (AIslevNo and $FF);

  // nesneye nokta (pixel) yazma işlemi
  if(Islev = 1) then
  begin

    // nesneyi kontrol et
    GN := GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere);
    if(GN = nil) then Exit;

    Alan := GN^.CizimAlaniniAl2(GN^.Kimlik);
    Sol := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    Ust := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    // belirtilen koordinatı işaretle
    GEkranKartSurucusu.NoktaYaz(GN, Sol, Ust, PRenk(ADegiskenler + 12)^, True);

    // başarı kodunu geri döndür
    Result := 1;
  end

  // dikdörtgen çiz
  else if(Islev = 2) then
  begin

    // nesneyi kontrol et
    GN := GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere);
    if(GN = nil) then Exit;

    Alan := GN^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    Sol := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    Ust := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Sag := PISayi4(ADegiskenler + 12)^ + Sol;
    Alt := PISayi4(ADegiskenler + 16)^ + Ust;

    if(PBoolean(ADegiskenler + 24)^) then
    begin

      GN^.DikdortgenDoldur(GN, Sol, Ust, Sag, Alt, PRenk(ADegiskenler + 20)^,
        PRenk(ADegiskenler + 20)^);

      Result := 1;
    end
    else
    begin

      Alan.Sol := Sol;
      Alan.Ust := Ust;
      Alan.Sag := Sag;
      Alan.Alt := Alt;
      GN^.Dikdortgen(GN, ctDuz, Alan, PRenk(ADegiskenler + 20)^);

      Result := 1;
    end;
  end

  // çizgi çiz
  else if(Islev = 3) then
  begin

    // nesneyi kontrol et
    GN := GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere);
    if(GN = nil) then Exit;

    Alan := GN^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    Sol := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    Ust := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Sag := PISayi4(ADegiskenler + 12)^ + Alan.Sol;
    Alt := PISayi4(ADegiskenler + 16)^ + Alan.Ust;

    GN^.Cizgi(GN, PCizgiTipi(ADegiskenler + 20)^, Sol, Ust, Sag, Alt, PRenk(ADegiskenler + 24)^);
  end

  // daire çiz
  else if(Islev = 4) then
  begin

    // nesneyi kontrol et
    GN := GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere);
    if(GN = nil) then Exit;

    Alan := GN^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    Sol := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    Ust := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    YariCap := PISayi4(ADegiskenler + 12)^;

    if(PBoolean(ADegiskenler + 20)^) then
    begin

      GN^.DaireDoldur(GN, Sol, Ust, YariCap, PISayi4(ADegiskenler + 16)^);
    end
    else
    begin

      GN^.Daire(Sol, Ust, YariCap, PISayi4(ADegiskenler + 16)^);
    end;
  end

  else Result := HATA_ISLEV;
end;

end.

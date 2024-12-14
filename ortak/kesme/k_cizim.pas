{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_cizim.pas
  Dosya İşlevi: grafiksel ekrana çizim işlevlerini içerir

  Güncelleme Tarihi: 05/08/2020

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
  GorselNesne: PGorselNesne;
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
    GorselNesne := GorselNesne^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere);
    if(GorselNesne = nil) then Exit;

    Alan := GorselNesne^.CizimAlaniniAl2(GorselNesne^.Kimlik);
    Sol := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    Ust := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    // belirtilen koordinatı işaretle
    GEkranKartSurucusu.NoktaYaz(GorselNesne, Sol, Ust, PRenk(ADegiskenler + 12)^, True);

    // başarı kodunu geri döndür
    Result := 1;
  end

  // dikdörtgen çiz
  else if(Islev = 2) then
  begin

    // nesneyi kontrol et
    GorselNesne := GorselNesne^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere);
    if(GorselNesne = nil) then Exit;

    Alan := GorselNesne^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    Sol := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    Ust := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Sag := PISayi4(ADegiskenler + 12)^ + Sol;
    Alt := PISayi4(ADegiskenler + 16)^ + Ust;

    if(PBoolean(ADegiskenler + 24)^) then
    begin

      GorselNesne^.DikdortgenDoldur(GorselNesne, Sol, Ust, Sag, Alt, PRenk(ADegiskenler + 20)^,
        PRenk(ADegiskenler + 20)^);

      Result := 1;
    end
    else
    begin

      Alan.Sol := Sol;
      Alan.Ust := Ust;
      Alan.Sag := Sag;
      Alan.Alt := Alt;
      GorselNesne^.Dikdortgen(GorselNesne, Alan, PRenk(ADegiskenler + 20)^);

      Result := 1;
    end;
  end

  // çizgi çiz
  else if(Islev = 3) then
  begin

    // nesneyi kontrol et
    GorselNesne := GorselNesne^.NesneTipiniKontrolEt(PKimlik(ADegiskenler)^, gntPencere);
    if(GorselNesne = nil) then Exit;

    Alan := GorselNesne^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    Sol := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    Ust := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Sag := PISayi4(ADegiskenler + 12)^ + Alan.Sol;
    Alt := PISayi4(ADegiskenler + 16)^ + Alan.Ust;

    GorselNesne^.Cizgi(GorselNesne, PCizgiTipi(ADegiskenler + 20)^, Sol, Ust,
      Sag, Alt, PRenk(ADegiskenler + 24)^);
  end

  // daire çiz
  else if(Islev = 4) then
  begin

    // nesneyi kontrol et
    GorselNesne := GorselNesne^.NesneTipiniKontrolEt(PKimlik(ADegiskenler)^, gntPencere);
    if(GorselNesne = nil) then Exit;

    Alan := GorselNesne^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    Sol := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    Ust := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    YariCap := PISayi4(ADegiskenler + 12)^;

    if(PBoolean(ADegiskenler + 20)^) then
    begin

      GorselNesne^.DaireDoldur(GorselNesne, Sol, Ust, YariCap, PISayi4(ADegiskenler + 16)^);
    end
    else
    begin

      GorselNesne^.Daire(Sol, Ust, YariCap, PISayi4(ADegiskenler + 16)^);
    end;
  end

  else Result := HATA_ISLEV;
end;

end.

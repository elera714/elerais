{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_yazim.pas
  Dosya İşlevi: grafiksel ekrana yazım kesme işlevlerini içerir

  Güncelleme Tarihi: 14/08/2026

 ==============================================================================}
{$mode objfpc}
unit k_yazim;

interface

uses paylasim;

function YazimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gorselnesne, gn_pencere, gorev, gn_islevler;

{==============================================================================
  görsel nesne (pencere nesnesi) yazım kesmelerini içerir
 ==============================================================================}
function YazimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Pencere: TPencere;
  Alan: TAlan;
  A1, B1: TISayi4;
  IslevNo: TSayi4;
  Bellek: Isaretci;
begin

  // öntanımlı geri dönüş değeri
  Result := HATA_ISLEV;

  // işlev no
  IslevNo := (AIslevNo and $FF);

  // görsel nesneye karakter yaz
  if(IslevNo = 1) then
  begin

    Pencere := TPencere(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(Pencere = nil) then Exit;

    Alan := Pencere.CizimAlaniniAl2;
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    Pencere.HarfYaz(Pencere, A1, B1, PChar(ADegiskenler + 16)^, RENK_YOK, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye karakter katarı yaz
  else if(IslevNo = 2) then
  begin

    Pencere := TPencere(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(Pencere = nil) then Exit;

    Alan := Pencere.CizimAlaniniAl2;
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Bellek := Isaretci((PSayi4(ADegiskenler + 16)^ + GGorevler.FAktifGrvBelAdr));

    Pencere.YaziYaz(Pencere, A1, B1, PKarakterKatari(Bellek)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye onaltılı tabanda sayı yaz
  else if(IslevNo = 3) then
  begin

    Pencere := TPencere(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(Pencere = nil) then Exit;

    Alan := Pencere.CizimAlaniniAl2;
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    Pencere.SayiYaz16(Pencere, A1, B1, PLongBool(ADegiskenler + 16)^, PISayi4(ADegiskenler + 20)^,
      PISayi4(ADegiskenler + 24)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye saat değerini yaz
  else if(IslevNo = 4) then
  begin

    Pencere := TPencere(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(Pencere = nil) then Exit;

    Alan := Pencere.CizimAlaniniAl2;
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    Pencere.SaatYaz(Pencere, A1, B1, PSaat(ADegiskenler + 16)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye mac adresini yaz
  else if(IslevNo = 5) then
  begin

    Pencere := TPencere(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(Pencere = nil) then Exit;

    Alan := Pencere.CizimAlaniniAl2;
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Bellek := PMACAdres(PSayi4(ADegiskenler + 16)^ + GGorevler.FAktifGrvBelAdr);

    Pencere.MACAdresiYaz(Pencere, A1, B1, PMACAdres(Bellek)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye ip adresini yaz
  else if(IslevNo = 6) then
  begin

    Pencere := TPencere(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(Pencere = nil) then Exit;

    Alan := Pencere.CizimAlaniniAl2;
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Bellek := PIP4Adres(PSayi4(ADegiskenler + 16)^ + GGorevler.FAktifGrvBelAdr);

    Pencere.IPAdresiYaz(Pencere, A1, B1, PIP4Adres(Bellek)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye ondalık sayısal değer yaz
  else if(IslevNo = 7) then
  begin

    Pencere := TPencere(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(Pencere = nil) then Exit;

    Alan := Pencere.CizimAlaniniAl2;
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    Pencere.SayiYaz10(Pencere, A1, B1, PISayi4(ADegiskenler + 16)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end;
end;

end.

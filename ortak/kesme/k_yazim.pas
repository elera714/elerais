{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_yazim.pas
  Dosya İşlevi: grafiksel ekrana yazım kesme işlevlerini içerir

  Güncelleme Tarihi: 25/02/2025

 ==============================================================================}
{$mode objfpc}
unit k_yazim;

interface

uses paylasim;

function YazimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gorselnesne, gn_pencere, gorev;

{==============================================================================
  görsel nesne (pencere nesnesi) yazım kesmelerini içerir
 ==============================================================================}
function YazimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  P: PPencere;
  Alan: TAlan;
  A1, B1: TISayi4;
  IslevNo: TSayi4;
  Bellek: Isaretci;
begin

  // öntanımlı geri dönüş değeri
  Result := 0;

  // işlev no
  IslevNo := (AIslevNo and $FF);

  // görsel nesneye karakter yaz
  if(IslevNo = 1) then
  begin

    P := PPencere(P^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(P = nil) then Exit;

    Alan := P^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    P^.HarfYaz(P, A1, B1, PChar(ADegiskenler + 16)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye karakter katarı yaz
  else if(IslevNo = 2) then
  begin

    P := PPencere(P^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(P = nil) then Exit;

    Alan := P^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Bellek := Isaretci((PSayi4(ADegiskenler + 16)^ + FAktifGorevBellekAdresi));

    P^.YaziYaz(P, A1, B1, PKarakterKatari(Bellek)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye onaltılı tabanda sayı yaz
  else if(IslevNo = 3) then
  begin

    P := PPencere(P^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(P = nil) then Exit;

    Alan := P^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    P^.SayiYaz16(P, A1, B1, PLongBool(ADegiskenler + 16)^, PISayi4(ADegiskenler + 20)^,
      PISayi4(ADegiskenler + 24)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye saat değerini yaz
  else if(IslevNo = 4) then
  begin

    P := PPencere(P^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(P = nil) then Exit;

    Alan := P^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    P^.SaatYaz(P, A1, B1, PSaat(ADegiskenler + 16)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye mac adresini yaz
  else if(IslevNo = 5) then
  begin

    P := PPencere(P^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(P = nil) then Exit;

    Alan := P^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Bellek := PMACAdres(PSayi4(ADegiskenler + 16)^ + FAktifGorevBellekAdresi);

    P^.MACAdresiYaz(P, A1, B1, PMACAdres(Bellek)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye ip adresini yaz
  else if(IslevNo = 6) then
  begin

    P := PPencere(P^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(P = nil) then Exit;

    Alan := P^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;
    Bellek := PIPAdres(PSayi4(ADegiskenler + 16)^ + FAktifGorevBellekAdresi);

    P^.IPAdresiYaz(P, A1, B1, PIPAdres(Bellek)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye ondalık sayısal değer yazar
  else if(IslevNo = 7) then
  begin

    P := PPencere(P^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntPencere));
    if(P = nil) then Exit;

    Alan := P^.CizimAlaniniAl2(PKimlik(ADegiskenler + 00)^);
    A1 := PISayi4(ADegiskenler + 04)^ + Alan.Sol;
    B1 := PISayi4(ADegiskenler + 08)^ + Alan.Ust;

    P^.SayiYaz10(P, A1, B1, PISayi4(ADegiskenler + 16)^, PRenk(ADegiskenler + 12)^);

    Result := 1;
  end

  // işlev belirtilen aralıkta değilse hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.

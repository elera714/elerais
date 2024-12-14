{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_yazim.pas
  Dosya İşlevi: grafiksel ekrana yazım kesme işlevlerini içerir

  Güncelleme Tarihi: 14/09/2019

 ==============================================================================}
{$mode objfpc}
unit k_yazim;

interface

uses paylasim;

function YazimCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;

implementation

uses gorselnesne, gn_pencere;

{==============================================================================
  görsel nesne (pencere nesnesi) yazım kesmelerini içerir
 ==============================================================================}
function YazimCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  _Pencere: PPencere;
  _Alan: TAlan;
  _A1, _B1: TISayi4;
  _Islev: TSayi4;
  _Bellek: Isaretci;
begin

  // öntanımlı geri dönüş değeri
  Result := 0;

  // işlev no
  _Islev := (IslevNo and $FF);

  // görsel nesneye karakter yaz
  if(_Islev = 1) then
  begin

    _Pencere := PPencere(_Pencere^.NesneTipiniKontrolEt(PKimlik(Degiskenler)^, gntPencere));
    if(_Pencere = nil) then Exit;

    _Alan := _Pencere^.CizimAlaniniAl2(PKimlik(Degiskenler)^);
    _A1 := PISayi4(Degiskenler + 04)^ + _Alan.Sol;
    _B1 := PISayi4(Degiskenler + 08)^ + _Alan.Ust;

    _Pencere^.HarfYaz(_Pencere, _A1, _B1, PChar(Degiskenler + 16)^,
      PRenk(Degiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye karakter katarı yaz
  else if(_Islev = 2) then
  begin

    _Pencere := PPencere(_Pencere^.NesneTipiniKontrolEt(PKimlik(Degiskenler)^, gntPencere));
    if(_Pencere = nil) then Exit;

    _Alan := _Pencere^.CizimAlaniniAl2(PKimlik(Degiskenler)^);
    _A1 := PISayi4(Degiskenler + 04)^ + _Alan.Sol;
    _B1 := PISayi4(Degiskenler + 08)^ + _Alan.Ust;
    _Bellek := Isaretci((PSayi4(Degiskenler + 16)^ + CalisanGorevBellekAdresi));

    _Pencere^.YaziYaz(_Pencere, _A1, _B1, PKarakterKatari(_Bellek)^, PRenk(Degiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye onaltılı tabanda sayı yaz
  else if(_Islev = 3) then
  begin

    _Pencere := PPencere(_Pencere^.NesneTipiniKontrolEt(PKimlik(Degiskenler)^, gntPencere));
    if(_Pencere = nil) then Exit;

    _Alan := _Pencere^.CizimAlaniniAl2(PKimlik(Degiskenler)^);
    _A1 := PISayi4(Degiskenler + 04)^ + _Alan.Sol;
    _B1 := PISayi4(Degiskenler + 08)^ + _Alan.Ust;

    _Pencere^.SayiYaz16(_Pencere, _A1, _B1, PLongBool(Degiskenler + 16)^, PISayi4(Degiskenler + 20)^,
      PISayi4(Degiskenler + 24)^, PRenk(Degiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye saat değerini yaz
  else if(_Islev = 4) then
  begin

    _Pencere := PPencere(_Pencere^.NesneTipiniKontrolEt(PKimlik(Degiskenler)^, gntPencere));
    if(_Pencere = nil) then Exit;

    _Alan := _Pencere^.CizimAlaniniAl2(PKimlik(Degiskenler)^);
    _A1 := PISayi4(Degiskenler + 04)^ + _Alan.Sol;
    _B1 := PISayi4(Degiskenler + 08)^ + _Alan.Ust;

    _Pencere^.SaatYaz(_Pencere, _A1, _B1, PSaat(Degiskenler + 16)^, PRenk(Degiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye mac adresini yaz
  else if(_Islev = 5) then
  begin

    _Pencere := PPencere(_Pencere^.NesneTipiniKontrolEt(PKimlik(Degiskenler)^, gntPencere));
    if(_Pencere = nil) then Exit;

    _Alan := _Pencere^.CizimAlaniniAl2(PKimlik(Degiskenler)^);
    _A1 := PISayi4(Degiskenler + 04)^ + _Alan.Sol;
    _B1 := PISayi4(Degiskenler + 08)^ + _Alan.Ust;
    _Bellek := PMACAdres(PSayi4(Degiskenler + 16)^ + CalisanGorevBellekAdresi);

    _Pencere^.MACAdresiYaz(_Pencere, _A1, _B1, PMACAdres(_Bellek)^, PRenk(Degiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye ip adresini yaz
  else if(_Islev = 6) then
  begin

    _Pencere := PPencere(_Pencere^.NesneTipiniKontrolEt(PKimlik(Degiskenler)^, gntPencere));
    if(_Pencere = nil) then Exit;

    _Alan := _Pencere^.CizimAlaniniAl2(PKimlik(Degiskenler)^);
    _A1 := PISayi4(Degiskenler + 04)^ + _Alan.Sol;
    _B1 := PISayi4(Degiskenler + 08)^ + _Alan.Ust;
    _Bellek := PIPAdres(PSayi4(Degiskenler + 16)^ + CalisanGorevBellekAdresi);

    _Pencere^.IPAdresiYaz(_Pencere, _A1, _B1, PIPAdres(_Bellek)^, PRenk(Degiskenler + 12)^);

    Result := 1;
  end

  // görsel nesneye ondalık sayısal değer yazar
  else if(_Islev = 7) then
  begin

    _Pencere := PPencere(_Pencere^.NesneTipiniKontrolEt(PKimlik(Degiskenler)^, gntPencere));
    if(_Pencere = nil) then Exit;

    _Alan := _Pencere^.CizimAlaniniAl2(PKimlik(Degiskenler)^);
    _A1 := PISayi4(Degiskenler + 04)^ + _Alan.Sol;
    _B1 := PISayi4(Degiskenler + 08)^ + _Alan.Ust;

    _Pencere^.SayiYaz10(_Pencere, _A1, _B1, PISayi4(Degiskenler + 16)^, PRenk(Degiskenler + 12)^);

    Result := 1;
  end

  // işlev belirtilen aralıkta değilse hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.

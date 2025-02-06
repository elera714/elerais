{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: islevler.pas
  Dosya İşlevi: genel işlevleri içerir

  Güncelleme Tarihi: 29/09/2019

 ==============================================================================}
{$mode objfpc}
unit islevler;

interface

uses paylasim;

procedure DosyaYolunuParcala(const ATamDosyaYolu: string; var ASurucu,
  ADizin, ADosyaAdi: string);
procedure DosyaYolunuParcala2(const ATamDosyaYolu: string; var ASurucu,
  AKlasor, ADosyaAdi: string);
function IPAdresleriniKarsilastir(AIPAdres1, AIPAdres2: TIPAdres): Boolean;

implementation

{==============================================================================
  sürücü + dizin + dosya yolunu parçalara ayırır
  { TODO : dizin işlevi henüz uygulanmadı }
 ==============================================================================}
procedure DosyaYolunuParcala(const ATamDosyaYolu: string; var ASurucu,
  ADizin, ADosyaAdi: string);
var
  i: TSayi4;
begin

  i := Pos(':\', ATamDosyaYolu);
  if(i = 0) then
  begin

    ASurucu := AcilisSurucuAygiti;
    ADizin := '';
    ADosyaAdi := ATamDosyaYolu;
  end
  else
  begin

    ASurucu := Copy(ATamDosyaYolu, 1, i - 1);
    ADizin := '';
    ADosyaAdi := Copy(ATamDosyaYolu, i + 2, Length(ATamDosyaYolu) - i - 1);
  end;
end;

{==============================================================================
  sürücü + dizin + dosya yolunu parçalara ayırır
  giriş: disk1:\klasör1\dosya1.c
  çıktı: ASurucu = disk1, AKlasor = \klasör1\, ADosyaAdi = dosya1.c
 ==============================================================================}
procedure DosyaYolunuParcala2(const ATamDosyaYolu: string; var ASurucu,
  AKlasor, ADosyaAdi: string);
var
  i: TSayi4;
  s: string;
begin

  // örnek değer: disk1:\klasör1\dosya1.c
  i := Pos(':', ATamDosyaYolu);
  if(i = 0) then
  begin

    ASurucu := AcilisSurucuAygiti;
    AKlasor := '\' + KLASOR_PROGRAM + '\';
    ADosyaAdi := ATamDosyaYolu;
  end
  else
  begin

    // ASurucu = disk1
    ASurucu := Copy(ATamDosyaYolu, 1, i - 1);
    s := Copy(ATamDosyaYolu, i + 1, Length(ATamDosyaYolu) - i);

    i := Length(s);
    while s[i] <> '\' do Dec(i);

    // AKlasor = \klasör1\
    AKlasor := Copy(s, 1, i);

    // ADosyaAdi = dosya1.c
    ADosyaAdi := Copy(s, i + 1, Length(s) - i);
  end;
end;

{==============================================================================
  2 ip adresini karşılaştırır
 ==============================================================================}
function IPAdresleriniKarsilastir(AIPAdres1, AIPAdres2: TIPAdres): Boolean;
var
  i: TISayi4;
begin

  Result := False;

  for i := 0 to 3 do
  begin

    if(AIPAdres1[i] <> AIPAdres2[i]) then Exit;
  end;

  Result := True;
end;

end.

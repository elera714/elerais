program grafik5;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: grafik5.lpr
  Program İşlevi: çoklu dikdörtgen / kare çizim programı - double değer testi

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
uses n_gorev, gn_pencere, n_zamanlayici;

const
  ProgramAdi: string = 'Grafik-5';

  USTDEGER_NOKTASAYISI = 55;

type
  TSayac = record
    AzamiDeger: TSayi4;
    MevcutDeger, Hiz: Double;
    Renk: TRenk;
  end;

var
  Gorev: TGorev;
  Pencere: TPencere;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  i, j, Sol, Ust: TISayi4;
  SayacListesi: array[0..USTDEGER_NOKTASAYISI - 1] of TSayac;
  HizListesi: array[0..7] of Double = (0.1, 1.0, 2.0, 3.0, 3.5, 2.5, 1.5, 0.5);
  RenkListesi: array[0..7] of Integer = ($FF0000, $00FF00, $FFFF00, $0000FF, $FF00FF,
    $00FFFF, $000080, $008000);

function RDTSCDegeriAl: TISayi4;
var
  Deger: TISayi4;
begin

  // RDTSC değerini al - geçici işlev
  asm
    mov eax,19
    int $34
    mov Deger,eax
  end;

  Result := Deger;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 150, 150, 450, 300, ptIletisim, ProgramAdi, $F7EEF3);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Zamanlayici.Olustur(30);

  Pencere.Gorunum := True;

  // tüm nokta değişkenlerini ilk değerlerle Ustükle
  for i := 0 to USTDEGER_NOKTASAYISI - 1 do
  begin

    j := RDTSCDegeriAl;
    SayacListesi[i].MevcutDeger := 0.0;
    SayacListesi[i].AzamiDeger := 300;
    SayacListesi[i].Hiz := HizListesi[j and 7];
    SayacListesi[i].Renk := RenkListesi[j and 7];
  end;

  // zamanlayıcıUstı başlat
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayAl(Olay);
    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      // tüm dikdörtgen / kare dikey değerlerini artır
      for i := 0 to USTDEGER_NOKTASAYISI - 1 do
      begin

        SayacListesi[i].MevcutDeger := SayacListesi[i].MevcutDeger + SayacListesi[i].Hiz;
        if(SayacListesi[i].MevcutDeger > SayacListesi[i].AzamiDeger) then
        begin

          SayacListesi[i].MevcutDeger := 0.0;
          j := RDTSCDegeriAl;
          SayacListesi[i].Hiz := HizListesi[j and 7];
        end;
      end;

      Pencere.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      // yeni koordinatlarla çizimleri yenile
      for i := 0 to USTDEGER_NOKTASAYISI - 1 do
      begin

        Sol := i * 8;
        Ust := Round(SayacListesi[i].MevcutDeger);
        Pencere.Tuval.Dikdortgen(Sol, Ust, 7, 7, SayacListesi[i].Renk, True);
      end;
    end;
  end;
end.

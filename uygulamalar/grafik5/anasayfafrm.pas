{$mode objfpc}
{$asmmode intel}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FZamanlayici: TZamanlayici;
    function RDTSCDegeriAl: TISayi4;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

type
  TSayac = record
    AzamiDeger: TSayi4;
    MevcutDeger, Hiz: Double;
    Renk: TRenk;
  end;

const
  PencereAdi: string = 'Grafik-5';

  USTDEGER_NOKTASAYISI = 55;

var
  i, j, Sol, Ust: TISayi4;
  SayacListesi: array[0..USTDEGER_NOKTASAYISI - 1] of TSayac;
  HizListesi: array[0..7] of Double = (0.1, 1.0, 2.0, 3.0, 3.5, 2.5, 1.5, 0.5);
  RenkListesi: array[0..7] of Integer = ($FF0000, $00FF00, $FFFF00, $0000FF, $FF00FF,
    $00FFFF, $000080, $008000);

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 150, 150, 450, 300, ptIletisim, PencereAdi, $F7EEF3);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FZamanlayici.Olustur(30);

  FPencere.Gorunum := True;

  // tüm nokta deðiþkenlerini ilk deðerlerle Ustükle
  for i := 0 to USTDEGER_NOKTASAYISI - 1 do
  begin

    j := RDTSCDegeriAl;
    SayacListesi[i].MevcutDeger := 0.0;
    SayacListesi[i].AzamiDeger := 300;
    SayacListesi[i].Hiz := HizListesi[j and 7];
    SayacListesi[i].Renk := RenkListesi[j and 7];
  end;

  // zamanlayýcýUstý baþlat
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    // tüm dikdörtgen / kare dikey deðerlerini artýr
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

    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    // yeni koordinatlarla çizimleri yenile
    for i := 0 to USTDEGER_NOKTASAYISI - 1 do
    begin

      Sol := i * 8;
      Ust := Round(SayacListesi[i].MevcutDeger);
      FPencere.Tuval.Dikdortgen(Sol, Ust, 7, 7, SayacListesi[i].Renk, True);
    end;
  end;

  Result := 1;
end;

function TfrmAnaSayfa.RDTSCDegeriAl: TISayi4;
var
  Deger: TISayi4;
begin

  // RDTSC deðerini al - geçici iþlev
  asm
    mov eax,19
    int $34
    mov Deger,eax
  end;

  Result := Deger;
end;

end.

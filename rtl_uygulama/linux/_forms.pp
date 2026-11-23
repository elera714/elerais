{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: _forms.pp
  Dosya İşlevi: lazarus uyumluluk birimi

  Güncelleme Tarihi: 22/11/2026

  Bilgi: ELERA İşletim Sistemi uygulamaları Lazarus uyum paketi (forms.pp)

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit _forms;

interface

uses n_gorev;

type

  TCagriIslevi = procedure of object;
  TOlayIslevi = function(AOlay: TOlay): TISayi4 of object;

  TForm = object
  private
  public
//    Olustur: TCagriIslevi;
  end;

  TApplication = object
  private
    FTitle: string;
    FGoster: TCagriIslevi;
    FOlay: TOlayIslevi;
    function GetTitle: string;
    procedure SetTitle(AValue: string);
  public
    Gorev: TGorev;
    procedure Initialize;
    procedure CreateForm(AForm: TForm; AOlustur, AGoster: TCagriIslevi;
      AOlay: TOlayIslevi);
    procedure Run;
  published
    property Title: string read GetTitle write SetTitle;
  end;

var
  Application: TApplication;

implementation

procedure TApplication.Initialize;
begin

  FGoster := nil;
  Gorev.Yukle;
end;

procedure TApplication.CreateForm(AForm: TForm; AOlustur, AGoster: TCagriIslevi;
  AOlay: TOlayIslevi);
begin

  // ilgili formun (pencere) oluştur (create) işlevini çalıştır
  AOlustur;

  // ilk formun göster işlevini al
  if(FGoster = nil) then
  begin

    FGoster := AGoster;
    FOlay := AOlay;
  end;
end;

procedure TApplication.Run;
var
  Olay: TOlay;
  i: TSayi4;
begin

  FGoster;

  while True do
  begin

    i := Gorev.OlaySayisiAl;
    if(i > 0) then
    begin

      Gorev.OlayAl(Olay);
      FOlay(Olay);
    end;
  end;
end;

function TApplication.GetTitle: string;
begin

  Result := FTitle;
end;

procedure TApplication.SetTitle(AValue: string);
begin

  FTitle := AValue;
  Gorev.Ad := FTitle;
end;

end.

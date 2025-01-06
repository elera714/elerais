{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: _forms.pp
  Dosya İşlevi: lazarus uyumluluk birimi

  Güncelleme Tarihi: 06/01/2025

  Bilgi: ELERA İşletim Sistemi uygulamaları Lazarus uyum paketi (forms.pp)

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit _forms;

interface

uses n_gorev;

type
  TApplication = object
  private
    FTitle: string;
    Gorev: TGorev;
    function GetTitle: string;
    procedure SetTitle(AValue: string);
  public
    procedure Olustur;
  published
    property Title: string read GetTitle write SetTitle;
  end;

var
  Application: TApplication;

implementation

procedure TApplication.Olustur;
begin

  Gorev.Yukle;
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

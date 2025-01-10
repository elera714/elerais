{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: paneller.lpr
  Program İşlevi: panel test programı

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program paneller;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Paneller';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

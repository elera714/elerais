{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: hafiza.lpr
  Program Ýþlevi: hafýza güçlendirmek için geliþtirilmiþ uygulama

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program hafiza;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Hafýza';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

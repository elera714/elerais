{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: takvim.lpr
  Program Ýþlevi: takvim uygulamasý

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program takvim;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Takvim';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

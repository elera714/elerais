{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: tasarim.lpr
  Program Ýþlevi: nesne tasarým - test programý

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program tasarim;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Nesne Tasarým - Test';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

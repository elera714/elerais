{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: grfktest.lpr
  Program Ýþlevi: grafik test programý (fps deðerini ölçer)

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program grfktest;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Grafik Test - 200x200';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

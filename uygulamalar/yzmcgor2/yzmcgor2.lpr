{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: yzmcgor2.lpr
  Program Ýþlevi: programýn yazmaç içeriðini görüntüler

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program yzmcgor2;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Yazmaçlar';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

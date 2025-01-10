{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: yzmcgor.lpr
  Program Ýþlevi: programýn yazmaç içeriðini görüntüler

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program yzmcgor;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Program Yazmaç Görüntüleyici';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

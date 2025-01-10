{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dskgor.lpr
  Program Ýþlevi: depolama aygýtý sektör içeriðini görüntüler

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program dskgor;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Depolama Aygýtý Ýçerik Görüntüleme';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

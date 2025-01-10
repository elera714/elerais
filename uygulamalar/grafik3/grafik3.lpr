{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: grafik3.lpr
  Program İşlevi: çoklu yönlendirilmiş nokta (pixel) işaretleme programı

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program grafik3;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Grafik-3';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

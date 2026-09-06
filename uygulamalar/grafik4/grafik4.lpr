{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: grafik4.lpr
  Program İşlevi: çoklu poligon çizim programı

  Güncelleme Tarihi: 12/08/2026

 ==============================================================================}
{$mode objfpc}
program grafik4;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Grafik-4';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

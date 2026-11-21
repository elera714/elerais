{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: grafik5.lpr
  Program İşlevi: çoklu dikdörtgen / kare çizim programı - double değer testi

  Güncelleme Tarihi: 21/11/2026

 ==============================================================================}
{$mode objfpc}
program grafik5;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Grafik-5';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

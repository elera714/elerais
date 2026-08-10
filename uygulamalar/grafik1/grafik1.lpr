{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: grafik1.lpr
  Program İşlevi: grafik test programı

  Güncelleme Tarihi: 10/08/2026

 ==============================================================================}
{$mode objfpc}
program grafik1;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Grafik-1';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

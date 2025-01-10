{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: noktalar.lpr
  Program İşlevi: nokta işaretleme test programı

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program saat;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Noktalar (300 x 300) - 0.5 saniye';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

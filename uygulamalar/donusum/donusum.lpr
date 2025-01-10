{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: donusum.lpr
  Program Ýþlevi: sayýsal deðer çevrim / dönüþüm programý

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program donusum;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Sayýsal Deðer Çevrimi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

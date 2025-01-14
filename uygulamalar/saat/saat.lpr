{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: saat.lpr
  Program Ýþlevi: dijital tarih / saat programý

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program saat;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Dijital Saat';
  Application.Initialize;

  //Application.CreateForm(TfrmAnaSayfa, frmAnaSayfa);
  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

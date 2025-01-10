{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: sisbilgi.lpr
  Program Ýþlevi: sistem hakkýnda bilgi verir

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program sisbilgi;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Sistem Bilgisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

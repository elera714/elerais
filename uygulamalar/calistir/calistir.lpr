{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: calistir.lpr
  Program Ýþlevi: komut satýrýndan çalýþtýrýlabilir programlarý çalýþtýrýr

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program calistir;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Program Çalýþtýr';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: calistir.lpr
  Program Ýþlevi: komut satýrýndan çalýþtýrýlabilir programlarý çalýþtýrýr

  Güncelleme Tarihi: 11/08/2026

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

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: kaydirma.lpr
  Program Ýþlevi: kaydýrma çubuðu tasarým çalýþmasý

  Güncelleme Tarihi: 11/08/2026

 ==============================================================================}
{$mode objfpc}
program kaydirma;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Kaydýrma Çubuðu - Tasarým';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

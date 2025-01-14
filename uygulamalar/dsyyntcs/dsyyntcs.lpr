{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dsyyntcs.lpr
  Program Ýþlevi: dosya yöneticisi

  Güncelleme Tarihi: 12/01/2025

 ==============================================================================}
{$mode objfpc}
program dsyyntcs;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Dosya Yöneticisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

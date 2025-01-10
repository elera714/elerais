{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: grvyntcs.lpr
  Program Ýþlevi: görev yöneticisi

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program grvyntcs;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Görev Yöneticisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

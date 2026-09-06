{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: muyntcs.lpr
  Program Ýþlevi: çoklu masaüstü yönetim programý

  Güncelleme Tarihi: 16/08/2026

 ==============================================================================}
{$mode objfpc}
program muyntcs;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Masaüstü Yöneticisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

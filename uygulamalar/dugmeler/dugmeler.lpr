{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dugmeler.lpr
  Program Ýþlevi: resim düðme test programý

  Güncelleme Tarihi: 11/08/2026

 ==============================================================================}
{$mode objfpc}
program dugmeler;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Düðmeler';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

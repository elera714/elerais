{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: suyari.lpr
  Program Ýþlevi: sistem uyarý mesajlarýný görüntüler

  Güncelleme Tarihi: 08/01/2026

 ==============================================================================}
{$mode objfpc}
program suyari;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Sistem Uyarý';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: smsjgor.lpr
  Program Ýþlevi: sistem tarafýndan üretilen mesajlarý görüntüleme programý

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program smsjgor;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Sistem Mesaj Görüntüleyici';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

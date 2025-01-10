{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: resimgor.lpr
  Program Ýþlevi: resim görüntüleyici program

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program resimgor;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Resim Görüntüleyici';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

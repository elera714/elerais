{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: bellkbil.lpr
  Program Ýþlevi: bellek kullanýmý hakkýnda bilgi verir

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program bellkbil;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Bellek Kullaným Bilgisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

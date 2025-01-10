{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dsybil.lpr
  Program Ýþlevi: dosyalar hakkýnda bilgi verir

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program dsybil;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Dosya Bilgisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

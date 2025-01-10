{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: nesnegor.lpr
  Program Ýþlevi: Görsel nesneler hakkýnda bilgiler verir.

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program nesnegor;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Nesne Görüntüleyici';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

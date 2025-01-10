{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dnssorgu.lpr
  Program Ýþlevi: dns adres sorgulama programý

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program dnssorgu;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Dijital Saat';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: arpbilgi.lpr
  Program Ýþlevi: ARP girdileri hakkýnda bilgi verir

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program saat;

uses anasayfafrm, _forms;

begin

  Application.Title := 'ARP Girdi Bilgisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

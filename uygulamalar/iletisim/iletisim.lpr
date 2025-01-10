{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: iletisim.lpr
  Program Ýþlevi: tcp / udp test programý

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program iletisim;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Ýletiþim - TCP/UDP';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

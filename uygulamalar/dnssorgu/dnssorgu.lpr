{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: dnssorgu.lpr
  Program ��levi: dns adres sorgulama program�

  G�ncelleme Tarihi: 10/01/2025

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

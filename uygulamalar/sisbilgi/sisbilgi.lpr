{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: sisbilgi.lpr
  Program ��levi: sistem hakk�nda bilgi verir

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program sisbilgi;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Sistem Bilgisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: bellkbil.lpr
  Program ��levi: bellek kullan�m� hakk�nda bilgi verir

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program bellkbil;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Bellek Kullan�m Bilgisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

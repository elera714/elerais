{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: hafiza.lpr
  Program ��levi: haf�za g��lendirmek i�in geli�tirilmi� uygulama

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program hafiza;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Haf�za';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

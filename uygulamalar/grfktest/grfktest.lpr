{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: grfktest.lpr
  Program ��levi: grafik test program� (fps de�erini �l�er)

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program grfktest;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Grafik Test - 200x200';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

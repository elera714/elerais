{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: donusum.lpr
  Program ��levi: say�sal de�er �evrim / d�n���m program�

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program donusum;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Say�sal De�er �evrimi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

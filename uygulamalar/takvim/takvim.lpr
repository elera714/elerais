{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: takvim.lpr
  Program ��levi: takvim uygulamas�

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program takvim;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Takvim';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

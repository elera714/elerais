{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: dsyyntcs.lpr
  Program ��levi: dosya y�neticisi

  G�ncelleme Tarihi: 12/01/2025

 ==============================================================================}
{$mode objfpc}
program dsyyntcs;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Dosya Y�neticisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

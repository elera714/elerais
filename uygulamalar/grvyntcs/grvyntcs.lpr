{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: grvyntcs.lpr
  Program ��levi: g�rev y�neticisi

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program grvyntcs;

uses anasayfafrm, _forms;

begin

  Application.Title := 'G�rev Y�neticisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: calistir.lpr
  Program ��levi: komut sat�r�ndan �al��t�r�labilir programlar� �al��t�r�r

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program calistir;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Program �al��t�r';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

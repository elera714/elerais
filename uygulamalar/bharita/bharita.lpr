{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: bharita.lpr
  Program ��levi: bellek i�erik harita program�

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program bharita;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Bellek Haritas�';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

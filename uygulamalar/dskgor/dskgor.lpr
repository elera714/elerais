{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: dskgor.lpr
  Program ��levi: depolama ayg�t� sekt�r i�eri�ini g�r�nt�ler

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program dskgor;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Depolama Ayg�t� ��erik G�r�nt�leme';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: smsjgor.lpr
  Program ��levi: sistem taraf�ndan �retilen mesajlar� g�r�nt�leme program�

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program smsjgor;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Sistem Mesaj G�r�nt�leyici';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: resimgor.lpr
  Program ��levi: resim g�r�nt�leyici program

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program resimgor;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Resim G�r�nt�leyici';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

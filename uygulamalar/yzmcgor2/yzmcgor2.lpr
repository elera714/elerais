{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: yzmcgor2.lpr
  Program ��levi: program�n yazma� i�eri�ini g�r�nt�ler

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program yzmcgor2;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Yazma�lar';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

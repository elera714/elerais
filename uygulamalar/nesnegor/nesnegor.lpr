{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: nesnegor.lpr
  Program ��levi: G�rsel nesneler hakk�nda bilgiler verir.

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program nesnegor;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Nesne G�r�nt�leyici';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

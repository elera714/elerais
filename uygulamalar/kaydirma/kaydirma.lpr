{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: kaydirma.lpr
  Program ��levi: kayd�rma �ubu�u tasar�m �al��mas�

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program kaydirma;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Kayd�rma �ubu�u - Tasar�m';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

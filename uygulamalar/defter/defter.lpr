{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: defter.lpr
  Program ��levi: metin d�zenleme program�

  G�ncelleme Tarihi: 10/01/2025

  Bilgi: �ekirdek taraf�ndan defter.c program�na bilgileri i�lemesi i�in
    Isaretci(4)^ adresinde 4096 * 10 byte yer tahsis edilmi�tir.

 ==============================================================================}
{$mode objfpc}
program defter;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Dijital Defter';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: iskelet.lpr
  Program ��levi: ana program iskeleti

  G�ncelleme Tarihi: 10/01/2025

  Bilgi: ELERA ��letim Sistemi program ana yap�s�n�n Lazarus nesnesel yap�s� ile uyumlu olmas�
    i�in gerekli �al��malar bu iskelet �al��mas� �zerinden ger�ekle�mektedir

 ==============================================================================}
{$mode objfpc}
program iskelet;

uses anasayfafrm, islemfrm, onayfrm, _forms;

begin

  Application.Title := 'Temel �skelet';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);
  Application.CreateForm(frmIslem, @frmIslem.Olustur, @frmIslem.Goster,
    @frmIslem.OlaylariIsle);
  Application.CreateForm(frmOnay, @frmOnay.Olustur, @frmOnay.Goster,
    @frmOnay.OlaylariIsle);

  Application.Run;
end.

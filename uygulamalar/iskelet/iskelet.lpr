{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: iskelet.lpr
  Program ��levi: ana program iskeleti

  G�ncelleme Tarihi: 06/01/2025

  Bilgi: ELERA ��letim Sistemi program ana yap�s�n�n Lazarus nesnesel yap�s� ile uyumlu olmas�
    i�in gerekli �al��malar bu uygulama iskelet �al��mas� arac�l���yla ger�ekle�mektedir

 ==============================================================================}
{$mode objfpc}
program iskelet;

uses n_gorev, anasayfafrm, islemfrm, onayfrm, _forms;

begin

  Application.Olustur;

  Application.Title := 'Temel �skelet';
  //Application.Initialize;
  //Application.CreateForm(TfrmAnaSayfa, frmAnaSayfa);
  //Application.Run;

  frmAnaSayfa.Olustur;
  frmIslem.Olustur;
  frmOnay.Olustur;

  frmAnaSayfa.Goster;
  frmAnaSayfa.OlaylariIsle;
end.

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: iskelet.lpr
  Program Ýþlevi: ana program iskeleti

  Güncelleme Tarihi: 06/01/2025

  Bilgi: ELERA Ýþletim Sistemi program ana yapýsýnýn Lazarus nesnesel yapýsý ile uyumlu olmasý
    için gerekli çalýþmalar bu uygulama iskelet çalýþmasý aracýlýðýyla gerçekleþmektedir

 ==============================================================================}
{$mode objfpc}
program iskelet;

uses n_gorev, anasayfafrm, islemfrm, onayfrm, _forms;

begin

  Application.Olustur;

  Application.Title := 'Temel Ýskelet';
  //Application.Initialize;
  //Application.CreateForm(TfrmAnaSayfa, frmAnaSayfa);
  //Application.Run;

  frmAnaSayfa.Olustur;
  frmIslem.Olustur;
  frmOnay.Olustur;

  frmAnaSayfa.Goster;
  frmAnaSayfa.OlaylariIsle;
end.

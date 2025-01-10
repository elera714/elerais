{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: iskelet.lpr
  Program Ýþlevi: ana program iskeleti

  Güncelleme Tarihi: 10/01/2025

  Bilgi: ELERA Ýþletim Sistemi program ana yapýsýnýn Lazarus nesnesel yapýsý ile uyumlu olmasý
    için gerekli çalýþmalar bu iskelet çalýþmasý üzerinden gerçekleþmektedir

 ==============================================================================}
{$mode objfpc}
program iskelet;

uses anasayfafrm, islemfrm, onayfrm, _forms;

begin

  Application.Title := 'Temel Ýskelet';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);
  Application.CreateForm(frmIslem, @frmIslem.Olustur, @frmIslem.Goster,
    @frmIslem.OlaylariIsle);
  Application.CreateForm(frmOnay, @frmOnay.Olustur, @frmOnay.Goster,
    @frmOnay.OlaylariIsle);

  Application.Run;
end.

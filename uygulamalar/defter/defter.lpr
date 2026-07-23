{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: defter.lpr
  Program Ýþlevi: metin düzenleme programý

  Güncelleme Tarihi: 23/07/2026

  Bilgi: çekirdek tarafýndan defter.c programýna bilgileri iþlemesi için
    Isaretci(4)^ adresinde 4096 * 10 byte yer tahsis edilmiþtir.

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

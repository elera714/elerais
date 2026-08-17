{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dskbolum.lpr
  Program Ýþlevi: sistemdeki mantýksal sürücü bilgisini verir

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
program dskbolum;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Depolama Aygýtý Bölüm Bilgisi';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

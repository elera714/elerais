{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: kopyala.lpr
  Program Ýþlevi: fiziksel disk kopyalama iþlevini gerçekleþtirir

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program kopyala;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Disk Kopyala';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

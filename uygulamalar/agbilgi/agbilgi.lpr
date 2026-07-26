{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: agbilgi.lpr
  Program Ýþlevi: að yapýlandýrmasý hakkýnda bilgi verir

  Güncelleme Tarihi: 26/07/2026

 ==============================================================================}
{$mode objfpc}
program saat;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Að Ayarlarý';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

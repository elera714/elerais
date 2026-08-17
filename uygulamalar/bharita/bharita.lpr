{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: bharita.lpr
  Program Ýþlevi: bellek içerik harita programý

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
program bharita;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Bellek Haritasý';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

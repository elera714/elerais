{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: mustudk.lpr
  Program Ýþlevi: masaüstü duvar kaðýt yönetim programý

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program mustudk;

uses anasayfafrm, _forms;

begin

  Application.Title := 'Masaüstü Duvar Kaðýdý';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

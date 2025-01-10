{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: pcibil.lpr
  Program Ýþlevi: pci aygýtlarý hakkýnda bilgi verir

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program pcibil;

uses anasayfafrm, _forms;

begin

  Application.Title := 'PCI Aygýt Bilgileri';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

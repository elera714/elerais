{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: pcibil.lpr
  Program ��levi: pci ayg�tlar� hakk�nda bilgi verir

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program pcibil;

uses anasayfafrm, _forms;

begin

  Application.Title := 'PCI Ayg�t Bilgileri';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

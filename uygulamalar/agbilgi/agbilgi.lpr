{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: agbilgi.lpr
  Program ��levi: a� yap�land�rmas� hakk�nda bilgi verir

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
program saat;

uses anasayfafrm, _forms;

begin

  Application.Title := 'A� Ayarlar�';
  Application.Initialize;

  Application.CreateForm(frmAnaSayfa, @frmAnaSayfa.Olustur, @frmAnaSayfa.Goster,
    @frmAnaSayfa.OlaylariIsle);

  Application.Run;
end.

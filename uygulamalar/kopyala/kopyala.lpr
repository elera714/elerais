{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: kopyala.lpr
  Program ��levi: fiziksel disk kopyalama i�levini ger�ekle�tirir

  G�ncelleme Tarihi: 10/01/2025

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

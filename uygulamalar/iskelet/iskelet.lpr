{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: iskelet.lpr
  Program ��levi: ana program iskeleti

  G�ncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
program iskelet;

uses n_gorev, anabirim, birim2, birim3;

const
  ProgramAdi: string = 'Temel �skelet';

var
  Gorev: TGorev;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere1.Olustur;
  Pencere2.Olustur;
  Pencere3.Olustur;

  Pencere1.Goster;
  Pencere1.OlaylariIsle;
end.

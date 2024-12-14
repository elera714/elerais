{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: iskelet.lpr
  Program Ýþlevi: ana program iskeleti

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
program iskelet;

uses n_gorev, anabirim, birim2, birim3;

const
  ProgramAdi: string = 'Temel Ýskelet';

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

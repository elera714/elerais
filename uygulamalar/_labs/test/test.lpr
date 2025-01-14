program test;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: test.lpr
  Program İşlevi: ELERA İşletim Sistemi programlarının Lazarus ile uyumu amacıyla
    oluşturulmuş test ortamı

  Güncelleme Tarihi: 13/01/2025

 ==============================================================================}
{$mode objfpc}
type
  PSinif = ^TSinif;
  TSinif = class
  private
    ii: Integer;
  public
    constructor Create;
    destructor Destroy; override;
  end;

type
  PNesne = ^TNesne;
  TNesne = object
  private
    s: string;
    i: Integer;
  public
    function Olustur: TNesne;
    constructor Create;
  end;

var
  Sinif: TSinif;
  Nesne: TNesne;

{ ------------------------------- SINIF -------------------------------------- }

constructor TSinif.Create;
begin

  ii := $1234;
end;

destructor TSinif.Destroy;
begin

  ii := $5678;
end;

{ ------------------------------- NESNE -------------------------------------- }

function TNesne.Olustur: TNesne;
begin

  Result := Self;
end;

constructor TNesne.Create;
begin

  i := $5678;
end;

begin

{  Nesne := Nesne.Olustur;
  Nesne.s := 'merhaba';
  Nesne.i := $12345678; }

  Sinif := Sinif.Create;
  Sinif.ii := $12345678;
  Sinif.Destroy;
end.

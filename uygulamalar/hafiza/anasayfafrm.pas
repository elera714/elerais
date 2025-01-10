{$mode objfpc}
{$asmmode intel}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_etiket, gn_dugme;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FDurum: TEtiket;
    FDugmeler: array[0..15] of TDugme;
    FSeciliDugme1, FSeciliDugme2: PDugme;
    function CiftDegerDegeriAl: TSayi4;
    procedure IlkDegerAtamalari;
    function DugmeAl(AKimlik: TKimlik): PDugme;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Haf�za';

var
  CiftDegerDizisi: array[1..8] of TSayi4;     // her 2 d��meye da��t�lan tek (e�) de�erler
  BulunanCiftSayisi, TiklamaSayisi,
  ToplamTiklamaSayisi, i: TSayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 328, 360, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FDurum.Olustur(FPencere.Kimlik, 92, 330, RENK_LACIVERT, 'T�klama Say�s�: 0  ');
  FDurum.Goster;

  IlkDegerAtamalari;

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    Inc(TiklamaSayisi);
    Inc(ToplamTiklamaSayisi);

    FDurum.BaslikDegistir('T�klama Say�s�: ' + IntToStr(ToplamTiklamaSayisi));

    if(TiklamaSayisi = 1) then
    begin

      FSeciliDugme1 := DugmeAl(AOlay.Kimlik);
      if not(FSeciliDugme1 = nil) then
        FSeciliDugme1^.BaslikDegistir(IntToStr(FSeciliDugme1^.Etiket));
    end

    else if(TiklamaSayisi = 2) then
    begin

      FSeciliDugme2 := DugmeAl(AOlay.Kimlik);

      // 1. ve 2. t�klama ayn� d��meye mi yap�ld�?
      if(FSeciliDugme1^.Kimlik = FSeciliDugme2^.Kimlik) then
      begin

        FSeciliDugme1^.BaslikDegistir('?');
      end
      else
      begin

        // bir rakam�n e�i bulunduysa
        if(FSeciliDugme1^.Etiket = FSeciliDugme2^.Etiket) then
        begin

          FSeciliDugme2^.BaslikDegistir(IntToStr(FSeciliDugme2^.Etiket));

          FGenel.Bekle(40);

          FSeciliDugme1^.Gizle;
          FSeciliDugme2^.Gizle;

          Inc(BulunanCiftSayisi);
          if(BulunanCiftSayisi = 8) then
          begin

            FGenel.Bekle(40);

            for i := 0 to 15 do FDugmeler[i].YokEt;

            // oyunu ba�a d�nd�r
            IlkDegerAtamalari;
          end;
        end
        else
        // bir rakam�n e�i BULUNMADIYSA
        begin

          FSeciliDugme2^.BaslikDegistir(IntToStr(FSeciliDugme2^.Etiket));

          FGenel.Bekle(40);

          FSeciliDugme1^.BaslikDegistir('?');
          FSeciliDugme2^.BaslikDegistir('?');
        end;
      end;

      TiklamaSayisi := 0;
    end;
  end;

  Result := 1;
end;

// �ift de�er dizilerinden bir adet de�er geri d�nd�r�r
function TfrmAnaSayfa.CiftDegerDegeriAl: TSayi4;
var
  Deger: TSayi4;

  function DegerUret: TSayi4;
  begin
    asm rdtsc end;
  end;
begin

  while True do
  begin

    Deger := DegerUret;
    Deger := (Deger and 7) + 1;

    if(Deger >= 1) and (Deger <= 8) then
    begin

      if(CiftDegerDizisi[Deger] < 2) then
      begin

        Inc(CiftDegerDizisi[Deger]);
        Exit(Deger);
      end;
    end;
  end;
end;

// program ilk de�er atamalar�
procedure TfrmAnaSayfa.IlkDegerAtamalari;
var
  Sol, Ust, i, j,
  DugmeSayisi: TISayi4;
begin

  ToplamTiklamaSayisi := 0;

  TiklamaSayisi := 0;

  BulunanCiftSayisi := 0;

  Sol := 12;
  Ust := 12;

  for i := 1 to 8 do CiftDegerDizisi[i] := 0;

  DugmeSayisi := 0;
  for i := 0 to 3 do
  for j := 0 to 3 do
  begin

    FDugmeler[DugmeSayisi].Olustur(FPencere.Kimlik, Sol + i * 76, Ust + j * 76, 74, 74, '?');
    FDugmeler[DugmeSayisi].Etiket := CiftDegerDegeriAl;
    FDugmeler[DugmeSayisi].Goster;

    Inc(DugmeSayisi);
  end;

  FDurum.BaslikDegistir('T�klama Say�s�: 0');
end;

// kimli�in kar��l��� olan d��meyi bulur
function TfrmAnaSayfa.DugmeAl(AKimlik: TKimlik): PDugme;
var
  i: TSayi4;
begin

  for i := 0 to 15 do
  begin

    if(FDugmeler[i].Kimlik = AKimlik) then Exit(@FDugmeler[i]);
  end;

  Exit(nil);
end;

end.

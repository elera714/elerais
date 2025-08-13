{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: arge.pas
  Dosya ��levi: sistem ar-ge �al��malar�n� i�erir

  G�ncelleme Tarihi: 21/05/2025

 ==============================================================================}
{$mode objfpc}
unit arge;

interface

uses paylasim, gn_masaustu, gn_pencere, gn_araccubugu, gn_durumcubugu, gn_gucdugmesi,
  gn_panel, gn_sayfakontrol, gn_etiket, gn_defter, gn_dugme, gn_giriskutusu,
  gn_onaykutusu, gn_kaydirmacubugu, gn_listekutusu, gn_karmaliste, gorselnesne;

type

  { TAracTipiSinif }
  PAracTipiSinif = ^TAracTipiSinif;
  TAracTipiSinif = class
  //private

  public
    FKimlik: TSayi4;
    constructor Create;
    destructor Destroy; override;
  published
    property Kimlik: TSayi4 read FKimlik write FKimlik;
  end;

type
  //TAracTipListesi = specialize TFPGObjectList<TAracTipiSinif>;

  { TAracTipleriSinif }

  TAracTipleriSinif = class
  private
    FToplam: TSayi4;
    function Al(ASiraNo: Integer): TAracTipiSinif;
    procedure Yaz(ASiraNo: Integer; AGaraj: TAracTipiSinif);
  public
    FAracTipListesi: array[0..9] of TAracTipiSinif;
    constructor Create;
    destructor Destroy; override;
    function Toplam: Integer;
    procedure Temizle;
    function Ekle: TAracTipiSinif;
    property AracTipi[ASiraNo: Integer]: TAracTipiSinif read Al write Yaz;
  end;

type
  TArgeIslev = procedure of object;

type
  TArGe = class
  private
    P1Pencere, P2Pencere: PPencere;
    P2AracCubugu: PAracCubugu;
    P2DurumCubugu: PDurumCubugu;
    P4Panel: PPanel;
    P1Dugmeler: array[0..44] of PGucDugmesi;
    P4Etiket: PEtiket;
    P4OnayKutusu: POnayKutusu;
    P4KarmaListe: PKarmaListe;
    P4ListeKutusu: PListeKutusu;
    P4KaydirmaCubugu: PKaydirmaCubugu;
    P4Dugme: PDugme;
    P4Defter: PDefter;
    P2ACDugmeler: array[0..11] of TKimlik;
    P4GucDugmesi: PGucDugmesi;
    P4GirisKutusu: PGirisKutusu;
    SonKonumY, SonKonumD, SonSecim: TSayi4;
  public
    GorevNo: TISayi4;
    Panel: PPanel;
    BulunanCiftSayisi, TiklamaSayisi, SecilenEtiket, ToplamTiklamaSayisi: TSayi4;
    FCalisacakIslev: TArgeIslev;
    P3SayfaKontrol: PSayfaKontrol;
    FSeciliYil, FSeciliAy: TISayi4;
    BuAy, BuYil: TSayi2;
    constructor Create(AProgramSN: TSayi4);
    procedure Calistir;
    procedure Program1Basla;
    procedure Program2Basla;
    procedure P1NesneTestOlayIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure P2NesneTestOlayIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

procedure Prg1;
procedure Prg2;

implementation

uses donusum, zamanlayici, sistemmesaj;

{ TAracTipleriSinif }

function TAracTipleriSinif.Al(ASiraNo: Integer): TAracTipiSinif;
begin

{  if(ASiraNo >= 0) and (ASiraNo < Toplam) then
    Result := FAracTipListesi[ASiraNo]
  else Result := nil;}
end;

procedure TAracTipleriSinif.Yaz(ASiraNo: Integer; AGaraj: TAracTipiSinif);
begin

  {if(ASiraNo >= 0) and (ASiraNo < Toplam) then
    FAracTipListesi[ASiraNo] := AGaraj;}
end;

constructor TAracTipleriSinif.Create;
var
  i: TSayi4;
begin

  FToplam := 0;

  for i := 0 to 9 do FAracTipListesi[i] := nil;

  //FAracTipListesi := TAracTipListesi.Create(False);
end;

destructor TAracTipleriSinif.Destroy;
begin

  //FreeAndNil(FAracTipListesi);
  inherited;
end;

function TAracTipleriSinif.Toplam: Integer;
begin

  Result := FToplam;
  //Result := FAracTipListesi.Count;
end;

procedure TAracTipleriSinif.Temizle;
begin

end;

function TAracTipleriSinif.Ekle: TAracTipiSinif;
var
  A: TAracTipiSinif;
begin

  A := TAracTipiSinif.Create;
  FAracTipListesi[FToplam] := A;
  Inc(FToplam);

  Result := A;
end;

{ TAracTipiSinif }

constructor TAracTipiSinif.Create;
begin

end;

destructor TAracTipiSinif.Destroy;
begin
  inherited Destroy;
end;

constructor TArGe.Create(AProgramSN: TSayi4);
begin

  FCalisacakIslev := nil;

  case AProgramSN of
    1: FCalisacakIslev := @Program1Basla;
    2: FCalisacakIslev := @Program2Basla;
  end;
end;

procedure TArGe.Calistir;
begin

  if not(FCalisacakIslev = nil) then FCalisacakIslev;
end;

procedure TArGe.Program1Basla;
var
  P1Masaustu: PMasaustu = nil;
begin

  P1Masaustu := P1Masaustu^.Olustur('giri�');
  P1Masaustu^.MasaustuRenginiDegistir($9FB6BF);
  P1Masaustu^.Aktiflestir;

  P1Pencere := P1Pencere^.Olustur(P1Masaustu, 100, 100, 500, 400,
    ptBoyutlanabilir, 'G�rsel Nesne Y�netim', RENK_BEYAZ);
  P1Pencere^.OlayYonlendirmeAdresi := @P1NesneTestOlayIsle;

  P1Dugmeler[0] := P1Dugmeler[0]^.Olustur(ktNesne, P1Pencere, 10,
    10, 100, 100, 'Art�r');
  P1Dugmeler[0]^.OlayYonlendirmeAdresi := @P1NesneTestOlayIsle;
  P1Dugmeler[0]^.Goster;

  P1Dugmeler[1] := P1Dugmeler[1]^.Olustur(ktNesne, P1Pencere, 120,
    10, 100, 100, 'Eksilt');
  P1Dugmeler[1]^.OlayYonlendirmeAdresi := @P1NesneTestOlayIsle;
  P1Dugmeler[1]^.Goster;

  P1Pencere^.Goster;

  P1Masaustu^.Gorunum := True;
end;

procedure TArGe.P1NesneTestOlayIsle(AGonderici: PGorselNesne; AOlay: TOlay);
begin

end;

procedure TArGe.Program2Basla;
begin

  SonSecim := 0;

  P2Pencere := P2Pencere^.Olustur(nil, 0, 0, 450, 300, ptBoyutlanabilir,
    'Nesneler', RENK_BEYAZ);
  P2Pencere^.OlayYonlendirmeAdresi := @P2NesneTestOlayIsle;

  P2AracCubugu := P2AracCubugu^.Olustur(ktNesne, P2Pencere);
  P2ACDugmeler[0] := P2AracCubugu^.DugmeEkle2(0);
  P2ACDugmeler[1] := P2AracCubugu^.DugmeEkle2(11);
  P2ACDugmeler[2] := P2AracCubugu^.DugmeEkle2(2);
  P2ACDugmeler[3] := P2AracCubugu^.DugmeEkle2(6);
  P2ACDugmeler[4] := P2AracCubugu^.DugmeEkle2(3);
  P2ACDugmeler[5] := P2AracCubugu^.DugmeEkle2(4);
  P2ACDugmeler[6] := P2AracCubugu^.DugmeEkle2(5);
  P2ACDugmeler[7] := P2AracCubugu^.DugmeEkle2(7);
  P2ACDugmeler[8] := P2AracCubugu^.DugmeEkle2(10);
  P2ACDugmeler[9] := P2AracCubugu^.DugmeEkle2(8);
  P2ACDugmeler[10] := P2AracCubugu^.DugmeEkle2(9);
  P2AracCubugu^.OlayYonlendirmeAdresi := @P2NesneTestOlayIsle;
  P2AracCubugu^.Goster;

  P2DurumCubugu := P2DurumCubugu^.Olustur(ktNesne, P2Pencere, 0, 0,
    10, 10, 'Konum: 0:0');
  P2DurumCubugu^.OlayYonlendirmeAdresi := @P2NesneTestOlayIsle;
  P2DurumCubugu^.Goster;

  P2Pencere^.Goster;
end;

procedure TArGe.P2NesneTestOlayIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Sol, Ust, G, Y, i: TISayi4;
  Alan: TAlan;
  s: string;
begin

  if(AOlay.Olay = CO_CIZIM) then
  begin

    G := AGonderici^.FAtananAlan.Genislik;
    Y := AGonderici^.FAtananAlan.Yukseklik - 28;

    // yatay �izgiler
    Ust := 5 + 28;
    repeat

      Alan := P2Pencere^.FKalinlik;
      for i := 0 to G div 10 do
        P2Pencere^.PixelYaz(P2Pencere, Alan.Sol + (i * 10) + 3,
          Alan.Ust + Ust, RENK_GRI);
      Inc(Ust, 10);
    until Ust > Y;
  end
  else if(AOlay.Olay = FO_HAREKET) and (AOlay.Kimlik = P2Pencere^.Kimlik) then
  begin

    SonKonumY := AOlay.Deger1 - P2Pencere^.FKalinlik.Sol;
    SonKonumD := AOlay.Deger2 - P2Pencere^.FKalinlik.Ust;

    case SonSecim of
      0: s := '-';
      1: s := 'TPanel';
      2: s := 'TD��me';
      3: s := 'TGucDugmesi';
      4: s := 'TEtiket';
      5: s := 'TGiri�Kutusu';
      6: s := 'TDefter';
      7: s := 'TOnayKutusu';
      8: s := 'TKayd�rma�ubu�u';
      9: s := 'TListeKutusu';
      10: s := 'TKarmaListe';
    end;

    P2DurumCubugu^.Baslik := 'Konum: ' + IntToStr(AOlay.Deger1) +
      ':' + IntToStr(AOlay.Deger2) + ' - Se�ili Nesne: ' + s;
    P2DurumCubugu^.Ciz;
  end
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) and (AOlay.Kimlik = P2Pencere^.Kimlik) then
  begin

    if(SonSecim = 1) then
    begin

      P4Panel := P4Panel^.Olustur(ktNesne, P2Pencere, SonKonumY,
        SonKonumD, 50, 50, 3, RENK_KIRMIZI, RENK_BEYAZ, RENK_SIYAH, 'TPanel');
      P4Panel^.Goster;
    end
    else if(SonSecim = 2) then
    begin

      P4Dugme := P4Dugme^.Olustur(ktNesne, P2Pencere, SonKonumY,
        SonKonumD, 100, 20, 'TD��me');
      P4Dugme^.Goster;
    end
    else if(SonSecim = 3) then
    begin

      P4GucDugmesi := P4GucDugmesi^.Olustur(ktNesne, P2Pencere,
        SonKonumY, SonKonumD, 100, 20, 'TG��D��mesi');
      P4GucDugmesi^.Goster;
    end
    else if(SonSecim = 4) then
    begin

      P4Etiket := P4Etiket^.Olustur(ktNesne, P2Pencere, SonKonumY,
        SonKonumD, 30, 16, RENK_SIYAH, 'TEtiket');
      P4Etiket^.Goster;
    end
    else if(SonSecim = 5) then
    begin

      P4GirisKutusu := P4GirisKutusu^.Olustur(ktNesne, P2Pencere,
        SonKonumY, SonKonumD, 120, 20, 'TGiri�Kutusu');
      P4GirisKutusu^.Goster;
    end
    else if(SonSecim = 6) then
    begin

      P4Defter := P4Defter^.Olustur(ktNesne, P2Pencere, SonKonumY,
        SonKonumD, 200, 200, $FCFCFC, RENK_SIYAH, False);
      P4Defter^.YaziEkle('TDefter');
      P4Defter^.Goster;
    end
    else if(SonSecim = 7) then
    begin

      P4OnayKutusu := P4OnayKutusu^.Olustur(ktNesne, P2Pencere,
        SonKonumY, SonKonumD, 'TOnayKutusu');
      P4OnayKutusu^.Goster;
    end
    else if(SonSecim = 8) then
    begin

      P4KaydirmaCubugu := P4KaydirmaCubugu^.Olustur(ktNesne, P2Pencere,
        SonKonumY, SonKonumD, 100, 24, yYatay);
      P4KaydirmaCubugu^.DegerleriBelirle(0, 100);
      P4KaydirmaCubugu^.MevcutDeger := 50;
      P4KaydirmaCubugu^.Goster;
    end
    else if(SonSecim = 9) then
    begin

      P4ListeKutusu := P4ListeKutusu^.Olustur(ktNesne, P2Pencere,
        SonKonumY, SonKonumD, 100, 60);
      P4ListeKutusu^.ListeyeEkle('TListeKutusu');
      P4ListeKutusu^.ListeyeEkle('Eleman1');
      P4ListeKutusu^.ListeyeEkle('Eleman2');
      P4ListeKutusu^.SeciliSiraNoYaz(0);
      P4ListeKutusu^.Goster;
    end
    else if(SonSecim = 10) then
    begin

      P4KarmaListe := P4KarmaListe^.Olustur(ktNesne, P2Pencere,
        SonKonumY, SonKonumD, 100, 24);
      P4KarmaListe^.ListeyeEkle('TKarmaListe1');
      P4KarmaListe^.ListeyeEkle('Eleman1');
      P4KarmaListe^.ListeyeEkle('Eleman2');
      P4KarmaListe^.BaslikSiraNoYaz(0);
      P4KarmaListe^.Goster;
    end;
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = P2ACDugmeler[0]) then
      SonSecim := 0
    else if(AOlay.Kimlik = P2ACDugmeler[1]) then
      SonSecim := 1
    else if(AOlay.Kimlik = P2ACDugmeler[2]) then
      SonSecim := 2
    else if(AOlay.Kimlik = P2ACDugmeler[3]) then
      SonSecim := 3
    else if(AOlay.Kimlik = P2ACDugmeler[4]) then
      SonSecim := 4
    else if(AOlay.Kimlik = P2ACDugmeler[5]) then
      SonSecim := 5
    else if(AOlay.Kimlik = P2ACDugmeler[6]) then
      SonSecim := 6
    else if(AOlay.Kimlik = P2ACDugmeler[7]) then
      SonSecim := 7
    else if(AOlay.Kimlik = P2ACDugmeler[8]) then
      SonSecim := 8
    else if(AOlay.Kimlik = P2ACDugmeler[9]) then
      SonSecim := 9
    else if(AOlay.Kimlik = P2ACDugmeler[10]) then
      SonSecim := 10;

    //SISTEM_MESAJ(RENK_SIYAH, 'Kimlik: %d', [AOlay.Kimlik]);
  end;
end;

var
  MutexDeger: TSayi4 = 0;
  MutexDurum: TSayi4 = 0;

procedure Prg1;
var
  i: TSayi4;
begin

  while True do
  begin

    while KritikBolgeyeGir(MutexDurum) = False do;

    i := MutexDeger;
    Inc(i);
    MutexDeger := i;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Prg1: %d', [MutexDeger]);

    KritikBolgedenCik(MutexDurum);

    BekleMS(100);
  end;
end;

procedure Prg2;
var
  i: TSayi4;
begin

  while True do
  begin

    while KritikBolgeyeGir(MutexDurum) = False do;

    i := MutexDeger;
    Inc(i);
    MutexDeger := i;

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Prg2: %d', [i]);

    KritikBolgedenCik(MutexDurum);

    BekleMS(1000);
  end;
end;

end.

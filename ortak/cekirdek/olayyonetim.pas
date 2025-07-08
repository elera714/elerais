{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: olayyonetim.pas
  Dosya ��levi: olay y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 21/05/2025

 ==============================================================================}
{$mode objfpc}
unit olayyonetim;

interface

uses gorselnesne, paylasim, gn_menu, gn_acilirmenu, sistemmesaj, gn_pencere;

type
  TOlayYonetim = class
  private
    FSonYatayFareDegeri, FSonDikeyFareDegeri: TISayi4;
    FSonBasilanFareTusu: TSayi1;
    FOdaklanilanGorselNesne: PGorselNesne;     // farenin, �zerinde bulundu�u nesne
  protected
    procedure OlaylariYonlendir(AGorselNesne: PGorselNesne; AOlay: TOlay);
  public
    constructor Create;
    function FareOlayiAl: TOlay;
    procedure FareOlaylariniIsle;
    procedure KlavyeOlaylariniIsle(ATusDegeri: TSayi2; ATusDurum: TTusDurum);
  end;

implementation

uses genel, gn_islevler, src_ps2, gorev;

{==============================================================================
  olay de�i�kenlerini ilk de�erlerle y�kler
 ==============================================================================}
constructor TOlayYonetim.Create;
begin

  FOdaklanilanGorselNesne := nil;
  YakalananGorselNesne := nil;

  FSonBasilanFareTusu := 0;
end;

{==============================================================================
  fare bilgilerini i�leyerek olaya �evirir
 ==============================================================================}
function TOlayYonetim.FareOlayiAl: TOlay;
var
  FareOlay: TFareOlay;
begin

  // fare s�r�c�s�nden fare olaylar�n� al
  if(GFareSurucusu.OlaylariAl(@FareOlay)) then
  begin

    // daha �nce fare tu�una bas�lmam��sa...
    if(FSonBasilanFareTusu = 0) then
    begin

      if((FareOlay.Dugme and 1) = 1) then
      begin

        FSonBasilanFareTusu := 1;
        Result.Olay := FO_SOLTUS_BASILDI;
      end
      else if((FareOlay.Dugme and 2) = 2) then
      begin

        FSonBasilanFareTusu := 2;
        Result.Olay := FO_SAGTUS_BASILDI;
      end
      else if((FareOlay.Dugme and 4) = 4) then
      begin

        FSonBasilanFareTusu := 4;
        Result.Olay := FO_ORTATUS_BASILDI;
      end
      else if((FareOlay.Dugme and 16) = 16) then
      begin

        FSonBasilanFareTusu := 16;
        Result.Olay := FO_4NCUTUS_BASILDI;
      end
      else if((FareOlay.Dugme and 32) = 32) then
      begin

        FSonBasilanFareTusu := 32;
        Result.Olay := FO_5NCITUS_BASILDI;
      end
      else if(FareOlay.Tekerlek <> 0) then
      begin

        Result.Olay := FO_KAYDIRMA;
        Result.Deger1 := FareOlay.Tekerlek;
      end
      else if(FareOlay.Yatay <> FSonYatayFareDegeri) or (FareOlay.Dikey <> FSonDikeyFareDegeri) then
      begin

        Result.Olay := FO_HAREKET;
      end
      else Result.Olay := FO_BILINMIYOR;
    end
    else
    // daha �nce fare tu�una bas�lm��sa...
    begin

      if(FSonBasilanFareTusu = 1) and ((FareOlay.Dugme and 1) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_SOLTUS_BIRAKILDI;
      end
      else if(FSonBasilanFareTusu = 2) and ((FareOlay.Dugme and 2) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_SAGTUS_BIRAKILDI;
      end
      else if(FSonBasilanFareTusu = 4) and ((FareOlay.Dugme and 4) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_ORTATUS_BIRAKILDI;
      end
      else if(FSonBasilanFareTusu = 16) and ((FareOlay.Dugme and 16) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_4NCUTUS_BIRAKILDI;
      end
      else if(FSonBasilanFareTusu = 32) and ((FareOlay.Dugme and 32) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_5NCITUS_BIRAKILDI;
      end
      else if(FareOlay.Yatay <> FSonYatayFareDegeri) or (FareOlay.Dikey <> FSonDikeyFareDegeri) then
      begin

        Result.Olay := FO_HAREKET;
      end
      else Result.Olay := FO_BILINMIYOR;
    end;

    // de�i�enleri bir sonraki durum i�in g�ncelle
    FSonYatayFareDegeri := FareOlay.Yatay;
    FSonDikeyFareDegeri := FareOlay.Dikey;

  end else Result.Olay := FO_BILINMIYOR;
end;

{==============================================================================
  t�m fare olaylar�n� i�ler, olaylar� ilgili nesnelere y�nlendirir
 ==============================================================================}
var
  SolTusOncekiOdaklanilanPencere: PPencere = nil;   // pencere nesnesi
  SolTusOncekiOdaklanilanGN: PGorselNesne = nil;    // pencere nesnesinin alt G�rsel Nesnesi

procedure TOlayYonetim.FareOlaylariniIsle;
var
  Pencere: PPencere;
  GN: PGorselNesne;
  Olay, Olay2: TOlay;
  Konum: TKonum;
begin

  // fare taraf�ndan olu�turulan olay� al
  Olay := FareOlayiAl;

  // bilinen bir fare olay� var ise ...
  if(Olay.Olay <> FO_BILINMIYOR) then
  begin

    // farkl� olaylar g�nderilecek olay de�i�keni
    Olay2.Kimlik := Olay.Kimlik;
    Olay2.Olay := Olay.Olay;

    Konum.Sol := GFareSurucusu.YatayKonum;
    Konum.Ust := GFareSurucusu.DikeyKonum;

    // fare yatay & dikey koordinat�nda bulunan nesneyi al
    // bilgi: yakalanan nesnenin �nceli�i vard�r
    if(YakalananGorselNesne <> nil) then
      GN := YakalananGorselNesne
    else GN := GorselNesneBul(Konum);

    // farenin bulundu�u noktada g�rsel nesne var ise ...
    if(GN <> nil) then
    begin

      // sol tu�a bas�lmas�yla, ayn� pencerede olan:
      // 1. bir �nceki odaklanan nesnenin oda��n� kaybetmesi
      // 2. sol tu� ile bas�lan nesnenin oda��n� kaybetmesi
      // i�levleri burada ger�ekle�mektedir
      // ---------------------------------------------------------------------->
      if(Olay2.Olay = FO_SOLTUS_BASILDI) then
      begin

        if(GN^.AtaNesne^.NesneTipi = gntPencere) then
          Pencere := PPencere(GN^.AtaNesne)
        else Pencere := nil;

        if(Pencere = SolTusOncekiOdaklanilanPencere) and (GN <> SolTusOncekiOdaklanilanGN) then
        begin

          if(GN^.Odaklanilabilir) then
          begin

            if(SolTusOncekiOdaklanilanGN <> nil) then SolTusOncekiOdaklanilanGN^.Odaklanildi := False;

            Pencere^.FAktifNesne := GN;
            GN^.Odaklanildi := True;
          end;
        end;

        if(GN^.Odaklanilabilir) then
        begin

          SolTusOncekiOdaklanilanPencere := Pencere;
          SolTusOncekiOdaklanilanGN := GN;
        end;
      end;
      // <----------------------------------------------------------------------

      // bulunan nesne bir �nceki nesne de�il ise
      if(FOdaklanilanGorselNesne <> GN) then
      begin

        // daha �nceden odaklanan nesne var ise
        if(FOdaklanilanGorselNesne <> nil) then
        begin

          //if(Olay2.Olay = FO_SOLTUS_BASILDI) and (FOdaklanilanGorselNesne^.AtaNesne^.NesneTipi = gntPencere) then
          begin

            // odaklan�lan nesneye oda�� kaybetti�ine dair mesaj g�nder
            Olay2.Olay := CO_ODAKKAYBEDILDI;
            OlaylariYonlendir(FOdaklanilanGorselNesne, Olay2);
          end;
        end;

        // odak kazanan nesneyi yeniden ata
        FOdaklanilanGorselNesne := GN;

        // nesneye odak kazand���na dair mesaj g�nder
        Olay2.Olay := CO_ODAKKAZANILDI;
        OlaylariYonlendir(FOdaklanilanGorselNesne, Olay2);
      end;

      // nesneye y�nlendirilecek parametreleri haz�rla
      Olay.Kimlik := GN^.FTGN.Kimlik;
      if(Olay.Olay <> FO_KAYDIRMA) then
        Olay.Deger1 := Konum.Sol;
      Olay.Deger2 := Konum.Ust;

{      SISTEM_MESAJ(RENK_SIYAH, 'Yatay: %d', [Olay.Deger1]);
      SISTEM_MESAJ(RENK_SIYAH, 'Dikey: %d', [Olay.Deger2]);
      SISTEM_MESAJ(RENK_SIYAH, 'G�rsel Nesne: %s', [GorselNesne^.NesneAdi]);
      SISTEM_MESAJ(RENK_SIYAH, 'Sol: %d', [GorselNesne^.FKonum.Sol]);
      SISTEM_MESAJ(RENK_SIYAH, '�st: %d', [GorselNesne^.FKonum.Ust]);
      SISTEM_MESAJ(RENK_SIYAH, 'Geni�lik: %d', [GorselNesne^.FBoyut.Genislik]);
      SISTEM_MESAJ(RENK_SIYAH, 'Y�kseklik: %d', [GorselNesne^.FBoyut.Yukseklik]);}

      // olay� nesneye y�nlendir
      OlaylariYonlendir(GN, Olay);
    end;
  end;
end;

{==============================================================================
  t�m klavye olaylar�n� i�ler, olaylar� ilgili nesnelere y�nlendirir
 ==============================================================================}
procedure TOlayYonetim.KlavyeOlaylariniIsle(ATusDegeri: TSayi2; ATusDurum: TTusDurum);
var
  Olay: TOlay;
begin

  // klavyeden bas�lan bir tu� olay� var ise ...
  if(ATusDegeri <> 0) then
  begin

    if(GAktifPencere <> nil) then
    begin

      // aktif nesne belirli mi?
      if(GAktifPencere^.FAktifNesne <> nil) then
      begin

        // aktif nesne giri� kutusu nesnesi mi?
        //if(GAktifNesne^.GorselNesneTipi = gntGirisKutusu) then
        begin

          // odaklan�lan nesneye mesaj� g�nder
          if(ATusDurum = tdBasildi) then
            Olay.Olay := CO_TUSBASILDI
          else Olay.Olay := CO_TUSBIRAKILDI;
          Olay.Deger1 := ATusDegeri;
          OlaylariYonlendir(GAktifPencere^.FAktifNesne, Olay);
        end;
      end;
    end;
  end;
end;

{==============================================================================
  olaylar� nesnelere y�nlendirir
 ==============================================================================}
procedure TOlayYonetim.OlaylariYonlendir(AGorselNesne: PGorselNesne; AOlay: TOlay);
var
  Gorev: PGorev;
begin

  Gorev := GorevAl(AGorselNesne^.GorevKimlik);

  // g�rev �al��m�yorsa nesneye olay g�nderme
  if(Gorev^.FGorevDurum <> gdCalisiyor) then Exit;

  // aktif nesneyi belirle
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // nesne pencereye ait bir g�rsel nesne ise
    if(AGorselNesne^.AtaNesne <> nil) and (AGorselNesne^.AtaNesne^.NesneTipi = gntPencere) then
      PPencere(AGorselNesne^.AtaNesne)^.FAktifNesne := AGorselNesne;

    AGorselNesne^.Odaklanildi := True;
  end;

  if not(AGorselNesne^.OlayCagriAdresi = nil) then
    AGorselNesne^.OlayCagriAdresi(AGorselNesne, AOlay);

  // tu� bas�m� esnas�nda a��k bir men� var ise kapat�lacak
  if(AOlay.Olay = FO_SOLTUS_BASILDI) or (AOlay.Olay = FO_SAGTUS_BASILDI) then
  begin

    if not(GAktifMenu = nil) then
    begin

      if(GAktifMenu^.NesneTipi = gntMenu) then PMenu(GAktifMenu)^.Gizle
      else if(GAktifMenu^.NesneTipi = gntAcilirMenu) then PAcilirMenu(GAktifMenu)^.Gizle
    end;
  end;
end;

end.

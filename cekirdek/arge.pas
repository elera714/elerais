{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: arge.pas
  Dosya Ýþlevi: sistem ar-ge çalýþmalarýný içerir

  Güncelleme Tarihi: 21/05/2025

 ==============================================================================}
{$mode objfpc}
unit arge;

interface

uses paylasim, gn_masaustu, gn_pencere, gn_araccubugu, gn_durumcubugu, gn_gucdugmesi,
  gn_panel, gn_etiket, gn_defter, gn_dugme, gn_giriskutusu, gn_onaykutusu, gn_kaydirmacubugu,
  gn_listekutusu, gn_karmaliste, gorselnesne;

type
  TArgeIslev = procedure of object;

type
  TSinif = class
  public
    F1, F2, F3: TSayi4;
    constructor Create;
  end;

type
  TNesne = object
  public
    F1, F2, F3: TSayi4;
    procedure Olustur;
  end;

var
  GSinif: TSinif;
  GNesne: TNesne;

type
  TArGe = class
  private
    Masaustu: TMasaustu;
    Pencere: TPencere;
    AracCubugu: TAracCubugu;
    DurumCubugu: TDurumCubugu;
    Panel: TPanel;
    GucDugmesi: TGucDugmesi;
    Etiket: TEtiket;
    OnayKutusu: TOnayKutusu;
    KarmaListe: TKarmaListe;
    ListeKutusu: TListeKutusu;
    KaydirmaCubugu: TKaydirmaCubugu;
    Dugme: TDugme;
    Defter: TDefter;
    GirisKutusu: TGirisKutusu;
    ACKimlikler: array[0..10] of TKimlik;
    SonKonumY, SonKonumD: TSayi4;
    SonSecim: TISayi4;
    SeciliNesneAdi: string;
    function SeciliNesneyiAl(ASecimNo: TISayi4): string;
  public
    GorevNo: TISayi4;
    FCalisacakIslev: TArgeIslev;
    constructor Create(AProgramSN: TSayi4);
    procedure Calistir;
    procedure Program1Basla;
    procedure Program2Basla;
    procedure P1NesneTestOlayIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure P2NesneTestOlayIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  end;

procedure Program1;
procedure Program2;
procedure CekirdekDosyaTSDegeriniKaydet;
procedure KaydedilenProgramlariYenidenYukle;
procedure AssertIslev(const msg,fname:ShortString;lineno:longint;erroraddr:pointer);

implementation

uses donusum, zamanlayici, sistemmesaj, dosyalar, gorev, gn_islevler;

procedure TNesne.Olustur;
begin

  F1 := $55555555;
  F2 := $66666666;
  F3 := $56565656;
end;

constructor TSinif.Create;
begin

  F1 := $11111111;
  F2 := $22222222;
  F3 := $12121212;
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
begin

  Masaustu := TMasaustu.Create;
  Masaustu.Ozellestir('giriþ');
  Masaustu.MasaustuRenginiDegistir($9FB6BF);
  Masaustu.Aktiflestir;

  Pencere := TPencere.Create;
  Pencere.Ozellestir(Masaustu, 100, 100, 500, 400, ptBoyutlanabilir, 'Görsel Nesne Yönetim',
    RENK_BEYAZ);
  Pencere.OlayYonlAdr := @P1NesneTestOlayIsle;

  GucDugmesi := TGucDugmesi.Create;
  GucDugmesi.Ozellestir(ktNesne, Pencere, 10, 10, 100, 100, 'Artýr');
  GucDugmesi.OlayYonlAdr := @P1NesneTestOlayIsle;
  GucDugmesi.Goster;

  GucDugmesi := TGucDugmesi.Create;
  GucDugmesi.Ozellestir(ktNesne, Pencere, 120, 10, 100, 100, 'Eksilt');
  GucDugmesi.OlayYonlAdr := @P1NesneTestOlayIsle;
  GucDugmesi.Goster;

  Pencere.Goster;

  Masaustu.Gorunum := True;
end;

procedure TArGe.P1NesneTestOlayIsle(AGonderici: TGorselNesne; AOlay: TOlay);
begin

end;

procedure TArGe.Program2Basla;
begin

  SonSecim := -1;

  SeciliNesneAdi := SeciliNesneyiAl(SonSecim);

  Pencere := TPencere.Create;
  Pencere.Ozellestir(nil, 0, 0, 450, 300, ptBoyutlanabilir, 'Nesneler', RENK_BEYAZ);
  Pencere.OlayYonlAdr := @P2NesneTestOlayIsle;

  AracCubugu := TAracCubugu.Create;
  AracCubugu.Ozellestir(ktNesne, Pencere);
  ACKimlikler[0] := AracCubugu.DugmeEkle2(0);
  ACKimlikler[1] := AracCubugu.DugmeEkle2(11);
  ACKimlikler[2] := AracCubugu.DugmeEkle2(2);
  ACKimlikler[3] := AracCubugu.DugmeEkle2(6);
  ACKimlikler[4] := AracCubugu.DugmeEkle2(3);
  ACKimlikler[5] := AracCubugu.DugmeEkle2(4);
  ACKimlikler[6] := AracCubugu.DugmeEkle2(5);
  ACKimlikler[7] := AracCubugu.DugmeEkle2(7);
  ACKimlikler[8] := AracCubugu.DugmeEkle2(10);
  ACKimlikler[9] := AracCubugu.DugmeEkle2(8);
  ACKimlikler[10] := AracCubugu.DugmeEkle2(9);
  AracCubugu.OlayYonlAdr := @P2NesneTestOlayIsle;
  AracCubugu.Goster;

  Etiket := TEtiket.Create;
  Etiket.Ozellestir(ktNesne, Pencere, 0, 40, 100 * 8, 16, RENK_KIRMIZI,
    'Farenin sol tuþuyla nesne seçip, tasarým alanýnda farenin sað tuþuyla nesneyi oluþturabilirsiniz');
  Etiket.Goster;

  DurumCubugu := TDurumCubugu.Create;
  DurumCubugu.Ozellestir(ktNesne, Pencere, 0, 0, 10, 10, 'Konum: 0:0');
  DurumCubugu.OlayYonlAdr := @P2NesneTestOlayIsle;
  DurumCubugu.Goster;

  Pencere.Goster;
end;

procedure TArGe.P2NesneTestOlayIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Sol, Ust, G, Y, i: TISayi4;
  Alan: TAlan;
begin

  if(AOlay.Olay = CO_CIZIM) then
  begin

    G := AGonderici.FAtananAlan.Genislik;
    Y := AGonderici.FAtananAlan.Yukseklik - 28;

    // yatay çizgiler
    Ust := 5 + 28;
    repeat

      Alan := Pencere.FKalinlik;

      for i := 0 to G div 10 do
        Pencere.PixelYaz(Pencere, Alan.Sol + (i * 10) + 3, Alan.Ust + Ust, RENK_GRI);

      Inc(Ust, 10);
    until Ust > Y;
  end
  else if(AOlay.Olay = FO_HAREKET) and (AOlay.Kimlik = Pencere.Kimlik) then
  begin

    SonKonumY := AOlay.Deger1 - Pencere.FKalinlik.Sol;
    SonKonumD := AOlay.Deger2 - Pencere.FKalinlik.Ust;

    DurumCubugu.Baslik := 'Konum: ' + IntToStr(AOlay.Deger1) +
      ':' + IntToStr(AOlay.Deger2) + ' - Seçili Nesne: ' + SeciliNesneAdi;

    DurumCubugu.Ciz;
  end
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) and (AOlay.Kimlik = Pencere.Kimlik) then
  begin

    if(SonSecim = 1) then
    begin

      Panel := TPanel.Create;
      Panel.Yapilandir2(ktNesne, Panel, Pencere, SonKonumY, SonKonumD, 70, 70, 3,
        RENK_KIRMIZI, RENK_BEYAZ, RENK_SIYAH, Panel.NesneAdi);
      Panel.Goster;
    end
    else if(SonSecim = 2) then
    begin

      Dugme := TDugme.Create;
      Dugme.Ozellestir(ktNesne, Pencere, SonKonumY, SonKonumD, 120, 22, Dugme.NesneAdi);
      Dugme.Goster;
    end
    else if(SonSecim = 3) then
    begin

      GucDugmesi := TGucDugmesi.Create;
      GucDugmesi.Ozellestir(ktNesne, Pencere, SonKonumY, SonKonumD, 120, 22, GucDugmesi.NesneAdi);
      GucDugmesi.Goster;
    end
    else if(SonSecim = 4) then
    begin

      Etiket := TEtiket.Create;
      Etiket.Ozellestir(ktNesne, Pencere, SonKonumY, SonKonumD, 70, 16, RENK_SIYAH, Etiket.NesneAdi);
      Etiket.Goster;
    end
    else if(SonSecim = 5) then
    begin

      GirisKutusu := TGirisKutusu.Create;
      GirisKutusu.Ozellestir(ktNesne, Pencere, SonKonumY, SonKonumD, 180, 20, GirisKutusu.NesneAdi);
      GirisKutusu.Goster;
    end
    else if(SonSecim = 6) then
    begin

      Defter := TDefter.Create;
      Defter.Ozellestir(ktNesne, Pencere, SonKonumY, SonKonumD, 220, 180, $FCFCFC, RENK_SIYAH, False);
      Defter.YaziEkle(Defter.NesneAdi);
      Defter.Goster;
    end
    else if(SonSecim = 7) then
    begin

      OnayKutusu := TOnayKutusu.Create;
      OnayKutusu.Ozellestir(ktNesne, Pencere, SonKonumY, SonKonumD, OnayKutusu.NesneAdi);
      OnayKutusu.Goster;
    end
    else if(SonSecim = 8) then
    begin

      KaydirmaCubugu := TKaydirmaCubugu.Create;
      KaydirmaCubugu.Ozellestir(ktNesne, Pencere, SonKonumY, SonKonumD, 200, 24, yYatay);
      KaydirmaCubugu.DegerleriBelirle(0, 100);
      KaydirmaCubugu.MevcutDeger := 50;
      KaydirmaCubugu.Goster;
    end
    else if(SonSecim = 9) then
    begin

      ListeKutusu := TListeKutusu.Create;
      ListeKutusu.Ozellestir(ktNesne, Pencere, SonKonumY, SonKonumD, 140, 100);
      ListeKutusu.ListeyeEkle(ListeKutusu.NesneAdi);
      ListeKutusu.ListeyeEkle('Eleman1');
      ListeKutusu.ListeyeEkle('Eleman2');
      ListeKutusu.ListeyeEkle('Eleman3');
      ListeKutusu.SeciliSiraNoYaz(0);
      ListeKutusu.Goster;
    end
    else if(SonSecim = 10) then
    begin

      KarmaListe := TKarmaListe.Create;
      KarmaListe.Ozellestir(ktNesne, Pencere, SonKonumY, SonKonumD, 140, 24);
      KarmaListe.ListeyeEkle(KarmaListe.NesneAdi);
      KarmaListe.ListeyeEkle('Eleman1');
      KarmaListe.ListeyeEkle('Eleman2');
      KarmaListe.BaslikSiraNoYaz(0);
      KarmaListe.Goster;
    end;
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    SonSecim := -1;

    if(AOlay.Kimlik = ACKimlikler[0]) then
      SonSecim := 0
    else if(AOlay.Kimlik = ACKimlikler[1]) then
      SonSecim := 1
    else if(AOlay.Kimlik = ACKimlikler[2]) then
      SonSecim := 2
    else if(AOlay.Kimlik = ACKimlikler[3]) then
      SonSecim := 3
    else if(AOlay.Kimlik = ACKimlikler[4]) then
      SonSecim := 4
    else if(AOlay.Kimlik = ACKimlikler[5]) then
      SonSecim := 5
    else if(AOlay.Kimlik = ACKimlikler[6]) then
      SonSecim := 6
    else if(AOlay.Kimlik = ACKimlikler[7]) then
      SonSecim := 7
    else if(AOlay.Kimlik = ACKimlikler[8]) then
      SonSecim := 8
    else if(AOlay.Kimlik = ACKimlikler[9]) then
      SonSecim := 9
    else if(AOlay.Kimlik = ACKimlikler[10]) then
      SonSecim := 10;

    SeciliNesneAdi := SeciliNesneyiAl(SonSecim);

    DurumCubugu.Baslik := 'Konum: ' + IntToStr(AOlay.Deger1) +
      ':' + IntToStr(AOlay.Deger2) + ' - Seçili Nesne: ' + SeciliNesneAdi;

    DurumCubugu.Ciz;
  end;
end;

function TArge.SeciliNesneyiAl(ASecimNo: TISayi4): string;
begin

  case ASecimNo of
    00: Result := '-';
    01: Result := 'TPanel';
    02: Result := 'TDüðme';
    03: Result := 'TGucDugmesi';
    04: Result := 'TEtiket';
    05: Result := 'TGiriþKutusu';
    06: Result := 'TDefter';
    07: Result := 'TOnayKutusu';
    08: Result := 'TKaydýrmaÇubuðu';
    09: Result := 'TListeKutusu';
    10: Result := 'TKarmaListe';
    else Result := '-';
  end;
end;

var
  MutexDeger: TSayi4 = 0;
  MutexDurum: TSayi4 = 0;

procedure Program1;
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

    GZamanlayicilar.BekleMS(CALISMA_FREKANSI);
  end;
end;

procedure Program2;
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

    GZamanlayicilar.BekleMS(10 * CALISMA_FREKANSI);
  end;
end;

// sistemin yüklenme esnasýnda çekirdeðin tarih + saat deðerini kaydeder
procedure CekirdekDosyaTSDegeriniKaydet;
var
  i: TISayi4;
  AramaKaydi: TDosyaArama;
  j: TSayi2;
begin

  i := FindFirst('disket1:\*.*', 0, AramaKaydi);
  while i = 0 do
  begin

    if(AramaKaydi.DosyaAdi = 'cekirdek.bin') then
    begin

      j := AramaKaydi.SonDegisimTarihi;
      CekirdekYuklemeTS.Gun := j and 31;
      CekirdekYuklemeTS.Ay := (j shr 5) and 15;
      CekirdekYuklemeTS.Yil := ((j shr 9) and 127) + 1980;

      j := AramaKaydi.SonDegisimSaati;
      CekirdekYuklemeTS.Saniye := (j and 31) * 2;
      CekirdekYuklemeTS.Dakika := (j shr 5) and 63;
      CekirdekYuklemeTS.Saat := (j shr 11) and 31;

      Break;
    end;

    i := FindNext(AramaKaydi);
  end;

  FindClose(AramaKaydi);
end;

procedure KaydedilenProgramlariYenidenYukle;
var
  GN: TGorselNesne;
  s, DosyaAdi, s2: string;
  MUGorev: PGorev;
  Konum: TKonum;
  Boyut: TBoyut;
  DosyaKimlik: TKimlik;
  U: TISayi8;
  Bellek0: Isaretci;
  SiraNo, Kod,
  i, j, k: TSayi4;
begin

  AssignFile(DosyaKimlik, 'disk2:\yuklenecek_programlar.ini');
  Reset(DosyaKimlik);
  if(IOResult = HATA_YOK) then
  begin

    U := FileSize(DosyaKimlik);
    Bellek0 := GetMem(U);

    Read(DosyaKimlik, Bellek0);

    j := 0;
    i := 0;
    repeat

      i := Pos(#10, PChar(Bellek0));
      if(i > 0) then
      begin

        Dec(i);
        s := Copy(PChar(Bellek0 + j), 0, (i - j) - 1);
        PChar(Bellek0 + i)^ := ' ';
        j := i + 1;

        if(Length(s) > 0) then
        begin

          DosyaAdi := '';
          Konum.Sol := 0;
          Konum.Ust := 0;
          Boyut.Genislik := 0;
          Boyut.Yukseklik := 0;
          SiraNo := 1;

          repeat

            k := Pos(';', s);
            if(k > 0) then
            begin

              case SiraNo of
                1: DosyaAdi := Copy(s, 1, k - 1);
                2: begin s2:= Copy(s, 1, k - 1); Val(s2, Konum.Sol, Kod) end;
                3: begin s2:= Copy(s, 1, k - 1); Val(s2, Konum.Ust, Kod) end;
                4: begin s2:= Copy(s, 1, k - 1); Val(s2, Boyut.Genislik, Kod) end;
              end;

              Delete(s, 1, k);
              Inc(SiraNo);
            end
            else
            begin

              s2:= s;
              Val(s2, Boyut.Yukseklik, Kod);
              k := 0;
            end;

          until k = 0;

          {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Dosya Adý: "%s"', [DosyaAdi]);
          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Sol: "%d, Üst: %d"', [Sol, Ust]);
          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Geniþlik: "%d, Yükseklik: %d"', [Genislik, Yukseklik]);}

          MUGorev := GGorevler.Calistir(AcilisSurucuAygiti + ':\progrmlr\' + DosyaAdi, CALISMA_SEVIYE3);

          GZamanlayicilar.BekleMS(CALISMA_FREKANSI);

          GN := GGNesneler.NesneAl(TPencere(MUGorev^.AktifPencere).Kimlik);

          TPencere(GN).FAtananAlan.Sol := Konum.Sol;
          TPencere(GN).FAtananAlan.Ust := Konum.Ust;
          TPencere(GN).FAtananAlan.Genislik := Boyut.Genislik;
          TPencere(GN).FAtananAlan.Yukseklik := Boyut.Yukseklik;
          TPencere(GN).Guncelle;

          TMasaustu(GN.AtaNesne).Ciz;
        end;
      end;
    until i = 0;

    FreeMem(Bellek0, U);
  end;

  CloseFile(DosyaKimlik);
end;

procedure AssertIslev(const msg,fname:ShortString;lineno:longint;erroraddr:pointer);
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Assert: %s', [msg]);
end;

end.

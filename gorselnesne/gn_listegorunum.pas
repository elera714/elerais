{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_listegorunum.pas
  Dosya ��levi: liste g�r�n�m (TListView) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 28/12/2024

 ==============================================================================}
{$mode objfpc}
unit gn_listegorunum;

interface

uses gorselnesne, paylasim, n_yazilistesi, n_sayilistesi, gn_panel, sistemmesaj;

type
  PListeGorunum = ^TListeGorunum;
  TListeGorunum = object(TPanel)
  private
    FSeciliSiraNo: TISayi4;               // se�ili s�ra de�eri
    FGorunenIlkSiraNo: TISayi4;           // liste g�r�n�mde en �stte g�r�nt�lenen eleman�n s�ra de�eri
    FGorunenElemanSayisi: TISayi4;        // kullan�c�ya nesne i�erisinde g�sterilen eleman say�s�
    FKolonAdlari: PYaziListesi;           // kolon ad listesi
    FKolonUzunluklari: PSayiListesi;      // kolon uzunluklar�
    FDegerler,                            // kolon i�erik de�erleri
    FDegerDizisi: PYaziListesi;           // FDegerler i�eri�ini b�l�mlemek i�in kullan�lacak
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PListeGorunum;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    function SeciliSatirDegeriniAl: string;
    procedure Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
      DegerDizisi: PYaziListesi);
  end;

function ListeGorunumCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses genel, gn_islevler, gn_pencere, temelgorselnesne;

{==============================================================================
  liste g�r�n�m kesme �a�r�lar�n� y�netir
 ==============================================================================}
function ListeGorunumCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne;
  Pencere: PPencere;
  ListeGorunum: PListeGorunum;
  Hiza: THiza;
  p: PKarakterKatari;
begin

  case AIslevNo of

    // nesne olu�tur
    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    // liste g�r�n�m nesnesini hizala
    ISLEV_HIZALA:
    begin

      ListeGorunum := PListeGorunum(ListeGorunum^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      ListeGorunum^.FHiza := Hiza;

      Pencere := PPencere(ListeGorunum^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // eleman ekle
    $010F:
    begin

      ListeGorunum := PListeGorunum(ListeGorunum^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then ListeGorunum^.FDegerler^.Ekle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi)^);
      Result := 1;
    end;

    // se�ilen s�ra de�erini al
    $020E:
    begin

      ListeGorunum := PListeGorunum(ListeGorunum^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then Result := ListeGorunum^.FSeciliSiraNo;
    end;

    // liste i�eri�ini temizle
    $030F:
    begin

      ListeGorunum := PListeGorunum(ListeGorunum^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        // i�eri�i temizle, de�erleri �n de�erlere �ek
        ListeGorunum^.FDegerler^.Temizle;
        ListeGorunum^.FGorunenIlkSiraNo := 0;
        ListeGorunum^.FSeciliSiraNo := -1;
        ListeGorunum^.Ciz;
      end;
    end;

    // se�ilen yaz� (text) de�erini geri d�nd�r
    $040E:
    begin

      ListeGorunum := PListeGorunum(ListeGorunum^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then Result := ListeGorunum^.FSeciliSiraNo;
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
      p^ := ListeGorunum^.SeciliSatirDegeriniAl;
    end;

    // liste g�r�nt�leyicisinin ba�l�klar�n� sil
    $050F:
    begin

      ListeGorunum := PListeGorunum(ListeGorunum^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        ListeGorunum^.FKolonUzunluklari^.Temizle;
        ListeGorunum^.FKolonAdlari^.Temizle;
        Result := 1;
      end;
    end;

    // liste g�r�nt�leyicisine kolon ekle
    $060F:
    begin

      ListeGorunum := PListeGorunum(ListeGorunum^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        ListeGorunum^.FKolonAdlari^.Ekle(
          PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi)^);
        ListeGorunum^.FKolonUzunluklari^.Ekle(PISayi4(ADegiskenler + 08)^);
        Result := 1;
      end;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  liste g�r�n�m nesnesini olu�turur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  ListeGorunum: PListeGorunum;
begin

  ListeGorunum := ListeGorunum^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);
  if(ListeGorunum = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := ListeGorunum^.Kimlik;
end;

{==============================================================================
  liste g�r�n�m nesnesini olu�turur
 ==============================================================================}
function TListeGorunum.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PListeGorunum;
var
  ListeGorunum: PListeGorunum;
  KolonAdlari, Degerler, DegerDizisi: PYaziListesi;
  KolonUzunluklari: PSayiListesi;
begin

  ListeGorunum := PListeGorunum(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 3, $828790, RENK_BEYAZ, 0, ''));

  ListeGorunum^.NesneTipi := gntListeGorunum;

  ListeGorunum^.Baslik := '';

  ListeGorunum^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  ListeGorunum^.OlayCagriAdresi := @OlaylariIsle;

  ListeGorunum^.FKolonAdlari := nil;
  KolonAdlari := KolonAdlari^.Olustur;
  if(KolonAdlari <> nil) then ListeGorunum^.FKolonAdlari := KolonAdlari;

  ListeGorunum^.FKolonUzunluklari := nil;
  KolonUzunluklari := KolonUzunluklari^.Olustur;
  if(KolonUzunluklari <> nil) then ListeGorunum^.FKolonUzunluklari := KolonUzunluklari;

  ListeGorunum^.FDegerler := nil;
  Degerler := Degerler^.Olustur;
  if(Degerler <> nil) then ListeGorunum^.FDegerler := Degerler;

  ListeGorunum^.FDegerDizisi := nil;
  DegerDizisi := DegerDizisi^.Olustur;
  if(DegerDizisi <> nil) then ListeGorunum^.FDegerDizisi := DegerDizisi;

  // nesnenin kullanaca�� di�er de�erler
  ListeGorunum^.FGorunenIlkSiraNo := 0;
  ListeGorunum^.FSeciliSiraNo := -1;

  // liste g�r�n�m nesnesinde g�r�nt�lenecek eleman say�s�
  ListeGorunum^.FGorunenElemanSayisi := (AYukseklik - 24) div 21;

  // nesneyi g�r�nt�le
  ListeGorunum^.Goster;

  // nesne adresini geri d�nd�r
  Result := ListeGorunum;
end;

{==============================================================================
  liste g�r�n�m nesnesini yok eder
 ==============================================================================}
procedure TListeGorunum.YokEt;
var
  ListeGorunum: PListeGorunum;
begin

  ListeGorunum := PListeGorunum(ListeGorunum^.NesneAl(Kimlik));
  if(ListeGorunum = nil) then Exit;

  if(ListeGorunum^.FDegerler <> nil) then ListeGorunum^.FDegerler^.YokEt;
  if(ListeGorunum^.FDegerDizisi <> nil) then ListeGorunum^.FDegerDizisi^.YokEt;
  if(ListeGorunum^.FKolonAdlari <> nil) then ListeGorunum^.FKolonAdlari^.YokEt;
  if(ListeGorunum^.FKolonUzunluklari <> nil) then ListeGorunum^.FKolonUzunluklari^.YokEt;

  inherited YokEt;
end;

{==============================================================================
  liste g�r�n�m nesnesini g�r�nt�ler
 ==============================================================================}
procedure TListeGorunum.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  liste g�r�n�m nesnesini gizler
 ==============================================================================}
procedure TListeGorunum.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  liste g�r�n�m nesnesini boyutland�r�r
 ==============================================================================}
procedure TListeGorunum.Boyutlandir;
var
  ListeGorunum: PListeGorunum;
begin

  ListeGorunum := PListeGorunum(ListeGorunum^.NesneAl(Kimlik));
  if(ListeGorunum = nil) then Exit;

  ListeGorunum^.Hizala;
end;

{==============================================================================
  liste g�r�n�m nesnesini �izer
 ==============================================================================}
procedure TListeGorunum.Ciz;
var
  Pencere: PPencere;
  ListeGorunum: PListeGorunum;
  KolonAdlari: PYaziListesi;
  KolonUzunluklari: PSayiListesi;
  Alan1, Alan2: TAlan;
  ElemanSayisi, SatirNo, i, j,
  Sol, Ust: TISayi4;
  s: string;
begin

  ListeGorunum := PListeGorunum(ListeGorunum^.NesneAl(Kimlik));
  if(ListeGorunum = nil) then Exit;

  inherited Ciz;

  // liste kutusunun �st nesneye ba�l� olarak koordinatlar�n� al
  Alan1 := ListeGorunum^.FCizimAlan;

  // ata nesne bir pencere mi?
  Pencere := EnUstPencereNesnesiniAl(ListeGorunum);
  if(Pencere = nil) then Exit;

  KolonUzunluklari := ListeGorunum^.FKolonUzunluklari;
  KolonAdlari := ListeGorunum^.FKolonAdlari;

  // tan�mlanm�� hi�bir kolon yok ise, ��k
  if(KolonAdlari^.ElemanSayisi = 0) then Exit;

  // kolon ba�l�k ve de�erleri
  Sol := Alan1.Sol + 1;
  for i := 0 to KolonUzunluklari^.ElemanSayisi - 1 do
  begin

    Sol += KolonUzunluklari^.Eleman[i];

    // dikey k�lavuz �izgisi
    ListeGorunum^.Cizgi(ListeGorunum, ctDuz, Sol, Alan1.Ust + 1, Sol, Alan1.Alt - 1, $F0F0F0);

    // ba�l�k dolgusu
    Alan2.Sol := Sol - KolonUzunluklari^.Eleman[i];
    Alan2.Ust := Alan1.Ust + 1;
    Alan2.Sag := Sol - 1;
    Alan2.Alt := Alan1.Ust + 1 + 22;
    ListeGorunum^.EgimliDoldur3(ListeGorunum, Alan2, $EAECEE, $ABB2B9);

    // ba�l�k
    ListeGorunum^.AlanaYaziYaz(ListeGorunum, Alan2, 4, 3, KolonAdlari^.Eleman[i], RENK_LACIVERT);

    Inc(Sol);    // 1 px �izgi kal�nl���
  end;

  // yatay k�lavuz �izgileri
  Ust := Alan1.Ust + 1 + 22;
  Ust += 20;
  while Ust < Alan1.Alt do
  begin

    ListeGorunum^.Cizgi(ListeGorunum, ctDuz, Alan1.Sol + 1, Ust, Alan1.Sag - 1, Ust, $F0F0F0);
    Ust += 1 + 20;
  end;

  // liste g�r�n�m nesnesinde g�r�nt�lenecek eleman say�s�
  ListeGorunum^.FGorunenElemanSayisi := ((ListeGorunum^.FCizimAlan.Alt -
    ListeGorunum^.FCizimAlan.Ust) - 24) div 21;

  // liste g�r�n�m kutusunda g�r�nt�lenecek eleman say�s�n�n belirlenmesi
  if(FDegerler^.ElemanSayisi > ListeGorunum^.FGorunenElemanSayisi) then
    ElemanSayisi := ListeGorunum^.FGorunenElemanSayisi + ListeGorunum^.FGorunenIlkSiraNo
  else ElemanSayisi := FDegerler^.ElemanSayisi + ListeGorunum^.FGorunenIlkSiraNo;

  Ust := Alan1.Ust + 1 + 22;
  Ust += 20;
  SatirNo := 0;
  KolonUzunluklari := ListeGorunum^.FKolonUzunluklari;

  // liste g�r�n�m de�erlerini yerle�tir
  for SatirNo := ListeGorunum^.FGorunenIlkSiraNo to ElemanSayisi - 1 do
  begin

    // de�eri belirtilen karakter ile b�l�mle
    Bolumle(FDegerler^.Eleman[SatirNo], '|', FDegerDizisi);

    Sol := Alan1.Sol + 1;
    if(FDegerDizisi^.ElemanSayisi > 0) then
    begin

      for j := 0 to FDegerDizisi^.ElemanSayisi - 1 do
      begin

        s := FDegerDizisi^.Eleman[j];
        Alan2.Sol := Sol + 1;
        Alan2.Ust := Ust - 20 + 1;
        Alan2.Sag := Sol + KolonUzunluklari^.Eleman[j] - 1;
        Alan2.Alt := Ust - 1;

        // sat�r verisini boyama ve yazma i�lemi
        if(SatirNo = ListeGorunum^.FSeciliSiraNo) then
        begin

          ListeGorunum^.DikdortgenDoldur(ListeGorunum, Alan2.Sol - 1, Alan2.Ust - 1,
            Alan2.Sag, Alan2.Alt, $3EC5FF, $3EC5FF);
        end
        else
        begin

          ListeGorunum^.DikdortgenDoldur(ListeGorunum, Alan2.Sol - 1, Alan2.Ust - 1,
            Alan2.Sag, Alan2.Alt, RENK_BEYAZ, RENK_BEYAZ);
        end;

        ListeGorunum^.AlanaYaziYaz(ListeGorunum, Alan2, 2, 2, s, RENK_SIYAH);

        Sol += 1 + KolonUzunluklari^.Eleman[j];
      end;
    end;

    Ust += 1 + 20;
  end;
end;

{==============================================================================
  liste g�r�n�m nesne olaylar�n� i�ler
 ==============================================================================}
procedure TListeGorunum.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  ListeGorunum: PListeGorunum;
  i, j: TISayi4;
begin

  ListeGorunum := PListeGorunum(AGonderici);

  // sol fare tu� bas�m�
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // liste g�r�n�m�n sahibi olan pencere en �stte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(ListeGorunum);

    // en �stte olmamas� durumunda en �ste getir
    if not(Pencere = nil) and (Pencere <> AktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // sol tu�a bas�m i�lemi nesnenin olay alan�nda m� ger�ekle�ti ?
    if(ListeGorunum^.FareNesneOlayAlanindaMi(ListeGorunum)) then
    begin

      // fare olaylar�n� yakala
      OlayYakalamayaBasla(ListeGorunum);

      // se�ilen s�ray� yeniden belirle
      j := (AOlay.Deger2 - 24) div 21;

      // bu de�ere kayd�r�lan de�eri de ekle
      ListeGorunum^.FSeciliSiraNo := (j + ListeGorunum^.FGorunenIlkSiraNo);

      // liste g�r�n�m nesnesini yeniden �iz
      ListeGorunum^.Ciz;

      // uygulamaya veya efendi nesneye mesaj g�nder
      if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
        ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
      else GorevListesi[ListeGorunum^.GorevKimlik]^.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
    end;
  end

  // sol fare tu� b�rak�m i�lemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylar�n� almay� b�rak
    OlayYakalamayiBirak(ListeGorunum);

    // fare b�rakma i�lemi nesnenin olay alan�nda m� ger�ekle�ti ?
    if(ListeGorunum^.FareNesneOlayAlanindaMi(ListeGorunum)) then
    begin

      // yakalama & b�rakma i�lemi bu nesnede oldu�u i�in
      // nesneye FO_TIKLAMA mesaj� g�nder
      AOlay.Olay := FO_TIKLAMA;
      if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
        ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
      else GorevListesi[ListeGorunum^.GorevKimlik]^.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj g�nder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
      ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
    else GorevListesi[ListeGorunum^.GorevKimlik]^.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
  end

  // fare hakeret i�lemi
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // e�er nesne yakalanm�� ise
    if(YakalananGorselNesne <> nil) then
    begin

      // fare liste g�r�n�m nesnesinin yukar�s�nda ise
      if(AOlay.Deger2 < 0) then
      begin

        j := ListeGorunum^.FGorunenIlkSiraNo;
        Dec(j);
        if(j >= 0) then
        begin

          ListeGorunum^.FGorunenIlkSiraNo := j;
          ListeGorunum^.FSeciliSiraNo := j;
        end;
      end

      // fare liste g�r�n�m nesnesinin a�a��s�nda ise
      else if(AOlay.Deger2 > ListeGorunum^.FBoyut.Yukseklik) then
      begin

        // azami kayd�rma de�eri
        i := ListeGorunum^.FKolonAdlari^.ElemanSayisi - ListeGorunum^.FGorunenElemanSayisi;
        if(i < 0) then i := 0;

        j := ListeGorunum^.FGorunenIlkSiraNo;
        Inc(j);
        if(j < i) then
        begin

          ListeGorunum^.FGorunenIlkSiraNo := j;
          i := (AOlay.Deger2 - 24) div 21;
          ListeGorunum^.FSeciliSiraNo := i + ListeGorunum^.FGorunenIlkSiraNo;
        end
      end

      // fare liste g�r�n�m kutusunun i�erisinde ise
      else
      begin

        i := (AOlay.Deger2 - 24) div 21;
        ListeGorunum^.FSeciliSiraNo := i + ListeGorunum^.FGorunenIlkSiraNo;
      end;

      // liste g�r�n�m nesnesini yeniden �iz
      ListeGorunum^.Ciz;

      // uygulamaya veya efendi nesneye mesaj g�nder
      if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
        ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
      else GorevListesi[ListeGorunum^.GorevKimlik]^.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
    end

    // nesne yakalanmam�� ise uygulamaya sadece mesaj g�nder
    else
    begin

      // uygulamaya veya efendi nesneye mesaj g�nder
      if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
        ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
      else GorevListesi[ListeGorunum^.GorevKimlik]^.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
    end;
  end

  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    // SISTEM_MESAJ(RENK_KIRMIZI, 'Kayd�rma De�eri: %d', [AOlay.Deger1]);

    // listeyi yukar� kayd�rma i�lemi. ilk elemana do�ru
    if(AOlay.Deger1 < 0) then
    begin

      j := ListeGorunum^.FGorunenIlkSiraNo;
      Dec(j);
      if(j >= 0) then ListeGorunum^.FGorunenIlkSiraNo := j;
    end

    // listeyi a�a��ya kayd�rma i�lemi. son elemana do�ru
    else if(AOlay.Deger1 > 0) then
    begin

      // azami kayd�rma de�eri
      i := ListeGorunum^.FDegerler^.ElemanSayisi - ListeGorunum^.FGorunenElemanSayisi;
      if(i < 0) then i := 0;

      j := ListeGorunum^.FGorunenIlkSiraNo;
      Inc(j);
      if(j < i) then ListeGorunum^.FGorunenIlkSiraNo := j;
    end;

    ListeGorunum^.Ciz;
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := ListeGorunum^.FFareImlecTipi;
end;

{==============================================================================
  se�ili eleman�n yaz� (text) de�erini geri d�nd�r�r
 ==============================================================================}
function TListeGorunum.SeciliSatirDegeriniAl: string;
var
  ListeGorunum: PListeGorunum;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  ListeGorunum := PListeGorunum(ListeGorunum^.NesneTipiniKontrolEt(Kimlik, gntListeGorunum));
  if(ListeGorunum = nil) then Exit;

  if(FSeciliSiraNo = -1) or (FSeciliSiraNo > FDegerler^.ElemanSayisi) then Exit('');

  Result := ListeGorunum^.FDegerler^.Eleman[FSeciliSiraNo];
end;

{==============================================================================
  | ay�rac�yla gelen karakter katar�n� b�l�mler
 ==============================================================================}
procedure TListeGorunum.Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
  DegerDizisi: PYaziListesi);
var
  Uzunluk, i: TISayi4;
  s: string;
begin

  DegerDizisi^.Temizle;

  Uzunluk := Length(ABicimlenmisDeger);
  if(Uzunluk > 0) then
  begin

    i := 1;
    s := '';
    while i <= Uzunluk do
    begin

      if(ABicimlenmisDeger[i] = AAyiracDeger) or (i = Uzunluk) then
      begin

        if(i = Uzunluk) then s += ABicimlenmisDeger[i];

        if(Length(s) > 0) then
        begin

          DegerDizisi^.Ekle(s);
          s := '';
        end;
      end else s += ABicimlenmisDeger[i];

      Inc(i);
    end;
  end;
end;

end.

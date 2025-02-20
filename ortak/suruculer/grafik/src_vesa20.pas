{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: src_vesa20.pas
  Dosya İşlevi: genel vesa 2.0 grafik kartı sürücüsü

  Güncelleme Tarihi: 19/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit src_vesa20;

interface

uses paylasim, gorselnesne, gn_pencere, gn_masaustu;

type
  PEkranKartSurucusu = ^TEkranKartSurucusu;
  TEkranKartSurucusu = object
  private
    function NoktaOku16(AYatay, ADikey: TISayi4): TRenk;
    function NoktaOku24(AYatay, ADikey: TISayi4): TRenk;
    function NoktaOku32(AYatay, ADikey: TISayi4): TRenk;
    procedure NoktaYaz16(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4; ARenk: TRenk;
      ARenkDonustur: Boolean);
    procedure NoktaYaz24(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4; ARenk: TRenk;
      AKullanilmiyor: Boolean);
    procedure NoktaYaz32(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4; ARenk: TRenk;
      AKullanilmiyor: Boolean);
    procedure GorselAnaNesneleriGuncelle;
    procedure FareGostergesiCiz;
  public
    KartBilgisi: TEkranKartBilgisi;
    procedure Yukle;
    function NoktaOku(AYatay, ADikey: TISayi4): TRenk;
    procedure NoktaYaz(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4; ARenk: TRenk;
      ARenkDonustur: Boolean);
    procedure EkranBelleginiGuncelle;
  end;

implementation

uses genel, donusum, gn_menu, gn_acilirmenu, fareimlec, gdt;

var
  ArkaBellek, EkranBellegi: Isaretci;

{==============================================================================
  vesa 2.0 grafik sürücüsünün ana yükleme işlevlerini içerir
 ==============================================================================}
procedure TEkranKartSurucusu.Yukle;
begin

  // grafik
  GDTRGirdisiEkle(SECICI_GRAFIK_LFB, KartBilgisi.BellekAdresi, $FFFFFF, $F2, $D0);
  //GDTRGirdisiEkle(SECICI_GRAFIK_LFB, KartBilgisi.BellekAdresi, $FFFFFF, $92, $D0);

  // arka plan için bellek ayır
  ArkaBellek := GGercekBellek.Ayir(GEkranKartSurucusu.KartBilgisi.YatayCozunurluk *
    GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk * (KartBilgisi.PixelBasinaBitSayisi div 8));

  // grafik kartı video belleği
  // bilgi: EkranBellegi değişkeni, ekran kartı belleğine direkt erişim için kullanılabilir
  EkranBellegi := Isaretci(KartBilgisi.BellekAdresi);
end;

{==============================================================================
  nokta okuma işlevi
 ==============================================================================}
function TEkranKartSurucusu.NoktaOku(AYatay, ADikey: TISayi4): TRenk;
begin

  if(AYatay < 0) or (AYatay > KartBilgisi.YatayCozunurluk - 1) then Exit(RENK_SIYAH);
  if(ADikey < 0) or (ADikey > KartBilgisi.DikeyCozunurluk - 1) then Exit(RENK_SIYAH);

  case KartBilgisi.PixelBasinaBitSayisi of
    16: Result := NoktaOku16(AYatay, ADikey);
    24: Result := NoktaOku24(AYatay, ADikey);
    32: Result := NoktaOku32(AYatay, ADikey);
  end;
end;

{==============================================================================
  nokta işaretleme işlevi
 ==============================================================================}
procedure TEkranKartSurucusu.NoktaYaz(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4;
  ARenk: TRenk; ARenkDonustur: Boolean);
var
  TuvalNesne: PGorselNesne;
  Sol, Ust: TISayi4;
begin

  // nesnenin belirtilmesi durumunda belirtilen koordinatın sınırlar içerisinde
  // olup olmadığını kontrol et
  if not(AGorselNesne = nil) then
  begin

    if(AYatay < 0) or (AYatay > AGorselNesne^.FBoyut.Genislik) then Exit;
    if(ADikey < 0) or (ADikey > AGorselNesne^.FBoyut.Yukseklik) then Exit;
  end;

  Sol := AGorselNesne^.FCizimBaslangic.Sol + AYatay;
  Ust := AGorselNesne^.FCizimBaslangic.Ust + ADikey;

  TuvalNesne := AGorselNesne^.FTuvalNesne;

  case KartBilgisi.PixelBasinaBitSayisi of
    16: NoktaYaz16(TuvalNesne, Sol, Ust, ARenk, ARenkDonustur);
    24: NoktaYaz24(TuvalNesne, Sol, Ust, ARenk, ARenkDonustur);
    32: NoktaYaz32(TuvalNesne, Sol, Ust, ARenk, ARenkDonustur);
  end;
end;

{==============================================================================
  belirtilen koordinattaki 16 bitlik nokta renk değerini alır
 ==============================================================================}
function TEkranKartSurucusu.NoktaOku16(AYatay, ADikey: TISayi4): TRenk;
var
  BellekAdresi: TSayi4;
begin

  // belirtilen koordinata konumlan
  BellekAdresi := (ADikey * KartBilgisi.SatirdakiByteSayisi) + (AYatay * 2);
  BellekAdresi += TSayi4(ArkaBellek);

  //  noktanın renk değerini al
  Result := PRenk(BellekAdresi)^ and $FFFF;
end;

{==============================================================================
  belirtilen koordinattaki noktayı 16 bitlik renk değeri ile işaretler
 ==============================================================================}
procedure TEkranKartSurucusu.NoktaYaz16(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4;
  ARenk: TRenk; ARenkDonustur: Boolean);
var
  BellekAdresi: TSayi4;
  SatirBasinaBitSayisi: TISayi4;
  PAdres16: PSayi2;
  Renk16: TSayi2;
begin

  if(AGorselNesne = nil) or (AGorselNesne^.NesneTipi = gntMasaustu) then
    SatirBasinaBitSayisi := KartBilgisi.SatirdakiByteSayisi
  else SatirBasinaBitSayisi := AGorselNesne^.FBoyut.Genislik * 2;

  // belirtilen koordinata konumlan
  BellekAdresi := (ADikey * SatirBasinaBitSayisi) + (AYatay * 2);
  if(AGorselNesne = nil) then
    BellekAdresi += TSayi4(ArkaBellek)
  else BellekAdresi += TSayi4(AGorselNesne^.FCizimBellekAdresi);

  // eğer dönüşüm isteniyorsa 24 / 32 bitlik renk değerini
  // 16 bitlik renk değerine çevir
  if(ARenkDonustur) then

    Renk16 := RGB24CevirRGB16(ARenk)
  else Renk16 := (ARenk and $FFFF);

  // noktayı belirtilen renk ile işaretle
  PAdres16 := PSayi2(BellekAdresi);
  PAdres16^ := Renk16;
end;

{==============================================================================
  belirtilen koordinattaki 24 bitlik nokta renk değerini alır
 ==============================================================================}
function TEkranKartSurucusu.NoktaOku24(AYatay, ADikey: TISayi4): TRenk;
var
  BellekAdresi: TSayi4;
begin

  // belirtilen koordinata konumlan
  BellekAdresi := (ADikey * KartBilgisi.SatirdakiByteSayisi) + (AYatay * 3);
  BellekAdresi += TSayi4(ArkaBellek);

  // noktanın renk değerini al
  Result := PRenk(BellekAdresi)^ and $FFFFFF;
end;

{==============================================================================
  belirtilen koordinattaki noktayı 24 bitlik renk değeri ile işaretler
 ==============================================================================}
procedure TEkranKartSurucusu.NoktaYaz24(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4;
  ARenk: TRenk; AKullanilmiyor: Boolean);
var
  BellekAdresi, SatirBasinaBitSayisi: TISayi4;
  PAdres8: PSayi1;
  RGB: PRGB;
begin

  if(AGorselNesne = nil) or (AGorselNesne^.NesneTipi = gntMasaustu) then
    SatirBasinaBitSayisi := KartBilgisi.SatirdakiByteSayisi
  else SatirBasinaBitSayisi := AGorselNesne^.FBoyut.Genislik * 3;

  // belirtilen koordinata konumlan
  BellekAdresi := (ADikey * SatirBasinaBitSayisi) + (AYatay * 3);
  if(AGorselNesne = nil) then
    BellekAdresi += TSayi4(ArkaBellek)
  else BellekAdresi += TSayi4(AGorselNesne^.FCizimBellekAdresi);

  // noktayı belirtilen renk ile işaretle
  PAdres8 := PByte(BellekAdresi);
  RGB := @ARenk;
  PAdres8[0] := RGB^.B;
  PAdres8[1] := RGB^.G;
  PAdres8[2] := RGB^.R;
end;

{==============================================================================
  belirtilen koordinattaki 32 bitlik nokta renk değerini alır
 ==============================================================================}
function TEkranKartSurucusu.NoktaOku32(AYatay, ADikey: TISayi4): TRenk;
var
  BellekAdresi: TSayi4;
begin

  // belirtilen koordinata konumlan
  BellekAdresi := (ADikey * KartBilgisi.SatirdakiByteSayisi) + (AYatay * 4);
  BellekAdresi += TSayi4(ArkaBellek);

  // noktanın renk değerini al
  Result := PRenk(BellekAdresi)^;
end;

{==============================================================================
  belirtilen koordinattaki noktayı 32 bitlik renk değeri ile işaretler
 ==============================================================================}
procedure TEkranKartSurucusu.NoktaYaz32(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4;
  ARenk: TRenk; AKullanilmiyor: Boolean);
var
  BellekAdresi, SatirBasinaBitSayisi: TSayi4;
begin

  if(AGorselNesne = nil) or (AGorselNesne^.NesneTipi = gntMasaustu) then
    SatirBasinaBitSayisi := KartBilgisi.SatirdakiByteSayisi
  else SatirBasinaBitSayisi := AGorselNesne^.FBoyut.Genislik * 4;

  // belirtilen koordinata konumlan
  BellekAdresi := (ADikey * SatirBasinaBitSayisi) + (AYatay * 4);
  BellekAdresi += TSayi4(AGorselNesne^.FCizimBellekAdresi);

  // noktayı belirtilen renk ile işaretle
  BellekAdresi := ARenk;
end;

// arka plana çizilen görsel nesne çizimlerini ekran belleğine (grafik kart) çizer
procedure TEkranKartSurucusu.EkranBelleginiGuncelle;
var
  i: TSayi4;
begin

  // ekran belleğine taşımadan önce yapılması gereken ön işlemler

  // 1. görsel ana nesneleri çizim belleğinden arka belleğe alarak güncelleştir
  GorselAnaNesneleriGuncelle;

  // 2. fare göstergesini çiz
  FareGostergesiCiz;

  // arka belleği ekran belleğine (grafik bellek) taşı
  i := KartBilgisi.YatayCozunurluk * KartBilgisi.DikeyCozunurluk *
    KartBilgisi.NoktaBasinaByteSayisi;

  asm
    cli
    pushad
    push ds
    push es

    mov ax,SECICI_SISTEM_VERI * 8
    mov ds,ax
    mov esi,ArkaBellek
    mov ax,SECICI_GRAFIK_LFB * 8
    mov es,ax
    mov edi,0

    mov ecx,i
    shr ecx,2
    cld
    repnz movsd

    pop es
    pop ds
    popad
    sti
  end;
end;

// görsel ana nesne çizimlerini arka belleğe çizer
// bilgi-1: bu ana nesneler: masaüstü, pencere ve menülerdir
// bilgi-2: her ana nesne (ekran kartı belleğine değil) kendi çizim belleğine
//  çizim işlemini gerçekleştirir
procedure TEkranKartSurucusu.GorselAnaNesneleriGuncelle;
var
  Masaustu: PMasaustu;
  Pencere: PPencere;
  BaslatMenu: PMenu;
  GorselNesne: PGorselNesne;
  MasaustuMenu: PAcilirMenu;
  PencereBellekAdresi: PPGorselNesne;
  KaynakBellek, HedefBellek, CizimBellekAdresi: Isaretci;
  Sol, KaynakA2,            // nesnelerin taşınması için
  Ust, KaynakB2,            // nesnelerin taşınması için
  HedefA1, HedefB1,         // nesnelerin taşınması için
  Yukseklik, Genislik, KaynakSatirdakiByteSayisi,
  HedefSatirdakiByteSayisi,
  NoktaBasinaByteSayisi, i, i2, j: TISayi4;
  MenuCiz: Boolean;
begin

  // geçerli masaüstü yok ise çık
  Masaustu := GAktifMasaustu;
  if(Masaustu = nil) then Exit;

  Genislik := Masaustu^.FBoyut.Genislik;        // sütundaki toplam pixel sayısı
  Yukseklik := Masaustu^.FBoyut.Yukseklik;      // satırdaki toplam pixel sayısı

  NoktaBasinaByteSayisi := KartBilgisi.NoktaBasinaByteSayisi;
  HedefSatirdakiByteSayisi := KartBilgisi.SatirdakiByteSayisi;
  KaynakSatirdakiByteSayisi := Genislik * NoktaBasinaByteSayisi;

  // arka planın çizilmesi işlemi

  // 1. masaüstünün arka belleğe çizilmesi
  for i := 0 to Yukseklik - 1 do
  begin

    KaynakBellek := (i * KaynakSatirdakiByteSayisi) + Masaustu^.FCizimBellekAdresi;
    HedefBellek := (i * HedefSatirdakiByteSayisi) + ArkaBellek;

    asm
      pushad
      mov esi,KaynakBellek
      mov edi,HedefBellek
      mov ecx,KaynakSatirdakiByteSayisi
      cld
      rep movsb
      popad
    end;
  end;

  // 2. pencere ve alt nesnelerin arka belleğe çizilmesi
  if(Masaustu^.FAltNesneSayisi > 0) then
  begin

    PencereBellekAdresi := Masaustu^.FAltNesneBellekAdresi;

    for i := 0 to Masaustu^.FAltNesneSayisi - 1 do
    begin

      GorselNesne := PencereBellekAdresi[i];
      if not(GorselNesne^.NesneTipi = gntMenu) and not(GorselNesne^.NesneTipi = gntAcilirMenu) then
      begin

        Pencere := PPencere(GorselNesne);
        if(Pencere^.Gorunum) and not(Pencere^.FPencereDurum = pdKucultuldu) then
        begin

          // sol sınır kontrol
          if(Pencere^.FKonum.Sol < 0) then
          begin

            Sol := Abs(Pencere^.FKonum.Sol);
            KaynakA2 := Pencere^.FBoyut.Genislik - Sol;
            HedefA1 := 0;
          end
          else
          begin

            Sol := 0;
            KaynakA2 := Pencere^.FBoyut.Genislik;
            HedefA1 := Pencere^.FKonum.Sol;
          end;

          // sağ sınır kontrol
          if((Pencere^.FKonum.Sol + Pencere^.FBoyut.Genislik) >
            Masaustu^.FBoyut.Genislik - 1) then
          begin

            KaynakA2 := Pencere^.FBoyut.Genislik -
              ((Pencere^.FKonum.Sol + Pencere^.FBoyut.Genislik) - (Masaustu^.FBoyut.Genislik - 1))
          end
          else
          begin

            if(Pencere^.FKonum.Sol >= 0) then KaynakA2 := Pencere^.FBoyut.Genislik;
          end;

          // üst sınır kontrol
          if(Pencere^.FKonum.Ust < 0) then
          begin

            Ust := Abs(Pencere^.FKonum.Ust);
            KaynakB2 := Pencere^.FBoyut.Yukseklik;
            HedefB1 := 0;
          end
          else
          begin

            Ust := 0;
            KaynakB2 := Pencere^.FBoyut.Yukseklik;
            HedefB1 := Pencere^.FKonum.Ust;
          end;

          // alt sınır kontrol
          if((Pencere^.FKonum.Ust + Pencere^.FBoyut.Yukseklik) >
            Masaustu^.FBoyut.Yukseklik - 1) then
          begin

            KaynakB2 := Pencere^.FBoyut.Yukseklik -
              ((Pencere^.FKonum.Ust + Pencere^.FBoyut.Yukseklik) - (Masaustu^.FBoyut.Yukseklik - 1))
          end
          else
          begin

            if(Pencere^.FKonum.Ust >= 0) then KaynakB2 := Pencere^.FBoyut.Yukseklik;
          end;

          KaynakSatirdakiByteSayisi := Pencere^.FBoyut.Genislik * NoktaBasinaByteSayisi;
          HedefSatirdakiByteSayisi := KartBilgisi.SatirdakiByteSayisi;

          for i2 := Ust to KaynakB2 - 1 do
          begin

            KaynakBellek := (i2 * KaynakSatirdakiByteSayisi) +
              (Sol * NoktaBasinaByteSayisi) + Pencere^.FCizimBellekAdresi;
            HedefBellek := ((Pencere^.FKonum.Ust + i2) * (HedefSatirdakiByteSayisi)) +
              (HedefA1 * NoktaBasinaByteSayisi) + ArkaBellek;

            j := KaynakA2 * NoktaBasinaByteSayisi;
            asm
              pushad
              mov esi,KaynakBellek
              mov edi,HedefBellek
              mov ecx,j
              cld
              rep movsb
              popad
            end;
          end;
        end;
      end;
    end;
  end;

  // 3. başlat menü veya açılır menünün arka belleğe çizilmesi
  MenuCiz := False;
  if(GAktifMenu^.NesneTipi = gntMenu) then
  begin

    BaslatMenu := PMenu(GAktifMenu);

    Sol := BaslatMenu^.FKonum.Sol;
    Ust := BaslatMenu^.FKonum.Ust;
    Genislik := BaslatMenu^.FBoyut.Genislik;      // sütundaki toplam pixel sayısı
    Yukseklik := BaslatMenu^.FBoyut.Yukseklik;    // satırdaki toplam pixel sayısı

    CizimBellekAdresi := BaslatMenu^.FCizimBellekAdresi;

    if(BaslatMenu^.Gorunum) then
    begin

      MenuCiz := True;
      BaslatMenu^.Ciz;
    end;
  end
  else
  begin

    MasaustuMenu := PAcilirMenu(GAktifMenu);

    Sol := MasaustuMenu^.FKonum.Sol;
    Ust := MasaustuMenu^.FKonum.Ust;
    Genislik := MasaustuMenu^.FBoyut.Genislik;      // sütundaki toplam pixel sayısı
    Yukseklik := MasaustuMenu^.FBoyut.Yukseklik;    // satırdaki toplam pixel sayısı

    CizimBellekAdresi := MasaustuMenu^.FCizimBellekAdresi;

    if(MasaustuMenu^.Gorunum) then
    begin

      MenuCiz := True;
      MasaustuMenu^.Ciz;
    end;
  end;

  if(MenuCiz) then
  begin

    NoktaBasinaByteSayisi := KartBilgisi.NoktaBasinaByteSayisi;
    HedefSatirdakiByteSayisi := KartBilgisi.SatirdakiByteSayisi;
    KaynakSatirdakiByteSayisi := Genislik * NoktaBasinaByteSayisi;

    for i := 0 to Yukseklik - 1 do
    begin

      KaynakBellek := (i * KaynakSatirdakiByteSayisi) + CizimBellekAdresi;
      HedefBellek := (((i + Ust) * HedefSatirdakiByteSayisi) +
        (Sol * NoktaBasinaByteSayisi)) + ArkaBellek;

      asm
        pushad
        mov esi,KaynakBellek
        mov edi,HedefBellek
        mov ecx,KaynakSatirdakiByteSayisi
        cld
        rep movsb
        popad
      end;
    end;
  end;
end;

{==============================================================================
  fare imleç göstergesini çizer
 ==============================================================================}
procedure TEkranKartSurucusu.FareGostergesiCiz;
var
  FareImlec: TFareImlec;
  ImlecBellekAdresi: PSayi1;
  Yatay, Dikey, ImlecYatayBaslangic, ImlecYatayBitis,
  ImlecDikeyBaslangic, ImlecDikeyBitis,
  FareYatayBaslangic, FareDikeyBaslangic,
  Deger: TISayi4;
begin

  // geçerli fare gösterge bilgilerini al
  FareImlec := CursorList[Ord(GecerliFareGostegeTipi)];

  // fare yatay başlangıç ve imleç yatay başlangıç değerlerinin hesaplanması
  FareYatayBaslangic := GFareSurucusu.YatayKonum - FareImlec.YatayOdak;
  if(FareYatayBaslangic < 0) then
    ImlecYatayBaslangic := Abs(FareYatayBaslangic)
  else ImlecYatayBaslangic := 0;

  // imleç yatay bitiş değerlerinin hesaplanması
  Deger := GFareSurucusu.YatayKonum + (FareImlec.Genislik - FareImlec.YatayOdak);
  if(Deger > GEkranKartSurucusu.KartBilgisi.YatayCozunurluk - 1) then
    ImlecYatayBitis := FareImlec.Genislik - (Deger - GEkranKartSurucusu.KartBilgisi.YatayCozunurluk - 1)
  else ImlecYatayBitis := FareImlec.Genislik - 1;

  // fare dikey başlangıç ve imleç dikey başlangıç değerlerinin hesaplanması
  FareDikeyBaslangic := GFareSurucusu.DikeyKonum - FareImlec.DikeyOdak;
  if(FareDikeyBaslangic < 0) then
    ImlecDikeyBaslangic := Abs(FareDikeyBaslangic)
  else ImlecDikeyBaslangic := 0;

  // imleç dikey bitiş değerlerinin hesaplanması
  Deger := GFareSurucusu.DikeyKonum + (FareImlec.Yukseklik - FareImlec.DikeyOdak);
  if(Deger > GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk - 1) then
    ImlecDikeyBitis := FareImlec.Yukseklik - (Deger - GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk - 1)
  else ImlecDikeyBitis := FareImlec.Yukseklik - 1;

  for Dikey := ImlecDikeyBaslangic to ImlecDikeyBitis do
  begin

    for Yatay := ImlecYatayBaslangic to ImlecYatayBitis do
    begin

      // fare imleç göstergesi bellek adresi
      ImlecBellekAdresi := FareImlec.BellekAdresi + (Dikey * FareImlec.Genislik) + Yatay;

      if(ImlecBellekAdresi^ = 1) then
        GEkranKartSurucusu.NoktaYaz(nil, FareYatayBaslangic + Yatay, FareDikeyBaslangic + Dikey,
          RENK_SIYAH, True)
      else if(ImlecBellekAdresi^ = 2) then
        GEkranKartSurucusu.NoktaYaz(nil, FareYatayBaslangic + Yatay, FareDikeyBaslangic + Dikey,
          RENK_BEYAZ, True);
    end;
  end;
end;

end.

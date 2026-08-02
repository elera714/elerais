{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: src_vesa20.pas
  Dosya İşlevi: genel vesa 2.0 grafik kartı sürücüsü

  Güncelleme Tarihi: 25/06/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit src_vesa20;

interface

uses paylasim, gorselnesne, gn_pencere, gn_masaustu;

type
  PEkranKartBilgisi = ^TEkranKartBilgisi;
  TEkranKartBilgisi = record
    BellekUzunlugu: TSayi2;
    EkranMod: TSayi2;
    YatayCozunurluk, DikeyCozunurluk: TISayi4;
    BellekAdresi: TSayi4;
    PixelBasinaBitSayisi: TSayi1;
    NoktaBasinaByteSayisi: TSayi1;
    SatirdakiByteSayisi: TSayi2;
  end;

type
  TNoktaOkuIslev = function(AYatay, ADikey: TISayi4): TRenk of object;
  TNoktaYazIslev = procedure(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4;
    ARenk: TRenk; ARenkDonustur: Boolean) of object;

type
  PEkranKartSurucusu = ^TEkranKartSurucusu;
  TEkranKartSurucusu = object
  private
    FArkaBellek: Isaretci;
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
    NoktaOkuIslev: TNoktaOkuIslev;
    NoktaYazIslev: TNoktaYazIslev;
    procedure Yukle;
    function NoktaOku(AYatay, ADikey: TISayi4): TRenk;
    procedure NoktaYaz(AGorselNesne: PGorselNesne; AYatay, ADikey: TISayi4; ARenk: TRenk;
      ARenkDonustur: Boolean);
    procedure EkranBelleginiGuncelle;
    property ArkaBellek: Isaretci read FArkaBellek write FArkaBellek;
  end;

var
  GEkranKartSurucusu: TEkranKartSurucusu;

implementation

uses genel, donusum, gn_menu, gn_acilirmenu, fareimlec, gdt, src_ps2;

{==============================================================================
  vesa 2.0 grafik sürücüsünün ana yükleme işlevlerini içerir
 ==============================================================================}
procedure TEkranKartSurucusu.Yukle;
var
  GMBilgi: PGMBilgi;
begin

  GMBilgi := PGMBilgi(BILDEN_VERIADRESI);

  // video bilgilerini al
  KartBilgisi.BellekUzunlugu := GMBilgi^.GrafikBellekUzunlugu;
  KartBilgisi.EkranMod := GMBilgi^.GrafikEkranMod;
  KartBilgisi.YatayCozunurluk := GMBilgi^.GrafikCozunurlukX;
  KartBilgisi.DikeyCozunurluk := GMBilgi^.GrafikCozunurlukY;
  KartBilgisi.BellekAdresi := GMBilgi^.GrafikBellekAdresi;
  //VIDEO_MEM_ADDR;
  KartBilgisi.PixelBasinaBitSayisi := GMBilgi^.GrafikPxBasinaBit;
  KartBilgisi.NoktaBasinaByteSayisi := (GMBilgi^.GrafikPxBasinaBit div 8);
  KartBilgisi.SatirdakiByteSayisi := GMBilgi^.GrafikSatirByteUz;

  // grafik
  GDTRGirdisiEkle(SECICI_GRAFIK_LFB, KartBilgisi.BellekAdresi, $FFFFFF, $F2, $D0);
  //GDTRGirdisiEkle(SECICI_GRAFIK_LFB, KartBilgisi.BellekAdresi, $FFFFFF, $92, $D0);

  // arka plan için bellek ayır
  ArkaBellek := GetMem(GEkranKartSurucusu.KartBilgisi.YatayCozunurluk *
    GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk * (KartBilgisi.PixelBasinaBitSayisi div 8));

  case KartBilgisi.PixelBasinaBitSayisi of
    16: begin NoktaOkuIslev := @NoktaOku16; NoktaYazIslev := @NoktaYaz16; end;
    24: begin NoktaOkuIslev := @NoktaOku24; NoktaYazIslev := @NoktaYaz24; end;
    32: begin NoktaOkuIslev := @NoktaOku32; NoktaYazIslev := @NoktaYaz32; end;
  end;
end;

{==============================================================================
  nokta okuma işlevi
 ==============================================================================}
function TEkranKartSurucusu.NoktaOku(AYatay, ADikey: TISayi4): TRenk;
begin

  Result := RENK_SIYAH;

  if(AYatay >= 0) or (AYatay <= KartBilgisi.YatayCozunurluk - 1) and
    (ADikey >= 0) or (ADikey <= KartBilgisi.DikeyCozunurluk - 1) then
      Result := NoktaOkuIslev(AYatay, ADikey);
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

    if(AYatay < 0) or (AYatay > AGorselNesne^.F0.FAtananAlan.Genislik) then Exit;
    if(ADikey < 0) or (ADikey > AGorselNesne^.F0.FAtananAlan.Yukseklik) then Exit;
  end;

  Sol := AGorselNesne^.F0.FCizimBaslangic.Sol + AYatay;
  Ust := AGorselNesne^.F0.FCizimBaslangic.Ust + ADikey;

  TuvalNesne := AGorselNesne^.FTuvalNesne;

  NoktaYazIslev(TuvalNesne, Sol, Ust, ARenk, ARenkDonustur);
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
  BellekAdresi := BellekAdresi + TSayi4(ArkaBellek);

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

  if(AGorselNesne = nil) or (AGorselNesne^.F0.NesneTipi = gntMasaustu) then
    SatirBasinaBitSayisi := KartBilgisi.SatirdakiByteSayisi
  else SatirBasinaBitSayisi := AGorselNesne^.F0.FAtananAlan.Genislik * 2;

  // belirtilen koordinata konumlan
  BellekAdresi := (ADikey * SatirBasinaBitSayisi) + (AYatay * 2);
  if(AGorselNesne = nil) then
    BellekAdresi := BellekAdresi + TSayi4(ArkaBellek)
  else BellekAdresi := BellekAdresi + TSayi4(AGorselNesne^.FCizimBellekAdresi);

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
  BellekAdresi := BellekAdresi + TSayi4(ArkaBellek);

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
  RGB24: PRGB24Bit;
begin

  if(AGorselNesne = nil) or (AGorselNesne^.F0.NesneTipi = gntMasaustu) then
    SatirBasinaBitSayisi := KartBilgisi.SatirdakiByteSayisi
  else SatirBasinaBitSayisi := AGorselNesne^.F0.FAtananAlan.Genislik * 3;

  // belirtilen koordinata konumlan
  BellekAdresi := (ADikey * SatirBasinaBitSayisi) + (AYatay * 3);
  if(AGorselNesne = nil) then
    BellekAdresi := BellekAdresi + TSayi4(ArkaBellek)
  else BellekAdresi := BellekAdresi + TSayi4(AGorselNesne^.FCizimBellekAdresi);

  // noktayı belirtilen renk ile işaretle
  PAdres8 := PByte(BellekAdresi);
  RGB24 := @ARenk;
  PAdres8[0] := RGB24^.B;
  PAdres8[1] := RGB24^.G;
  PAdres8[2] := RGB24^.R;
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
  BellekAdresi := BellekAdresi + TSayi4(ArkaBellek);

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

  if(AGorselNesne = nil) or (AGorselNesne^.F0.NesneTipi = gntMasaustu) then
    SatirBasinaBitSayisi := KartBilgisi.SatirdakiByteSayisi
  else SatirBasinaBitSayisi := AGorselNesne^.F0.FAtananAlan.Genislik * 4;

  // belirtilen koordinata konumlan
  BellekAdresi := (ADikey * SatirBasinaBitSayisi) + (AYatay * 4);
  BellekAdresi := BellekAdresi + TSayi4(AGorselNesne^.FCizimBellekAdresi);

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
    mov esi,GEkranKartSurucusu.ArkaBellek
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
  GN: PGorselNesne;
  MasaustuMenu: PAcilirMenu;
  GNBellekAdresi: PPGorselNesne;
  KaynakBellek, HedefBellek, CizimBellekAdresi: Isaretci;
  Sol, KaynakA2,            // nesnelerin taşınması için
  Ust, KaynakB2,            // nesnelerin taşınması için
  HedefA1, HedefB1,         // nesnelerin taşınması için
  Yukseklik, Genislik, KaynakSatirdakiByteSayisi,
  HedefSatirdakiByteSayisi,
  NoktaBasinaByteSayisi, i2: TISayi4;
  i, j: TSayi4;
  MenuCiz: Boolean;
begin

  // geçerli masaüstü yok ise çık
  Masaustu := GAktifMasaustu;
  if(Masaustu = nil) then Exit;

  Genislik := Masaustu^.F0.FAtananAlan.Genislik;        // sütundaki toplam pixel sayısı
  Yukseklik := Masaustu^.F0.FAtananAlan.Yukseklik;      // satırdaki toplam pixel sayısı

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
      shr ecx,2
      cld
      rep movsd
      popad
    end;
  end;

  // 2. pencere ve alt nesnelerin arka belleğe çizilmesi
  if(Masaustu^.F0.AltNesneSayisi > 0) then
  begin

    GNBellekAdresi := Masaustu^.F0.AltNesneBellekAdresi;

    for i := 0 to Masaustu^.F0.AltNesneSayisi - 1 do
    begin

      GN := GNBellekAdresi[i];
      if not(GN = nil) and (GN^.F0.NesneTipi = gntPencere) then
      begin

        Pencere := PPencere(GN);
        if(Pencere^.F0.Gorunum) and not(Pencere^.FPencereDurum = pdKucultuldu) then
        begin

          // sol sınır kontrol
          if(Pencere^.F0.FAtananAlan.Sol < 0) then
          begin

            Sol := Abs(Pencere^.F0.FAtananAlan.Sol);
            KaynakA2 := Pencere^.F0.FAtananAlan.Genislik - Sol;
            HedefA1 := 0;
          end
          else
          begin

            Sol := 0;
            KaynakA2 := Pencere^.F0.FAtananAlan.Genislik;
            HedefA1 := Pencere^.F0.FAtananAlan.Sol;
          end;

          // sağ sınır kontrol
          if((Pencere^.F0.FAtananAlan.Sol + Pencere^.F0.FAtananAlan.Genislik) >
            Masaustu^.F0.FAtananAlan.Genislik - 1) then
          begin

            KaynakA2 := Pencere^.F0.FAtananAlan.Genislik -
              ((Pencere^.F0.FAtananAlan.Sol + Pencere^.F0.FAtananAlan.Genislik) - (Masaustu^.F0.FAtananAlan.Genislik - 1))
          end
          else
          begin

            if(Pencere^.F0.FAtananAlan.Sol >= 0) then KaynakA2 := Pencere^.F0.FAtananAlan.Genislik;
          end;

          // üst sınır kontrol
          if(Pencere^.F0.FAtananAlan.Ust < 0) then
          begin

            Ust := Abs(Pencere^.F0.FAtananAlan.Ust);
            KaynakB2 := Pencere^.F0.FAtananAlan.Yukseklik;
            HedefB1 := 0;
          end
          else
          begin

            Ust := 0;
            KaynakB2 := Pencere^.F0.FAtananAlan.Yukseklik;
            HedefB1 := Pencere^.F0.FAtananAlan.Ust;
          end;

          // alt sınır kontrol
          if((Pencere^.F0.FAtananAlan.Ust + Pencere^.F0.FAtananAlan.Yukseklik) >
            Masaustu^.F0.FAtananAlan.Yukseklik - 1) then
          begin

            KaynakB2 := Pencere^.F0.FAtananAlan.Yukseklik -
              ((Pencere^.F0.FAtananAlan.Ust + Pencere^.F0.FAtananAlan.Yukseklik) - (Masaustu^.F0.FAtananAlan.Yukseklik - 1))
          end
          else
          begin

            if(Pencere^.F0.FAtananAlan.Ust >= 0) then KaynakB2 := Pencere^.F0.FAtananAlan.Yukseklik;
          end;

          KaynakSatirdakiByteSayisi := Pencere^.F0.FAtananAlan.Genislik * NoktaBasinaByteSayisi;
          HedefSatirdakiByteSayisi := KartBilgisi.SatirdakiByteSayisi;

          for i2 := Ust to KaynakB2 - 1 do
          begin

            KaynakBellek := (i2 * KaynakSatirdakiByteSayisi) +
              (Sol * NoktaBasinaByteSayisi) + Pencere^.FCizimBellekAdresi;
            HedefBellek := ((Pencere^.F0.FAtananAlan.Ust + i2) * (HedefSatirdakiByteSayisi)) +
              (HedefA1 * NoktaBasinaByteSayisi) + ArkaBellek;

            j := KaynakA2 * NoktaBasinaByteSayisi;
            asm
              pushad
              mov esi,KaynakBellek
              mov edi,HedefBellek
              mov ecx,j
              shr ecx,2
              cld
              rep movsd
              popad
            end;
          end;
        end;
      end;
    end;
  end;

  // 3. başlat menü veya açılır menünün arka belleğe çizilmesi
  MenuCiz := False;
  if(GAktifMenu^.F0.NesneTipi = gntMenu) then
  begin

    BaslatMenu := PMenu(GAktifMenu);

    Sol := BaslatMenu^.F0.FAtananAlan.Sol;
    Ust := BaslatMenu^.F0.FAtananAlan.Ust;
    Genislik := BaslatMenu^.F0.FAtananAlan.Genislik;      // sütundaki toplam pixel sayısı
    Yukseklik := BaslatMenu^.F0.FAtananAlan.Yukseklik;    // satırdaki toplam pixel sayısı

    CizimBellekAdresi := BaslatMenu^.FCizimBellekAdresi;

    if(BaslatMenu^.F0.Gorunum) then
    begin

      MenuCiz := True;
      BaslatMenu^.Ciz;
    end;
  end
  else
  begin

    MasaustuMenu := PAcilirMenu(GAktifMenu);

    Sol := MasaustuMenu^.F0.FAtananAlan.Sol;
    Ust := MasaustuMenu^.F0.FAtananAlan.Ust;
    Genislik := MasaustuMenu^.F0.FAtananAlan.Genislik;      // sütundaki toplam pixel sayısı
    Yukseklik := MasaustuMenu^.F0.FAtananAlan.Yukseklik;    // satırdaki toplam pixel sayısı

    CizimBellekAdresi := MasaustuMenu^.FCizimBellekAdresi;

    if(MasaustuMenu^.F0.Gorunum) then
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
        shr ecx,2
        cld
        rep movsd
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
  FareImlec := GFareImlecleri[Ord(GecerliFareGostegeTipi)];

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

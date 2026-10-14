{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: vbox.pas
  Dosya Ýþlevi: virtualbox sanal aygýt yönetim iþlevlerini içerir

  Güncelleme Tarihi: 14/10/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit vbox;

interface

uses paylasim, sistemmesaj, pci;

const
  VB_SURUM                  = $00010003;
  VB_ISTEK_BASLIK_SURUM     = $00010001;

  VB_FARE_DURUMAL           = 1;
  VB_FARE_DURUMYAZ          = 2;
  VB_FARE_AKTIF             = (1 shl 0) or (1 shl 4);
  VB_FARE_PASIF             = 0;

  VB_KONUK_BILGI            = 50;
  VB_KONUK_GORUNTU_DEGISIM  = 51;
  VB_KONUK_ONAY_OLAY        = 41;
  VB_KONUK_YETENEK          = 55;

type
  // vb_header
  PVBBaslik = ^TVBBaslik;
  TVBBaslik = record
    Uzunluk: TSayi4;
  	Surum: TSayi4;
  	IstekTipi: TSayi4;
  	RC: TISayi4;
  	Ayrildi1: TSayi4;
  	Ayrildi2: TSayi4;
  end;

  // vb_guest_info
  PVBMISBilgi = ^TVBMISBilgi;
  TVBMISBilgi = record      // Misafir Ýþletim Sistemi
    Baslik: TVBBaslik;
  	Surum: TSayi4;
  	ISType: TSayi4;         // Ýþletim Sistemi tipi
  end;

  // vb_mouse
  PVBFare = ^TVBFare;
  TVBFare = record
    Baslik: TVBBaslik;
  	Ozellikler: TSayi4;
  	X: TISayi4;
  	Y: TISayi4;
  end;

  // vb_guest_caps
  PVBMISYetenek = ^TVBMISYetenek;
  TVBMISYetenek = record
    Baslik: TVBBaslik;
  	Yetenek: TSayi4;
  end;

  // vb_ack_events
  PVBOnayOlay = ^TVBOnayOlay;
  TVBOnayOlay = record
    Baslik: TVBBaslik;
  	Olaylar: TSayi4;
  end;

  // vb_display_change
  PVBGoruntuDegisim = ^TVBGoruntuDegisim;
  TVBGoruntuDegisim = record
    Baslik: TVBBaslik;
  	XCozunurluk,
    YCozunurluk: TSayi4;
    BPP, OlayOnay: TSayi4;
  end;

  // vbox_version
  PVBSurum = ^TVBSurum;
  TVBSurum = record
    Baslik: TVBBaslik;
    SurumX: TSayi2;
    SurumY: TSayi2;
    Yapim: TSayi4;
    Degisim: TSayi4;
    Ozellik: TSayi4;
  end;

type
  TVirtualBox = class
  private
    FPCIAygit: TPCI;
    FPort: TSayi4;
    FBellek: TSayi4;
    FKesmeNo: TSayi1;
    FFareYuklendi: Boolean;
  public
    constructor Create(APCI: TPCI);
    procedure Yukle;
    procedure FareDurumDegistir(AAktiflestir: Boolean);
    procedure FareKonumDegerleriniAl;
    procedure SurumDegeriniAl;
  end;

var
  GVirtualBox: TVirtualBox;

procedure VBoxKesmeCagrisi;

implementation

uses port, src_ps2;

{==============================================================================
  nesne ana yükleme iþlevlerini gerçekleþtirir
 ==============================================================================}
constructor TVirtualBox.Create(APCI: TPCI);
begin

  FPCIAygit := APCI;

  FFareYuklendi := False;

  Yukle;
end;

{==============================================================================
  virtualbox sanal sürücü yükleme iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TVirtualBox.Yukle;
var
  KesmeAktif: TSayi2;
  MISBilgi: TVBMISBilgi;
  MISYetenek: TVBMISYetenek;
  OnayOlay: TVBOnayOlay;
  GoruntuDegisim: TVBGoruntuDegisim;
  Fare: TVBFare;
begin

  FPort := GPCIAygitlar.Oku4(FPCIAygit.FYol, FPCIAygit.FAygit, FPCIAygit.FIslev,
    PCI_BAR0) and $FFFFFFFC;
  FBellek := GPCIAygitlar.Oku4(FPCIAygit.FYol, FPCIAygit.FAygit, FPCIAygit.FIslev,
    PCI_BAR1) and $FFFFFFF0;
  KesmeAktif := GPCIAygitlar.Oku2(FPCIAygit.FYol, FPCIAygit.FAygit, FPCIAygit.FIslev,
    PCI_KOMUT);
  FKesmeNo := GPCIAygitlar.Oku1(FPCIAygit.FYol, FPCIAygit.FAygit, FPCIAygit.FIslev,
    PCI_KESME_NO);

  {SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'VirtualBox.........:', []);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Yol: %d', [FPCIAygit.FYol]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Aygýt: %d', [FPCIAygit.FAygit]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Ýþlev: %d', [FPCIAygit.FIslev]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Satýcý Kimlik: $%.4x', [FPCIAygit.FSaticiKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Aygýt Kimlik: $%.4x', [FPCIAygit.FAygitKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Port: $%.4x', [FPort]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Bellek: $%.8x', [FBellek]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Kesme No: %d', [FKesmeNo]);

  // 10. bitin 1 olmasý kesmenin pasif olduðu anlamýna gelir
  if(KesmeAktif and (1 shl 10) = 0) then
    SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - INT Aktif', [])
  else SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - INT Pasif', []);}

  // vbox kesmesini aktifleþtir
  //IRQIsleviAta(FKesmeNo, @VBoxKesmeCagrisi);
  //IRQEtkinlestir(VBKesmeNo);

	MISBilgi.Baslik.Uzunluk := SizeOf(TVBMISBilgi);
	MISBilgi.Baslik.Surum := VB_ISTEK_BASLIK_SURUM;
	MISBilgi.Baslik.IstekTipi := VB_KONUK_BILGI;
	MISBilgi.Baslik.RC := 0;
	MISBilgi.Baslik.Ayrildi1 := 0;
	MISBilgi.Baslik.Ayrildi2 := 0;
	MISBilgi.Surum := VB_SURUM;
	MISBilgi.ISType := 0;
	PortYaz4(FPort, TSayi4(@MISBilgi));

{	MISYetenek.Baslik.Uzunluk := SizeOf(TVBMISYetenek);
	MISYetenek.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	MISYetenek.Baslik.IstekTipi := VB_KONUK_YETENEK;
	MISYetenek.Baslik.RC := 0;
	MISYetenek.Baslik.Ayrildi1 := 0;
	MISYetenek.Baslik.Ayrildi2 := 0;
	MISYetenek.Yetenek := 1 shl 0;
	PortYaz4(VBPort, TSayi4(@MISYetenek));

	OnayOlay.Baslik.Uzunluk := SizeOf(TVBOnayOlay);
	OnayOlay.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	OnayOlay.Baslik.IstekTipi := VB_KONUK_ONAY_OLAY;
	OnayOlay.Baslik.RC := 0;
	OnayOlay.Baslik.Ayrildi1 := 0;
	OnayOlay.Baslik.Ayrildi2 := 0;
	OnayOlay.Olaylar := 0;
	//PortYaz4(VBPort, TSayi4(@OnayOlay));

	GoruntuDegisim.Baslik.Uzunluk := SizeOf(TVBGoruntuDegisim);
	GoruntuDegisim.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	GoruntuDegisim.Baslik.IstekTipi := VB_KONUK_GORUNTU_DEGISIM;
	GoruntuDegisim.Baslik.RC := 0;
	GoruntuDegisim.Baslik.Ayrildi1 := 0;
	GoruntuDegisim.Baslik.Ayrildi2 := 0;
	GoruntuDegisim.XCozunurluk := 0;
	GoruntuDegisim.YCozunurluk := 0;
	GoruntuDegisim.BPP := 0;
	GoruntuDegisim.OlayOnay := 1;
	//PortYaz4(VBPort, TSayi4(@GoruntuDegisim));

  //PSayi4(Isaretci(VBBellek) + 04)^ := $FFFFFFFF;
  //PSayi4(Isaretci(VBBellek) + 08)^ := $FFFFFFFF;
  PSayi4(Isaretci(VBBellek + 12))^ := $FFFFFFFF;

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'VBoxGuestBilgi: %x', [TSayi4(@VBoxGuestBilgi)]);

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 0)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 4)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 8)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 12)^]);

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 0)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 4)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 8)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 12)^]);

  PSayi4(VBBellek + 12)^ := $FFFFFFFF; }
end;

{==============================================================================
  sanal fare sürücüsünü aktifleþtirir / pasifleþtirir
 ==============================================================================}
procedure TVirtualBox.FareDurumDegistir(AAktiflestir: Boolean);
var
  Fare: TVBFare;
begin

  Fare.Baslik.Uzunluk := SizeOf(TVBFare);
  Fare.Baslik.Surum := VB_ISTEK_BASLIK_SURUM;
  Fare.Baslik.IstekTipi := VB_FARE_DURUMYAZ;
  Fare.Baslik.RC := 0;
  Fare.Baslik.Ayrildi1 := 0;
  Fare.Baslik.Ayrildi2 := 0;

  if(AAktiflestir) then
  begin

    Fare.Ozellikler := VB_FARE_AKTIF;
    FFareYuklendi := True;
  end
  else
  begin

    Fare.Ozellikler := VB_FARE_PASIF;
    FFareYuklendi := False;
  end;

  Fare.X := 0;
  Fare.Y := 0;
  PortYaz4(FPort, TSayi4(@Fare));
end;

{==============================================================================
  sanal fare sürücü deðerlerini alýr ve bu deðerlerle fare koordinatlarýný günceller
  bilgi: fare sürücüsü sadece fare koordinatlarýný verir, düðme iþlevlerini içermez
 ==============================================================================}
procedure TVirtualBox.FareKonumDegerleriniAl;
var
  Fare: TVBFare;
begin

  if(FFareYuklendi) then
  begin

	  Fare.Baslik.Uzunluk := SizeOf(TVBFare);
	  Fare.Baslik.Surum := VB_ISTEK_BASLIK_SURUM;
	  Fare.Baslik.IstekTipi := VB_FARE_DURUMAL;
	  Fare.Baslik.RC := 0;
	  Fare.Baslik.Ayrildi1 := 0;
	  Fare.Baslik.Ayrildi2 := 0;
	  PortYaz4(FPort, TSayi4(@Fare));

    {SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox RC: %d', [Fare.Baslik.RC]);
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox O: %d', [Fare.Ozellikler]);}

    GFareSurucusu.KonumDegistir((Fare.X * 1024) div 65535, (Fare.Y * 768) div 65535);
  end;
end;

{==============================================================================
  sürücü kesmesi (irq)
 ==============================================================================}
procedure VBoxKesmeCagrisi;
begin

  //int 3;
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Kesme Çaðrýsý: ', []);
end;

{==============================================================================
  sanal makine sürüm deðerlerini alýr
 ==============================================================================}
procedure TVirtualBox.SurumDegeriniAl;
var
  Surum: TVBSurum;
begin

  Surum.Baslik.Uzunluk := SizeOf(TVBSurum);
  Surum.Baslik.Surum := VB_ISTEK_BASLIK_SURUM;
  Surum.Baslik.IstekTipi := 4;
  Surum.Baslik.RC := 0;
  Surum.Baslik.Ayrildi1 := 0;
  Surum.Baslik.Ayrildi2 := 0;
  Surum.SurumX := 0;
  Surum.SurumY := 0;
  Surum.Yapim := 0;
  Surum.Degisim := 0;
  Surum.Ozellik := 0;
  PortYaz4(FPort, TSayi4(@Surum));

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VB Sürüm: %d.%d, Yapim:: %d',
    [Surum.SurumX, Surum.SurumY, Surum.Yapim]);
end;

end.

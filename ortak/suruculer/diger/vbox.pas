{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: vbox.pas
  Dosya Ýþlevi: virtualbox sanal aygýt yönetim iþlevlerini içerir

  Güncelleme Tarihi: 10/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit vbox;

interface

uses paylasim, sistemmesaj, pci;

function Yukle(APCI: PPCI): TISayi4;
procedure Listele;
procedure IcerigiGoruntule;
procedure VBoxKesmeCagrisi;

implementation

uses irq, port;

const
  VMMDEV_SURUM                = $00010003;
  VBOX_ISTEK_BASLIK_SURUM     = $00010001;

  VMM_FARE_DURUMAL            = 1;
  VMM_FARE_DURUMYAZ           = 2;
//  #define VMM_SetPointerShape 3
//  #define VMM_AcknowledgeEvents 41
  VMM_GUEST_BILGIAL           = 50;
  VMM_KONUK_GORUNTU_DEGISIM   = 51;
  VMM_KONUK_ONAY_OLAY         = 41;
  VMM_GUEST_YETENEKAL         = 55;
//  #define VMM_VideoSetVisibleRegion 72

type
  PVBoxBaslik = ^TVBoxBaslik;
  TVBoxBaslik = record
    Uzunluk: TSayi4;
  	Surum: TSayi4;
  	IstekTipi: TSayi4;
  	RC: TISayi4;
  	Ayrildi1: TSayi4;
  	Ayrildi2: TSayi4;
  end;

  PVBoxGuestBilgi = ^TVBoxGuestBilgi;
  TVBoxGuestBilgi = record
    Baslik: TVBoxBaslik;
  	Surum: TSayi4;
  	ISType: TSayi4;     // Ýþletim Sistemi tipi
  end;

  PVBoxFare = ^TVBoxFare;
  TVBoxFare = record
    Baslik: TVBoxBaslik;
  	Ozellikler: TSayi4;
  	X: TISayi4;
  	Y: TISayi4;
  end;

  PVBoxGuestYetenek = ^TVBoxGuestYetenek;
  TVBoxGuestYetenek = record
    Baslik: TVBoxBaslik;
  	Yetenek: TSayi4;
  end;

  PVBoxOnayOlay = ^TVBoxOnayOlay;
  TVBoxOnayOlay = record
    Baslik: TVBoxBaslik;
  	Olaylar: TSayi4;
  end;

  PVBoxGoruntuDegisim = ^TVBoxGoruntuDegisim;
  TVBoxGoruntuDegisim = record
    Baslik: TVBoxBaslik;
  	XCozunurluk,
    YCozunurluk: TSayi4;
    BPP, OlayOnay: TSayi4;
  end;

var
  PCIAygit: TPCI;
  VBPort: TSayi4;
  VBBellek: TSayi4;
  VBKesmeNo: TSayi1;

  {$CODEALIGN PROC=4}
  VBoxGuestBilgi: TVBoxGuestBilgi;
  {$CODEALIGN PROC=4}
  VBoxGuestYetenek: TVBoxGuestYetenek;
  {$CODEALIGN PROC=4}
  VBoxOnayOlay: TVBoxOnayOlay;
  {$CODEALIGN PROC=4}
  VBoxGoruntuDegisim: TVBoxGoruntuDegisim;
  {$CODEALIGN PROC=4}
  VBoxFare: TVBoxFare;

{==============================================================================
  að ilk deðer yüklemelerini gerçekleþtirir
 ==============================================================================}
function Yukle(APCI: PPCI): TISayi4;
begin

  PCIAygit := APCI^;
  Result := -1;
end;

procedure Listele;
var
  KesmeAktif: TSayi2;
begin

  VBPort := PCIOku4(PCIAygit.Yol, PCIAygit.Aygit, PCIAygit.Islev, $10);
  VBBellek := PCIOku4(PCIAygit.Yol, PCIAygit.Aygit, PCIAygit.Islev, $14) and $FFFFFFF0;
  KesmeAktif := PCIOku2(PCIAygit.Yol, PCIAygit.Aygit, PCIAygit.Islev, $4);
  VBKesmeNo := PCIOku1(PCIAygit.Yol, PCIAygit.Aygit, PCIAygit.Islev, $3C);

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Yol: %d', [PCIAygit.Yol]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Aygýt: %d', [PCIAygit.Aygit]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Ýþlev: %d', [PCIAygit.Islev]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Satýcý Kimlik: $%.4x', [PCIAygit.SaticiKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Aygýt Kimlik: $%.4x', [PCIAygit.AygitKimlik]);

  if((VBPort and 1) = 1) then
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Port: $%.4x', [VBPort and $FFFFFFFC])
  else SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Bellek: $%.8x', [VBPort and $FFFFFFFC]);

  // 10. bitin 1 olmasý kesmenin pasif olduðu anlamýna gelir
  if(KesmeAktif and (1 shl 10) = 0) then
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'INT Aktif', [])
  else SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'INT Pasif', []);

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Kesme No: %d', [VBKesmeNo]);

  // vbox kesmesini aktifleþtir
  IRQIsleviAta(VBKesmeNo, @VBoxKesmeCagrisi);
  //IRQEtkinlestir(VBKesmeNo);

	{VBoxGuestBilgi.Baslik.Uzunluk := SizeOf(TVBoxGuestBilgi);
	VBoxGuestBilgi.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	VBoxGuestBilgi.Baslik.IstekTipi := VMM_GUEST_BILGIAL;
	VBoxGuestBilgi.Baslik.RC := 0;
	VBoxGuestBilgi.Baslik.Ayrildi1 := 0;
	VBoxGuestBilgi.Baslik.Ayrildi2 := 0;
	VBoxGuestBilgi.Surum := VMMDEV_SURUM;
	VBoxGuestBilgi.ISType := 0;
	PortYaz4(VBPort, TSayi4(@VBoxGuestBilgi));}

	VBoxGuestYetenek.Baslik.Uzunluk := SizeOf(TVBoxGuestYetenek);
	VBoxGuestYetenek.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	VBoxGuestYetenek.Baslik.IstekTipi := VMM_GUEST_YETENEKAL;
	VBoxGuestYetenek.Baslik.RC := 0;
	VBoxGuestYetenek.Baslik.Ayrildi1 := 0;
	VBoxGuestYetenek.Baslik.Ayrildi2 := 0;
	VBoxGuestYetenek.Yetenek := 1 shl 2; //4;
	PortYaz4(VBPort, TSayi4(@VBoxGuestYetenek));

	VBoxOnayOlay.Baslik.Uzunluk := SizeOf(TVBoxOnayOlay);
	VBoxOnayOlay.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	VBoxOnayOlay.Baslik.IstekTipi := VMM_KONUK_ONAY_OLAY;
	VBoxOnayOlay.Baslik.RC := 0;
	VBoxOnayOlay.Baslik.Ayrildi1 := 0;
	VBoxOnayOlay.Baslik.Ayrildi2 := 0;
	VBoxOnayOlay.Olaylar := 0;
	//PortYaz4(VBPort, TSayi4(@VBoxOnayOlay));

	VBoxGoruntuDegisim.Baslik.Uzunluk := SizeOf(TVBoxGoruntuDegisim);
	VBoxGoruntuDegisim.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	VBoxGoruntuDegisim.Baslik.IstekTipi := VMM_KONUK_GORUNTU_DEGISIM;
	VBoxGoruntuDegisim.Baslik.RC := 0;
	VBoxGoruntuDegisim.Baslik.Ayrildi1 := 0;
	VBoxGoruntuDegisim.Baslik.Ayrildi2 := 0;
	VBoxGoruntuDegisim.XCozunurluk := 0;
	VBoxGoruntuDegisim.YCozunurluk := 0;
	VBoxGoruntuDegisim.BPP := 0;
	VBoxGoruntuDegisim.OlayOnay := 1;
	//PortYaz4(VBPort, TSayi4(@VBoxGoruntuDegisim));

  //PSayi4(Isaretci(VBBellek) + 04)^ := $FFFFFFFF;
  //PSayi4(Isaretci(VBBellek) + 08)^ := $FFFFFFFF;
  PSayi4(Isaretci(VBBellek + 12))^ := $FFFFFFFF;

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'VBoxGuestBilgi: %x', [TSayi4(@VBoxGuestBilgi)]);

{  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 0)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 4)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 8)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 12)^]);
}
//  asm int $25 end;
end;

procedure IcerigiGoruntule;
begin

	VBoxFare.Baslik.Uzunluk := SizeOf(TVBoxFare);
	VBoxFare.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	VBoxFare.Baslik.IstekTipi := VMM_FARE_DURUMAL;
	VBoxFare.Baslik.RC := 0;
	VBoxFare.Baslik.Ayrildi1 := 0;
	VBoxFare.Baslik.Ayrildi2 := 0;
	VBoxFare.Ozellikler := $16 + $1;
	VBoxFare.X := 0;
	VBoxFare.Y := 0;
	PortYaz4(VBPort, TSayi4(@VBoxFare));

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox X: %d', [VBoxFare.X]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Y: %d', [VBoxFare.Y]);

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 0)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 4)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 8)^]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 12)^]);
end;

procedure VBoxKesmeCagrisi;
begin

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'VBox Kesme Çaðrýsý: ', []);
end;

end.

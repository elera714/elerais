{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: vbox.pas
  Dosya Ýþlevi: virtualbox sanal aygýt yönetim iþlevlerini içerir

  Güncelleme Tarihi: 06/10/2024

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
  VBOX_ISTEK_BASLIK_SURUM     = $10001;

  VMM_FARE_DURUMAL            = 1;
  VMM_FARE_DURUMYAZ           = 2;
//  #define VMM_SetPointerShape 3
//  #define VMM_AcknowledgeEvents 41
  VMM_GUEST_BILGIAL           = 50;
//  #define VMM_GetDisplayChangeRequest 51
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

  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Yol: ', PCIAygit.Yol, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Aygýt: ', PCIAygit.Aygit, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Ýþlev: ', PCIAygit.Islev, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Satýcý Kimlik: ', PCIAygit.SaticiKimlik, 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Aygýt Kimlik: ', PCIAygit.AygitKimlik, 4);

  if((VBPort and 1) = 1) then
    SISTEM_MESAJ_S16(RENK_KIRMIZI, 'VBox Port: ', VBPort and $FFFFFFFC, 4)
  else SISTEM_MESAJ_S16(RENK_KIRMIZI, 'VBox Bellek: ', VBPort and $FFFFFFFC, 8);

  // 10. bitin 1 olmasý kesmenin pasif olduðu anlamýna gelir
  if(KesmeAktif and (1 shl 10) = 0) then
    SISTEM_MESAJ(RENK_KIRMIZI, 'INT Aktif', [])
  else SISTEM_MESAJ(RENK_KIRMIZI, 'INT Pasif', []);

  SISTEM_MESAJ_S16(RENK_KIRMIZI, 'Kesme No: ', VBKesmeNo, 2);

  // vbox kesmesini aktifleþtir
  IRQIsleviAta(VBKesmeNo, @VBoxKesmeCagrisi);
  IRQEtkinlestir(VBKesmeNo);

	VBoxGuestBilgi.Baslik.Uzunluk := SizeOf(TVBoxGuestBilgi);
	VBoxGuestBilgi.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	VBoxGuestBilgi.Baslik.IstekTipi := VMM_GUEST_BILGIAL;
	VBoxGuestBilgi.Baslik.RC := 0;
	VBoxGuestBilgi.Baslik.Ayrildi1 := 0;
	VBoxGuestBilgi.Baslik.Ayrildi2 := 0;
	VBoxGuestBilgi.Surum := VMMDEV_SURUM;
	VBoxGuestBilgi.ISType := 0;
	PortYaz4(VBPort, TSayi4(Isaretci(@VBoxGuestBilgi)));

	VBoxGuestYetenek.Baslik.Uzunluk := SizeOf(TVBoxGuestYetenek);
	VBoxGuestYetenek.Baslik.Surum := VBOX_ISTEK_BASLIK_SURUM;
	VBoxGuestYetenek.Baslik.IstekTipi := VMM_GUEST_YETENEKAL;
	VBoxGuestYetenek.Baslik.RC := 0;
	VBoxGuestYetenek.Baslik.Ayrildi1 := 0;
	VBoxGuestYetenek.Baslik.Ayrildi2 := 0;
	VBoxGuestYetenek.Yetenek := 4;
	PortYaz4(VBPort, TSayi4(Isaretci(@VBoxGuestYetenek)));

  PSayi4(Isaretci(VBBellek) + 12)^ := $FFFFFFFF;

  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 0)^]);
  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 4)^]);
  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 8)^]);
  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 12)^]);

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

  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox X: %d', [VBoxFare.X]);
  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Y: %d', [VBoxFare.Y]);

  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 0)^]);
  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 4)^]);
  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 8)^]);
  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Deðer: %x', [PSayi4(Isaretci(VBBellek) + 12)^]);
end;

procedure VBoxKesmeCagrisi;
begin

  SISTEM_MESAJ(RENK_KIRMIZI, 'VBox Kesme Çaðrýsý: ', []);
end;

end.

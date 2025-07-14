{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: uhci.pas
  Dosya Ýþlevi: usb uhci yönetim iþlevlerini içerir

  Güncelleme Tarihi: 10/05/2025

 ==============================================================================}
{$mode objfpc}
unit uhci;

interface

uses pci, paylasim;

const
  UHCI_YAZMAC_KOMUT		          = $0000;    // word
  UHCI_YAZMAC_DURUM		          = $0002;    // word
  UHCI_YAZMAC__IRQ		          = $0004;    // word
  UHCI_YAZMAC_CERCEVENO	        = $0006;    // word
  UHCI_YAZMAC_CERCEVEADRES	    = $0008;    // dword
  UHCI_YAZMAC_CERCEVEBASI	      = $000C;    // byte
  UHCI_YAZMAC__PORT1		        = $0010;    // word
  UHCI_YAZMAC__PORT2		        = $0012;    // word

  // UHCI komut yazmaçlarý
  UHCI_KOMUT_CALISTIR		        = $0001;
  UHCI_KOMUT_EVSAHIBINISIFIRLA  = $0002;
  UHCI_KOMUT_GENELSIFIRLA	      = $0004;

  // UHCI durum yazmacý
  UHCI_DURUM_DURDU		          = $0020;
  UHCI_DURUM_ISLEMHATASI	      = $0010;
  UHCI_DURUM_PCIHATASI		      = $0008;
  UHCI_DURUM_KESMEHATASI	      = $0002;
  UHCI_DURUM_IOC			          = $0001;

  // UHCI Port komut / durum
  UHCI_PORT_BAGLAN		          = $0001;
  UHCI_PORT_BAGLANTIDEGISIMI	  = $0002;
  UHCI_PORT_AKTIFLESTIR		      = $0004;
  UHCI_PORT_AKTIFDEGISTI		    = $0008;
  UHCI_PORT_AYGITHIZI		        = $0100;    // set = low speed; clear = high speed
  UHCI_PORT_SIFIRLA			        = $0200;
  UHCI_PORT_ASKIDA		          = $1000;

  // UHCI paket tip
  UHCI_PAKET_GIRIS			        = $69;
  UHCI_PAKET_CIKIS			        = $E1;
  UHCI_PAKET_AYAR		            = $2D;

  // UHCI açýklayýcý (descriptor) uzunluðu
  UHCI_TD_UZUNLUK			          = 32;

  USB_DURUMAL			              = $00;
  USB_OZELLIKTEMIZLE		        = $01;
  USB_OZELLIKBELIRLE			      = $03;
  USB_ADRESBELIRLE			        = $05;
  USB_ACIKLAYICIAL		          = $06;
  USB_ACIKLAYICIBELIRLE		      = $07;
  USB_YAPILANDIRMAAL		        = $08;
  USB_YAPILANDIRMABELIRLE		    = $09;
  USB_ARAYUZAL		              = $0A;
  USB_ARAYUZBELIRLE		          = $0B;
  USB_CERCEVEESZAMANLA			    = $0C;

type
  PUSBPaket = ^TUSBPaket;
  TUSBPaket = packed record
    IstekBayragi,
    Istek: TSayi1;
    Deger, Sira,
    Uzunluk: TSayi2;
  end;

var
  UHCIAygit: PPCI = nil;
  PortNo: TSayi2;
  UHCI_CERCEVE_ADRESI: TSayi4 = (14 * 1024 * 1024);

procedure Yukle(APCI: PPCI);
procedure UHCIAygitBilgileriniGoster;
procedure USBSifirla;
procedure PaketGonder;

implementation

uses sistemmesaj, port;

procedure Yukle(APCI: PPCI);
begin

  UHCIAygit := APCI;
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> USB:UHCI kontrol aygýtý bulundu...', []);
end;

procedure UHCIAygitBilgileriniGoster;
var
  _Deger4, i: TSayi4;
  _CerceveAdresi: PSayi4;
begin

  if not(UHCIAygit = nil) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'USB-UHCI Genel Bilgiler:', []);

    PortNo := PCIAygiti0.Oku4(UHCIAygit^.Yol, UHCIAygit^.Aygit, UHCIAygit^.Islev, $20) and $FFFC;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Giriþ/Çýkýþ Port No: $%.2x', [PortNo]);

    _Deger4 := PCIAygiti0.Oku4(UHCIAygit^.Yol, UHCIAygit^.Aygit, UHCIAygit^.Islev, 4);
    _Deger4 := _Deger4 or $405;
    PCIAygiti0.Yaz4(UHCIAygit^.Yol, UHCIAygit^.Aygit, UHCIAygit^.Islev, 4, _Deger4);

    _CerceveAdresi := PSayi4(UHCI_CERCEVE_ADRESI);
    for i := 0 to 1023 do
    begin

      _CerceveAdresi^ := 1;
      Inc(_CerceveAdresi);
    end;

    USBSifirla;

    PaketGonder;
  end;
end;

procedure USBSifirla;
var
  _Durum: TSayi2;
begin

	// uhci aygýtýný kapat
  PortYaz2(PortNo, 0);

  _Durum := 0;
  while _Durum = 0 do
  begin

    _Durum := PortAl2(PortNo + UHCI_YAZMAC_DURUM);
    _Durum := _Durum and UHCI_DURUM_DURDU;
  end;

  PortYaz2(PortNo, UHCI_KOMUT_GENELSIFIRLA);
	//call iowait

	//mov eax, 10
	//call pit_sleep

  PortYaz2(PortNo, 0);
	//call iowait

  PortYaz2(PortNo + UHCI_YAZMAC__IRQ, 0);
	//disable interrupts

	// reset the two ports
  PortYaz2(PortNo + UHCI_YAZMAC__PORT1, UHCI_PORT_SIFIRLA or UHCI_PORT_AKTIFLESTIR);
	//call iowait

	//mov eax, 10
	//call pit_sleep

  PortYaz2(PortNo + UHCI_YAZMAC__PORT1, UHCI_PORT_AKTIFLESTIR);
	//call iowait

  PortYaz2(PortNo + UHCI_YAZMAC__PORT2, UHCI_PORT_SIFIRLA or UHCI_PORT_AKTIFLESTIR);
	//call iowait

	//mov eax, 10
	//call pit_sleep

  PortYaz2(PortNo + UHCI_YAZMAC__PORT2, UHCI_PORT_AKTIFLESTIR);
	//call iowait

  PortYaz4(PortNo + UHCI_YAZMAC_CERCEVEADRES, UHCI_CERCEVE_ADRESI);

  PortYaz1(PortNo + UHCI_YAZMAC_CERCEVEBASI, $40);

  // max packet = 64 bytes
  PortYaz2(PortNo, $80);

  // clear status
  PortYaz2(PortNo + UHCI_YAZMAC_DURUM, $3F);
end;

procedure PaketGonder;
var
  USBPaket: TUSBPaket;
  _Durum: TSayi2;
  TamHiz: Boolean;    // full speed
begin

  USBPaket.IstekBayragi := $80;
  USBPaket.Istek := USB_ACIKLAYICIAL;
  USBPaket.Deger := 0;        // description
  USBPaket.Sira := 0;         // language
  USBPaket.Uzunluk := 0;      // data size

  PortYaz2(PortNo + UHCI_YAZMAC__PORT2, not UHCI_PORT_AKTIFLESTIR);

  PortYaz2(PortNo + UHCI_YAZMAC__PORT1, UHCI_PORT_AKTIFLESTIR);

	//mov eax, 5
	//call pit_sleep

  _Durum := PortAl2(PortNo + UHCI_YAZMAC__PORT1);
  if((_Durum and UHCI_PORT_BAGLAN) = 0) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Baðlantý yok', []);
  end
  else
  begin

    if((_Durum and UHCI_PORT_AYGITHIZI) = 0) then
    begin

      TamHiz := True;
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Tam hýz', []);
    end
    else
    begin

      TamHiz := False;
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Düþük hýz', []);
    end;
  end;
end;

end.

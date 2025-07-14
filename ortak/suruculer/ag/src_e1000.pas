{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_e1000.pas
  Dosya Ýþlevi: intel e1000 að (network) sürücüsü

  Güncelleme Tarihi: 10/05/2025

 ==============================================================================}
{$mode objfpc}
unit src_e1000;

interface

uses paylasim, pci;

const
  REG_CTRL      = $0000;    // aygýt kontrol
  REG_STATUS          = $0008;    // aygýt durumu
  REG_EEPROM   = $0014;    // eeprom okuma
  REG_IMASK = $00D0;    // kesme maskesi okuma / yazma
  REG_ICR   = $00C0;    // kesme okuma
  REG_RXDESCTAIL      = $2818;

  ECTRL_SLU     = $40;      // baðlantýyý baþlat

  E1000_NUM_TX_DESC       =       8;
  E1000_NUM_RX_DESC       =       32;

  //REG_CTRL        = $0000;
  //REG_STATUS      = $0008;
  //REG_EEPROM      = $0014;
  REG_CTRL_EXT    = $0018;
  //REG_IMASK       = $00D0;
  REG_RCTRL       = $0100;
  REG_RXDESCLO    = $2800;
  REG_RXDESCHI    = $2804;
  REG_RXDESCLEN   = $2808;
  REG_RXDESCHEAD  = $2810;
  //REG_RXDESCTAIL  = $2818;

  REG_TCTRL       = $0400;
  REG_TXDESCLO    = $3800;
  REG_TXDESCHI    = $3804;
  REG_TXDESCLEN   = $3808;
  REG_TXDESCHEAD  = $3810;
  REG_TXDESCTAIL  = $3818;

  RCTL_EN                 =       (1 SHL 1);    // Receiver Enable
  RCTL_SBP                =       (1 SHL 2);    // Store Bad Packets
  RCTL_UPE                =       (1 SHL 3);    // Unicast Promiscuous Enabled
  RCTL_MPE                =       (1 SHL 4);    // Multicast Promiscuous Enabled
  RCTL_LPE                =       (1 SHL 5);    // Long Packet Reception Enable
  RCTL_LBM_NONE           =       (0 SHL 6);    // No Loopback
  RCTL_LBM_PHY            =       (3 SHL 6);    // PHY or external SerDesc loopback
  RTCL_RDMTS_HALF         =       (0 SHL 8);    // Free Buffer Threshold is 1/2 of RDLEN
  RTCL_RDMTS_QUARTER      =       (1 SHL 8);    // Free Buffer Threshold is 1/4 of RDLEN
  RTCL_RDMTS_EIGHTH       =       (2 SHL 8);    // Free Buffer Threshold is 1/8 of RDLEN
  RCTL_MO_36              =       (0 SHL 12);   // Multicast Offset - bits 47:36
  RCTL_MO_35              =       (1 SHL 12);   // Multicast Offset - bits 46:35
  RCTL_MO_34              =       (2 SHL 12);   // Multicast Offset - bits 45:34
  RCTL_MO_32              =       (3 SHL 12);   // Multicast Offset - bits 43:32
  RCTL_BAM                =       (1 SHL 15);   // Broadcast Accept Mode
  RCTL_VFE                =       (1 SHL 18);   // VLAN Filter Enable
  RCTL_CFIEN              =       (1 SHL 19);   // Canonical Form Indicator Enable
  RCTL_CFI                =       (1 SHL 20);   // Canonical Form Indicator Bit Value
  RCTL_DPF                =       (1 SHL 22);   // Discard Pause Frames
  RCTL_PMCF               =       (1 SHL 23);   // Pass MAC Control Frames
  RCTL_SECRC              =       (1 SHL 26);   // Strip Ethernet CRC

  // Buffer Sizes
  RCTL_BSIZE_256          =       (3 SHL 16);
  RCTL_BSIZE_512          =       (2 SHL 16);
  RCTL_BSIZE_1024         =       (1 SHL 16);
  RCTL_BSIZE_2048         =       (0 SHL 16);
  RCTL_BSIZE_4096         =       ((3 SHL 16) OR (1 SHL 25));
  RCTL_BSIZE_8192         =       ((2 SHL 16) OR (1 SHL 25));
  RCTL_BSIZE_16384        =       ((1 SHL 16) OR (1 SHL 25));

  // Transmit Command
  CMD_EOP                 =       (1 SHL 0);    // End of Packet
  CMD_IFCS                =       (1 SHL 1);    // Insert FCS
  CMD_IC                  =       (1 SHL 2);    // Insert Checksum
  CMD_RS                  =       (1 SHL 3);    // Report Status
  CMD_RPS                 =       (1 SHL 4);    // Report Packet Sent
  CMD_VLE                 =       (1 SHL 6);    // VLAN Packet Enable
  CMD_IDE                 =       (1 SHL 7);    // Interrupt Delay Enable

  // TCTL Register
  TCTL_EN                 =       (1 SHL 1);    // Transmit Enable
  TCTL_PSP                =       (1 SHL 3);    // Pad Short Packets
  TCTL_CT_SHIFT           =       4;            // Collision Threshold
  TCTL_COLD_SHIFT         =       12;           // Collision Distance
  TCTL_SWXOFF             =       (1 SHL 22);   // Software XOFF Transmission
  TCTL_RTLC               =       (1 SHL 24);   // Re-transmit on Late Collision

  TSTA_DD                 =       (1 SHL 0);    // Descriptor Done
  TSTA_EC                 =       (1 SHL 1);    // Excess Collisions
  TSTA_LC                 =       (1 SHL 2);    // Late Collision
  LSTA_TU                 =       (1 SHL 3);    // Transmit Underrun

type
  PE1000_tx_desc = ^TE1000_tx_desc;
  TE1000_tx_desc = bitpacked record
      address : uint64;
      length  : uint16;
      cso     : uint8;
      cmd     : uint8;
      status  : uint8;
      css     : uint8;
      special : uint16;
  end;

type
    PE1000_rx_desc = ^TE1000_rx_desc;
    TE1000_rx_desc = packed record
        address  : uint64;
        length   : uint16;
        checksum : uint16;
        status   : uint8;
        errors   : uint8;
        special  : uint16;
    end;

type
  TAygit = packed record
    Yol, Aygit,
    Islev: TSayi1;
    PortDegeri: TSayi2;
    BellekDegeri: TSayi4;
    IRQNo: TSayi1;
    CipSurum: TSayi4;
    CipAdi: PChar;
    MACAdres: TMACAdres;
  end;

var
  AygitBilgisi: TAygit;
  EEPROMVar: Boolean;
  tx_descs : array[0..E1000_NUM_TX_DESC-1] of TE1000_tx_desc;
  rx_descs : array[0..E1000_NUM_RX_DESC-1] of PE1000_rx_desc;
  rx_buffs : array[0..E1000_NUM_RX_DESC-1] of puint8;
  GidisSiraNo, GelisSiraNo: TSayi4;

function Yukle(APCI: PPCI): TISayi4;
procedure KomutGonder(AAdres, AKomut: TSayi4);
function VeriOku(AAdres: TSayi4): TSayi4;
procedure BitAktiflestir(AAdres, ADeger: TSayi4);
procedure BitPasiflestir(AAdres, ADeger: TSayi4);
function EEPROMVarMi: Boolean;
procedure MACAdresiAl;
procedure KesmeAktiflestir;
procedure BaglantiyiBaslat;
procedure KesmeIslevi;
procedure VeriAl1;
procedure rxinit;
procedure txinit;
procedure DMAErisiminiAktiflestir(APCI: PPCI);

implementation

uses port, irq, genel, sistemmesaj;

{==============================================================================
  intel e1000 að sürücü yükleme iþlevlerini içerir
 ==============================================================================}
function Yukle(APCI: PPCI): TISayi4;
var
  i: Integer;
begin

  // çýkýþ öndeðeri
  Result := -1;

  // çekirdeðin gönderdiði pci aygýt bilgilerini hedef bölgeye kopyala
  AygitBilgisi.Yol := APCI^.Yol;
  AygitBilgisi.Aygit := APCI^.Aygit;
  AygitBilgisi.Islev := APCI^.Islev;

  EEPROMVar := False;

  // aygýt port deðerini al
  AygitBilgisi.PortDegeri := PCIAygiti0.IlkPortDegeriniAl(APCI);
  if(AygitBilgisi.PortDegeri = 0) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'E1000 ethernet port deðeri alýnamýyor!', []);
    Exit;
  end;

  // aygýt bellek deðerini al
  AygitBilgisi.BellekDegeri := PCIAygiti0.IlkBellekDegeriniAl(APCI);
  if(AygitBilgisi.BellekDegeri = 0) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'E1000 ethernet bellek deðeri alýnamýyor!', []);
    Exit;
  end;

  // IRQ numarasýný al
  AygitBilgisi.IRQNo := PCIAygiti0.IRQNoAl(APCI);

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'E1000 aygýt bilgileri:', []);
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '----------------------', []);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Yol: %d', [APCI^.Yol]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Aygýt: %d', [APCI^.Aygit]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Ýþlev: %d', [APCI^.Islev]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Satýcý Kimlik: $%x', [APCI^.SaticiKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Aygýt Kimlik: $%x', [APCI^.AygitKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Port: $%x', [AygitBilgisi.PortDegeri]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Bellek: $%x', [AygitBilgisi.BellekDegeri]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 IRQ: %d', [AygitBilgisi.IRQNo]);

  EEPROMVar := EEPROMVarMi;
{  if(EEPROMVar) then
    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'EEPROM var', [])
  else SISTEM_MESAJ(mtBilgi, RENK_MOR, 'EEPROM yok', []);}

  // aygýtýn mac adresini al
  MACAdresiAl;

  // reset
  BitAktiflestir(REG_CTRL, 1 shl 26); //E1000_REG_CTRL_RST);

  BitAktiflestir(REG_CTRL, (1 shl 5) or (1 shl 6));
  BitPasiflestir(REG_CTRL, 1 shl 3);
  BitPasiflestir(REG_CTRL, 1 shl 31);
  BitPasiflestir(REG_CTRL, 1 shl 7);
  KomutGonder($0028, 0);
  KomutGonder($002c, 0);
  KomutGonder($0030,  0);
  KomutGonder($0170, 0);
  BitPasiflestir(REG_CTRL, 1 shl 30);



  for i:=0 to 64 - 1 do begin
      KomutGonder($4000 + (i * 4), 0);
  end;

//  DMAErisiminiAktiflestir(APCI);

  for i:=0 to 128 - 1 do begin
      KomutGonder($5200 + i * 4, 0);
  end;

  rxinit;
//  txinit;

  //IRQEtkinlestir(2);
  IRQIsleviAta(AygitBilgisi.IRQNo, @KesmeIslevi);

  BaglantiyiBaslat;

  // kesmeyi aktifleþtir
  KesmeAktiflestir;


end;

procedure KomutGonder(AAdres, AKomut: TSayi4);
begin

  PortYaz4(AygitBilgisi.PortDegeri + 0, AAdres);
  PortYaz4(AygitBilgisi.PortDegeri + 4, AKomut);
end;

function VeriOku(AAdres: TSayi4): TSayi4;
begin

  PortYaz4(AygitBilgisi.PortDegeri + 0, AAdres);
  Result := PortAl4(AygitBilgisi.PortDegeri + 4);
end;

procedure BitAktiflestir(AAdres, ADeger: TSayi4);
var
  Deger: TSayi4;
begin

  Deger := PortAl4(AAdres);
  PortYaz4(AAdres, ADeger or Deger);
end;

procedure BitPasiflestir(AAdres, ADeger: TSayi4);
var
  Deger: TSayi4;
begin

  Deger := PortAl4(AAdres);
  PortYaz4(AAdres, ADeger and not(Deger));
end;

function EEPROMVarMi: Boolean;
var
  i, j: TSayi4;
begin

  KomutGonder(REG_EEPROM, 1);

  for i := 0 to 1000 do
  begin

    j := VeriOku(REG_EEPROM);
    if((j and $10) <> 0) then Exit(True);
  end;

  Result := False;
end;

{==============================================================================
  aygýtýn mac adresini alýr
 ==============================================================================}
procedure MACAdresiAl;
var
  i, j, k: TSayi4;
begin

  k := 0;

  for i := 0 to 2 do
  begin

    KomutGonder(REG_EEPROM, (i shl 8) or 1);
    repeat
      j := VeriOku(REG_EEPROM);
    until (j and (1 shl 4)) <> 0;

    j := j shr 16;

    AygitBilgisi.MACAdres[k] := j;
    j := j shr 8;
    Inc(k);
    AygitBilgisi.MACAdres[k] := j;
    Inc(k);
  end;

  SISTEM_MESAJ_MAC(mtBilgi, RENK_MOR, 'E1000 MAC Adres: ', AygitBilgisi.MACAdres);
end;

{==============================================================================
  aygýtýn kesmesini aktifleþtirir
 ==============================================================================}
procedure KesmeAktiflestir;
begin
    KomutGonder(REG_IMASK, $1F6DC);
    KomutGonder(REG_IMASK, $FF and not(4));
    VeriOku(REG_ICR);
end;

{==============================================================================
  aygýtýn kesmesini aktifleþtirir
 ==============================================================================}
procedure BaglantiyiBaslat;
var
  i: TSayi4;
begin

  i := VeriOku(REG_CTRL);
  KomutGonder(REG_CTRL, i or ECTRL_SLU or ECTRL_SLU{ or ECTRL_ASDE or ECTRL_FD or ECTRL_100M or ECTRL_FRCSPD});

  KomutGonder($0028, 0);
  KomutGonder($002C, 0);
  KomutGonder($0030, 0);
  KomutGonder($0170, 0);
end;

procedure KesmeIslevi;
var
  Durum: TSayi4;
    data     : uint32;

begin

  KomutGonder($00D0, 1);

  Durum := VeriOku($C0);
  if((Durum and $04) = $04) then
  begin

    BaglantiyiBaslat
  end
  else if((Durum and $10) = $10) then
  begin

    //Good Threshold
  end
  else if((Durum and $80) > 0) then
  begin

    VeriAl1;
  end;


  //KomutGonder(REG_IMASK, 1);

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'E1000 kesme iþlevi', []);
end;

procedure VeriAl1;
var
  len: UInt16;
  old_cur: TSayi4;
  p: PE1000_rx_desc;
begin

  p := rx_descs[GelisSiraNo];
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'veri->status: %d', [p^.status]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'veri->len : %d', [p^.length]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'veri->address: %d', [p^.address]);

  rx_descs[GelisSiraNo]^.status:= 0;
  old_cur:= GelisSiraNo;
  GelisSiraNo := (GelisSiraNo + 1) mod E1000_NUM_RX_DESC;
  KomutGonder(REG_RXDESCTAIL, old_cur);

  {while (rx_descs[GelisSiraNo]^.status AND $1) > 0 do
  begin

    //buf:= rx_buffs[GelisSiraNo];
    len:= rx_descs[GelisSiraNo]^.length;

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'veri-u: %d', [len]);

    rx_descs[GelisSiraNo]^.status:= 0;
    old_cur:= GelisSiraNo;
    GelisSiraNo := (GelisSiraNo + 1) mod E1000_NUM_RX_DESC;
    KomutGonder(REG_RXDESCTAIL, old_cur);
  end;}
end;

procedure rxinit;
var
    ptr    : puint8;
    outptr : puint8;
    descs  : PE1000_rx_desc;
    i      : uint32;
    GelisHalkaBellekAdresi, p: Isaretci;

begin

  GelisHalkaBellekAdresi := GetMem(sizeof(TE1000_rx_desc) * E1000_NUM_RX_DESC + 16);
  p := GelisHalkaBellekAdresi;

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'p2 Bellek Adresi: $%x', [TSayi4(GelisHalkaBellekAdresi)]);

  for i := 0 to E1000_NUM_RX_DESC - 1 do
  begin

    rx_descs[i] := p;
    rx_descs[i]^.address := 10; //TSayi8(GetMem(8192));
    rx_descs[i]^.status := 0;
    p += sizeof(TE1000_rx_desc);

    //if(i < 3) then SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'p1 Bellek Adresi: $%x', [TSayi4(p)]);
  end;
  GelisSiraNo := 0;

  //KomutGonder(REG_TXDESCLO, 0);
  //KomutGonder(REG_TXDESCHI, 0);

  p := @rx_descs;
  KomutGonder(REG_RXDESCLO, TSayi4(GelisHalkaBellekAdresi));
  KomutGonder(REG_RXDESCHI, 0);

  KomutGonder(REG_RXDESCLEN, E1000_NUM_RX_DESC * 16); //sizeof(TE1000_rx_desc));

  KomutGonder(REG_RXDESCHEAD, 0);
  KomutGonder(REG_RXDESCTAIL, E1000_NUM_RX_DESC - 1);

{	KomutGonder($0028, $002C8001);
	KomutGonder($002c, $0100);
	KomutGonder($0030, $8808);
	KomutGonder($0170, $FFFF);  // fazladan eklendi }

  KomutGonder(REG_RCTRL, //RCTL_EN OR RCTL_SBP OR RCTL_UPE OR RCTL_MPE OR RCTL_LBM_NONE OR RTCL_RDMTS_HALF OR RCTL_BAM OR RCTL_SECRC OR RCTL_BSIZE_2048);
    (1 shl 1) or
    (1 shl 2) or
    (1 shl 3) or
    (1 shl 4) or
    (1 shl 15) or
    ((2 shl 16) or (1 shl 25)));

  //BitPasiflestir(REG_CTRL, (1 shl 16) or (1 shl 17));
  //BitAktiflestir(REG_CTRL, (1 shl 1));
end;

procedure txinit;
var
    ptr    : puint8;
    outptr : puint8;
    descs  : PE1000_rx_desc;
    i      : uint32;
    GidisHalkaBellekAdresi, p: Isaretci;

begin

  GidisHalkaBellekAdresi := GetMem(sizeof(TE1000_tx_desc) * E1000_NUM_TX_DESC + 16);
  p := GidisHalkaBellekAdresi;

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Bellek Adresi: $%x', [TSayi4(p)]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Bellek Adresi: $%x', [TSayi4(GidisHalkaBellekAdresi)]);

{  for i := 0 to E1000_NUM_TX_DESC - 1 do
  begin

    tx_descs[i] := p;
    tx_descs[i]^.address := $91000;
    tx_descs[i]^.cmd := 0;
    tx_descs[i]^.status:= TSTA_DD;
    p += sizeof(TE1000_tx_desc);
  end;}
  GidisSiraNo := 0;

  KomutGonder(REG_TXDESCLO, TSayi4(GidisHalkaBellekAdresi));
  KomutGonder(REG_TXDESCHI, 0);

  KomutGonder(REG_TXDESCLEN, E1000_NUM_TX_DESC * sizeof(TE1000_tx_desc));

  KomutGonder(REG_TXDESCHEAD, 0);
  KomutGonder(REG_TXDESCTAIL, E1000_NUM_TX_DESC - 1);

  KomutGonder(REG_RCTRL, TCTL_EN OR TCTL_PSP OR (15 SHL TCTL_CT_SHIFT) OR (64 SHL TCTL_COLD_SHIFT) OR TCTL_RTLC);

  //if (card_type = ct82577LM) OR (card_type = ctI217) then begin
      KomutGonder(REG_TCTRL, $3003F0FA);
      //KomutGonder(REG_TIPG, $0060200A);

end;

procedure DMAErisiminiAktiflestir(APCI: PPCI);
var
  Deger: TSayi2;
begin

  Deger := PCIAygiti0.Oku2(APCI^.Yol, APCI^.Aygit, APCI^.Islev, 4);
  if((Deger and 4) = 4) then Exit;
  PCIAygiti0.Yaz2(APCI^.Yol, APCI^.Aygit, APCI^.Islev, 4, (Deger and 4));
end;

end.

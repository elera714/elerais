{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_disket.pas
  Dosya Ýþlevi: disket aygýt sürücüsü

  Güncelleme Tarihi: 18/10/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit src_disket;
 
interface

{
  1.44 kapasiteli disket sürücü deðerleri

  kafa numarasý     : 00..01 = 2
  iz numarasý       : 00..79 = 80
  sektör numarasý   : 01..18 = 18
  sektör kapasitesi : 512 byte

  2 * 80 * 18 * 512 = 1474560 = 1.44
}

uses paylasim, port, fdepolama, aygit;

const
  USTSINIR_DISKETAYGIT = 2;

const
  DISKET_DURUM_YZMC_A       = $3F0;         // STATUS_REGISTER_A - durum yazmaç a - sadece okunur
  DISKET_DURUM_YZMC_B       = $3F1;         // STATUS_REGISTER_B - durum yazmaç b - sadece okunur
  DISKET_DJTL_CIKISYZMC     = $3F2;         // DIGITAL_OUTPUT_REGISTER - dijital çýkýþ yazmaç
  DISKET_TEYP_SURUCU_YZMC   = $3F3;         // TAPE_DRIVE_REGISTER - teyp sürücü yazmacý
  DISKET_ANADURUM_YZMC      = $3F4;         // MAIN_STATUS_REGISTER - ana durum yazmacý - sadece okunur
  DISKET_HIZ_SECIM_YZMC     = $3F4;         // DATARATE_SELECT_REGISTER - veri hýz, seçim yazmacý - sadece yazýlabilir
  DISKET_VERI_YZMC          = $3F5;         // DATA_FIFO - veri yazmacý
                         // = $3F6          // bilgi: ide aygýtlarý tarafýndan kullanýlýr
  DISKET_DJTL_GIRIS_YZMC    = $3F7;         // DIGITAL_INPUT_REGISTER - dijital giriþ yazmacý - sadece okunur
  DISKET_AYAR_KONTROL_YZMC  = $3F7;         // CONFIGURATION_CONTROL_REGISTER - ayar / kontrol yazmacý - sadece yazýlabilir

  DMA_BELLEKADRESI          = $8000;        // DMA veri transfer adresi
  DMA_OKU                   = $46;          // disket sürücü -> bellek
  DMA_YAZ                   = $4A;          // bellek -> disket sürücü

  // komutlar
  KOMUT_YENIDEN_KALIBREET   = 7;            // 0. sektöre konumlan
  KOMUT_KESME_ALGISI        = 8;            // son komutun sonuçlarýný al
  KOMUT_KONUMLAN            = 15;           // konumlanma komutu

{
  DISKET_DJTL_CIKISYZMC = $3F2 bit deðerleri
  ----------------------------------------------
  MOTD  - 7.bit   - 3. sürücü motoru aktif
  MOTC  - 6.bit   - 2. sürücü motoru aktif
  MOTB  - 5.bit   - 1. sürücü motoru aktif
  MOTA  - 4.bit   - 0. sürücü motoru aktif
  IRQ   - 3.bit   - irq ve dma aktif
  RESET - 2.bit   - 0 = sürücü sýfýrlama modunda, 1 = normal
  DSEL1 - 0,1.bit - sürücü seçimi

  DISKET_ANADURUM_YZMC = $3F4 bit deðerleri
  ----------------------------------------------
  RQM   - 7.bit  - = 1 = $3F5 portu (fifo) her 2 veri gönderimine hazýrdýr, = 0 = aygýt meþgul
  DIO   - 6.bit  - = 1 = okuma modu, = 0 = yazma modu
  NDMA  - 5.bit  - = 1 = pio modu etkin, = 0 = dma modu etkin
  CB    - 4.bit  - = 1 = denetleyici meþgul, = 0 = denetleyici boþta
  ACTD  - 3.bit  - = 1 = 3. sürücü adým hareketi (seeking) sürmekte
  ACTC  - 2.bit  - = 1 = 2. sürücü adým hareketi (seeking) sürmekte
  ACTB  - 1.bit  - = 1 = 1. sürücü adým hareketi (seeking) sürmekte
  ACTA	- 0.bit  - = 1 = 0. sürücü adým hareketi (seeking) sürmekte
}

var
  IRQ6Tetiklendi: Boolean;
  DURUM_ST0, DURUM_ST1,
  DURUM_ST2, DURUM_I,
  DURUM_K, DURUM_SN,
  DURUM_SU: TSayi1;

type
  TDisket = class(TFDAygiti)
  public
    // FIslemYapiliyor: sürücü ile ilgili (okuma / yazma vb) iþlemin yapýldýðýný belirtir
    // diðer iþlevler tarafýndan sürücü motorunun kapatýlmamasý içindir
    // True = sürücü iþlem yapmakta, False = sürücü boþta
    FIslemYapiliyor: Boolean;
    // motor Kapatma Bekleme süresi = 5 saniye
    // FMotorKBSuresi = 0 = motor kapalý
    // FIslemYapiliyor = False olduktan 5 saniye sonra motor kapatýlacaktýr
    FMotorKBSuresi: TSayi4;
    // disket sürücüsünün kafasýnýn bulunduðu son iz (track) numarasý
    FSonIzKonumu: TISayi1;

    constructor Create; override;
    function Oku(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
    function TekSektorOku(ASektorNo: TSayi4): TSayi4;
    function Yaz(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
    function TekSektorYaz(ASektorNo: TSayi4): TSayi4;
    procedure DMA2Yukle(AIslem: TSayi1);
    function KesmeGeldiMi: Boolean;
    procedure MotorAc;
    procedure MotorKapat;
    function VeriAl: TSayi1;
    function VeriYaz(ADeger: TSayi1): Boolean;
    function Konumlan0: Boolean;
    function Konumlan(AIz, AKafa: TSayi1): Boolean;
    procedure SektoruAyristir(ASektorNo: TSayi4; var AKafa, AIz, ASektor: TSayi1);
  end;

type
  TDisketAygitlari = class
  private
    FToplamAygit: TSayi4;
    FDisketAygitlari: array[0..USTSINIR_DISKETAYGIT - 1] of TDisket;
    function Al(ASiraNo: TISayi4): TDisket;
    procedure Yaz(ASiraNo: TISayi4; ADisket: TDisket);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Yukle;
    procedure DisketSurucuMotorunuKontrolEt;
    property DisketAygitlari[ASiraNo: TISayi4]: TDisket read Al write Yaz;
    property ToplamAygit: TSayi4 read FToplamAygit;
  end;

procedure IRQ6KesmeIslevi;

var
  GDisketAygitlari: TDisketAygitlari;

implementation

uses irq, zamanlayici, islevler, sistemmesaj;

{==============================================================================
  disket sürücü nesnesi ilk yükleme iþlevlerini içerir
 ==============================================================================}
constructor TDisket.Create;
begin

  inherited Create;

  FIslemYapiliyor := False;

  // 0 = motor kapalý
  FMotorKBSuresi := 0;

  FSonIzKonumu := -1;
end;

{==============================================================================
  disket sürücü sektör okuma iþlevi
 ==============================================================================}
function TDisket.Oku(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
var
  BellekAdresi: Isaretci;
  OkunacakSektorNo,
  OkunacakSektorSayisi, i: TSayi4;
begin

  asm pushad; pushfd; end;

  BellekAdresi := ABellekAdresi;
  OkunacakSektorNo := AIlkSektor;
  OkunacakSektorSayisi := ASektorSayisi;

  // motoru aç
  MotorAc;

  repeat

    // belirtilen sektörü oku
    // hata olmasý durumunda okuma iþlemini 3 kez tekrarla
    for i := 1 to 3 do
    begin

      Result := TekSektorOku(OkunacakSektorNo);
      if(Result = HATA_YOK) then Break;
    end;

    if(Result = HATA_YOK) then
    begin

      // okunan sektör içeriðini hedef bellek bölgesine kopyala
      Tasi2(Pointer(DMA_BELLEKADRESI), BellekAdresi, 512);

      // bir sonraki bellek bölgesini esapla
      BellekAdresi := BellekAdresi + 512;

      // okunacak bir sonraki sektörü belirle
      Inc(OkunacakSektorNo);

      // okunacak sektör sayýsýný 1 azalt
      Dec(OkunacakSektorSayisi);
    end;

  until (Result <> HATA_YOK) or (OkunacakSektorSayisi = 0);

  // iþlem tamamlandý
  FIslemYapiliyor := False;

  // 5 saniye sonra motoru kapat
  FMotorKBSuresi := GZamanlayicilar.FZamanlayiciSayaci + (5 * CALISMA_FREKANSI);

  asm popfd; popad; end;
end;

{==============================================================================
  disket sürücünden tek bir sektör okuma iþlemi gerçekleþtirir
 ==============================================================================}
function TDisket.TekSektorOku(ASektorNo: TSayi4): TSayi4;
var
  Kafa, Iz,
  Sektor: TSayi1;
begin

  // sektör numarasýný kafa, iz, sektor biçimine çevir
  SektoruAyristir(ASektorNo, Kafa, Iz, Sektor);

  // konumlanacaðýmýz iz þu anki iz ise kalibrasyon veya konumlanma iþlemi yapma
  if(FSonIzKonumu <> Iz) then
  begin

    if(Iz = 0) then
    begin

      // okuma kafasýný baþlangýç konumuna getir
      if(Konumlan0 = False) then Exit(HATA_SEKTOR_KONUM);
    end
    else
    begin

      // okuma kafasýný belirtilen ize konumlandýr
      if(Konumlan(Iz, Kafa) = False) then Exit(HATA_SEKTOR_KONUM);
    end;

    // deðiþkeni güncelle
    FSonIzKonumu := Iz;
  end;

  // irq bayraðýný pasifleþtir
  IRQ6Tetiklendi := False;

  // DMA2'yi aygýttan okuma için ayarla
  DMA2Yukle(DMA_OKU);

  // MFS sektör oku
  VeriYaz($E6);
  VeriYaz((Kafa shl 2) or FKanal);
  VeriYaz(Iz);
  VeriYaz(Kafa);
  VeriYaz(Sektor);
  VeriYaz(2);                // sektör uzunluðu = 128 * 2^x. (x=2) = 512
  VeriYaz(18);               // bir izdeki sektör sayýsý
  VeriYaz($1B);              // GAP3 standart deðer = 27
  VeriYaz($FF);              // sektör uzunluðu sýfýrdan farklý ise 0xff.

  // kesmenin gelmesini bekle
  if(KesmeGeldiMi) then
  begin

    // iþlem sonucunu oku
    DURUM_ST0 := VeriAl;      // DURUM_ST0
    DURUM_ST1 := VeriAl;      // DURUM_ST1
    DURUM_ST2 := VeriAl;      // DURUM_ST2
    DURUM_I := VeriAl;        // Ýz
    DURUM_K := VeriAl;        // Kafa
    DURUM_SN := VeriAl;       // Sektör No
    DURUM_SU := VeriAl;       // Sektör Uzunluðu

    if((DURUM_ST0 and %11011000) = 0) then Exit(HATA_YOK);
  end;

  Result := HATA_AYGITSEKTOROKUMA;
end;

{==============================================================================
  disket sürücü sektör yazma iþlevi
 ==============================================================================}
function TDisket.Yaz(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
var
  BellekAdresi: Isaretci;
  YazilacakSektorNo,
  YazilacakSektorSayisi, i: TSayi4;
begin

  asm pushad; pushfd; end;

  BellekAdresi := ABellekAdresi;
  YazilacakSektorNo := AIlkSektor;
  YazilacakSektorSayisi := ASektorSayisi;

  // motoru aç
  MotorAc;

  repeat

    // yazýlacak sektör içeriðini hedef bellek bölgesine kopyala
    Tasi2(BellekAdresi, Pointer(DMA_BELLEKADRESI), 512);

    // bir sonraki bellek bölgesini hesapla
    BellekAdresi := BellekAdresi + 512;

    // belirtilen sektörü yaz
    // hata olmasý durumunda yazma iþlemini 3 kez tekrarla
    for i := 1 to 3 do
    begin

      Result := TekSektorYaz(YazilacakSektorNo);
      if(Result = HATA_YOK) then Break;
    end;

    if(Result = HATA_YOK) then
    begin

      // yazýlacak bir sonraki sektörü belirle
      Inc(YazilacakSektorNo);

      // yazýlacak sektör sayýsýný 1 azalt
      Dec(YazilacakSektorSayisi);
    end;

  until (Result <> HATA_YOK) or (YazilacakSektorSayisi = 0);

  // iþlem tamamlandý
  FIslemYapiliyor := False;

  // 5 saniye sonra motoru kapat
  FMotorKBSuresi := GZamanlayicilar.FZamanlayiciSayaci + (5 * CALISMA_FREKANSI);

  asm popfd; popad; end;
end;

{==============================================================================
  disket sürücüsüne tek bir sektör yazma iþlemi gerçekleþtirir
 ==============================================================================}
function TDisket.TekSektorYaz(ASektorNo: TSayi4): TSayi4;
var
  Kafa, Iz,
  Sektor: TSayi1;
begin

  // sektör numarasýný kafa, iz, sektor biçimine çevir
  SektoruAyristir(ASektorNo, Kafa, Iz, Sektor);

  // konumlanacaðýmýz iz þu anki iz ise kalibrasyon veya konumlanma iþlemi yapma
  if(FSonIzKonumu <> Iz) then
  begin

    if(Iz = 0) then
    begin

      // yazma kafasýný baþlangýç konumuna getir
      if(Konumlan0 = False) then Exit(HATA_SEKTOR_KONUM);
    end
    else
    begin

      // yazma kafasýný belirtilen ize konumlandýr
      if(Konumlan(Iz, Kafa) = False) then Exit(HATA_SEKTOR_KONUM);
    end;

    // deðiþkeni güncelle
    FSonIzKonumu := Iz;
  end;

  // IRQ bayraðýný pasifleþtir
  IRQ6Tetiklendi := False;

  // DMA2'yi aygýta yazma için ayarla
  DMA2Yukle(DMA_YAZ);

  // MFS sektör yaz
  VeriYaz($45);
  VeriYaz((Kafa shl 2) or FKanal);
  VeriYaz(Iz);
  VeriYaz(Kafa);
  VeriYaz(Sektor);
  VeriYaz(2);             // sektör uzunluðu = 128 * 2^x. (x=2) = 512
  VeriYaz(18);            // bir izdeki sektör sayýsý
  VeriYaz(27);            // GAP3 standart deðer = 27
  VeriYaz($FF);           // sektör uzunluðu sýfýrdan farklý ise 0xff.

  // kesmenin gelmesini bekle
  if(KesmeGeldiMi) then
  begin

    // iþlem sonucunu oku
    DURUM_ST0 := VeriAl;      // DURUM_ST0
    DURUM_ST1 := VeriAl;      // DURUM_ST1
    DURUM_ST2 := VeriAl;      // DURUM_ST2
    DURUM_I := VeriAl;        // Ýz
    DURUM_K := VeriAl;        // Kafa
    DURUM_SN := VeriAl;       // Sektör No
    DURUM_SU := VeriAl;       // Sektör Uzunluðu

    if((DURUM_ST0 and %11011000) = 0) then Exit(HATA_YOK);
  end;

  Result := HATA_AYGITSEKTORYAZMA;
end;

{==============================================================================
  okuma / yazma iþlevi için DMA aygýtýný hazýrlar
 ==============================================================================}
procedure TDisket.DMA2Yukle(AIslem: TSayi1);
begin

  // flip-flop sýfýrla
  PortYaz1($0C, 0);

  // 2 nolu DMA kanalýný maskele
  // bilgi: 2 nolu DMA disket sürücüsüne sabitlenmiþtir
  PortYaz1($0A, 4 + 2);

  // DMA'nýn yapacaðý iþlevi belirle.
  PortYaz1($0B, AIslem);

  // flip-flop sýfýrla
  PortYaz1($0C, 0);

  // bellek adresini belirle
  PortYaz1($04, (DMA_BELLEKADRESI and $FF));
  PortYaz1($04, ((DMA_BELLEKADRESI shr 8) and $FF));
  PortYaz1($81, ((DMA_BELLEKADRESI shr 16) and $FF));

  // flip-flop sýfýrla
  PortYaz1($0C, 0);

  // iþlem (okuma / yazma) yapýlacak veri miktarý. $1FF = 511, $23FF = 9215
  PortYaz1($05, $FF);
  PortYaz1($05, $1);

  // 2 nolu DMA'yý aktifleþtir
  PortYaz1($0A, 2);
end;

{==============================================================================
  disket sürücüsü bekleme rutini
 ==============================================================================}
function TDisket.KesmeGeldiMi: Boolean;
var
  i: TSayi4;
begin

  Result := True;

  i := GZamanlayicilar.FZamanlayiciSayaci + (5 * CALISMA_FREKANSI);

  // þart true olduðu müddetçe devam et
  while (i > GZamanlayicilar.FZamanlayiciSayaci) do
  begin

    if(IRQ6Tetiklendi) then Exit;
    ElleGorevDegistir;
  end;

  Result := False;
end;

{==============================================================================
  disket sürücü motorunu çalýþtýrýr
 ==============================================================================}
procedure TDisket.MotorAc;
begin

  // eðer aygýt ile ilgili iþlem yapýlmakta ise çýk (motor zaten açýk)
  if(FIslemYapiliyor) then
  begin

    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'TDisket->Motor durumu zaten aktif!', []);
    Exit;
  end;

  // eðer aygýt ile ilgili iþlem tamamlanmýþ ve motorun kapanmasý için geri sayým
  // gerçekleþmekte ise geri sayým iþlemini iptal et
  FIslemYapiliyor := True;

  // motor açma iþlemlerini gerçekleþtir
  PortYaz1(DISKET_DJTL_CIKISYZMC, %00000000);

  // motor'u aç
  if(FKanal = 0) then
  begin

    PortYaz1(DISKET_DJTL_CIKISYZMC, %00011100);
    //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'TDisket->Motor1 açýldý...', []);
  end
  else
  begin

    PortYaz1(DISKET_DJTL_CIKISYZMC, %00101101);
    //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'TDisket->Motor2 açýldý...', []);
  end;

  // veri transfer hýzý = 500kbits/s
  // 0 = 500kbits/s
  // 1 = 300kbits/s
  // 2 = 250kbits/s
  // 3 - 1Mbits/s
  PortYaz1(DISKET_AYAR_KONTROL_YZMC, 0);
end;

{==============================================================================
  disket sürücü motorunu kapatýr
 ==============================================================================}
procedure TDisket.MotorKapat;
begin

  // motor'u kapat
  if(FKanal = 0) then
  begin

    PortYaz1(DISKET_DJTL_CIKISYZMC, %00001100);
    //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'TDisket->Motor1 kapatýldý...', []);
  end
  else
  begin

    PortYaz1(DISKET_DJTL_CIKISYZMC, %00001101);
    //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'TDisket->Motor2 kapatýldý...', []);
  end;
end;

{==============================================================================
  disket sürücü denetleyicisinden veri alma iþlevi
 ==============================================================================}
function TDisket.VeriAl: TSayi1;
var
  i: TSayi4;
begin

  Result := 0;

  // RQM = 1, DIO = 1 þartý aranmakta
  for i := 1 to $1000 do
  begin

    if((PortAl1(DISKET_ANADURUM_YZMC) and %11000000) = %11000000) then
    begin

      Result := PortAl1(DISKET_VERI_YZMC);
      Exit;
    end;
  end;

  //SISTEM_MESAJ(mtHata, RENK_SIYAH, 'TDisket->DurumOku zaman aþýmý', []);
end;

{==============================================================================
  disket sürücü denetleyicisine veri yazma iþlevi
 ==============================================================================}
function TDisket.VeriYaz(ADeger: TSayi1): Boolean;
var
  i: TSayi4;
begin

  Result := False;

  for i := 1 to $1000 do
  begin

    // RQM = 1, DIO = 0 þartý aranmakta
    if((PortAl1(DISKET_ANADURUM_YZMC) and %11000000) = %10000000) then
    begin

      PortYaz1(DISKET_VERI_YZMC, ADeger);
      Exit(True);
    end;
  end;

  //SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'TDisket->DurumYaz zaman aþýmý', []);
end;

{==============================================================================
  disket okuma kafasýný baþlangýç konumuna (0. sektör) getirir (calibrate)
 ==============================================================================}
function TDisket.Konumlan0: Boolean;
begin

  Result := True;

  // irq bayraðýný pasifleþtir
  IRQ6Tetiklendi := False;

  VeriYaz(KOMUT_YENIDEN_KALIBREET);       // 0. sektöre konumlan
  VeriYaz(FKanal);                        // kafa no (0) + sürücü

  // iþlemin bitmesini bekle
  if(KesmeGeldiMi) then
  begin

    // iþlem sonucunu test et (sensei)
    VeriYaz(KOMUT_KESME_ALGISI);
    DURUM_ST0 := VeriAl;
    VeriAl;

    if((DURUM_ST0 and %11100000) = %00100000) then Exit;
  end;

  Result := False;
end;

{==============================================================================
  disket okuma kafasýný belirtilen iz'e (track) konumlandýrýr
 ==============================================================================}
function TDisket.Konumlan(AIz, AKafa: TSayi1): Boolean;
begin

  // istenen iz konumu ile son iz konumu ayný ise çýk
  if(FSonIzKonumu = AIz) then Exit(True);

  Result := True;

  // irq bayraðýný pasifleþtir
  IRQ6Tetiklendi := False;

  VeriYaz(KOMUT_KONUMLAN);                // sektöre Konumlan
  VeriYaz((AKafa shl 2) or FKanal);       // kafa no + sürücü
  VeriYaz(AIz);

  // iþlemin bitmesini bekle
  if(KesmeGeldiMi) then
  begin

    // iþlem sonucunu test et (sensei)
    VeriYaz(KOMUT_KESME_ALGISI);
    DURUM_ST0 := VeriAl;
    VeriAl;

    if((DURUM_ST0 and %11100000) = %00100000) then Exit;
  end;

  Result := False;
end;

{==============================================================================
  disket aygýtlarý nesne ilk yükleme iþlevlerini içerir
 ==============================================================================}
constructor TDisketAygitlari.Create;
var
  i: TSayi4;
begin

  FToplamAygit := 0;

  for i := 0 to USTSINIR_DISKETAYGIT - 1 do DisketAygitlari[i] := nil;
end;

{==============================================================================
  disket aygýtlarý nesne yok etme iþlevlerini içerir
 ==============================================================================}
destructor TDisketAygitlari.Destroy;
begin

  inherited Destroy;
end;

function TDisketAygitlari.Al(ASiraNo: TISayi4): TDisket;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DISKETAYGIT) then
    Result := FDisketAygitlari[ASiraNo]
  else Result := nil;
end;

procedure TDisketAygitlari.Yaz(ASiraNo: TISayi4; ADisket: TDisket);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DISKETAYGIT) then
    FDisketAygitlari[ASiraNo] := ADisket;
end;

{==============================================================================
  sistemde mevcut disket aygýtlarýný yükler
 ==============================================================================}
procedure TDisketAygitlari.Yukle;
var
  FD: TFDAygiti;
  i, j: TSayi1;
begin

  // cmos'tan disket sürücü bilgilerini al
  PortYaz1($70, $10);
  i := PortAl1($71);

  PDisket1 := nil;
  PDisket2 := nil;

  // eðer herhangi bir disket sürücüsü var ise
  if(i > 0) then
  begin

  { -----------------------------------
    i = Sürücü Tip = AAAABBBB
    AAAA = birinci sürücü, BBBB = ikinci sürücü
    ===================================
    0	  sürücü yok
    1	  5.25" 320K veya 360K
    2	  5.25" 1.2M
    3	  3.5"  720K
    4	  3.5"  1.44M
    5	  3.5"  2.88M
    ----------------------------------}

    // birincil sürücü (master)
    j := ((i shr 4) and $F);
    if(j > 0) then
    begin

      FD := GFizikselDepolama.AygitOlustur(SURUCUTIP_DISKET);
      if(FD <> nil) then
      begin

        FD.FAnaPort := $3F0;
        FD.FKanal := 0;
        FD.FOku := @TDisket(FD).Oku;
        FD.FYaz := @TDisket(FD).Yaz;

        TDisket(FD).FOzellikler := j;
        TDisket(FD).FSonIzKonumu := -1;

        FD.FSilindirSayisi := 18;
        FD.FKafaSayisi := 2;
        FD.FIzBasinaSektorSayisi := 80;
        FD.FToplamSektorSayisi := 18 * 2 * 80;

        PDisket1 := FD;
      end;
    end;

    // ikincil sürücü (slave)
    j := (i and $F);
    if(j > 0) then
    begin

      FD := GFizikselDepolama.AygitOlustur(SURUCUTIP_DISKET);
      if(FD <> nil) then
      begin

        FD.FAnaPort := $3F0;
        FD.FKanal := 1;
        FD.FOku := @TDisket(FD).Oku;
        FD.FYaz := @TDisket(FD).Yaz;

        TDisket(FD).FOzellikler := j;
        TDisket(FD).FSonIzKonumu := -1;

        FD.FSilindirSayisi := 18;
        FD.FKafaSayisi := 2;
        FD.FIzBasinaSektorSayisi := 80;
        FD.FToplamSektorSayisi := 18 * 2 * 80;

        PDisket2 := FD;
      end;
    end;

    // öndeðerler atanýyor
    IRQ6Tetiklendi := False;

    // disket sürücüsü için irq istek kanalýný etkinleþtir
    IRQIsleviAta(6, @IRQ6KesmeIslevi);
  end;
end;

{==============================================================================
  disket sürücü motorunun otomatik kapanmasýný saðlayan rutin
  bilgi: iþlev çekirdek tarafýndan çaðrýlýr
 ==============================================================================}
procedure TDisketAygitlari.DisketSurucuMotorunuKontrolEt;
var
  Disket: TDisket;
begin

  // birinci disket sürücüsü
  if(PDisket1 <> nil) then
  begin

    Disket := TDisket(PDisket1);

    if(Disket.FIslemYapiliyor = False) and (Disket.FMotorKBSuresi > 0) then
    begin

      if((Disket.FMotorKBSuresi) < GZamanlayicilar.FZamanlayiciSayaci) then
      begin

        Disket.MotorKapat;
        Disket.FMotorKBSuresi := 0;
      end;
    end;
  end;

  // ikinci disket sürücüsü
  if(PDisket2 <> nil) then
  begin

    Disket := TDisket(PDisket2);

    if(Disket.FIslemYapiliyor = False) and (Disket.FMotorKBSuresi > 0) then
    begin

      if((Disket.FMotorKBSuresi ) < GZamanlayicilar.FZamanlayiciSayaci) then
      begin

        Disket.MotorKapat;
        Disket.FMotorKBSuresi := 0;
      end;
    end;
  end;
end;

{==============================================================================
  sektör numarasýný; kafa, iz, sektör numarasý biçimine çevirir
 ==============================================================================}
procedure TDisket.SektoruAyristir(ASektorNo: TSayi4; var AKafa, AIz, ASektor: TSayi1);
var
  i: TSayi2;
begin

  AIz := (ASektorNo div 36);
  i := (ASektorNo mod 36);
  AKafa := (i div 18);
  ASektor := (i mod 18) + 1;
end;

{==============================================================================
  IRQ istek çaðrýlarýnýn yönlendirildiði iþlev
 ==============================================================================}
procedure IRQ6KesmeIslevi;
begin

  { TODO : IRQ6KesmeIslevi her iki floppy sürücüsüne göre ayarlanacaktýr }
  IRQ6Tetiklendi := True;

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IRQ6Tetiklendi', []);
end;

end.

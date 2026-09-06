{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_disket.pas
  Dosya Ýþlevi: disket aygýt sürücüsü

  Güncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit src_disket;
 
interface
{

  1.44 kapasiteli sürücünün deðerleri

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
  DISKET_TEMEL          = $3F0;       // base addres
  DISKET_CIKISYAZMAC    = $3F2;       // digital output register
  DISKET_ANADURUMYAZMAC = $3F4;       // main status register
  DISKET_HIZSECIMYAZMAC = $3F4;       // data rate select register
  DISKET_VERI           = $3F5;       // data register
  DISKET_GIRISYAZMAC    = $3F7;       // digital input register
  DISKET_AYARYAZMAC     = $3F7;       // configuration control register

  DMA_BELLEKADRESI      = $8000;      // DMA'nýn veri transfer adresi
  DMA_OKU               = $46;        // fdc->mem
  DMA_YAZ               = $4A; //8;        // mem->fdc

var
  IRQ6Tetiklendi: Boolean;
  DURUM0, DURUM1, DURUM2: TSayi1;

type
  TDisket = class(TFDAygiti)
  public
    FIslemYapiliyor: Boolean;         // True = sürücü iþlem yapmakta, False = sürücü boþta
    FMotorBeklemeSuresi: TSayi4;      // motor kapatma geri sayým sayacý (þu an sadece floppy sürücüsü için, 3 saniye)
    FSonIzKonumu: TISayi1;            // floppy sürücüsünün kafasýnýn bulunduðu son iz (track) no

    constructor Create; override;

    function Oku(AIlkSektor, ASektorSayisi: TSayi4; AHedefBellek: Isaretci): TISayi4;
    function Yaz(AIlkSektor, ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
    function TekSektorOku(ASektorNo: TSayi4): Boolean;
    function TekSektorYaz(ASektorNo: TSayi4): Boolean;

    procedure MotorAc;
    procedure MotorKapat;
    function DurumOku: TSayi1;
    procedure DurumYaz(ADeger: TSayi1);
    function Konumlan0(AFDAygiti: TFDAygiti): Boolean;
    function Konumlan(AFDAygiti: TFDAygiti; AIz, AKafa: TSayi1): Boolean;
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
    procedure VeritabaniOlustur;
    property DisketAygitlari[ASiraNo: TISayi4]: TDisket read Al write Yaz;
    property ToplamAygit: TSayi4 read FToplamAygit;
  end;

procedure DMA2Yukle(Op: Byte);
function Bekle: Boolean;
procedure IRQ6KesmeIslevi;
procedure DisketSurucuMotorunuKontrolEt;
procedure SektoruAyristir(ASektorNo: TSayi2; var AKafa, AIz, ASektor: TSayi1);

var
  GDisketAygitlari: TDisketAygitlari;

implementation

uses irq, zamanlayici, islevler, sistemmesaj;

constructor TDisketAygitlari.Create;
var
  i: TSayi4;
begin

  FToplamAygit := 0;

  for i := 0 to USTSINIR_DISKETAYGIT - 1 do DisketAygitlari[i] := nil;
end;

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

procedure TDisketAygitlari.VeritabaniOlustur;
var
  FD: TFDAygiti;
  i, j: TSayi1;
begin

  // CMOS'tan disket sürücü bilgilerini al
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
  disket sürücü ilk yükleme iþlevlerini içerir
 ==============================================================================}
constructor TDisket.Create;
begin

  inherited Create;

  FIslemYapiliyor := False;

  // 0 = motor kapalý
  FMotorBeklemeSuresi := 0;

  FSonIzKonumu := -1;
end;

{==============================================================================
  disket sürücü motorunu çalýþtýrýr
 ==============================================================================}
procedure TDisket.MotorAc;
begin

  // eðer aygýt ile ilgili iþlem yapýlmakta ise çýk (motor zaten açýk)
  if(FIslemYapiliyor) then
  begin

    //SISTEM_MESAJ(RENK_KIRMIZI, 'Disket->MotorAc durumu zaten aktif 1', []);
    Exit;
  end;

  // eðer aygýt ile ilgili iþlem tamamlanmýþ ve motorun kapanmasý için geri sayým
  // gerçekleþmekte ise geri sayým iþlemini iptal et
  if(FIslemYapiliyor = False) then
  begin

    FIslemYapiliyor := True;

    // motor açma iþlemlerini gerçekleþtir
    PortYaz1(DISKET_CIKISYAZMAC, 0);

    // motor'u aç
    if(FKanal = 0) then
    begin

      PortYaz1(DISKET_CIKISYAZMAC, $1C);
      //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Disket1->Motor açýldý...', []);
    end
    else
    begin

      PortYaz1(DISKET_CIKISYAZMAC, $2D);
      //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Disket2->Motor açýldý...', []);
    end;

    // CCR = 500kbits/s
    //PortYaz1(DISKET_AYARYAZMAC, 0);

    // BekleMS(150);
  end;
end;

{==============================================================================
  disket sürücü motorunu durdurur
 ==============================================================================}
procedure TDisket.MotorKapat;
begin

  // motor'u kapat
  if(FKanal = 0) then
  begin

    PortYaz1(DISKET_CIKISYAZMAC, $C);
    //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Disket1->Motor kapatýldý...', []);
  end
  else
  begin

    PortYaz1(DISKET_CIKISYAZMAC, $5);
    //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Disket2->Motor kapatýldý...', []);
  end;
end;

{==============================================================================
  okuma / yazma iþlevi için DMA aygýtýný hazýrlar
 ==============================================================================}
procedure DMA2Yukle(Op: Byte);
begin

  // FLIP-FLOP sýfýrla
  PortYaz1($C, 0);

  // 2 nolu DMA kanalýný maskele
  PortYaz1($A, 4 + 2);

  // DMA'nýn yapacaðý iþlevi belirle. oku/yaz. +2 = dma kanalý
  PortYaz1($B, Op);

  // FLIP-FLOP sýfýrla
  PortYaz1($C, 0);

  // bellek adresini belirle
  PortYaz1(4, (DMA_BELLEKADRESI and $FF));
  PortYaz1(4, ((DMA_BELLEKADRESI shr 8) and $FF));
  PortYaz1($81, ((DMA_BELLEKADRESI shr 16) and $FF));

  // FLIP-FLOP sýfýrla
  PortYaz1($C, 0);

  // iþlem (okuma / yazma) yapýlacak veri miktarý. $1FF = 511
  PortYaz1(5, $FF);
  PortYaz1(5, $1);

  // 2 nolu DMA'yý aktifleþtir
  PortYaz1($A, 2);
end;

{==============================================================================
  disket sürücü denetleyicisinden bilgi alma iþlevi
 ==============================================================================}
function TDisket.DurumOku: TSayi1;
var
  i: TSayi4;
begin

  for i := 1 to $10000 do
  begin

    if((PortAl1(DISKET_ANADURUMYAZMAC) and $C0) = $C0) then   // MRQ=1, DIO=1
    begin

      Result := PortAl1(DISKET_VERI);
      Exit;
    end;
  end;

  //SISTEM_MESAJ(mtHata, RENK_SIYAH, 'Disket->DurumOku zaman aþýmý', []);
end;

{==============================================================================
  disket sürücü denetleyicisine bilgi gönderme iþlevi
 ==============================================================================}
procedure TDisket.DurumYaz(ADeger: TSayi1);
var
  i: TSayi4;
begin

  for i := 1 to $10000 do
  begin

    if((PortAl1(DISKET_ANADURUMYAZMAC) and $C0) = $80) then   // $80 = MRQ=1
    begin

      PortYaz1(DISKET_VERI, ADeger);
      Exit;
    end;
  end;

  //SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'Disket->DurumYaz zaman aþýmý', []);
end;

{==============================================================================
  disket sürücüsü bekleme rutini
 ==============================================================================}
function Bekle: Boolean;
var
  i: TSayi4;
begin

  Bekle := True;

  // kesme tetiklenmedi durumuna getiriliyor
  IRQ6Tetiklendi := False;

  i := GZamanlayicilar.FZamanlayiciSayaci + (2 * CALISMA_FREKANSI);

  // þart true olduðu müddetçe devam et
  while (i > GZamanlayicilar.FZamanlayiciSayaci) do
  begin

    if(IRQ6Tetiklendi) then Exit;
    ElleGorevDegistir;
  end;

  Bekle := False;
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

{==============================================================================
  disket okuma kafasýný baþlangýç konumuna (0. sektör) getirir (calibrate)
 ==============================================================================}
function TDisket.Konumlan0(AFDAygiti: TFDAygiti): Boolean;
var
  _Iz: TSayi1;
begin

  // irq bayraðýný pasifleþtir
  IRQ6Tetiklendi := False;

  DurumYaz(7);                                      // Konumlan0
  DurumYaz(AFDAygiti.FKanal);                  // kafa no (0) + sürücü

  // iþlemin bitmesini bekle
  Bekle;

  // iþlem sonucunu test et (sensei)
  DurumYaz(8);
  DURUM0 := DurumOku;
  _Iz := DurumOku;

  if(DURUM0 = $20) then
  begin

    if(_Iz = 0) then Exit(True);
  end;

  Result := False;
end;

{==============================================================================
  floppy okuma kafasýný belirtilen iz'e (track) konumlandýrýr
 ==============================================================================}
function TDisket.Konumlan(AFDAygiti: TFDAygiti; AIz, AKafa: TSayi1): Boolean;
var
  _Iz: TSayi1;
begin

  //if(MevcutIz = AIz) then Exit(True);

  // irq bayraðýný pasifleþtir
  IRQ6Tetiklendi := False;

  DurumYaz($F);                                                   // Konumlan
  DurumYaz((AKafa shl 2) or AFDAygiti.FKanal);               // kafa no + sürücü
  DurumYaz(AIz);

  // iþlemin bitmesini bekle
  Bekle;

  // iþlem sonucunu test et (sensei)
  DurumYaz(8);
  DURUM0 := DurumOku;
  _Iz := DurumOku;

  if(DURUM0 = $20) then
  begin

    if(_Iz = AIz) then Exit(True);
  end;

  Result := False;
end;

{==============================================================================
  disket sürücü motorunun otomatik kapanmasýný saðlayan rutin
 ==============================================================================}
procedure DisketSurucuMotorunuKontrolEt;
begin

  // birinci floppy sürücüsü
  if(PDisket1 <> nil) then
  begin

    // motor çalýþma durumlarý
    // ======================================
    // 0 = motor kapalý
    // 1..4 = motor kapanma durumunda
    // 5 = motor açýk

    if(TDisket(PDisket1).FIslemYapiliyor = False) and (TDisket(PDisket1).FMotorBeklemeSuresi > 0) then
    begin

      if((TDisket(PDisket1).FMotorBeklemeSuresi) < GZamanlayicilar.FZamanlayiciSayaci) then
      begin

        TDisket(PDisket1).MotorKapat;
        TDisket(PDisket1).FMotorBeklemeSuresi := 0;
      end;
    end;
  end;

  // ikinci floppy sürücüsü
  if(PDisket2 <> nil) then
  begin

    // motor çalýþma durumlarý
    // ======================================
    // 0 = motor kapalý
    // 1..4 = motor kapanma durumunda
    // 5 = motor açýk

    if(TDisket(PDisket2).FIslemYapiliyor = False) and (TDisket(PDisket2).FMotorBeklemeSuresi > 0) then
    begin

      if((TDisket(PDisket2).FMotorBeklemeSuresi) < GZamanlayicilar.FZamanlayiciSayaci) then
      begin

        TDisket(PDisket2).MotorKapat;
        TDisket(PDisket2).FMotorBeklemeSuresi := 0;
      end;
    end;
  end;
end;

{==============================================================================
  sektör numarasýný kafa, iz, sektör biçimine çevirir
 ==============================================================================}
procedure SektoruAyristir(ASektorNo: TSayi2; var AKafa, AIz, ASektor: TSayi1);
var
  i: TSayi2;
begin

  AIz := (ASektorNo div 36);
  i := (ASektorNo mod 36);
  AKafa := (i div 18);
  ASektor := (i mod 18) + 1;
end;

{==============================================================================
  disketten tek bir sektör okuma iþlevini gerçekleþtirir
 ==============================================================================}
function TDisket.TekSektorOku(ASektorNo: TSayi4): Boolean;
var
  _Kafa, _Iz, _Sektor: TSayi1;
begin

  Result := False;

  // sektör bilgisini kafa, iz, sektor biçimine çevir
  SektoruAyristir(ASektorNo, _Kafa, _Iz, _Sektor);
{
  // konumlanacaðýmýz iz þu anki iz ise kalibrasyon, konumlanma iþlemi yapma
  if(AFizikselSurucu^.SonIzKonumu <> _Iz) then
  begin

    if(_Iz = 0) then
    begin

      // okuma kafasýný baþlangýç konumuna getir
      if(Konumlan0(AFizikselSurucu) = False) then Exit;
    end
    else
    begin

      // okuma kafasýný belirtilen ize konumlandýr
      if(Konumlan(AFizikselSurucu, _Iz, _Kafa) = False) then Exit;
    end;
  end;
}
  // kafanýn konumlandýðý izi kaydet
  FSonIzKonumu := _Iz;

  // DMA2'yi aygýttan okuma için ayarla
  DMA2Yukle(DMA_OKU);

  // IRQ bayraðýný pasifleþtir
  IRQ6Tetiklendi := False;

  // MFS sektör oku
  DurumYaz($E6);
  DurumYaz((_Kafa shl 2) or FKanal);
  DurumYaz(_Iz);
  DurumYaz(_Kafa);
  DurumYaz(_Sektor);
  DurumYaz(2);             // sektör uzunluðu = 128 * 2^x. (x=2) = 512
  DurumYaz(18);            // bir izdeki sektör sayýsý
  DurumYaz($1B);           // GAP3 standart deðer = 27
  DurumYaz($FF);           // sektör uzunluðu sýfýrdan farklý ise 0xff.

  // iþlem sonucunu oku
  DURUM0 := DurumOku;       // DURUM0
  DURUM1 := DurumOku;       // DURUM1
  DURUM2 := DurumOku;       // DURUM2
  DurumOku;                 // Ýz
  DurumOku;                 // Kafa
  DurumOku;                 // Sektör No
  DurumOku;                 // Sektör Uzunluðu

  if((DURUM0 and $C0) = 0) then Exit(True);

  Result := False;
end;

{==============================================================================
  diskete tek bir sektör yazma iþlevini gerçekleþtirir
 ==============================================================================}
function TDisket.TekSektorYaz(ASektorNo: TSayi4): Boolean;
//const
//  s: string = 'merhaba';
var
  _Kafa, _Iz, _Sektor: TSayi1;
begin

  //Tasi2(@s, Pointer(DMA_BELLEKADRESI), 512);

  Result := False;

  // sektör bilgisini kafa, iz, sektor biçimine çevir
  SektoruAyristir(ASektorNo, _Kafa, _Iz, _Sektor);
{
  // konumlanacaðýmýz iz þu anki iz ise kalibrasyon, konumlanma iþlemi yapma
  if(AFizikselSurucu^.SonIzKonumu <> _Iz) then
  begin

    if(_Iz = 0) then
    begin

      // okuma kafasýný baþlangýç konumuna getir
      if(Konumlan0(AFizikselSurucu) = False) then Exit;
    end
    else
    begin

      // okuma kafasýný belirtilen ize konumlandýr
      if(Konumlan(AFizikselSurucu, _Iz, _Kafa) = False) then Exit;
    end;
  end;
}
  // kafanýn konumlandýðý izi kaydet
  FSonIzKonumu := _Iz;

  // DMA2'yi aygýttan okuma için ayarla
  DMA2Yukle(DMA_YAZ);

  // IRQ bayraðýný pasifleþtir
  IRQ6Tetiklendi := False;

  // MFS sektör oku
  DurumYaz($45);
  DurumYaz((_Kafa shl 2) or FKanal);
  DurumYaz(_Iz);
  DurumYaz(_Kafa);
  DurumYaz(_Sektor);
  DurumYaz(2);             // sektör uzunluðu = 128 * 2^x. (x=2) = 512
  DurumYaz(18);            // bir izdeki sektör sayýsý
  DurumYaz(27);            // GAP3 standart deðer = 27
  DurumYaz($FF);           // sektör uzunluðu sýfýrdan farklý ise 0xff.

  // iþlem sonucunu oku
  DURUM0 := DurumOku;       // DURUM0

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'ST0 Deðer: %d', [DURUM0]);

  DURUM1 := DurumOku;       // DURUM1
  DURUM2 := DurumOku;       // DURUM2
  DurumOku;                 // Ýz
  DurumOku;                 // Kafa
  DurumOku;                 // Sektör No
  DurumOku;                 // Sektör Uzunluðu

//  if((DURUM0 and $C0) = 0) then Exit(True);

  Result := False;
end;

{==============================================================================
  disket sürücü sektör okuma iþlevi
 ==============================================================================}
function TDisket.Oku(AIlkSektor, ASektorSayisi: TSayi4; AHedefBellek: Isaretci): TISayi4;
var
  _BellekAdresi: Isaretci;
  _OkumaSonuc: Boolean;
  _OkunacakSektor, _SektorSayisi, i: TSayi4;
begin

  // öndeðer dönüþ deðeri
  Result := 0;

  // hedef bellek bölgesi
  _BellekAdresi := AHedefBellek;

  _OkunacakSektor := AIlkSektor;
  _SektorSayisi := ASektorSayisi;

  // motoru aç
  MotorAc;

  repeat

    for i := 1 to 3 do
    begin

      // belirtilen sektörü oku
      _OkumaSonuc := TekSektorOku(_OkunacakSektor);
      if(_OkumaSonuc = True) then Break;
    end;

    if(_OkumaSonuc) then
    begin

      // okunan sektör içeriðini hedef bellek bölgesine kopyala
      Tasi2(Pointer(DMA_BELLEKADRESI), _BellekAdresi, 512);

      // bir sonraki bellek bölgesini belirle
      _BellekAdresi := _BellekAdresi + 512;

      // bir sonraki sektörü belirle
      Inc(_OkunacakSektor);

      // sayacý bir azalt
      Dec(_SektorSayisi);
    end
    else
    begin

      // eðer okuma baþarý ile gerçekleþmemiþse mevcut iz durumunu deðiþtir
      // not: bu iþlem kalibrasyon için yapýlmaktadýr.
      FSonIzKonumu := -1;

      Result := 1;
      Exit;
    end;

    // iþlem tamamlandý
    FIslemYapiliyor := False;

    // 5 saniye sonra motoru kapat
    FMotorBeklemeSuresi := GZamanlayicilar.FZamanlayiciSayaci + (3 * CALISMA_FREKANSI);

  until (_SektorSayisi = 0);
end;


{==============================================================================
  disket sürücü sektör okuma iþlevi
 ==============================================================================}
function TDisket.Yaz(AIlkSektor, ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
var
  _BellekAdresi: Isaretci;
  _OkumaSonuc: Boolean;
  _OkunacakSektor, _SektorSayisi, i: TSayi4;
begin

  // öndeðer dönüþ deðeri
  Result := 0;

  // hedef bellek bölgesi
  _BellekAdresi := ABellek;

  _OkunacakSektor := AIlkSektor;
  _SektorSayisi := ASektorSayisi;

  // motoru aç
  MotorAc;

  TekSektorYaz(AIlkSektor);

  // iþlem tamamlandý
  FIslemYapiliyor := False;

  // 5 saniye sonra motoru kapat
  FMotorBeklemeSuresi := GZamanlayicilar.FZamanlayiciSayaci + (3 * CALISMA_FREKANSI);
end;

end.

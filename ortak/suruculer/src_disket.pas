{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: src_disket.pas
  Dosya ��levi: disket ayg�t s�r�c�s�

  G�ncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit src_disket;
 
interface
{

  1.44 kapasiteli s�r�c�n�n de�erleri

  kafa numaras�     : 00..01 = 2
  iz numaras�       : 00..79 = 80
  sekt�r numaras�   : 01..18 = 18
  sekt�r kapasitesi : 512 byte

  2 * 80 * 18 * 512 = 1474560 = 1.44

}
uses paylasim, port;

const
  DISKET_TEMEL          = $3F0;       // base addres
  DISKET_CIKISYAZMAC    = $3F2;       // digital output register
  DISKET_ANADURUMYAZMAC = $3F4;       // main status register
  DISKET_HIZSECIMYAZMAC = $3F4;       // data rate select register
  DISKET_VERI           = $3F5;       // data register
  DISKET_GIRISYAZMAC    = $3F7;       // digital input register
  DISKET_AYARYAZMAC     = $3F7;       // configuration control register

  DMA_BELLEKADRESI      = $8000;      // DMA'n�n veri transfer adresi
  DMA_OKU               = $46;        // fdc->mem
  DMA_YAZ               = $4A; //8;        // mem->fdc

var
  IRQ6Tetiklendi: Boolean;
  DURUM0, DURUM1, DURUM2: TSayi1;

procedure Yukle;
procedure MotorAc(AFizikselDepolama: PFizikselDepolama);
procedure MotorKapat(AFizikselDepolama: PFizikselDepolama);
procedure DMA2Yukle(Op: Byte);
function DurumOku: TSayi1;
procedure DurumYaz(ADeger: TSayi1);
function Bekle: Boolean;
procedure IRQ6KesmeIslevi;
function Konumlan0(AFizikselDepolama: PFizikselDepolama): Boolean;
function Konumlan(AFizikselDepolama: PFizikselDepolama; AIz, AKafa: TSayi1): Boolean;
procedure DisketSurucuMotorunuKontrolEt;
procedure SektoruAyristir(ASektorNo: TSayi2; var AKafa, AIz, ASektor: TSayi1);
function TekSektorOku(AFizikselDepolama: PFizikselDepolama; ASektorNo: TSayi4): Boolean;
function TekSektorYaz(AFizikselDepolama: PFizikselDepolama; ASektorNo: TSayi4): Boolean;
function SektorOku(AFizikselSurucu: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  AHedefBellek: Isaretci): TISayi4;
function SektorYaz(AFizikselDepolama: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;

implementation

uses irq, zamanlayici, aygityonetimi, sistemmesaj;

{==============================================================================
  disket s�r�c� ilk y�kleme i�levlerini i�erir
 ==============================================================================}
procedure Yukle;
var
  FD: PFizikselDepolama;
  i, j: TSayi1;
begin

  // CMOS'tan disket s�r�c� bilgilerini al
  PortYaz1($70, $10);
  i := PortAl1($71);

  PDisket1 := nil;
  PDisket2 := nil;

  // e�er herhangi bir disket s�r�c�s� var ise
  if(i > 0) then
  begin

  { -----------------------------------
    i = S�r�c� Tip = AAAABBBB
    AAAA = birinci s�r�c�, BBBB = ikinci s�r�c�
    ===================================
    0	  s�r�c� yok
    1	  5.25" 320K veya 360K
    2	  5.25" 1.2M
    3	  3.5"  720K
    4	  3.5"  1.44M
    5	  3.5"  2.88M
    ----------------------------------}

    // birincil s�r�c� (master)
    j := ((i shr 4) and $F);
    if(j > 0) then
    begin

      FD := FizikselDepolamaAygitiOlustur(SURUCUTIP_DISKET);
      if(FD <> nil) then
      begin

        FD^.Ozellikler := j;
        FD^.SektorOku := @SektorOku;
        FD^.SektorYaz := @SektorYaz;
        FD^.Aygit.AnaPort:= $3F0;
        FD^.Aygit.Kanal := 0;
        FD^.SonIzKonumu := -1;

        FD^.FD3.SilindirSayisi := 18;
        FD^.FD3.KafaSayisi := 2;
        FD^.FD3.IzBasinaSektorSayisi := 80;
        FD^.FD3.ToplamSektorSayisi := 18 * 2 * 80;

        // disket s�r�c� motorunu kapat
        FD^.IslemYapiliyor := False;
        FD^.MotorSayac := $1000000;

        PDisket1 := FD;
      end;
    end;

    // ikincil s�r�c� (slave)
    j := (i and $F);
    if(j > 0) then
    begin

      FD := FizikselDepolamaAygitiOlustur(SURUCUTIP_DISKET);
      if(FD <> nil) then
      begin

        FD^.Ozellikler := j;
        FD^.SektorOku := @SektorOku;
        FD^.SektorYaz := @SektorYaz;
        FD^.Aygit.AnaPort:= $3F0;
        FD^.Aygit.Kanal := 1;
        FD^.SonIzKonumu := -1;

        FD^.FD3.SilindirSayisi := 18;
        FD^.FD3.KafaSayisi := 2;
        FD^.FD3.IzBasinaSektorSayisi := 80;
        FD^.FD3.ToplamSektorSayisi := 18 * 2 * 80;

        // disket s�r�c� motorunu kapat
        FD^.IslemYapiliyor := False;
        FD^.MotorSayac := $1000000;

        PDisket2 := FD;
      end;
    end;

    // �nde�erler atan�yor
    IRQ6Tetiklendi := False;

    // disket s�r�c�s� i�in irq istek kanal�n� etkinle�tir
    IRQIsleviAta(6, @IRQ6KesmeIslevi);
  end;
end;

{==============================================================================
  disket s�r�c� motorunu �al��t�r�r
 ==============================================================================}
procedure MotorAc(AFizikselDepolama: PFizikselDepolama);
begin

  // e�er ayg�t ile ilgili i�lem yap�lmakta ise ��k (motor zaten a��k)
  if(AFizikselDepolama^.IslemYapiliyor) then
  begin

    //SISTEM_MESAJ(RENK_KIRMIZI, 'Disket->MotorAc durumu zaten aktif 1', []);
    Exit;
  end;

  // e�er ayg�t ile ilgili i�lem tamamlanm�� ve motorun kapanmas� i�in geri say�m
  // ger�ekle�mekte ise geri say�m i�lemini iptal et
  if(AFizikselDepolama^.IslemYapiliyor = False) and (AFizikselDepolama^.MotorSayac > 0) then
  begin

    AFizikselDepolama^.IslemYapiliyor := True;
    //SISTEM_MESAJ(RENK_KIRMIZI, 'Disket->MotorAc durumu zaten aktif 2', []);
    Exit;
  end;

  // motor a�ma i�lemlerini ger�ekle�tir
  AFizikselDepolama^.IslemYapiliyor := True;

  PortYaz1(DISKET_CIKISYAZMAC, 0);

  // motor'u a�
  if(AFizikselDepolama^.Aygit.Kanal = 0) then
  begin

    PortYaz1(DISKET_CIKISYAZMAC, $1C);
    SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Disket1->Motor a��ld�...', []);
  end
  else
  begin

    PortYaz1(DISKET_CIKISYAZMAC, $2D);
    SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Disket2->Motor a��ld�...', []);
  end;

  // CCR = 500kbits/s
  //PortYaz1(DISKET_AYARYAZMAC, 0);

  // BekleMS(150);
end;

{==============================================================================
  disket s�r�c� motorunu durdurur
 ==============================================================================}
procedure MotorKapat(AFizikselDepolama: PFizikselDepolama);
begin

  // motor'u kapat
  if(AFizikselDepolama^.Aygit.Kanal = 0) then
  begin

    PortYaz1(DISKET_CIKISYAZMAC, $C);
    SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Disket1->Motor kapat�ld�...', []);
  end
  else
  begin

    PortYaz1(DISKET_CIKISYAZMAC, $5);
    SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Disket2->Motor kapat�ld�...', []);
  end;
end;

{==============================================================================
  okuma / yazma i�levi i�in DMA ayg�t�n� haz�rlar
 ==============================================================================}
procedure DMA2Yukle(Op: Byte);
begin

  // FLIP-FLOP s�f�rla
  PortYaz1($C, 0);

  // 2 nolu DMA kanal�n� maskele
  PortYaz1($A, 4 + 2);

  // DMA'n�n yapaca�� i�levi belirle. oku/yaz. +2 = dma kanal�
  PortYaz1($B, Op);

  // FLIP-FLOP s�f�rla
  PortYaz1($C, 0);

  // bellek adresini belirle
  PortYaz1(4, (DMA_BELLEKADRESI and $FF));
  PortYaz1(4, ((DMA_BELLEKADRESI shr 8) and $FF));
  PortYaz1($81, ((DMA_BELLEKADRESI shr 16) and $FF));

  // FLIP-FLOP s�f�rla
  PortYaz1($C, 0);

  // i�lem (okuma / yazma) yap�lacak veri miktar�. $1FF = 511
  PortYaz1(5, $FF);
  PortYaz1(5, $1);

  // 2 nolu DMA'y� aktifle�tir
  PortYaz1($A, 2);
end;

{==============================================================================
  disket s�r�c� denetleyicisinden bilgi alma i�levi
 ==============================================================================}
function DurumOku: TSayi1;
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

  SISTEM_MESAJ(mtHata, RENK_SIYAH, 'Disket->DurumOku zaman a��m�', []);
end;

{==============================================================================
  disket s�r�c� denetleyicisine bilgi g�nderme i�levi
 ==============================================================================}
procedure DurumYaz(ADeger: TSayi1);
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

  SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'Disket->DurumYaz zaman a��m�', []);
end;

{==============================================================================
  disket s�r�c�s� bekleme rutini
 ==============================================================================}
function Bekle: Boolean;
var
  i: TSayi4;
begin

  Bekle := True;

  // kesme tetiklenmedi durumuna getiriliyor
  IRQ6Tetiklendi := False;

  i := ZamanlayiciSayaci + 150;

  // �art true oldu�u m�ddet�e devam et
  while (i > ZamanlayiciSayaci) do
  begin

    if(IRQ6Tetiklendi) then Exit;
    ElleGorevDegistir;
  end;

  Bekle := False;
end;

{==============================================================================
  IRQ istek �a�r�lar�n�n y�nlendirildi�i i�lev
 ==============================================================================}
procedure IRQ6KesmeIslevi;
begin

  { TODO : IRQ6KesmeIslevi her iki floppy s�r�c�s�ne g�re ayarlanacakt�r }
  IRQ6Tetiklendi := True;

  //SISTEM_MESAJ(RENK_KIRMIZI, 'IRQ6Tetiklendi', []);
end;

{==============================================================================
  disket okuma kafas�n� ba�lang�� konumuna (0. sekt�r) getirir (calibrate)
 ==============================================================================}
function Konumlan0(AFizikselDepolama: PFizikselDepolama): Boolean;
var
  _Iz: TSayi1;
begin

  // irq bayra��n� pasifle�tir
  IRQ6Tetiklendi := False;

  DurumYaz(7);                                      // Konumlan0
  DurumYaz(AFizikselDepolama^.Aygit.Kanal);           // kafa no (0) + s�r�c�

  // i�lemin bitmesini bekle
  Bekle;

  // i�lem sonucunu test et (sensei)
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
  floppy okuma kafas�n� belirtilen iz'e (track) konumland�r�r
 ==============================================================================}
function Konumlan(AFizikselDepolama: PFizikselDepolama; AIz, AKafa: TSayi1): Boolean;
var
  _Iz: TSayi1;
begin

  //if(MevcutIz = AIz) then Exit(True);

  // irq bayra��n� pasifle�tir
  IRQ6Tetiklendi := False;

  DurumYaz($F);                                                   // Konumlan
  DurumYaz((AKafa shl 2) or AFizikselDepolama^.Aygit.Kanal);        // kafa no + s�r�c�
  DurumYaz(AIz);

  // i�lemin bitmesini bekle
  Bekle;

  // i�lem sonucunu test et (sensei)
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
  disket s�r�c� motorunun otomatik kapanmas�n� sa�layan rutin
 ==============================================================================}
procedure DisketSurucuMotorunuKontrolEt;
begin

  // birinci floppy s�r�c�s�
  if(PDisket1 <> nil) then
  begin

    // motor �al��ma durumlar�
    // ======================================
    // 0 = motor kapal�
    // 1..4 = motor kapanma durumunda
    // 5 = motor a��k

    if(PDisket1^.IslemYapiliyor = False) and (PDisket1^.MotorSayac > 0) then
    begin

      Dec(PDisket1^.MotorSayac);
      if(PDisket1^.MotorSayac = 0) then
      begin

        MotorKapat(PDisket1);
      end;
    end;
  end;

  // ikinci floppy s�r�c�s�
  if(PDisket2 <> nil) then
  begin

    // motor �al��ma durumlar�
    // ======================================
    // 0 = motor kapal�
    // 1..4 = motor kapanma durumunda
    // 5 = motor a��k

    if(PDisket2^.IslemYapiliyor = False) and (PDisket2^.MotorSayac > 0) then
    begin

      Dec(PDisket2^.MotorSayac);
      if(PDisket2^.MotorSayac = 0) then
      begin

        MotorKapat(PDisket2);
      end;
    end;
  end;
end;

{==============================================================================
  sekt�r numaras�n� kafa, iz, sekt�r bi�imine �evirir
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
  disketten tek bir sekt�r okuma i�levini ger�ekle�tirir
 ==============================================================================}
function TekSektorOku(AFizikselDepolama: PFizikselDepolama; ASektorNo: TSayi4): Boolean;
var
  _Kafa, _Iz, _Sektor: TSayi1;
begin

  Result := False;

  // sekt�r bilgisini kafa, iz, sektor bi�imine �evir
  SektoruAyristir(ASektorNo, _Kafa, _Iz, _Sektor);
{
  // konumlanaca��m�z iz �u anki iz ise kalibrasyon, konumlanma i�lemi yapma
  if(AFizikselSurucu^.SonIzKonumu <> _Iz) then
  begin

    if(_Iz = 0) then
    begin

      // okuma kafas�n� ba�lang�� konumuna getir
      if(Konumlan0(AFizikselSurucu) = False) then Exit;
    end
    else
    begin

      // okuma kafas�n� belirtilen ize konumland�r
      if(Konumlan(AFizikselSurucu, _Iz, _Kafa) = False) then Exit;
    end;
  end;
}
  // kafan�n konumland��� izi kaydet
  AFizikselDepolama^.SonIzKonumu := _Iz;

  // DMA2'yi ayg�ttan okuma i�in ayarla
  DMA2Yukle(DMA_OKU);

  // IRQ bayra��n� pasifle�tir
  IRQ6Tetiklendi := False;

  // MFS sekt�r oku
  DurumYaz($E6);
  DurumYaz((_Kafa shl 2) or AFizikselDepolama^.Aygit.Kanal);
  DurumYaz(_Iz);
  DurumYaz(_Kafa);
  DurumYaz(_Sektor);
  DurumYaz(2);             // sekt�r uzunlu�u = 128 * 2^x. (x=2) = 512
  DurumYaz(18);            // bir izdeki sekt�r say�s�
  DurumYaz($1B);           // GAP3 standart de�er = 27
  DurumYaz($FF);           // sekt�r uzunlu�u s�f�rdan farkl� ise 0xff.

  // i�lem sonucunu oku
  DURUM0 := DurumOku;       // DURUM0
  DURUM1 := DurumOku;       // DURUM1
  DURUM2 := DurumOku;       // DURUM2
  DurumOku;                 // �z
  DurumOku;                 // Kafa
  DurumOku;                 // Sekt�r No
  DurumOku;                 // Sekt�r Uzunlu�u

  if((DURUM0 and $C0) = 0) then Exit(True);

  Result := False;
end;

{==============================================================================
  diskete tek bir sekt�r yazma i�levini ger�ekle�tirir
 ==============================================================================}
function TekSektorYaz(AFizikselDepolama: PFizikselDepolama; ASektorNo: TSayi4): Boolean;
const
  s: string = 'merhaba';
var
  _Kafa, _Iz, _Sektor: TSayi1;
begin

  Tasi2(@s, Pointer(DMA_BELLEKADRESI), 512);

  Result := False;

  // sekt�r bilgisini kafa, iz, sektor bi�imine �evir
  SektoruAyristir(ASektorNo, _Kafa, _Iz, _Sektor);
{
  // konumlanaca��m�z iz �u anki iz ise kalibrasyon, konumlanma i�lemi yapma
  if(AFizikselSurucu^.SonIzKonumu <> _Iz) then
  begin

    if(_Iz = 0) then
    begin

      // okuma kafas�n� ba�lang�� konumuna getir
      if(Konumlan0(AFizikselSurucu) = False) then Exit;
    end
    else
    begin

      // okuma kafas�n� belirtilen ize konumland�r
      if(Konumlan(AFizikselSurucu, _Iz, _Kafa) = False) then Exit;
    end;
  end;
}
  // kafan�n konumland��� izi kaydet
  AFizikselDepolama^.SonIzKonumu := _Iz;

  // DMA2'yi ayg�ttan okuma i�in ayarla
  DMA2Yukle(DMA_YAZ);

  // IRQ bayra��n� pasifle�tir
  IRQ6Tetiklendi := False;

  // MFS sekt�r oku
  DurumYaz($45);
  DurumYaz((_Kafa shl 2) or AFizikselDepolama^.Aygit.Kanal);
  DurumYaz(_Iz);
  DurumYaz(_Kafa);
  DurumYaz(_Sektor);
  DurumYaz(2);             // sekt�r uzunlu�u = 128 * 2^x. (x=2) = 512
  DurumYaz(18);            // bir izdeki sekt�r say�s�
  DurumYaz(27);            // GAP3 standart de�er = 27
  DurumYaz($FF);           // sekt�r uzunlu�u s�f�rdan farkl� ise 0xff.

  // i�lem sonucunu oku
  DURUM0 := DurumOku;       // DURUM0

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'ST0 De�er: %d', [DURUM0]);

  DURUM1 := DurumOku;       // DURUM1
  DURUM2 := DurumOku;       // DURUM2
  DurumOku;                 // �z
  DurumOku;                 // Kafa
  DurumOku;                 // Sekt�r No
  DurumOku;                 // Sekt�r Uzunlu�u

//  if((DURUM0 and $C0) = 0) then Exit(True);

  Result := False;
end;

{==============================================================================
  disket s�r�c� sekt�r okuma i�levi
 ==============================================================================}
function SektorOku(AFizikselSurucu: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  AHedefBellek: Isaretci): TISayi4;
var
  FD: PFizikselDepolama;
  _BellekAdresi: Isaretci;
  _OkumaSonuc: Boolean;
  _OkunacakSektor, _SektorSayisi, i: TSayi4;
begin

  // s�r�c� bilgisine konumlan
  FD := AFizikselSurucu;

  // �nde�er d�n�� de�eri
  Result := 0;

  // hedef bellek b�lgesi
  _BellekAdresi := AHedefBellek;

  _OkunacakSektor := AIlkSektor;
  _SektorSayisi := ASektorSayisi;

  // motoru a�
  MotorAc(FD);

  repeat

    for i := 1 to 3 do
    begin

      // belirtilen sekt�r� oku
      _OkumaSonuc := TekSektorOku(FD, _OkunacakSektor);
      if(_OkumaSonuc = True) then Break;
    end;

    if(_OkumaSonuc) then
    begin

      // okunan sekt�r i�eri�ini hedef bellek b�lgesine kopyala
      Tasi2(Pointer(DMA_BELLEKADRESI), _BellekAdresi, 512);

      // bir sonraki bellek b�lgesini belirle
      _BellekAdresi := _BellekAdresi + 512;

      // bir sonraki sekt�r� belirle
      Inc(_OkunacakSektor);

      // sayac� bir azalt
      Dec(_SektorSayisi);
    end
    else
    begin

      // e�er okuma ba�ar� ile ger�ekle�memi�se mevcut iz durumunu de�i�tir
      // not: bu i�lem kalibrasyon i�in yap�lmaktad�r.
      FD^.SonIzKonumu := -1;

      Result := 1;
      Exit;
    end;

    // motoru kapat
    FD^.IslemYapiliyor := False;
    FD^.MotorSayac := $1000000;

  until (_SektorSayisi = 0);
end;

{==============================================================================
  disket s�r�c� sekt�r okuma i�levi
 ==============================================================================}
function SektorYaz(AFizikselDepolama: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
var
  FD: PFizikselDepolama;
  _BellekAdresi: Isaretci;
  _OkumaSonuc: Boolean;
  _OkunacakSektor, _SektorSayisi, i: TSayi4;
begin

  // s�r�c� bilgisine konumlan
  FD := AFizikselDepolama;

  // �nde�er d�n�� de�eri
  Result := 0;

  // hedef bellek b�lgesi
  _BellekAdresi := ABellek;

  _OkunacakSektor := AIlkSektor;
  _SektorSayisi := ASektorSayisi;

  // motoru a�
  MotorAc(FD);

  TekSektorYaz(AFizikselDepolama, AIlkSektor);

  // motoru kapat
  FD^.IslemYapiliyor := False;
  FD^.MotorSayac := $1000000;
end;

end.

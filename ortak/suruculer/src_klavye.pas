{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: src_klavye.pas
  Dosya ��levi: standart klavye s�r�c�s�

  G�ncelleme Tarihi: 03/04/2025

 ==============================================================================}
{$mode objfpc}
unit src_klavye;
 
interface

uses paylasim, port;

const
  // tu� de�erleri
  TUS_KONTROL_SOL   = TSayi2($0100);
  TUS_KONTROL_SAG   = TSayi2($0200);
  TUS_ALT_SOL       = TSayi2($0300);
  TUS_ALT_SAG       = TSayi2($0400);
  TUS_DEGISIM_SOL   = TSayi2($0500);
  TUS_DEGISIM_SAG   = TSayi2($0600);

  TUS_SIKISTIR      = TSayi2($0700);
  TUS_SIL           = TSayi2($0800);
  TUS_GIT_BASA      = TSayi2($0900);
  TUS_GIT_SONA      = TSayi2($0A00);
  TUS_SAYFA_YUKARI  = TSayi2($0B00);
  TUS_SAYFA_ASAGI   = TSayi2($0C00);

  TUS_KUBU          = TSayi2($0D00);          // karakter k���ltme / b�y�tme tu�u (caps lock)
  TUS_HESAP         = TSayi2($0E00);          // hesap makinesi a�ma / kapama tu�u (num lock)
  TUS_KAYDIRMA      = TSayi2($0F00);          // kayd�rma a�ma / kapama tu�u (scroll lock)

  TUS_F1            = TSayi2($1000);
  TUS_F2            = TSayi2($1100);
  TUS_F3            = TSayi2($1200);
  TUS_F4            = TSayi2($1300);
  TUS_F5            = TSayi2($1400);
  TUS_F6            = TSayi2($1500);
  TUS_F7            = TSayi2($1600);
  TUS_F8            = TSayi2($1700);
  TUS_F9            = TSayi2($1800);
  TUS_F10           = TSayi2($1900);

var
  TusDurumSolKontrol  : TTusDurum = tdYok;
  TusDurumSagKontrol  : TTusDurum = tdYok;
  TusDurumSolAlt      : TTusDurum = tdYok;
  TusDurumSagAlt      : TTusDurum = tdYok;
  TusDurumSolDegisim  : TTusDurum = tdYok;
  TusDurumSagDegisim  : TTusDurum = tdYok;

  TusDurumKUBUAcik    : Boolean = False;        // karakter k���ltme / b�y�tme tu�u (caps lock)
  TusDurumHesapAcik   : Boolean = False;        // hesap makinesi a�ma / kapama tu�u (num lock)
  TusDurumKaydirmaAcik: Boolean = False;        // kayd�rma a�ma / kapama tu�u (scroll lock)

procedure Yukle;
procedure KlavyeKesmeCagrisi;
function KlavyedenTusAl(var ATusDegeri: TSayi2): TTusDurum;

implementation

uses irq, islevler, sistemmesaj;

const
  USTLIMIT_KLAVYE_BELLEK = 128;

  // k���k / normal karakter klavye tu�lar�
  KlavyeTRKucuk: array[0..127] of Char = (
    #0, #27 {Esc}, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '*', '-',
    {14} #08 {Backspace}, #09 {Tab}, 'q', 'w', 'e', 'r', 't', 'y', 'u', Chr($FD) {�},
    {24} 'o', 'p', Chr($F0) {�}, Chr($FC) {�}, #10 {Enter}, #0 {sol kontrol}, 'a', 's', 'd',
    'f', 'g', 'h', 'j', 'k', 'l', Chr($FE) {�}, 'i', '"', #0 {Left Shift},
    ',', 'z', 'x', 'c', 'v', 'b', 'n', 'm', Chr($F6) {�}, Chr($E7) {�}, '.',
    #0 {Right Shift}, '*', #0 {TUS_ALT}, ' ', #0 {Caps Lock},
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,  {F1 - F10}
    #0 {Num Lock},
    #0 {Scroll Lock},
    {71} '7', '8', '9', '-', '4', '5', '6', '+', '1', '2', '3', '0', ',',
    {84} #0, #0, '<',
    #0,   // F11 Key
    #0,   // F12 Key
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);

  // b�y�k karakter klavye tu�lar�
  KlavyeTRBuyuk: array[0..127] of Char = (
    #0, #27 {Esc}, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '*', '-',
    {14} #08 {Backspace}, #09 {Tab}, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I',
    {24} 'O', 'P', Chr($D0) {�}, Chr($DC) {�}, #10 {Enter}, #0 {sol kontrol}, 'A', 'S', 'D',
    'F', 'G', 'H', 'J', 'K', 'L', Chr($DE) {�}, Chr($DD) {'�'}, '"', #0 {Left Shift},
    ',', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', Chr($D6) {�}, Chr($C7) {�}, '.',
    #0 {Right Shift}, '*', #0 {TUS_ALT}, ' ', #0 {Caps Lock},
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,  {F1 - F10}
    #0 {Num Lock},
    #0 {Scroll Lock},
    {71} '7', '8', '9', '-', '4', '5', '6', '+', '1', '2', '3', '0', ',',
    {84} #0, #0, '<',
    #0,   // F11 Key
    #0,   // F12 Key
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);

  // her 2 (sa� / sol) shift tu�u ile bas�lan tu�lar
  KlavyeTRShift: array[0..127] of Char = (
    #0, #0, '!', '''', '^', '+', '%', '&', '/', '(', ')', '=', '?', '_',
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, '�', #0,
    ';', #0, #0, #0, #0, #0, #0, #0, #0, #0, ':',
    #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, //F1 - F10  // ge�ici de�er
    #0,   // Num Lock
    #0,   // Scroll Lock
    { TODO - a�a��daki hesap makinesi tu�lar� shift tu�u ile birlikte y�n kontrol tu�lar�
      olarak i�lev g�recek }
    {71} '7', '8', '9', '-', '4', '5', '6', '+', '1', '2', '3', '0', ',',
    {84} #0, #0, '>',
    #0,   // F11 Key
    #0,   // F12 Key
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);

  // alt gr (sa� alt) ile bas�lan tu�lar
  KlavyeTRAlt: array[0..127] of Char = (
    #0, #0, '>', '�', '#', '$', '�', #0, '{', '[', ']', '}', '\', '|',
    #0, #0, '@', #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, '~', #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, '�', #0, '<', #0,
    '`', #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, //F1 - F10  // ge�ici de�er
    #0,   // Num Lock
    #0,   // Scroll Lock
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, '|',
    #0,   // F11 Key
    #0,   // F12 Key
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);

var
  ToplamVeriUzunlugu: TSayi4;
  KlavyeVeriBellegi: array[0..USTLIMIT_KLAVYE_BELLEK - 1] of TSayi1;

{==============================================================================
  klavye y�kleme i�levlerini i�erir
 ==============================================================================}
procedure Yukle;
begin

  // klavye kesme (irq) giri�ini ata
  IRQIsleviAta(1, @KlavyeKesmeCagrisi);

  // klavye sayac�n� s�f�rla
  ToplamVeriUzunlugu := 0;
end;

{==============================================================================
  klavye kesme i�levi
 ==============================================================================}
procedure KlavyeKesmeCagrisi;
var
  i: TSayi1;
begin

  // klavye belle�indeki veriyi al
  i := PortAl1($60);

  // e�er azami veri a��lmam��sa
  if(ToplamVeriUzunlugu < USTLIMIT_KLAVYE_BELLEK) then
  begin

    // veriyi sistem belle�ine kaydet
    KlavyeVeriBellegi[ToplamVeriUzunlugu] := i;

    // klavye sayac�n� art�r
    Inc(ToplamVeriUzunlugu);
  end;
end;

var
  OlayTus: TSayi1;
  GenTusBasildi: Boolean = False;       // geni�letilmi� tu�a {$E0} bas�ld�
{==============================================================================
  klavye tu�lar�n� sistem tabanl� tu�lara �evirme i�levi

  bilgi: ATus[15..00] -> g�r�nt�lenebilir tu� karakterleri
         ATus[31..16] -> kontrol tu�lar�n� i�erir
 ==============================================================================}
function KlavyedenTusAl(var ATusDegeri: TSayi2): TTusDurum;
var
  HamTus: TSayi1;
  TusBirakildi,
  KontrolTusunaBasildi: Boolean;
  TusDurumu: TTusDurum;
begin

  // e�er klavyeden veri gelmemi�se ��k
  if(ToplamVeriUzunlugu = 0) then
  begin

    ATusDegeri := 0;
    Result := tdYok;
    Exit(tdYok);
  end
  else
  begin

    HamTus := KlavyeVeriBellegi[0];

    Dec(ToplamVeriUzunlugu);
    if(ToplamVeriUzunlugu > 0) then
    begin

      Tasi2(@KlavyeVeriBellegi[1], @KlavyeVeriBellegi[0], ToplamVeriUzunlugu);
    end;

    if(HamTus = $E0) then
    begin

      GenTusBasildi := True;
      ATusDegeri := 0;
      Exit(tdYok);
    end;

    TusBirakildi := (HamTus and $80) = $80;
    OlayTus := (HamTus and $7F);
    if(TusBirakildi) then
      TusDurumu := tdBirakildi
    else TusDurumu := tdBasildi;

    //SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Al�nan Klavye De�eri: %x', [HamTus]);

    // geni�letilmi� tu� kontrolleri
    if(GenTusBasildi) then
    begin

      GenTusBasildi := False;

      // sol kontrol tu�u
      case OlayTus of
        $1D: begin TusDurumSagKontrol := TusDurumu; ATusDegeri := TUS_KONTROL_SAG; Exit(TusDurumu); end;
        $38: begin TusDurumSagAlt := TusDurumu; ATusDegeri := TUS_ALT_SAG; Exit(TusDurumu); end;
        $52: begin ATusDegeri := TUS_SIKISTIR; Exit(TusDurumu); end;
        $53: begin ATusDegeri := TUS_SIL; Exit(TusDurumu); end;
        $47: begin ATusDegeri := TUS_GIT_BASA; Exit(TusDurumu); end;
        $4F: begin ATusDegeri := TUS_GIT_SONA; Exit(TusDurumu); end;
        $49: begin ATusDegeri := TUS_SAYFA_YUKARI; Exit(TusDurumu); end;
        $51: begin ATusDegeri := TUS_SAYFA_ASAGI; Exit(TusDurumu); end;
      end;
    end
    else
    begin

      KontrolTusunaBasildi := False;

      // sol kontrol tu�u
      case OlayTus of
        $1D: begin TusDurumSolKontrol := TusDurumu; ATusDegeri := TUS_KONTROL_SOL; KontrolTusunaBasildi := True; end;
        $2A: begin TusDurumSolDegisim := TusDurumu; ATusDegeri := TUS_DEGISIM_SOL; KontrolTusunaBasildi := True; end;
        $36: begin TusDurumSagDegisim := TusDurumu; ATusDegeri := TUS_DEGISIM_SAG; KontrolTusunaBasildi := True; end;
        $38: begin TusDurumSolAlt := TusDurumu; ATusDegeri := TUS_ALT_SOL; KontrolTusunaBasildi := True; end;
        // karakter k���ltme / b�y�tme tu�u (caps lock)
        $3A:
        begin

          if(TusDurumu = tdBasildi) then TusDurumKUBUAcik := not TusDurumKUBUAcik;
          ATusDegeri := TUS_KUBU; KontrolTusunaBasildi := True;
        end;
        // hesap makinesi a�ma / kapama tu�u (num lock)
        $45:
        begin

          if(TusDurumu = tdBasildi) then TusDurumHesapAcik := not TusDurumHesapAcik;
          ATusDegeri := TUS_HESAP; KontrolTusunaBasildi := True;
        end;
        // kayd�rma a�ma / kapama tu�u (scroll lock)
        $46:
        begin

          if(TusDurumu = tdBasildi) then TusDurumKaydirmaAcik := not TusDurumKaydirmaAcik;
          ATusDegeri := TUS_KAYDIRMA; KontrolTusunaBasildi := True;
        end;
        // kayd�rma a�ma / kapama tu�u (scroll lock)
        $3B..$44:
        begin

          ATusDegeri := TUS_F1 + (OlayTus - $3B); KontrolTusunaBasildi := True;
        end;
      end;

      if(KontrolTusunaBasildi) then Exit(TusDurumu);

      // de�i�im tu�una (shift) bas�lmas� durumunda
      if(TusDurumSolDegisim = tdBasildi) or (TusDurumSagDegisim = tdBasildi) then
      begin

        // de�i�im tablosunda tu� olmamas� durumunda
        // k���k / b�y�k klavye tablosundan ilgili tu�u al
        ATusDegeri := TSayi1(KlavyeTRShift[OlayTus and $7F]);
        if(ATusDegeri = 0) then
        begin

          if(TusDurumKUBUAcik) then
            ATusDegeri := TSayi1(KlavyeTRKucuk[OlayTus and $7F])
          else ATusDegeri := TSayi1(KlavyeTRBuyuk[OlayTus and $7F]);
        end;
      end
      // sa� alt tu�u ile ger�ekle�tirilen tu� olay�
      else if(TusDurumSagAlt = tdBasildi) then

        ATusDegeri := TSayi1(KlavyeTRAlt[OlayTus and $7F])
      else
      // sadece tek bir normal tu� olay i�levi
      begin

        if(TusDurumKUBUAcik) then
          ATusDegeri := TSayi2(KlavyeTRBuyuk[OlayTus and $7F])
        else ATusDegeri := TSayi2(KlavyeTRKucuk[OlayTus and $7F]);
      end;

      if(TusBirakildi) then
        Result := tdBirakildi
      else Result := tdBasildi;
    end;
  end;
end;

end.

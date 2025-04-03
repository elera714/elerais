{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_klavye.pas
  Dosya Ýþlevi: standart klavye sürücüsü

  Güncelleme Tarihi: 03/04/2025

 ==============================================================================}
{$mode objfpc}
unit src_klavye;
 
interface

uses paylasim, port;

const
  // tuþ deðerleri
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

  TUS_KUBU          = TSayi2($0D00);          // karakter küçültme / büyütme tuþu (caps lock)
  TUS_HESAP         = TSayi2($0E00);          // hesap makinesi açma / kapama tuþu (num lock)
  TUS_KAYDIRMA      = TSayi2($0F00);          // kaydýrma açma / kapama tuþu (scroll lock)

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

  TusDurumKUBUAcik    : Boolean = False;        // karakter küçültme / büyütme tuþu (caps lock)
  TusDurumHesapAcik   : Boolean = False;        // hesap makinesi açma / kapama tuþu (num lock)
  TusDurumKaydirmaAcik: Boolean = False;        // kaydýrma açma / kapama tuþu (scroll lock)

procedure Yukle;
procedure KlavyeKesmeCagrisi;
function KlavyedenTusAl(var ATusDegeri: TSayi2): TTusDurum;

implementation

uses irq, islevler, sistemmesaj;

const
  USTLIMIT_KLAVYE_BELLEK = 128;

  // küçük / normal karakter klavye tuþlarý
  KlavyeTRKucuk: array[0..127] of Char = (
    #0, #27 {Esc}, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '*', '-',
    {14} #08 {Backspace}, #09 {Tab}, 'q', 'w', 'e', 'r', 't', 'y', 'u', Chr($FD) {ý},
    {24} 'o', 'p', Chr($F0) {ð}, Chr($FC) {ü}, #10 {Enter}, #0 {sol kontrol}, 'a', 's', 'd',
    'f', 'g', 'h', 'j', 'k', 'l', Chr($FE) {þ}, 'i', '"', #0 {Left Shift},
    ',', 'z', 'x', 'c', 'v', 'b', 'n', 'm', Chr($F6) {ö}, Chr($E7) {ç}, '.',
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

  // büyük karakter klavye tuþlarý
  KlavyeTRBuyuk: array[0..127] of Char = (
    #0, #27 {Esc}, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '*', '-',
    {14} #08 {Backspace}, #09 {Tab}, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I',
    {24} 'O', 'P', Chr($D0) {Ð}, Chr($DC) {Ü}, #10 {Enter}, #0 {sol kontrol}, 'A', 'S', 'D',
    'F', 'G', 'H', 'J', 'K', 'L', Chr($DE) {Þ}, Chr($DD) {'Ý'}, '"', #0 {Left Shift},
    ',', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', Chr($D6) {Ö}, Chr($C7) {Ç}, '.',
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

  // her 2 (sað / sol) shift tuþu ile basýlan tuþlar
  KlavyeTRShift: array[0..127] of Char = (
    #0, #0, '!', '''', '^', '+', '%', '&', '/', '(', ')', '=', '?', '_',
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, 'é', #0,
    ';', #0, #0, #0, #0, #0, #0, #0, #0, #0, ':',
    #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, //F1 - F10  // geçici deðer
    #0,   // Num Lock
    #0,   // Scroll Lock
    { TODO - aþaðýdaki hesap makinesi tuþlarý shift tuþu ile birlikte yön kontrol tuþlarý
      olarak iþlev görecek }
    {71} '7', '8', '9', '-', '4', '5', '6', '+', '1', '2', '3', '0', ',',
    {84} #0, #0, '>',
    #0,   // F11 Key
    #0,   // F12 Key
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
    #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);

  // alt gr (sað alt) ile basýlan tuþlar
  KlavyeTRAlt: array[0..127] of Char = (
    #0, #0, '>', '£', '#', '$', '½', #0, '{', '[', ']', '}', '\', '|',
    #0, #0, '@', #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, '~', #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, '´', #0, '<', #0,
    '`', #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, //F1 - F10  // geçici deðer
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
  klavye yükleme iþlevlerini içerir
 ==============================================================================}
procedure Yukle;
begin

  // klavye kesme (irq) giriþini ata
  IRQIsleviAta(1, @KlavyeKesmeCagrisi);

  // klavye sayacýný sýfýrla
  ToplamVeriUzunlugu := 0;
end;

{==============================================================================
  klavye kesme iþlevi
 ==============================================================================}
procedure KlavyeKesmeCagrisi;
var
  i: TSayi1;
begin

  // klavye belleðindeki veriyi al
  i := PortAl1($60);

  // eðer azami veri aþýlmamýþsa
  if(ToplamVeriUzunlugu < USTLIMIT_KLAVYE_BELLEK) then
  begin

    // veriyi sistem belleðine kaydet
    KlavyeVeriBellegi[ToplamVeriUzunlugu] := i;

    // klavye sayacýný artýr
    Inc(ToplamVeriUzunlugu);
  end;
end;

var
  OlayTus: TSayi1;
  GenTusBasildi: Boolean = False;       // geniþletilmiþ tuþa {$E0} basýldý
{==============================================================================
  klavye tuþlarýný sistem tabanlý tuþlara çevirme iþlevi

  bilgi: ATus[15..00] -> görüntülenebilir tuþ karakterleri
         ATus[31..16] -> kontrol tuþlarýný içerir
 ==============================================================================}
function KlavyedenTusAl(var ATusDegeri: TSayi2): TTusDurum;
var
  HamTus: TSayi1;
  TusBirakildi,
  KontrolTusunaBasildi: Boolean;
  TusDurumu: TTusDurum;
begin

  // eðer klavyeden veri gelmemiþse çýk
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

    //SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Alýnan Klavye Deðeri: %x', [HamTus]);

    // geniþletilmiþ tuþ kontrolleri
    if(GenTusBasildi) then
    begin

      GenTusBasildi := False;

      // sol kontrol tuþu
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

      // sol kontrol tuþu
      case OlayTus of
        $1D: begin TusDurumSolKontrol := TusDurumu; ATusDegeri := TUS_KONTROL_SOL; KontrolTusunaBasildi := True; end;
        $2A: begin TusDurumSolDegisim := TusDurumu; ATusDegeri := TUS_DEGISIM_SOL; KontrolTusunaBasildi := True; end;
        $36: begin TusDurumSagDegisim := TusDurumu; ATusDegeri := TUS_DEGISIM_SAG; KontrolTusunaBasildi := True; end;
        $38: begin TusDurumSolAlt := TusDurumu; ATusDegeri := TUS_ALT_SOL; KontrolTusunaBasildi := True; end;
        // karakter küçültme / büyütme tuþu (caps lock)
        $3A:
        begin

          if(TusDurumu = tdBasildi) then TusDurumKUBUAcik := not TusDurumKUBUAcik;
          ATusDegeri := TUS_KUBU; KontrolTusunaBasildi := True;
        end;
        // hesap makinesi açma / kapama tuþu (num lock)
        $45:
        begin

          if(TusDurumu = tdBasildi) then TusDurumHesapAcik := not TusDurumHesapAcik;
          ATusDegeri := TUS_HESAP; KontrolTusunaBasildi := True;
        end;
        // kaydýrma açma / kapama tuþu (scroll lock)
        $46:
        begin

          if(TusDurumu = tdBasildi) then TusDurumKaydirmaAcik := not TusDurumKaydirmaAcik;
          ATusDegeri := TUS_KAYDIRMA; KontrolTusunaBasildi := True;
        end;
        // kaydýrma açma / kapama tuþu (scroll lock)
        $3B..$44:
        begin

          ATusDegeri := TUS_F1 + (OlayTus - $3B); KontrolTusunaBasildi := True;
        end;
      end;

      if(KontrolTusunaBasildi) then Exit(TusDurumu);

      // deðiþim tuþuna (shift) basýlmasý durumunda
      if(TusDurumSolDegisim = tdBasildi) or (TusDurumSagDegisim = tdBasildi) then
      begin

        // deðiþim tablosunda tuþ olmamasý durumunda
        // küçük / büyük klavye tablosundan ilgili tuþu al
        ATusDegeri := TSayi1(KlavyeTRShift[OlayTus and $7F]);
        if(ATusDegeri = 0) then
        begin

          if(TusDurumKUBUAcik) then
            ATusDegeri := TSayi1(KlavyeTRKucuk[OlayTus and $7F])
          else ATusDegeri := TSayi1(KlavyeTRBuyuk[OlayTus and $7F]);
        end;
      end
      // sað alt tuþu ile gerçekleþtirilen tuþ olayý
      else if(TusDurumSagAlt = tdBasildi) then

        ATusDegeri := TSayi1(KlavyeTRAlt[OlayTus and $7F])
      else
      // sadece tek bir normal tuþ olay iþlevi
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

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_klavye.pas
  Dosya Ýþlevi: standart klavye sürücüsü

  Güncelleme Tarihi: 23/01/2025

 ==============================================================================}
{$mode objfpc}
unit src_klavye;
 
interface

uses paylasim, port;

type
  TTusDurum = (tdYok, tdBasildi, tdBirakildi);

const
  { TODO - aþaðýdaki deðiþkenler yeni deðerlerle yüklenecek
    tüm kontrol tuþlarý taným deðerlerine göre buraya eklenecek }
  TUS_KONTROL = Chr($C0);
  TUS_ALT     = Chr($C1);
  TUS_DEGISIM = Chr($C2);
  TUS_KBT     = Chr($3A);                           // karakter büyütme tuþu (capslock)
  TUS_SYT     = Chr($45);                           // sayý yazma tuþu (numlock)
  TUS_KT      = Chr($46);                           // kaydýrma tuþu (scrolllock)

var
  SolKontrolTusDurumu: TTusDurum = tdYok;
  SagKontrolTusDurumu: TTusDurum = tdYok;
  SolAltTusDurumu    : TTusDurum = tdYok;
  SagAltTusDurumu    : TTusDurum = tdYok;
  SolDegisimTusDurumu: TTusDurum = tdYok;
  SagDegisimTusDurumu: TTusDurum = tdYok;

  KBTDurum        : Boolean = False;                // karakter büyütme tuþu (capslock)
  SYTDurum        : Boolean = False;                // sayý yazma tuþu (numlock)
  KTDurum         : Boolean = False;                // kaydýrma tuþu (scrolllock)

procedure Yukle;
procedure KlavyeKesmeCagrisi;
function KlavyedenTusAl(var ATus: TSayi2): TTusDurum;

implementation

uses irq, sistemmesaj;

const
  USTLIMIT_KLAVYE_BELLEK = 128;

  // küçük / normal karakter klavye tuþlarý
  KlavyeTRKucuk: array[0..127] of Char = (
    #0, #27 {Esc}, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '*', '-',
    {14} #08 {Backspace}, #09 {Tab}, 'q', 'w', 'e', 'r', 't', 'y', 'u', Chr($FD) {ý},
    {24} 'o', 'p', Chr($F0) {ð}, Chr($FC) {ü}, #10 {Enter}, TUS_KONTROL, 'a', 's', 'd',
    'f', 'g', 'h', 'j', 'k', 'l', Chr($FE) {þ}, 'i', '"', TUS_DEGISIM {Left Shift},
    ',', 'z', 'x', 'c', 'v', 'b', 'n', 'm', Chr($F6) {ö}, Chr($E7) {ç}, '.',
    TUS_DEGISIM {Right Shift}, '*', TUS_ALT, ' ', TUS_KBT {Caps Lock}, #33, #34,
    #0, #0, #0, #0, #0, #0, #0, #0, //F1 - F10  // geçici deðer
    TUS_SYT,   // Num Lock
    TUS_KT,   // Scroll Lock
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
    {24} 'O', 'P', Chr($D0) {Ð}, Chr($DC) {Ü}, #10 {Enter}, TUS_KONTROL, 'A', 'S', 'D',
    'F', 'G', 'H', 'J', 'K', 'L', Chr($DE) {Þ}, Chr($DD) {'Ý'}, '"', TUS_DEGISIM {Left Shift},
    ',', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', Chr($D6) {Ö}, Chr($C7) {Ç}, '.',
    TUS_DEGISIM {Right Shift}, '*', TUS_ALT, ' ', TUS_KBT {Caps Lock}, #33, #34,
    #0, #0, #0, #0, #0, #0, #0, #0, //F1 - F10  // geçici deðer
    TUS_SYT,   // Num Lock
    TUS_KT,   // Scroll Lock
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

{==============================================================================
  klavye tuþlarýnýn anlamlý tuþlara çevrilme iþlevi
 ==============================================================================}
var
  OlayTus: TSayi1;
  OncekiOlayTus: TSayi1 = 0;

function KlavyedenTusAl(var ATus: TSayi2): TTusDurum;
var
  HamTus: TSayi1;
  TusBirakildi: Boolean;
  TusDurumu: TTusDurum;
begin

  // eðer klavyeden veri gelmemiþse çýk
  if(ToplamVeriUzunlugu = 0) then
  begin

    ATus := 0;
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

      OncekiOlayTus := HamTus;
      ATus := 0;
      Exit(tdYok);
    end;

    TusBirakildi := (HamTus and $80) = $80;
    OlayTus := (HamTus and $7F);
    if(TusBirakildi) then
      TusDurumu := tdBirakildi
    else TusDurumu := tdBasildi;

    //SISTEM_MESAJ(RENK_SIYAH, 'Tuþ: %x', [i]);

    // kontrol tuþu
    if(OlayTus = $1D) then
    begin

      if(OncekiOlayTus = $E0) then
        SagKontrolTusDurumu := TusDurumu
      else SolKontrolTusDurumu := TusDurumu;

      ATus := 0;
      Result := tdYok;
    end
    // alt tuþu
    else if(OlayTus = $38) then
    begin

      if(OncekiOlayTus = $E0) then
        SagAltTusDurumu := TusDurumu
      else SolAltTusDurumu := TusDurumu;

      SISTEM_MESAJ(RENK_KIRMIZI, 'Alt Tuþ: ?', []);

      ATus := 0;
      Result := tdYok;
    end
    // deðiþim - sol shift tuþu
    else if(OlayTus = $2A) then
    begin

      SolDegisimTusDurumu := TusDurumu;
      ATus := 0;
      Result := tdYok;
    end
    // deðiþim - sað shift tuþu
    else if(OlayTus = $36) then
    begin

      SagDegisimTusDurumu := TusDurumu;
      ATus := 0;
      Result := tdYok;
    end
    // büyütme / küçültme tuþu - capslock
    else if(OlayTus = $3A) then
    begin

      if(TusDurumu = tdBasildi) then KBTDurum := not KBTDurum;

      ATus := 0;
      Result := tdYok;
    end
    else
    begin

      {if(SagAltTusDurumu = tdBasildi) then
        SISTEM_MESAJ(RENK_KIRMIZI, 'Alt Tuþ: basýldý', [])
      else if(SagAltTusDurumu = tdBirakildi) then
        SISTEM_MESAJ(RENK_KIRMIZI, 'Alt Tuþ: býrakýldý', []);}

      // deðiþim tuþuna (shift) basýlmasý durumunda
      if(SolDegisimTusDurumu = tdBasildi) or (SagDegisimTusDurumu = tdBasildi) then
      begin

        // deðiþim tablosunda tuþ olmamasý durumunda
        // küçük / büyük klavye tablosundan ilgili tuþu al
        ATus := TSayi1(KlavyeTRShift[OlayTus and $7F]);
        if(ATus = 0) then
        begin

          if(KBTDurum) then
            ATus := TSayi1(KlavyeTRKucuk[OlayTus and $7F])
          else ATus := TSayi1(KlavyeTRBuyuk[OlayTus and $7F]);
        end;
      end
      // sað alt tuþu ile gerçekleþtirilen tuþ olayý
      else if(SagAltTusDurumu = tdBasildi) then

        ATus := TSayi1(KlavyeTRAlt[OlayTus and $7F])
      else
      // sadece tek bir normal tuþ olay iþlevi
      begin

        if(KBTDurum) then
          ATus := TSayi1(KlavyeTRBuyuk[OlayTus and $7F])
        else ATus := TSayi1(KlavyeTRKucuk[OlayTus and $7F]);
      end;

      if(TusBirakildi) then
        Result := tdBirakildi
      else Result := tdBasildi;
    end;

    OncekiOlayTus := HamTus;
  end;
{
  // tuþun býrakýlmasý
  if(TusBirakildi) then
  begin

    else if(OlayTus = TUS_SYT) then
    begin

      OlayTus := #0;
      SYTDurum := not SYTDurum;
    end
    else if(OlayTus = TUS_KT) then
    begin

      OlayTus := #0;
      KTDurum := not KTDurum;
    end
    else if(OlayTus = TUS_KONTROL) then
    begin

      OlayTus := #0;
      KONTROLTusDurumu := tdBirakildi;
    end
    else if(OlayTus = TUS_ALT) then
    begin

      OlayTus := #0;
      ALTTusDurumu := tdBirakildi;
    end
    else if(OlayTus = TUS_DEGISIM) then
    begin

      OlayTus := #0;
      DEGISIMTusDurumu := tdBirakildi;
    end else OlayTus := OlayTus;

    //Result := tdBirakildi;
  end
  else
  begin

    else if(OlayTus = TUS_SYT) then
    begin

      OlayTus := #0;
    end
    else if(OlayTus = TUS_KT) then
    begin

      OlayTus := #0;
    end
    else if(OlayTus = TUS_KONTROL) then
    begin

      OlayTus := #0;
      KONTROLTusDurumu := tdBasildi;
    end
    else if(OlayTus = TUS_ALT) then
    begin

      OlayTus := #0;
      ALTTusDurumu := tdBasildi;
    end
    else if(OlayTus = TUS_DEGISIM) then
    begin

      OlayTus := #0;
      DEGISIMTusDurumu := tdBasildi;
    end else OlayTus := OlayTus;

    //Result := tdBasildi;
  end;  }
end;

end.

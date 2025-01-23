{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: src_klavye.pas
  Dosya ��levi: standart klavye s�r�c�s�

  G�ncelleme Tarihi: 23/01/2025

 ==============================================================================}
{$mode objfpc}
unit src_klavye;
 
interface

uses paylasim, port;

type
  TTusDurum = (tdYok, tdBasildi, tdBirakildi);

const
  { TODO - a�a��daki de�i�kenler yeni de�erlerle y�klenecek
    t�m kontrol tu�lar� tan�m de�erlerine g�re buraya eklenecek }
  TUS_KONTROL = Chr($C0);
  TUS_ALT     = Chr($C1);
  TUS_DEGISIM = Chr($C2);
  TUS_KBT     = Chr($3A);                           // karakter b�y�tme tu�u (capslock)
  TUS_SYT     = Chr($45);                           // say� yazma tu�u (numlock)
  TUS_KT      = Chr($46);                           // kayd�rma tu�u (scrolllock)

var
  SolKontrolTusDurumu: TTusDurum = tdYok;
  SagKontrolTusDurumu: TTusDurum = tdYok;
  SolAltTusDurumu    : TTusDurum = tdYok;
  SagAltTusDurumu    : TTusDurum = tdYok;
  SolDegisimTusDurumu: TTusDurum = tdYok;
  SagDegisimTusDurumu: TTusDurum = tdYok;

  KBTDurum        : Boolean = False;                // karakter b�y�tme tu�u (capslock)
  SYTDurum        : Boolean = False;                // say� yazma tu�u (numlock)
  KTDurum         : Boolean = False;                // kayd�rma tu�u (scrolllock)

procedure Yukle;
procedure KlavyeKesmeCagrisi;
function KlavyedenTusAl(var ATus: TSayi2): TTusDurum;

implementation

uses irq, sistemmesaj;

const
  USTLIMIT_KLAVYE_BELLEK = 128;

  // k���k / normal karakter klavye tu�lar�
  KlavyeTRKucuk: array[0..127] of Char = (
    #0, #27 {Esc}, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '*', '-',
    {14} #08 {Backspace}, #09 {Tab}, 'q', 'w', 'e', 'r', 't', 'y', 'u', Chr($FD) {�},
    {24} 'o', 'p', Chr($F0) {�}, Chr($FC) {�}, #10 {Enter}, TUS_KONTROL, 'a', 's', 'd',
    'f', 'g', 'h', 'j', 'k', 'l', Chr($FE) {�}, 'i', '"', TUS_DEGISIM {Left Shift},
    ',', 'z', 'x', 'c', 'v', 'b', 'n', 'm', Chr($F6) {�}, Chr($E7) {�}, '.',
    TUS_DEGISIM {Right Shift}, '*', TUS_ALT, ' ', TUS_KBT {Caps Lock}, #33, #34,
    #0, #0, #0, #0, #0, #0, #0, #0, //F1 - F10  // ge�ici de�er
    TUS_SYT,   // Num Lock
    TUS_KT,   // Scroll Lock
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
    {24} 'O', 'P', Chr($D0) {�}, Chr($DC) {�}, #10 {Enter}, TUS_KONTROL, 'A', 'S', 'D',
    'F', 'G', 'H', 'J', 'K', 'L', Chr($DE) {�}, Chr($DD) {'�'}, '"', TUS_DEGISIM {Left Shift},
    ',', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', Chr($D6) {�}, Chr($C7) {�}, '.',
    TUS_DEGISIM {Right Shift}, '*', TUS_ALT, ' ', TUS_KBT {Caps Lock}, #33, #34,
    #0, #0, #0, #0, #0, #0, #0, #0, //F1 - F10  // ge�ici de�er
    TUS_SYT,   // Num Lock
    TUS_KT,   // Scroll Lock
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

{==============================================================================
  klavye tu�lar�n�n anlaml� tu�lara �evrilme i�levi
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

  // e�er klavyeden veri gelmemi�se ��k
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

    //SISTEM_MESAJ(RENK_SIYAH, 'Tu�: %x', [i]);

    // kontrol tu�u
    if(OlayTus = $1D) then
    begin

      if(OncekiOlayTus = $E0) then
        SagKontrolTusDurumu := TusDurumu
      else SolKontrolTusDurumu := TusDurumu;

      ATus := 0;
      Result := tdYok;
    end
    // alt tu�u
    else if(OlayTus = $38) then
    begin

      if(OncekiOlayTus = $E0) then
        SagAltTusDurumu := TusDurumu
      else SolAltTusDurumu := TusDurumu;

      SISTEM_MESAJ(RENK_KIRMIZI, 'Alt Tu�: ?', []);

      ATus := 0;
      Result := tdYok;
    end
    // de�i�im - sol shift tu�u
    else if(OlayTus = $2A) then
    begin

      SolDegisimTusDurumu := TusDurumu;
      ATus := 0;
      Result := tdYok;
    end
    // de�i�im - sa� shift tu�u
    else if(OlayTus = $36) then
    begin

      SagDegisimTusDurumu := TusDurumu;
      ATus := 0;
      Result := tdYok;
    end
    // b�y�tme / k���ltme tu�u - capslock
    else if(OlayTus = $3A) then
    begin

      if(TusDurumu = tdBasildi) then KBTDurum := not KBTDurum;

      ATus := 0;
      Result := tdYok;
    end
    else
    begin

      {if(SagAltTusDurumu = tdBasildi) then
        SISTEM_MESAJ(RENK_KIRMIZI, 'Alt Tu�: bas�ld�', [])
      else if(SagAltTusDurumu = tdBirakildi) then
        SISTEM_MESAJ(RENK_KIRMIZI, 'Alt Tu�: b�rak�ld�', []);}

      // de�i�im tu�una (shift) bas�lmas� durumunda
      if(SolDegisimTusDurumu = tdBasildi) or (SagDegisimTusDurumu = tdBasildi) then
      begin

        // de�i�im tablosunda tu� olmamas� durumunda
        // k���k / b�y�k klavye tablosundan ilgili tu�u al
        ATus := TSayi1(KlavyeTRShift[OlayTus and $7F]);
        if(ATus = 0) then
        begin

          if(KBTDurum) then
            ATus := TSayi1(KlavyeTRKucuk[OlayTus and $7F])
          else ATus := TSayi1(KlavyeTRBuyuk[OlayTus and $7F]);
        end;
      end
      // sa� alt tu�u ile ger�ekle�tirilen tu� olay�
      else if(SagAltTusDurumu = tdBasildi) then

        ATus := TSayi1(KlavyeTRAlt[OlayTus and $7F])
      else
      // sadece tek bir normal tu� olay i�levi
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
  // tu�un b�rak�lmas�
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

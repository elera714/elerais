{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: src_klavye.pas
  Dosya ��levi: standart klavye s�r�c�s�

  G�ncelleme Tarihi: 16/09/2024

 ==============================================================================}
{$mode objfpc}
unit src_klavye;
 
interface

uses paylasim, port;

procedure Yukle;
procedure KlavyeKesmeCagrisi;
function KlavyedenTusAl(var ATus: Char): TTusDurum;

implementation

uses irq, sistemmesaj;

const
  USTLIMIT_KLAVYE_BELLEK = 128;

  KlavyeTRNormal: array[0..127] of Char = (
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
    #0,   // All other keys are undefined
    #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0);

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
    #0,   // All other keys are undefined
    #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0);

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
  _Tus: TSayi1;
begin

  // klavye belle�indeki veriyi al
  _Tus := PortAl1($60);

  // e�er azami veri a��lmam��sa
  if(ToplamVeriUzunlugu < USTLIMIT_KLAVYE_BELLEK) then
  begin

    // veriyi sistem belle�ine kaydet
    KlavyeVeriBellegi[ToplamVeriUzunlugu] := _Tus;

    // klavye sayac�n� art�r
    Inc(ToplamVeriUzunlugu);
  end;
end;

{==============================================================================
  klavye kesme i�levi
 ==============================================================================}
function KlavyedenTusAl(var ATus: Char): TTusDurum;
var
  _Tus: Char;
  _Sayi1: TSayi1;
  _TusBirakildi: Boolean;
begin

  // e�er klavyeden veri gelmemi�se ��k
  if(ToplamVeriUzunlugu = 0) then
  begin

    ATus := #0;
    Result := tdYok;
  end
  else
  begin

    _Sayi1 := KlavyeVeriBellegi[0];

    //SISTEM_MESAJ(RENK_SIYAH, 'Tus: %d', [_Sayi1]);

    Dec(ToplamVeriUzunlugu);
    if(ToplamVeriUzunlugu > 0) then
    begin

      Tasi2(@KlavyeVeriBellegi[1], @KlavyeVeriBellegi[0], ToplamVeriUzunlugu);
    end;

    _TusBirakildi := (_Sayi1 and $80) = $80;

    if(KBTDurum) then
    begin

      if(DEGISIMTusDurumu = tdBasildi) then
        _Tus := KlavyeTRNormal[_Sayi1 and $7F]
      else _Tus := KlavyeTRBuyuk[_Sayi1 and $7F]
    end
    else
    begin

      if(DEGISIMTusDurumu = tdBasildi) then
        _Tus := KlavyeTRBuyuk[_Sayi1 and $7F]
      else _Tus := KlavyeTRNormal[_Sayi1 and $7F];
    end;

    // tu�un b�rak�lmas�
    if(_TusBirakildi) then
    begin

      if(_Tus = TUS_KBT) then
      begin

        ATus := #0;
        KBTDurum := not KBTDurum;
      end
      else if(_Tus = TUS_SYT) then
      begin

        ATus := #0;
        SYTDurum := not SYTDurum;
      end
      else if(_Tus = TUS_KT) then
      begin

        ATus := #0;
        KTDurum := not KTDurum;
      end
      else if(_Tus = TUS_KONTROL) then
      begin

        ATus := #0;
        KONTROLTusDurumu := tdBirakildi;
      end
      else if(_Tus = TUS_ALT) then
      begin

        ATus := #0;
        ALTTusDurumu := tdBirakildi;
      end
      else if(_Tus = TUS_DEGISIM) then
      begin

        ATus := #0;
        DEGISIMTusDurumu := tdBirakildi;
      end else ATus := _Tus;

      Result := tdBirakildi;
    end
    else
    begin

      if(_Tus = TUS_KBT) then
      begin

        ATus := #0;
      end
      else if(_Tus = TUS_SYT) then
      begin

        ATus := #0;
      end
      else if(_Tus = TUS_KT) then
      begin

        ATus := #0;
      end
      else if(_Tus = TUS_KONTROL) then
      begin

        ATus := #0;
        KONTROLTusDurumu := tdBasildi;
      end
      else if(_Tus = TUS_ALT) then
      begin

        ATus := #0;
        ALTTusDurumu := tdBasildi;
      end
      else if(_Tus = TUS_DEGISIM) then
      begin

        ATus := #0;
        DEGISIMTusDurumu := tdBasildi;
      end else ATus := _Tus;

      Result := tdBasildi;
    end;
  end;
end;

end.

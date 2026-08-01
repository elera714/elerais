{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: islemci.pas
  Dosya İşlevi: işlemci (cpu) işlevlerini içerir

  Güncelleme Tarihi: 31/07/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit islemci;

interface

uses paylasim;

var
  // işlemci kabiliyetleri
  iFPU, iTSC, iMSR, iAPIC, iMTRR, iACPI, iMMX,
  iSSE, iSSE2, iSSE3, iVMX, iSSE41, iSSE42, iAVX: Boolean;

type
  TIslemci = class
  public
    constructor Create;
    function SaticiBilgisiAl: string;
    procedure OzellikBilgisiAl(var AEAX, AEDX, AECX: TSayi4);
  end;

var
  GIslemci: TIslemci;

implementation

constructor TIslemci.Create;
begin

end;

{==============================================================================
  işlemci satıcı bilgisini alır
 ==============================================================================}
function TIslemci.SaticiBilgisiAl: string;
begin

  asm
    pushad

    xor eax,eax
    cpuid

    mov edi,Result
    mov al,12             // bilgi uzunluğu, string tip
    mov [edi+00],al
    mov [edi+01],ebx
    mov [edi+05],edx
    mov [edi+09],ecx

    popad
  end;
end;

{==============================================================================
  işlemci bilgisi ve özelliklerini döndürür
  https://en.wikipedia.org/wiki/CPUID adresinden ayrıntılı bilgilere bakılabilir.
 ==============================================================================}
procedure TIslemci.OzellikBilgisiAl(var AEAX, AEDX, AECX: TSayi4);
var
  YEAX, YEDX,
  YECX: TSayi4;
begin

  asm
    pushad

    xor eax,eax
    inc eax
    cpuid

    lea edi,YEAX
    mov [edi],eax
    lea edi,YEDX
    mov [edi],edx
    lea edi,YECX
    mov [edi],ecx

    popad
  end;

  AEAX := YEAX;
  AEDX := YEDX;
  AECX := YECX;

  iFPU  := (AEDX and (1 shl 00)) = (1 shl 00);
  iTSC  := (AEDX and (1 shl 04)) = (1 shl 04);
  iMSR  := (AEDX and (1 shl 05)) = (1 shl 05);
  iAPIC := (AEDX and (1 shl 09)) = (1 shl 09);
  iMTRR := (AEDX and (1 shl 12)) = (1 shl 12);
  iACPI := (AEDX and (1 shl 22)) = (1 shl 22);
  iMMX  := (AEDX and (1 shl 23)) = (1 shl 23);
  iSSE  := (AEDX and (1 shl 25)) = (1 shl 25);
  iSSE2 := (AEDX and (1 shl 26)) = (1 shl 26);

  iSSE3 := (AECX and (1 shl 00)) = (1 shl 00);
  iVMX  := (AECX and (1 shl 05)) = (1 shl 05);
  iSSE41:= (AECX and (1 shl 19)) = (1 shl 19);
  iSSE42:= (AECX and (1 shl 20)) = (1 shl 20);
  iAVX  := (AECX and (1 shl 28)) = (1 shl 28);
end;

end.

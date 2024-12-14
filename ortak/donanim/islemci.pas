{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: islemci.pas
  Dosya İşlevi: işlemci (cpu) işlevlerini içerir

  Güncelleme Tarihi: 23/08/2020

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

function IslemciSaticisiniAl: string;
procedure IslemciOzellikleriniAl1(var Aeax, Aedx, Aecx: TSayi4);

implementation

{==============================================================================
  işlemci satıcı bilgisini alır
 ==============================================================================}
function IslemciSaticisiniAl: string;
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
procedure IslemciOzellikleriniAl1(var Aeax, Aedx, Aecx: TSayi4);
var
  _eax, _edx,
  _ecx: TSayi4;
begin

  asm
    pushad

    xor eax,eax
    inc eax
    cpuid

    lea edi,_eax
    mov [edi],eax
    lea edi,_edx
    mov [edi],edx
    lea edi,_ecx
    mov [edi],ecx

    popad
  end;

  Aeax := _eax;
  Aedx := _edx;
  Aecx := _ecx;

  iFPU  := (Aedx and (1 shl 00)) = (1 shl 00);
  iTSC  := (Aedx and (1 shl 04)) = (1 shl 04);
  iMSR  := (Aedx and (1 shl 05)) = (1 shl 05);
  iAPIC := (Aedx and (1 shl 09)) = (1 shl 09);
  iMTRR := (Aedx and (1 shl 12)) = (1 shl 12);
  iACPI := (Aedx and (1 shl 22)) = (1 shl 22);
  iMMX  := (Aedx and (1 shl 23)) = (1 shl 23);
  iSSE  := (Aedx and (1 shl 25)) = (1 shl 25);
  iSSE2 := (Aedx and (1 shl 26)) = (1 shl 26);

  iSSE3 := (Aecx and (1 shl 00)) = (1 shl 00);
  iVMX  := (Aecx and (1 shl 05)) = (1 shl 05);
  iSSE41:= (Aecx and (1 shl 19)) = (1 shl 19);
  iSSE42:= (Aecx and (1 shl 20)) = (1 shl 20);
  iAVX  := (Aecx and (1 shl 28)) = (1 shl 28);
end;

end.

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: islemci.pas
  Dosya İşlevi: işlemci (cpu) işlevlerini içerir

  Güncelleme Tarihi: 02/08/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit islemci;

interface

uses paylasim;

type
  TIslemci = class
  private
    FSatici: string;                    // cpu id = 0
    FOzellik1_EAX,
    FOzellik1_EDX,
    FOzellik1_ECX: TSayi4;              // cpu id = 1

    // işlemci kabiliyetleri
    FFPU, FTSC, FMSR, FAPIC, FMTRR, FACPI, FMMX,
    FSSE, FSSE2, FSSE3, FVMX, FSSE41, FSSE42, FAVX: Boolean;
  public
    constructor Create;
    function SaticiBilgisiAl: string;
    procedure OzellikBilgisiAl(var AEAX, AEDX, AECX: TSayi4);
  published
    property Satici: string read FSatici;
    property Ozellik1_EAX: TSayi4 read FOzellik1_EAX;
    property Ozellik1_EDX: TSayi4 read FOzellik1_EDX;
    property Ozellik1_ECX: TSayi4 read FOzellik1_ECX;
  end;

var
  GIslemci: TIslemci;

implementation

constructor TIslemci.Create;
begin

  FSatici := SaticiBilgisiAl;

  OzellikBilgisiAl(FOzellik1_EAX, FOzellik1_EDX, FOzellik1_ECX);
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
  işlemci bilgisi ve özelliklerini alır
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

  FFPU  := (AEDX and (1 shl 00)) = (1 shl 00);
  FTSC  := (AEDX and (1 shl 04)) = (1 shl 04);
  FMSR  := (AEDX and (1 shl 05)) = (1 shl 05);
  FAPIC := (AEDX and (1 shl 09)) = (1 shl 09);
  FMTRR := (AEDX and (1 shl 12)) = (1 shl 12);
  FACPI := (AEDX and (1 shl 22)) = (1 shl 22);
  FMMX  := (AEDX and (1 shl 23)) = (1 shl 23);
  FSSE  := (AEDX and (1 shl 25)) = (1 shl 25);
  FSSE2 := (AEDX and (1 shl 26)) = (1 shl 26);

  FSSE3 := (AECX and (1 shl 00)) = (1 shl 00);
  FVMX  := (AECX and (1 shl 05)) = (1 shl 05);
  FSSE41:= (AECX and (1 shl 19)) = (1 shl 19);
  FSSE42:= (AECX and (1 shl 20)) = (1 shl 20);
  FAVX  := (AECX and (1 shl 28)) = (1 shl 28);
end;

end.

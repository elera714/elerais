{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: tmode.pp
  Dosya İşlevi: yazı (text) mod işlevlerini içerir

  Güncelleme Tarihi: 25/11/2017

 ==============================================================================}
{$asmmode intel}
{$mode objfpc}
unit tmode;

interface

uses paylasim;

const
  ScreenWidth = 80;
  ScreenHeight = 25;

var
  CurrentX, CurrentY: Word;

procedure Init;
procedure GotoXY(X, Y: Word);
procedure ClrScr;
procedure DisableCursor;
procedure Write(s: string);
procedure Write(s: PChar);
procedure WriteChar(c: Char);
procedure WriteKernelMsg(Msg: string);

implementation

uses port;

{==============================================================================
  yazı (text) mod ortamını ilk değerlerle yükler
 ==============================================================================}
procedure Init;
begin

  ClrScr;
end;

{==============================================================================
  ekranı temizler. kursörü 0, 0 koordinatına konumlandırır.
 ==============================================================================}
procedure ClrScr;
var
  PPoint: PChar;
  X, Y: Word;
begin

  for Y := 0 to ScreenHeight - 1 do
  begin

    for X := 0 to ScreenWidth - 1 do
    begin

      PPoint := PChar((Y * (ScreenWidth * 2)) + (X * 2) + VIDEO_BELLEK_ADRESI);
      PPoint^ := ' ';
    end;
  end;

  CurrentX := 0;
  CurrentY := 0;

  GotoXY(CurrentX, CurrentY);
end;

{==============================================================================
  kursörü konumlandırır
 ==============================================================================}
procedure GotoXY(X, Y: Word);
var
  Val: Word;
begin

  CurrentX := X;
  CurrentY := Y;

  Val := (CurrentY * ScreenWidth) + CurrentX;

  PortYaz1($3D4, $F);
  PortYaz1($3D5, (Val and $FF));
  PortYaz1($3D4, $E);
  PortYaz1($3D5, (Val shr 8) and $FF);
end;

{==============================================================================
  kursörü görünmez duruma getirir
 ==============================================================================}
procedure DisableCursor;
begin

  PortYaz1($3D4, $0A);
  PortYaz1($3D5, $3F);
end;

{==============================================================================
  ekrana string türünde karakter katarı yazar
 ==============================================================================}
procedure Write(s: string);
var
  Len, i: Integer;
begin

  Len := Length(s);
  for i := 1 to Len do
  begin

    WriteChar(s[i]);
  end;
end;

{==============================================================================
  ekrana pchar türünde karakter katarı yazar
 ==============================================================================}
procedure Write(s: PChar);
begin

  while s^ <> #0 do
  begin

    WriteChar(s^);
    Inc(s);
  end;
end;

{==============================================================================
  ekrana tek bir karakter yazar
 ==============================================================================}
procedure WriteChar(c: Char);
var
  PPoint: PChar;
begin

  if(c = #10) then
  begin

    CurrentX := 0;
    Inc(CurrentY);
    if(CurrentY >= ScreenHeight) then
    begin

      asm
        mov     esi,VIDEO_BELLEK_ADRESI
        mov     edi,esi
        add     esi,80*2
        mov     ecx,(24*80*2) / 4
        cld
        rep     movsd

        mov     edi,VIDEO_BELLEK_ADRESI + (24*80*2)
        mov     ecx,(80*2) / 4
        mov     eax,$07200720
        cld
        rep     stosd
      end;

      CurrentX := 0;
      CurrentY := 24;
    end;
  end
  else
  begin

    PPoint := PChar((CurrentY * 160) + (CurrentX * 2) + VIDEO_BELLEK_ADRESI);
    PPoint^ := c;
    Inc(CurrentX);
  end;

  GotoXY(CurrentX, CurrentY);
end;

{==============================================================================
  çekirdek (kernel) mesajlarını ekrana yazar
 ==============================================================================}
procedure WriteKernelMsg(Msg: string);
begin

  Write(#10 + Msg);
end;

end.

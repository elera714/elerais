{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: test.pp
  Dosya İşlevi: test işlevlerini içerir

  Güncelleme Tarihi: 08/03/2013

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit test1;

interface

procedure CreateThread(MemStart: LongWord; Entry: LongWord; ESP: LongWord);
procedure SetPixel24(X, Y: Integer; Color: Integer);
procedure TestThread;
procedure TimerThread;
procedure DelayTest;
function DumpFlags: LongWord;
procedure FramedProc;
//procedure NonFramedProc;
procedure AsmProc;
procedure InB1(Port: Word; Val: Byte);

implementation

uses global, timer, macmsg, sysutils, shared, convert, process, draw, write, test2;

//100, 100, 100, $ffffff şeklinde test edildi.
procedure Circle(xStart, yStart, Radius: Integer); //; Color: TColor);
var
  { x, } xpos, ypos: Integer;
  Pix, Pixels: Integer;
  x: Real;
begin
  Pixels := Round(2 * Radius * Pi);
  // for x:=0 to 359 do
  for Pix := 0 to Pixels - 1 do
  begin
    x := 360 * Pix / Pixels; { calculate a value of 0-359 }
    xpos := (Round(xStart + sin(x * Pi / 180) * Radius));
    ypos := (Round(yStart + cos(x * Pi / 180) * Radius));
    //SetPixel(nil, xpos, ypos, $ffffff, false);
  end;
end;

//draw_line(0, 0, 100, 100); şeklinde test edildi.
procedure draw_line(x1, y1, x2, y2: Integer);
  var
  dx, dy, x, y: Integer;
  m: Integer;
begin
  dx := x2-x1;
  dy := y2-y1;
  m := dy div dx;
  for x := x1 to x2 do
  begin
    y := Round(m*x + y1 + 0.5);
    //SetPixel(nil, x, y, $ffffff, false);
  end;
end;

procedure CreateThread(MemStart: LongWord; Entry: LongWord; ESP: LongWord);
  var
  PID: TPID;
begin
{

    // dosyanın çalıştırılması için proses oluştur
    PID := ProcessCreate(@MemStart, $ffffffff, Entry, ESP);

    // proses'in olay sayacını sıfırla
    Processes[PID]^.EvCount := 0;

    // proses'in görev değişim sayacını sıfırla
    Processes[PID]^.TaskCounter := 0;

    // bellek başlangıç adresi
    Processes[PID]^.MemStartAddr := MemStart;

    // bellek miktarı
    Processes[PID]^.MemSize := $ffffff;

    // process adı
    Processes[PID]^.Name := 'merhaba';

    // oluşturulan proses sayısını bir artır
    Inc(CreatedProcess);

    // proses'in durumunu çalışıyor olarak belirle
    SetProcessState(PID, PROCESSSTATE_RUNNING);
}
end;

procedure SetPixel24(X, Y: Integer; Color: Integer);
  var
  Addr: LongWord;
  PAddr: PByte;
  RGB: PRGB;
begin

  // belirtilen koordinata konumlan
  Addr := (Y * (800*600)) + (X * 3);
  Addr += $E0000000;

  // pixel'i belirtilen renk ile işaretle
  PAddr := PByte(Addr);
  RGB := @Color;
  PAddr[0] := RGB^.B;
  PAddr[1] := RGB^.G;
  PAddr[2] := RGB^.R;
end;

procedure TestThread;
  var
  i: Integer;
begin

  i := 0;
  repeat

    Inc(i);

    {SysCanvas.Pen.Color := $ffffff;
    SysCanvas.Brush.Color := $ffffff;
    SysCanvas.FillRect(0, 0, 80, 16);

    SysCanvas.Pen.Color := $ff0000;
    SysCanvas.WriteHex(0, 0, True, 8, i);}

  until 1=2;
end;

var
  TTCount: Integer = 0;

procedure TimerThread;
  var
  i: Integer;
begin
  Inc(TTCount);
end;

procedure DelayTest;
  var
  i: Integer;
begin
  i := TTCount + 10;
  while i > TTCount do
end;

function GetCRVal(Index: Byte): DWORD;
begin
{  case Index of
    0: asm mov eax, cr0; mov GetCRVal, eax end;
    2: asm mov eax, cr2; mov GetCRVal, eax end;
    3: asm mov eax, cr3; mov GetCRVal, eax end;
    4: asm mov eax, cr4; mov GetCRVal, eax end;
    else GetCRVal := -1;
  end; }
end;

{procedure GetGDTInfo(p: TGDTR); stdcall;
begin
{  asm
    sgdt p
  end; }
end;
}

procedure ShowCRInfo;
  var
  CR: DWORD;
begin
{  CR := GetCRVal(0);
  WriteStr(CRLF + 'CR0 Degeri: ');
  WriteStr(HexToStr32(CR));
  if((CR and $00000001) = $00000001) then WriteStr(CRLF + '  PE - Protected Enable');
  if((CR and $00000002) = $00000002) then WriteStr(CRLF + '  MP - Monitor Coprocessor');
  if((CR and $00000004) = $00000004) then WriteStr(CRLF + '  EM - Emulate Math Coprocessor');
  if((CR and $00000008) = $00000008) then WriteStr(CRLF + '  TS - Task Switch');
  if((CR and $00000010) = $00000010) then WriteStr(CRLF + '  ET - Extention Type');
  if((CR and $00000020) = $00000020) then WriteStr(CRLF + '  NE - Numerics Exception');
  if((CR and $00010000) = $00010000) then WriteStr(CRLF + '  WP - Write Protect');
  if((CR and $00040000) = $00040000) then WriteStr(CRLF + '  AM - Alignment Mask');
  if((CR and $20000000) = $20000000) then WriteStr(CRLF + '  NW - No Write - Through');
  if((CR and $40000000) = $40000000) then WriteStr(CRLF + '  CD - Cache Disable');
  if((CR and $80000000) = $80000000) then WriteStr(CRLF + '  PG - Paging');

  //CR2 - Sayfalama hatası varsa, bu hatanın olduğu doğrusal adres
  CR := GetCRVal(2);
  WriteStr(CRLF + 'CR2 Degeri: ');
  WriteStr(HexToStr32(CR));

  CR := GetCRVal(3);
  WriteStr(CRLF + 'CR3 Degeri: ');
  WriteStr(HexToStr32(CR));
  WriteStr(CRLF + '  Dizin Tablosu Fiziksel Adres: ');
  WriteStr(HexToStr32(CR and $FFFFF000));

  //CR4 -
  CR := GetCRVal(4);
  WriteStr(CRLF + 'CR4 Degeri: ');
  WriteStr(HexToStr32(CR)); }
end;

{ TDeneme }
{
constructor TDeneme.Create;
begin
  //inherited Create;

  Say1 := 100;

end;
}
function DumpFlags: LongWord;
  var
  i: LongWord;
begin

  asm
    push  eax
    pushfd
    pop eax
    mov i,eax
    pop eax
  end;

  Result := i;
end;

procedure IntHandler; assembler; interrupt;
{
  push  gs
  push  fs
  push  es
  push  ds
  push  edi
  push  esi
  push  edx
  push  ecx
  push  ebx
  push  eax

  mov   eax,10

  pop   eax
  pop   ebx
  pop   ecx
  pop   edx
  pop   esi
  pop   edi
  pop   ds
  pop   es
  pop   fs
  pop   gs
  iret        // $cf
}
asm

  mov eax,10
end;

procedure FramedProc;
{
  push  ebp
  mov   ebp,esp
  sub   esp,4
  mov   [ebp-4],$a
  leave
  ret
}
  var
  Val: Integer;
begin

  Val := 10;

{
  pushf     // $9c
  push  cs  // $0e

  IntHandler;

  leave     // $c9
  ret       // $c3
}

  IntHandler;
end;

//procedure NonFramedProc; nostackframe;
{
  mov   [ebp-4],$a
  ret
}
//  var
//  Val: Integer;
//begin

//  Val := 10;
//end;

procedure AsmProc; assembler;
{
  mov   eax,10
  ret
}
asm

  mov eax,10
end;

                               //dl=$20
procedure InB1(Port: Word; Val: Byte);  assembler; nostackframe;
asm
  mov dx,Port
  in	al,dx
  mov Val,al
end;

end.

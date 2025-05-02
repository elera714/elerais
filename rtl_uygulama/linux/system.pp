{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2000 by Marco van de Voort
    member of the Free Pascal development team.

    System unit for Linux.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{ These things are set in the makefile, }
{ But you can override them here.}
{ If you use an aout system, set the conditional AOUT}
{ $Define AOUT}

unit system;

{*****************************************************************************}
                                    interface
{*****************************************************************************}
{$define FPC_IS_SYSTEM}
{$define HAS_CMDLINE}
{$define USE_NOTHREADMANAGER}

{$i osdefs.inc}
{$I ..\unix\sysunixh.inc}

// elera iþletim sistemine ait tüm sabit/deðiþken/yapý/iþlev/ek dosyalar bu dosyanýn içerisindedir
{$i elera.inc}


function get_cmdline:Pchar; 
property cmdline:Pchar read get_cmdline;

function Trim(const S: string): string;
function IntToStr(ADeger: TISayi4): string;
function HexToStr(Val: LongInt; WritePrefix: LongBool; DivNum: LongInt): string;
function TimeToStr(Buffer: array of Byte): string;
function Saat2KK(ADeger: TSayi4): string;
function DateToStr(Buffer: array of Word; GunAdiEkle: Boolean): string;
function Tarih2KK(ADeger: TSayi4): string;
function StrToHex(Val: string): LongWord;
function UpperCase(s: string): string;
procedure Tasi2(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4);
function ntohs(ADeger: TSayi2): TSayi2;
function ntohs(ADeger: TSayi4): TSayi4;
function htons(ADeger: TSayi2): TSayi2;
function htons(ADeger: TSayi4): TSayi4;
function StrToIP(AIPAdres: string): TIPAdres;
function IPAdresiGecerliMi(AIPAdresi: string): Boolean;
function IP_KarakterKatari(AIPAdres: TIPAdres): string;
function MAC_KarakterKatari(AMACAdres: TMACAdres): string;
procedure StrPasEx(Src, Dest: Pointer);
function StrPasEx(ASrc: PChar): string;
function IPKarsilastir(IP1, IP2: TIPAdres): Boolean;
function ParamCount: LongInt;
function ParamStr(Index: LongInt): string;
function ParamStr1(Index: LongInt): string;

{$if defined(CPUARM) or defined(CPUM68K) or (defined(CPUSPARC) and defined(VER2_6))}

{$define fpc_softfpu_interface}
{$i softfpu.pp}
{$undef fpc_softfpu_interface}

{$endif defined(CPUARM) or defined(CPUM68K) or (defined(CPUSPARC) and defined(VER2_6))}

{ program çaðrý baþlýk bilgileri }

{*****************************************************************************}
                                 implementation
{*****************************************************************************}
const
  SayiSistemi16: PChar = ('0123456789ABCDEF');

{$asmmode intel}

{TODO - lazarus'tan buraya eklendi. lazarus birimi eklenince kaldýrýlacak }
function Trim(const S: string): string;
var
  Ofs, Len: sizeint;
begin
  len := Length(S);
  while (Len>0) and (S[Len]<=' ') do
   dec(Len);
  Ofs := 1;
  while (Ofs<=Len) and (S[Ofs]<=' ') do
    Inc(Ofs);
  result := Copy(S, Ofs, 1 + Len - Ofs);
end;

procedure MoveEx(Src, Dest: Pointer; Size: LongInt); assembler;
asm

  pushad
  mov esi,Src
  mov edi,Dest
  mov ecx,Size
  cld
  rep movsb
  popad
end;
{$asmmode att}

{==============================================================================
  10lu sayý sistem sayý deðerini karakter katarýna dönüþtürür
 ==============================================================================}
function IntToStr(ADeger: TISayi4): string;
var
  _Bellek: array[0..11] of Char;
  _Negatif: Boolean;
  _HaneSayisi: TISayi4;
  _Deger: TISayi4;
	_p: PChar;
begin

  // 32 bit maximum sayý = 4294967295 - on hane

  // hane sayýsýný sýfýrla
  _HaneSayisi := 0;

  // deðerlerin yerleþtirileceði belleðin en son kýsmýna konumlan
  _p := @_Bellek[11];

  // sayýsal deðer negatif mi ? pozitif mi ?
	if (ADeger < 0) then
	begin

		_Deger := -ADeger;
		_Negatif := True;
	end
	else
	begin

		_Deger := ADeger;
		_Negatif := False;
	end;

  // sayýsal deðeri çevir
	repeat

		_p^ := Char((_Deger mod 10) + Byte('0'));
		_Deger := _Deger div 10;
    Inc(_HaneSayisi);
		Dec(_p);
	until (_Deger = 0);

  // sayýsal deðer negatif ise - iþaretini de ekle
	if(_Negatif) then
	begin

		PChar(_p)^ := '-';
    Inc(_HaneSayisi);
	end;

  // deðeri hedef bölgeye kopyala
  Tasi2(@_Bellek[11 - _HaneSayisi + 1], @Result[1], _HaneSayisi);
  SetLength(Result, _HaneSayisi);
end;

{==============================================================================
  saat deðerini string deðere dönüþtürür
 ==============================================================================}
function TimeToStr(Buffer: array of Byte): string;
begin

  // array[0] = saat
  // array[1] = dakika
  // array[2] = saniye
  SetLength(Result, 8);

  // saat deðerini string'e çevir
  if(Buffer[0] > 9) then
    Result := IntToStr(Buffer[0])
  else Result := '0' + IntToStr(Buffer[0]);
  Result += ':';

  // dakika deðerini string'e çevir
  if(Buffer[1] > 9) then
    Result += IntToStr(Buffer[1])
  else Result += '0' + IntToStr(Buffer[1]);
  Result += ':';

  // saniye deðerini string'e çevir
  if(Buffer[2] > 9) then
    Result += IntToStr(Buffer[2])
  else Result += '0' + IntToStr(Buffer[2]);
end;

{==============================================================================
  dosya saat deðerini karakter katarýna çevirir
 ==============================================================================}
function Saat2KK(ADeger: TSayi4): string;
var
  s: string;
begin

  SetLength(Result, 8);

  // saat deðerini karakter katarýna çevir
  s := IntToStr(ADeger and $FF);
  if(Length(s) = 1) then
    Result := '0' + s
  else Result := s;

  // dakika deðerini karakter katarýna çevir
  s := IntToStr((ADeger shr 8) and $FF);
  if(Length(s) = 1) then
    Result += ':0' + s
  else Result += ':' + s;

  // saniye deðerini karakter katarýna çevir
  s := IntToStr((ADeger shr 16) and $FF);
  if(Length(s) = 1) then
    Result += ':0' + s
  else Result += ':' + s;

  // bilgi: salise deðeri sonuç deðerine eklenmiyor - eklenebilir
end;

{==============================================================================
  tarih deðerini string deðere dönüþtürür
 ==============================================================================}
function DateToStr(Buffer: array of Word; GunAdiEkle: Boolean): string;
const
  Gunler: array[0..6] of string = ('Pz', 'Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct');
begin

  // array[0] = gün
  // array[1] = ay
  // array[2] = yýl
  // array[3] = haftanýn günü
  if(GunAdiEkle) then
    SetLength(Result, 13)
  else SetLength(Result, 10);

  // gün deðerini string'e çevir
  if(Buffer[0] > 9) then
    Result := IntToStr(Buffer[0])
  else Result := '0' + IntToStr(Buffer[0]);
  Result += '.';

  // ay deðerini string'e çevir
  if(Buffer[1] > 9) then
    Result += IntToStr(Buffer[1])
  else Result += '0' + IntToStr(Buffer[1]);

  if(GunAdiEkle) then
  begin

    Result += '.';
    Result += IntToStr(Buffer[2]) + ' ';
    Result += Gunler[Buffer[3]];
  end
  else
  begin

    Result += '.';
    Result += IntToStr(Buffer[2]);
  end;
end;

{==============================================================================
  dosya tarih deðerini karakter katarýna çevirir
 ==============================================================================}
function Tarih2KK(ADeger: TSayi4): string;
var
  s: string;
begin

  SetLength(Result, 10);

  // gün deðerini karakter katarýna çevir
  s := IntToStr(ADeger and $FF);
  if(Length(s) = 1) then
    Result := '0' + s
  else Result := s;

  // ay deðerini karakter katarýna çevir
  s := IntToStr((ADeger shr 8) and $FF);
  if(Length(s) = 1) then
    Result += '.0' + s
  else Result += '.' + s;

  // yýl deðerini karakter katarýna çevir
  Result += '.' + IntToStr((ADeger shr 16) and $FFFF);
end;

{==============================================================================
  hexadesimal sayý deðerini string deðere dönüþtürür
 ==============================================================================}
function HexToStr(Val: LongInt; WritePrefix: LongBool; DivNum: LongInt): string;
var
  i: Byte;
  p: PChar;
begin

  p := @Result;

  // eðer ön ek varsa ekle ve yerleþtirilecek sayýsal deðerin
  // en sonuna konumlan
  if(WritePrefix) then
  begin

    SetLength(Result, DivNum + 2);
    p[1] := '0';
    p[2] := 'x';
    Inc(p, DivNum + 2);
  end
  else
  begin

    SetLength(Result, DivNum);
    Inc(p, DivNum);
  end;

  // sayýsal deðeri sondan baþa doðru belleðe yerleþtir
  for i := 0 to DivNum - 1 do
  begin

    p^ := SayiSistemi16[(Val shr (i * 4) and $F)];
    Dec(p);
  end;
end;

{==============================================================================
  string deðeri hexadesimal sayý deðerine dönüþtürür
 ==============================================================================}
function StrToHex(Val: string): LongWord;
var
  i: LongInt;
  s: string;
begin

  Result := 0;
  if(Length(Val) > 0) then
  begin

    s := UpperCase(Val);
    for i := 1 to Length(s) do
    begin

      Result := Result shl 4;
      case s[i] of
        '0'..'9': begin Result := Result + Ord(s[i]) - 48 end;
        'A'..'F': begin Result := Result + Ord(s[i]) - 55 end;
      end;
    end;
  end;
end;

{==============================================================================
  string deðeri büyük harfe çevirir
 ==============================================================================}
function UpperCase(s: string): string;
var
  i: Integer;
  C: Char;
begin

  if(Length(s) > 0) then
  begin

    Result := '';
    for i := 1 to Length(s) do
    begin

      C := s[i];
    	if(C in [#97..#122]) then
        Result := Result + Char(Byte(C) - 32)
      else Result := Result + C;
    end;
  end else Result := '';
end;

{$asmmode intel}
procedure Tasi2(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4); assembler;
asm
  pushad
  mov esi,AKaynak
  mov edi,AHedef
  mov ecx,AUzunluk
  cld
  rep movsb
  popad
end;

// big endian -> little endian çevrimi

// network sýralý deðeri host sýralý deðere çevirir (örnek: $1234 -> $3412)
function ntohs(ADeger: TSayi2): TSayi2;
begin

  Result := SwapEndian(ADeger);
end;

// network sýralý deðeri host sýralý deðere çevirir (örnek: $12345678 -> $56781234)
function ntohs(ADeger: TSayi4): TSayi4;
begin

  Result := SwapEndian(ADeger);
end;

// host sýralý deðeri network sýralý deðere çevirir (örnek: $1234 -> $3412)
function htons(ADeger: TSayi2): TSayi2;
begin

  Result := SwapEndian(ADeger);
end;

// host sýralý deðeri network sýralý deðere çevirir (örnek: $12345678 -> $56781234)
function htons(ADeger: TSayi4): TSayi4;
begin

  Result := SwapEndian(ADeger);
end;

{==============================================================================
  IP adresini karakter katarýna dönüþtürür
 ==============================================================================}
function IP_KarakterKatari(AIPAdres: TIPAdres): string;
var
   Toplam, i: TSayi1;
  Deger: string[3];
begin

  Toplam := 0;
  Result := '';

  // ip adresini çevir
  for i := 0 to 3 do
  begin

    Deger := IntToStr(AIPAdres[i]);
    Toplam := Toplam + Length(Deger);
    Result := Result + Deger;

    if(i < 3) then
    begin

      Result := Result + '.'
    end;
  end;

  SetLength(Result, Toplam + 3);  // + 3 = sayý aralardaki her nokta
end;

{==============================================================================
  karakter katar deðerini IP adres deðerine dönüþtürür
 ==============================================================================}
function StrToIP(AIPAdres: string): TIPAdres;
var
  IPAdres, s: string;
  NoktaSayisi, SiraNo,
  Sonuc, i: TSayi1;
  s2: TSayi2;
  Deger: Char;
label
  Hata;
begin

  // ip adresinin sað / sol taraflarýndaki boþluklarý yok et
  IPAdres := Trim(AIPAdres);
  NoktaSayisi := 0;
  SiraNo := 0;
  s := '';

  // ip adresini çevir
  for i := 1 to Length(IPAdres) do
  begin

    Deger := IPAdres[i];
    if(Deger = '.') then
    begin

      Inc(NoktaSayisi);

      // 2 nokta arasýnda rakam yoksa çýk
      if(Length(s) = 0) then Goto Hata;

      Val(s, s2, Sonuc);
      if(s2 > 255) then Goto Hata;

      Result[SiraNo] := s2;

      s := '';
      Inc(SiraNo);
    end
    else
    begin

      if(Deger in ['0'..'9']) then
        s += IPAdres[i]
      else Goto Hata;
    end;
  end;

  Val(s, s2, Sonuc);
  if(s2 > 255) then Goto Hata;

  Result[SiraNo] := s2;

  if(NoktaSayisi <> 3) then Goto Hata;
  Exit;

Hata:
  Result := IPAdres0;
end;

{==============================================================================
  IP adresinin geçerli bir ip adresi olup olmadýðýný kontrol eder
 ==============================================================================}
function IPAdresiGecerliMi(AIPAdresi: string): Boolean;
var
  IPAdres: TIPAdres;
begin

  IPAdres := StrToIP(AIPAdresi);
  Result := not(IPKarsilastir(IPAdres, IPAdres0));
end;

{==============================================================================
  MAC adresini karakter katarýna dönüþtürür
 ==============================================================================}
function MAC_KarakterKatari(AMACAdres: TMACAdres): string;
var
  Deger, i: TSayi4;
begin

  Result := '';

  // mac adresini çevir
  for i := 0 to 5 do
  begin

    Deger := AMACAdres[i];
    Result := Result + SayiSistemi16[((Deger shr 4) and $F)];
    Result := Result + SayiSistemi16[Deger and $F];
    if(i < 5) then
    begin

      Result := Result + Char('-');
    end;
  end;

  SetLength(Result, 17);
end;

{$if defined(CPUI386) and not defined(FPC_USE_LIBC)}
var
  sysenter_supported: LongInt = 0;
{$endif}

const calculated_cmdline:Pchar=nil;

{$if defined(CPUARM) or defined(CPUM68K) or (defined(CPUSPARC) and defined(VER2_6))}

{$define fpc_softfpu_implementation}
{$i softfpu.pp}
{$undef fpc_softfpu_implementation}

{ we get these functions and types from the softfpu code }
{$define FPC_SYSTEM_HAS_float64}
{$define FPC_SYSTEM_HAS_float32}
{$define FPC_SYSTEM_HAS_flag}
{$define FPC_SYSTEM_HAS_extractFloat64Frac0}
{$define FPC_SYSTEM_HAS_extractFloat64Frac1}
{$define FPC_SYSTEM_HAS_extractFloat64Exp}
{$define FPC_SYSTEM_HAS_extractFloat64Sign}
{$define FPC_SYSTEM_HAS_ExtractFloat32Frac}
{$define FPC_SYSTEM_HAS_extractFloat32Exp}
{$define FPC_SYSTEM_HAS_extractFloat32Sign}

{$endif defined(CPUARM) or defined(CPUM68K) or (defined(CPUSPARC) and defined(VER2_6))}

{$I ..\inc\system.inc}

{$ifdef android}
{$I sysandroid.inc}
{$endif android}

{*****************************************************************************
                       Misc. System Dependent Functions
*****************************************************************************}

{$if defined(CPUARM) and defined(FPC_ABI_EABI)}
procedure haltproc(e:longint);cdecl;external name '_haltproc_eabi';
{$else}
procedure haltproc(e:longint);cdecl;external name '_haltproc';
{$endif}

{$ifdef FPC_USE_LIBC}
function  FpPrCtl(options : cInt; const args : ptruint) : cint; cdecl; external clib name 'prctl';
{$endif}

procedure System_exit;
begin
  haltproc(ExitCode);
End;

{function BackPos(c:char; const s: shortstring): integer;
var
 i: integer;
Begin
  for i:=length(s) downto 0 do
    if s[i] = c then break;
  if i=0 then
    BackPos := 0
  else
    BackPos := i;
end;}


 { variable where full path and filename and executable is stored }
 { is setup by the startup of the system unit.                    }
var
 execpathstr : shortstring;

function IPKarsilastir(IP1, IP2: TIPAdres): Boolean;
var
  i: TISayi4;
begin

  Result := False;

  for i := 0 to 3 do if(IP1[i] <> IP2[i]) then Exit;

  Result := True;
end;

function ParamCount: LongInt;
begin

  Result := PLongWord(32 + 0)^;
end;

function ParamStr(Index: LongInt): string;
var
  i, j: LongInt;
  p: PChar;
begin

  i := ParamCount;

  Result := '';
  if(Index < 0) or (Index > i) then Exit;

  if(Index = 0) then
  begin

    Result := StrPasEx(Pointer(4));
    //Exit;
  end;

  {j := 0;
  p := PChar(4);

  while not(Index = j) do
  begin

    while (p^ <> #0) do begin Inc(p); end;

    Inc(p);
    Inc(j);
  end;

  Result := StrPasEx(p);}
end;

function ParamStr1(Index: LongInt): string;
var
  i, j: LongInt;
  p: PChar;
begin

  i := ParamCount;

  Result := '';
  if(Index < 0) or (Index > i) then Exit;

  if(Index = 0) then
  begin

    Result := StrPasEx(PChar(32 + 4));
    Exit;
  end;

  j := 0;
  p := PChar(32 + 4);

  while not(Index = j) do
  begin

    while (p^ <> #0) do begin Inc(p); end;

    Inc(p);
    Inc(j);
  end;

  Result := StrPasEx(p);
end;

procedure StrPasEx(Src, Dest: Pointer);
var
  p, p2: PChar;
  i: Byte;
begin

  i := 0;
  p := Src;
  p2 := PChar(Dest);
  while (p^ <> #0) do
  begin

    Inc(i);
    p2^ := p^;
    Inc(p);
    Inc(p2);
  end;
  PByte(Dest)^ := i;
end;

function StrPasEx(ASrc: PChar): string;
var
  Src, Dest: PChar;
  i: Byte;
begin

  i := 0;
  Src := ASrc;
  Dest := @Result[1];

  while (Src^ <> #0) do
  begin

    Dest^ := Src^;
    Inc(Src);
    Inc(Dest);
    Inc(i);
  end;
  SetLength(Result, i);
end;

Procedure Randomize;
Begin
  //randseed:=longint(Fptime(nil));
End;

{*****************************************************************************
                                    cmdline
*****************************************************************************}

procedure SetupCmdLine;
var
  bufsize,
  len,j,
  size,i : longint;
  found  : boolean;
  buf    : pchar;

  procedure AddBuf;
  begin
    reallocmem(calculated_cmdline,size+bufsize);
    move(buf^,calculated_cmdline[size],bufsize);
    inc(size,bufsize);
    bufsize:=0;
  end;

begin
  if argc<=0 then
    exit;
  GetMem(buf,ARG_MAX);
  size:=0;
  bufsize:=0;
  i:=0;
  while (i<argc) do
   begin
     len:=strlen(argv[i]);
     if len>ARG_MAX-2 then
      len:=ARG_MAX-2;
     found:=false;
     for j:=1 to len do
      if argv[i][j]=' ' then
       begin
         found:=true;
         break;
       end;
     found:=found or (len=0); // also quote if len=0, bug 19114
     if bufsize+len>=ARG_MAX-2 then
      AddBuf;
     if found then
      begin
        buf[bufsize]:='"';
        inc(bufsize);
      end;
     if len>0 then
       begin
         move(argv[i]^,buf[bufsize],len);
         inc(bufsize,len);
       end;
     if found then
      begin
        buf[bufsize]:='"';
        inc(bufsize);
      end;
     if i<argc-1 then
      buf[bufsize]:=' '
     else
      buf[bufsize]:=#0;
     inc(bufsize);
     inc(i);
   end;
  AddBuf;
  FreeMem(buf,ARG_MAX);
end;

function get_cmdline:Pchar;

begin
  if calculated_cmdline=nil then
    setupcmdline;
  get_cmdline:=calculated_cmdline;
end;

{*****************************************************************************
                         SystemUnit Initialization
*****************************************************************************}

function  reenable_signal(sig : longint) : boolean;
var
  e : TSigSet;
  i,j : byte;
  olderrno: cint;
begin
  fillchar(e,sizeof(e),#0);
  { set is 1 based PM }
  dec(sig);
  i:=sig mod (sizeof(cuLong) * 8);
  j:=sig div (sizeof(cuLong) * 8);
  e[j]:=1 shl i;
  { this routine is called from a signal handler, so must not change errno }
  olderrno:=geterrno;
  fpsigprocmask(SIG_UNBLOCK,@e,nil);
  reenable_signal:=geterrno=0;
  seterrno(olderrno);
end;

// signal handler is arch dependant due to processorexception to language
// exception translation

{$i i386\sighnd.inc}

procedure InstallDefaultSignalHandler(signum: longint; out oldact: SigActionRec); public name '_FPC_INSTALLDEFAULTSIGHANDLER';
var
  act: SigActionRec;
begin
  { Initialize the sigaction structure }
  { all flags and information set to zero }
  FillChar(act, sizeof(SigActionRec),0);
  { initialize handler                    }
  act.sa_handler := SigActionHandler(@SignalToRunError);
  act.sa_flags:=SA_SIGINFO;
  FpSigAction(signum,@act,@oldact);
end;

var
  oldsigfpe: SigActionRec; public name '_FPC_OLDSIGFPE';
  oldsigsegv: SigActionRec; public name '_FPC_OLDSIGSEGV';
  oldsigbus: SigActionRec; public name '_FPC_OLDSIGBUS';
  oldsigill: SigActionRec; public name '_FPC_OLDSIGILL';

Procedure InstallSignals;
begin
  InstallDefaultSignalHandler(SIGFPE,oldsigfpe);
  InstallDefaultSignalHandler(SIGSEGV,oldsigsegv);
  InstallDefaultSignalHandler(SIGBUS,oldsigbus);
  InstallDefaultSignalHandler(SIGILL,oldsigill);
end;

procedure SysInitStdIO;
begin
  OpenStdIO(Input,fmInput,StdInputHandle);
  OpenStdIO(Output,fmOutput,StdOutputHandle);
  OpenStdIO(ErrOutput,fmOutput,StdErrorHandle);
  OpenStdIO(StdOut,fmOutput,StdOutputHandle);
  OpenStdIO(StdErr,fmOutput,StdErrorHandle);
end;

Procedure RestoreOldSignalHandlers;
begin
  FpSigAction(SIGFPE,@oldsigfpe,nil);
  FpSigAction(SIGSEGV,@oldsigsegv,nil);
  FpSigAction(SIGBUS,@oldsigbus,nil);
  FpSigAction(SIGILL,@oldsigill,nil);
end;


procedure SysInitExecPath;
var
  i    : longint;
begin
  execpathstr[0]:=#0;
  i:=Fpreadlink('/proc/self/exe',@execpathstr[1],high(execpathstr));
  { it must also be an absolute filename, linux 2.0 points to a memory
    location so this will skip that }
  if (i>0) and (execpathstr[1]='/') then
     execpathstr[0]:=char(i);
end;

function GetProcessID: SizeUInt;
begin
 GetProcessID := SizeUInt (fpGetPID);
end;

{$ifdef FPC_USE_LIBC}
{$ifdef HAS_UGETRLIMIT}
    { there is no ugetrlimit libc call, just map it to the getrlimit call in these cases }
function FpUGetRLimit(resource : cInt; rlim : PRLimit) : cInt; cdecl; external clib name 'getrlimit';
{$endif}
{$endif}

function CheckInitialStkLen(stklen : SizeUInt) : SizeUInt;
var
  limits : TRLimit;
  success : boolean;
begin
  success := false;
  fillchar(limits, sizeof(limits), 0);
  {$ifdef has_ugetrlimit}
  success := fpugetrlimit(RLIMIT_STACK, @limits)=0;
  {$endif}
  {$ifndef NO_SYSCALL_GETRLIMIT}
  if (not success) then
    success := fpgetrlimit(RLIMIT_STACK, @limits)=0;
  {$endif}
  if (success) and (limits.rlim_cur < stklen) then
    result := limits.rlim_cur
  else
    result := stklen;
end;

var
  initialstkptr : Pointer;external name '__stkptr';
begin
{$if defined(i386) and not defined(FPC_USE_LIBC)}
  InitSyscallIntf;
{$endif}

{$ifndef FPUNONE}
{$if defined(cpupowerpc)}
  // some PPC kernels set the exception bits FE0/FE1 in the MSR to zero,
  // disabling all FPU exceptions. Enable them again.
  fpprctl(PR_SET_FPEXC, PR_FP_EXC_PRECISE);
{$endif}
{$endif}
  IsConsole := TRUE;
  StackLength := CheckInitialStkLen(initialStkLen);
  StackBottom := initialstkptr - StackLength;
  { Set up signals handlers (may be needed by init code to test cpu features) }
  InstallSignals;
{$if defined(cpui386) or defined(cpuarm)}
  fpc_cpucodeinit;
{$endif cpui386}

  { Setup heap }
  InitHeap;
  SysInitExceptions;
  initunicodestringmanager;
  { Setup stdin, stdout and stderr }
  SysInitStdIO;
  { Arguments }
  SysInitExecPath;
  { Reset IO Error }
  InOutRes:=0;
  { threading }
  InitSystemThreads;
  { restore original signal handlers in case this is a library }
  if IsLibrary then
    RestoreOldSignalHandlers;
end.

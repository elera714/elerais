{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: process.pp
  Dosya ��levi: program (proses) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 12/08/2017

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit process;

interface

uses shared, control, ports;

const
  // bir s�re� (process) i�in tan�mlanan maximum olay say�s�
  // olay belle�i 4K olarak tan�mlanm��t�r. 4096 / SizeOf(TEvent)
  MAX_EVENT = 64;
  PROGRAM_EXTRA_MEM = 0; // (4096 * 3); d�zeltmeyi unutma

type
  PProcess = ^TProcess;
  TProcess = object
  private
    FMemSize: LongWord;             // i�lemin kulland��� bellek uzunlu�u
    FStartAddr: LongWord;           // i�lemin bellek ba�lang�� adresi
    FStackAddr: LongWord;           // i�lemin y���n adresi
    FEvCount: LongWord;             // olay sayac�
    FEvBuffer: PEv;                 // olaylar�n yerle�tirilece�i bellek b�lgesi
    procedure SetTaskCounter(ATaskCounter: LongWord);
    procedure SetEvCount(AEvCount: LongWord);
    procedure SetName(APID: TPID; AName: string);
  protected
    function Create: PProcess;
    function FindProcesSlot: PProcess;
    procedure CreateSelectors;
  public
    FPID: TPID;                     // i�lem numaras�
    FState: TProcessState;          // i�lem durumu
    FTaskCounter: LongWord;         // g�rev de�i�im sayac�
    FLoadedMemAddr: LongWord;       // i�lemin y�klendi�i bellek adresi
    FName: string;                  // i�lem ad�
    procedure Init;
    function Execute(FullName: string; PAddr: Pointer): PProcess;
    function Execute2(FullName: string; PAddr: Pointer): PProcess;
    function Execute3(FullName: string; PAddr: Pointer): PProcess;
    procedure SetState(APID: TPID; AState: TProcessState);
    procedure EventAdd1(APID: TPID; Obj: PControl; Event, Param1, Param2: Integer);
    procedure EventAdd2(APID: TPID; Ev: TEv);
    function EventGet(var Ev: TEv): Boolean;
    function Terminate(APID: TPID; const Reason: Byte = $FF): LongInt;
    property EvBuffer: PEv read FEvBuffer write FEvBuffer;
  published
    property PID: TPID read FPID;
    property LoadedMemAddr: LongWord read FLoadedMemAddr write FLoadedMemAddr;
    property MemSize: LongWord read FMemSize write FMemSize;
    property StartAddr: LongWord read FStartAddr write FStartAddr;
    property StackAddr: LongWord read FStackAddr write FStackAddr;
    property TaskCounter: LongWord read FTaskCounter write SetTaskCounter;
    property EvCount: LongWord read FEvCount write SetEvCount;
  end;

function GetCreatedProcessInfo(Index: Integer): PProcess;
function GetCreatedProcessIndex(Index: Integer): TPID;
function FindNextProcessToRun: TPID;
function GetRelatedPrograms(Ext: string): string;

implementation

uses gvars, gdt, partman, files, macmsg, convert, timer, vobject, sysmngr;

const
  SException: array[0..15] of string = (
    ('S�f�ra B�lme Hatas�'),
    ('Hata Ay�klama'),
    ('Engellenemeyen Kesme'),
    ('Durma Noktas�'),
    ('Ta�ma Hatas�'),
    ('Dizi Aral��� A�ma Hatas�'),
    ('Hatal� ��lemci Kodu'),
    ('Matematik ��lemci Mevcut De�il'),
    ('�ifte Hata'),
    ('Matematik ��lemci Yazma� Hatas�'),
    ('Hatal� TSS Giri�i'),
    ('Yazma� Mevcut De�il'),
    ('Y���n Hatas�'),
    ('Genel Koruma Hatas�'),
    ('Sayfa Hatas�'),
    ('Hata No: 15 - Tan�mlanmam��'));

type
  TRelatedPrograms = record
    Ext: string;
    Name: string;
  end;

const
  DEFRELATED_PROGS = 3;
  RelatedPrograms: array[0..DEFRELATED_PROGS - 1] of TRelatedPrograms = (
    (Ext: ''; Name: 'dsybil.c'),            // her dosya i�in default program
    (Ext: 'bmp'; Name: 'resimgor.c'),
    (Ext: 'txt'; Name: 'defter.c'));

{==============================================================================
  �al��t�r�lacak i�lemlerin ana y�kleme i�levlerini i�erir
 ==============================================================================}
procedure TProcess.Init;
var
  i: Integer;
  p: PProcess;
begin

  // i�lem bilgilerinin yerle�tirilmesi i�in bellek ay�r
  p := GMem.Alloc(SizeOf(TProcess) * MAX_PROCESSES);

  // bellek giri�lerini i�lem yap�lar�yla e�le�tir
  for i := 1 to MAX_PROCESSES do
  begin

    ArrProcesses[i] := p;

    // i�lemi bo� olarak belirle
    p^.FState := psFree;
    p^.FPID := i;

    Inc(p);
  end;
end;

{==============================================================================
  program dosyalar�n� �al��t�r�r
 ==============================================================================}
function TProcess.Execute(FullName: string; PAddr: Pointer): PProcess;
var
  p: PProcess;
  FileBuffer: Pointer;
  EventBuffer: PEv;
  Size, i: Integer;
  Drive, Dir,
  FileName: string;
  FileHandle: THandle;
  ELFHeader: PELFHeader;
  FullPath, Params,
  Ext: string;
  p1: PChar;
  p2: PByte;
begin

  asm cli end;

  // bo� i�lem giri�i bul
  p := p^.Create;
  if(p = nil) then
  begin

    //MSG_S('PROCESS.PP: ' + FullName + ' i�in proses olu�turulam�yor!');
    MSG_S('PROCESS.PP: program i�in proses olu�turulam�yor!');
    Result := nil;
    Exit;
  end;

  // dosyay� s�r�c� + dizin + dosya par�alar�na ay�r
  ProcessPath(FullName, Drive, Dir, FileName);

  // dosya ad�n�n uzunlu�unu al
  Size := Length(FileName);

  { TODO : .c dosyalar� ileride .� (�al��t�r�labilir) olarak de�i�tirilecek. }

  // dosya uzant�s�n� al
  i := Pos('.', FileName);
  if(i > 0) then Ext := Copy(FileName, i + 1, Size - i) else Ext := '';

  // dosya �al��t�r�labilir bir dosya de�il ise
  // dosya ile ilgili ili�kili program� bul
  if(Ext <> 'c') then
  begin

    // e�er dosya �al��t�r�labilir de�il ise
    // a��l�� ayg�t�ndan ili�kili program� ata
    Params := Drive + ':\' + FileName;
    FileName := GetRelatedPrograms(Ext);
    FullPath := BootDev + ':\' + FileName;
  end
  else
  begin

    Params := '';
    FullPath := Drive + ':\' + FileName;
  end;

  // �al��t�r�lacak dosyay� tan�mla ve a�
  AssignFile(FileHandle, FullPath);
  Reset(FileHandle);
  if(IOResult = 0) then
  begin

    // dosya uzunlu�unu al
    Size := FileSize(FileHandle);
    //Size := 4096*4;

    // dosyan�n �al��t�r�lmas� i�in bellekte yer rezerv et
    FileBuffer := GMem.Alloc(Size + PROGRAM_EXTRA_MEM);
    if(FileBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: program i�in yeterli bellek yok!');
      Result := nil;
      Exit;
    end;

    //MoveEx(PAddr, FileBuffer + $1000, 4095);

    {p2 := FileBuffer;
    p2^ := $B8;
    Inc(p2);
    p2^ := $01;
    Inc(p2);
    p2^ := $00;
    Inc(p2);
    p2^ := $00;
    Inc(p2);
    p2^ := $00;
    Inc(p2);
    p2^ := $CD;
    Inc(p2);
    p2^ := $35;
    Inc(p2);
    p2^ := $EB;
    Inc(p2);
    p2^ := $F7;}

    // MSG_SH('PROCESS.PP Bellek Adresi: ', Integer(FileBuffer), 8);

    // dosyay� hedef adrese kopyala
    if(Read(FileHandle, FileBuffer) = 0) then
    begin

      // dosyay� kapat
      CloseFile(FileHandle);
      MSG_S('PROCESS.PP: ' + FullPath + ' dosyas� okunam�yor!');
      Result := nil;
      Exit;
    end;

    // dosyay� kapat
    CloseFile(FileHandle);

    // olay i�lemleri i�in bellekte yer rezerv et
    {EventBuffer := PEv(GMem.Alloc(4096));
    if(EventBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: Olay bilgisi i�in bellek ayr�lam�yor!');
      Result := nil;
      Exit;
    end;}

    // bellek ba�lang�� adresi
    p^.FLoadedMemAddr := LongWord(FileBuffer);

    // bellek miktar�
    p^.FMemSize := Size + PROGRAM_EXTRA_MEM;

    // elf format�ndaki dosyan�n ba� taraf�na konumlan
    ELFHeader := FileBuffer;

    // i�lem ba�lang�� adresi
    p^.FStartAddr := ELFHeader^.e_entry;
    //p^.FStartAddr := $1000;

    // i�lemin y���m adresi
    p^.FStackAddr := (Size + PROGRAM_EXTRA_MEM) - 256;

    // dosyan�n �al��t�r�lmas� i�in selekt�rleri olu�tur
    p^.CreateSelectors;

    // i�lemin g�rev de�i�im sayac�n� s�f�rla
    p^.FTaskCounter := 0;

    // i�lemin olay sayac�n� s�f�rla
    p^.FEvCount := 0;

    // i�lemin olay bellek b�lgesini ata
    //p^.FEvBuffer := EventBuffer;
    p^.FEvBuffer := nil;

    // i�lemin ad�
    p^.FName := FileName;

    // parametre g�nderimi
    // ilk parametre - �al��an i�lemin ad�
    {PLongWord(FileBuffer)^ := 0;
    p1 := PChar(FileBuffer + 4);
    MoveEx(@FullPath[1], p1, Length(FullPath));
    p1 += Length(FullPath);
    p1^ := #0;}

    // e�er varsa ikinci parametre - �al��an program�n kullanaca�� de�er
    {if(Params <> '') then
    begin

      PLongWord(FileBuffer)^ := 1;
      Inc(p1);
      MoveEx(@Params[1], p1, Length(Params));
      p1 += Length(Params);
      p1^ := #0;
    end;}

    // i�lemin durumunu �al���yor olarak belirle
    p^.FState := psRunning;

    // olu�turulan i�lem say�s�n� bir art�r
    Inc(CreatedProcess);

    // i�lemin bellek adresini geri d�nd�r
    Result := @Self;

    asm sti end;
  end
  {else
  begin

    //CloseFile(FileHandle);
    p^.SetState(p^.PID, psFree);
    MSG_S('PROCESS.PP: ' + FullPath + ' dosyas� bulunamad�!');
  end;}
end;

{==============================================================================
  program dosyalar�n� �al��t�r�r
 ==============================================================================}
function TProcess.Execute2(FullName: string; PAddr: Pointer): PProcess;
var
  p: PProcess;
  FileBuffer: Pointer;
  EventBuffer: PEv;
  Size, i: Integer;
  Drive, Dir,
  FileName: string;
  FileHandle: THandle;
  ELFHeader: PELFHeader;
  FullPath, Params,
  Ext: string;
  p1: PChar;
  p2: PByte;
begin

  asm cli end;

  // bo� i�lem giri�i bul
  p := p^.Create;
  if(p = nil) then
  begin

    //MSG_S('PROCESS.PP: ' + FullName + ' i�in proses olu�turulam�yor!');
    MSG_S('PROCESS.PP: program i�in proses olu�turulam�yor!');
    Result := nil;
    Exit;
  end;

  // dosyay� s�r�c� + dizin + dosya par�alar�na ay�r
  //ProcessPath(FullName, Drive, Dir, FileName);

  // dosya ad�n�n uzunlu�unu al
  //Size := Length(FileName);

  { TODO : .c dosyalar� ileride .� (�al��t�r�labilir) olarak de�i�tirilecek. }

  // dosya uzant�s�n� al
  {i := Pos('.', FileName);
  if(i > 0) then Ext := Copy(FileName, i + 1, Size - i) else Ext := '';}

  // dosya �al��t�r�labilir bir dosya de�il ise
  // dosya ile ilgili ili�kili program� bul
  {if(Ext <> 'c') then
  begin

    // e�er dosya �al��t�r�labilir de�il ise
    // a��l�� ayg�t�ndan ili�kili program� ata
    Params := Drive + ':\' + FileName;
    FileName := GetRelatedPrograms(Ext);
    FullPath := BootDev + ':\' + FileName;
  end
  else
  begin

    Params := '';
    FullPath := Drive + ':\' + FileName;
  end;

  // �al��t�r�lacak dosyay� tan�mla ve a�
  AssignFile(FileHandle, FullPath);
  Reset(FileHandle);
  if(IOResult = 0) then}
  begin

    // dosya uzunlu�unu al
    //Size := FileSize(FileHandle);
    Size := 8191;

    // dosyan�n �al��t�r�lmas� i�in bellekte yer rezerv et
    FileBuffer := GMem.Alloc(Size + PROGRAM_EXTRA_MEM);
    if(FileBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: program i�in yeterli bellek yok!');
      Result := nil;
      Exit;
    end;

    MoveEx(PAddr, FileBuffer + $1000, 4095);

    {p2 := FileBuffer;
    p2^ := $B8;
    Inc(p2);
    p2^ := $01;
    Inc(p2);
    p2^ := $00;
    Inc(p2);
    p2^ := $00;
    Inc(p2);
    p2^ := $00;
    Inc(p2);
    p2^ := $CD;
    Inc(p2);
    p2^ := $35;
    Inc(p2);
    p2^ := $EB;
    Inc(p2);
    p2^ := $F7;}

    // MSG_SH('PROCESS.PP Bellek Adresi: ', Integer(FileBuffer), 8);

    // dosyay� hedef adrese kopyala
    {if(Read(FileHandle, FileBuffer) = 0) then
    begin

      // dosyay� kapat
      CloseFile(FileHandle);
      MSG_S('PROCESS.PP: ' + FullPath + ' dosyas� okunam�yor!');
      Result := nil;
      Exit;
    end;

    // dosyay� kapat
    CloseFile(FileHandle);

    // olay i�lemleri i�in bellekte yer rezerv et
    EventBuffer := PEv(GMem.Alloc(4096));
    if(EventBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: Olay bilgisi i�in bellek ayr�lam�yor!');
      Result := nil;
      Exit;
    end;}

    // bellek ba�lang�� adresi
    p^.FLoadedMemAddr := LongWord(FileBuffer);

    // bellek miktar�
    p^.FMemSize := Size + PROGRAM_EXTRA_MEM;

    // elf format�ndaki dosyan�n ba� taraf�na konumlan
    //ELFHeader := FileBuffer;

    // i�lem ba�lang�� adresi
    //p^.FStartAddr := ELFHeader^.e_entry;
    p^.FStartAddr := $1000;

    // i�lemin y���m adresi
    p^.FStackAddr := (Size + PROGRAM_EXTRA_MEM) - 256;

    // dosyan�n �al��t�r�lmas� i�in selekt�rleri olu�tur
    p^.CreateSelectors;

    // i�lemin g�rev de�i�im sayac�n� s�f�rla
    p^.FTaskCounter := 0;

    // i�lemin olay sayac�n� s�f�rla
    p^.FEvCount := 0;

    // i�lemin olay bellek b�lgesini ata
    //p^.FEvBuffer := EventBuffer;
    p^.FEvBuffer := nil;

    // i�lemin ad�
    p^.FName := FileName;

    // parametre g�nderimi
    // ilk parametre - �al��an i�lemin ad�
    {PLongWord(FileBuffer)^ := 0;
    p1 := PChar(FileBuffer + 4);
    MoveEx(@FullPath[1], p1, Length(FullPath));
    p1 += Length(FullPath);
    p1^ := #0;}

    // e�er varsa ikinci parametre - �al��an program�n kullanaca�� de�er
    {if(Params <> '') then
    begin

      PLongWord(FileBuffer)^ := 1;
      Inc(p1);
      MoveEx(@Params[1], p1, Length(Params));
      p1 += Length(Params);
      p1^ := #0;
    end;}

    // i�lemin durumunu �al���yor olarak belirle
    p^.FState := psRunning;

    // olu�turulan i�lem say�s�n� bir art�r
    Inc(CreatedProcess);

    // i�lemin bellek adresini geri d�nd�r
    Result := @Self;

    asm sti end;
  end
  {else
  begin

    //CloseFile(FileHandle);
    p^.SetState(p^.PID, psFree);
    MSG_S('PROCESS.PP: ' + FullPath + ' dosyas� bulunamad�!');
  end;}
end;

{==============================================================================
  program dosyalar�n� �al��t�r�r
 ==============================================================================}
function TProcess.Execute3(FullName: string; PAddr: Pointer): PProcess;
var
  p: PProcess;
  FileBuffer: Pointer;
  EventBuffer: PEv;
  Size, i: Integer;
  Drive, Dir,
  FileName: string;
  FileHandle: THandle;
  ELFHeader: PELFHeader;
  FullPath, Params,
  Ext: string;
  p1: PChar;
  p2: PByte;
begin

  asm cli end;

  // bo� i�lem giri�i bul
  p := p^.Create;
  if(p = nil) then
  begin

    //MSG_S('PROCESS.PP: ' + FullName + ' i�in proses olu�turulam�yor!');
    MSG_S('PROCESS.PP: program i�in proses olu�turulam�yor!');
    Result := nil;
    Exit;
  end;

  // dosyay� s�r�c� + dizin + dosya par�alar�na ay�r
  ProcessPath(FullName, Drive, Dir, FileName);

  // dosya ad�n�n uzunlu�unu al
  Size := Length(FileName);

  { TODO : .c dosyalar� ileride .� (�al��t�r�labilir) olarak de�i�tirilecek. }

  // dosya uzant�s�n� al
  i := Pos('.', FileName);
  if(i > 0) then Ext := Copy(FileName, i + 1, Size - i) else Ext := '';

  // dosya �al��t�r�labilir bir dosya de�il ise
  // dosya ile ilgili ili�kili program� bul
  if(Ext <> 'c') then
  begin

    // e�er dosya �al��t�r�labilir de�il ise
    // a��l�� ayg�t�ndan ili�kili program� ata
    Params := Drive + ':\' + FileName;
    FileName := GetRelatedPrograms(Ext);
    FullPath := BootDev + ':\' + FileName;
  end
  else
  begin

    Params := '';
    FullPath := Drive + ':\' + FileName;
  end;

  // �al��t�r�lacak dosyay� tan�mla ve a�
  AssignFile(FileHandle, FullPath);
  Reset(FileHandle);
  if(IOResult = 0) then
  begin

    // dosya uzunlu�unu al
    Size := FileSize(FileHandle);
    //Size := 4096*4;

    // dosyan�n �al��t�r�lmas� i�in bellekte yer rezerv et
    FileBuffer := GMem.Alloc(Size + PROGRAM_EXTRA_MEM);
    if(FileBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: program i�in yeterli bellek yok!');
      Result := nil;
      Exit;
    end;

    //MoveEx(PAddr, FileBuffer + $1000, 4095);

    {p2 := FileBuffer;
    p2^ := $B8;
    Inc(p2);
    p2^ := $01;
    Inc(p2);
    p2^ := $00;
    Inc(p2);
    p2^ := $00;
    Inc(p2);
    p2^ := $00;
    Inc(p2);
    p2^ := $CD;
    Inc(p2);
    p2^ := $35;
    Inc(p2);
    p2^ := $EB;
    Inc(p2);
    p2^ := $F7;}

    // MSG_SH('PROCESS.PP Bellek Adresi: ', Integer(FileBuffer), 8);

    // dosyay� hedef adrese kopyala
    if(Read(FileHandle, FileBuffer) = 0) then
    begin

      // dosyay� kapat
      CloseFile(FileHandle);
      MSG_S('PROCESS.PP: ' + FullPath + ' dosyas� okunam�yor!');
      Result := nil;
      Exit;
    end;

    // dosyay� kapat
    CloseFile(FileHandle);

    // olay i�lemleri i�in bellekte yer rezerv et
    {EventBuffer := PEv(GMem.Alloc(4096));
    if(EventBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: Olay bilgisi i�in bellek ayr�lam�yor!');
      Result := nil;
      Exit;
    end;}

    MoveEx(FileBuffer, FileBuffer + $1000, 300);

    // bellek ba�lang�� adresi
    p^.FLoadedMemAddr := LongWord(FileBuffer);

    // bellek miktar�
    p^.FMemSize := Size + PROGRAM_EXTRA_MEM;

    // elf format�ndaki dosyan�n ba� taraf�na konumlan
    //ELFHeader := FileBuffer;

    // i�lem ba�lang�� adresi
    //p^.FStartAddr := ELFHeader^.e_entry;
    p^.FStartAddr := $1000;

    // i�lemin y���m adresi
    p^.FStackAddr := (Size + PROGRAM_EXTRA_MEM) - 256;

    // dosyan�n �al��t�r�lmas� i�in selekt�rleri olu�tur
    p^.CreateSelectors;

    // i�lemin g�rev de�i�im sayac�n� s�f�rla
    p^.FTaskCounter := 0;

    // i�lemin olay sayac�n� s�f�rla
    p^.FEvCount := 0;

    // i�lemin olay bellek b�lgesini ata
    //p^.FEvBuffer := EventBuffer;
    p^.FEvBuffer := nil;

    // i�lemin ad�
    p^.FName := FileName;

    // parametre g�nderimi
    // ilk parametre - �al��an i�lemin ad�
    {PLongWord(FileBuffer)^ := 0;
    p1 := PChar(FileBuffer + 4);
    MoveEx(@FullPath[1], p1, Length(FullPath));
    p1 += Length(FullPath);
    p1^ := #0;}

    // e�er varsa ikinci parametre - �al��an program�n kullanaca�� de�er
    {if(Params <> '') then
    begin

      PLongWord(FileBuffer)^ := 1;
      Inc(p1);
      MoveEx(@Params[1], p1, Length(Params));
      p1 += Length(Params);
      p1^ := #0;
    end;}

    // i�lemin durumunu �al���yor olarak belirle
    p^.FState := psRunning;

    // olu�turulan i�lem say�s�n� bir art�r
    Inc(CreatedProcess);

    // i�lemin bellek adresini geri d�nd�r
    Result := @Self;

    asm sti end;
  end
  {else
  begin

    //CloseFile(FileHandle);
    p^.SetState(p^.PID, psFree);
    MSG_S('PROCESS.PP: ' + FullPath + ' dosyas� bulunamad�!');
  end;}
end;

{==============================================================================
  �al��acak i�lem i�in bo� yer olu�turur
 ==============================================================================}
function TProcess.Create: PProcess;
var
  p: PProcess;
begin

  // bo� i�lem giri�i bul
  p := p^.FindProcesSlot;

  Result := p;
end;

{==============================================================================
  �al��t�r�lacak i�lem i�in bo� i�lem giri�i bulur
 ==============================================================================}
function TProcess.FindProcesSlot: PProcess;
var
  p: PProcess;
  i: Byte;
begin

  // t�m i�lem giri�lerini incele
  for i := 2 to MAX_PROCESSES do
  begin

    p := ArrProcesses[i];

    // e�er i�lem giri�i bo� ise
    if(P^.FState = psFree) then
    begin

      // OLU�TURULDU olarak i�aretle ve �a��ran i�leve geri d�n
      P^.SetState(i, psCreated);
      Result := p;
      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  i�lem i�in tss giri�lerini olu�turur
 ==============================================================================}
procedure TProcess.CreateSelectors;
var
  SelCSIdx, SelDSIdx,
  SelTSSIdx, i: TPID;
  Limit: LongWord;
begin

  i := PID;

  Limit := FMemSize shr 12;

  // uygulaman�n TSS, CS, DS selekt�rlerini belirle
  SelTSSIdx := i * 3;
  SelDSIdx := SelTSSIdx - 1;
  SelCSIdx := SelDSIdx - 1;

  // uygulama i�in CS selekt�r�n� olu�tur
  // access = p, dpl3, 1, 1, conforming, readable, accessed
  // gran = gran = 1, default = 1, 0, avl = 1, limit (4 bit)
  SetGDTEntry(SelCSIdx, FLoadedMemAddr, Limit, $FA, $D0);

  // uygulama i�in DS selekt�r�n� olu�tur
  // access = p, dpl3, 1, 0, exp direction, writable, accessed
  // gran = gran = 1, big = 1, 0, avl = 1, limit (4 bit)
  SetGDTEntry(SelDSIdx, FLoadedMemAddr, Limit, $F2, $D0);

  // uygulama i�in TSS selekt�r�n� olu�tur
  // access = p, dpl3, 0, 1, 0, 0 (non_busy), 1
  // gran = g = 0, 0, 0, avl = 1, limit (4 bit)
  SetGDTEntry(SelTSSIdx, LongWord(@TSSArr[i]), SizeOf(TTSS) - 1, $E9, $10);

  // TSS'nin i�eri�ini s�f�rla
  FillByte(TSSArr[i], SizeOf(TTSS), 0);

  // TSS i�eri�ini doldur
  TSSArr[i].CR3 := PDIR_MEM or 7;
  TSSArr[i].EIP := FStartAddr;
  TSSArr[i].EFLAGS := $202;
  TSSArr[i].ESP := FStackAddr;
  TSSArr[i].CS := (SelCSIdx * 8) + 3;
  TSSArr[i].DS := (SelDSIdx * 8) + 3;
  TSSArr[i].ES := (SelDSIdx * 8) + 3;
  TSSArr[i].SS := (SelDSIdx * 8) + 3;
  TSSArr[i].FS := (SelDSIdx * 8) + 3;
  TSSArr[i].GS := (SelDSIdx * 8) + 3;
  TSSArr[i].SS0 := SELOS_DATA;
  TSSArr[i].ESP0 := (i * PROCESSRING0_ESPSIZE) + PROCESSRING0_ESP;
end;

{==============================================================================
  i�lemin yeni �al��ma durumunu belirler
 ==============================================================================}
procedure TProcess.SetState(APID: TPID; AState: TProcessState);
var
  p: PProcess;
begin

  p := ArrProcesses[APID];
  if(AState <> p^.FState) then p^.FState := AState;
end;

{==============================================================================
  i�lemin g�rev sayac�n� belirler
 ==============================================================================}
procedure TProcess.SetTaskCounter(ATaskCounter: LongWord);
begin

  if(ATaskCounter <> FTaskCounter) then FTaskCounter := ATaskCounter;
end;

{==============================================================================
  i�lemin olay sayac�n� belirler
 ==============================================================================}
procedure TProcess.SetEvCount(AEvCount: LongWord);
begin

  if(AEvCount <> FEvCount) then FEvCount := AEvCount;
end;

{==============================================================================
  i�lemin olay ad�n� belirler
 ==============================================================================}
procedure TProcess.SetName(APID: TPID; AName: string);
var
  p: PProcess;
begin

  p := ArrProcesses[APID];
  if(p^.FState = psRunning) then Exit;

  p^.FName := AName;
end;

{==============================================================================
  �ekirdek taraf�ndan i�lem i�in olu�turulan olay� kaydeder
  not: bu i�lev g�rsel nesneler i�indir
 ==============================================================================}
procedure TProcess.EventAdd1(APID: TPID; Obj: PControl; Event, Param1, Param2: Integer);
var
  E: PEv;
  p: PProcess;
begin

  p := ArrProcesses[APID];

  if(p^.FState = psRunning) then
  begin

    // olay belle�i dolu de�ilse, olay� kaydet
    if(p^.FEvCount < MAX_EVENT) then
    begin

      // i�lemin olay belle�ine konumlan
      E := p^.FEvBuffer;
      Inc(E, p^.FEvCount);

      // olay� i�lem belle�ine kaydet
      E^.Handle := Obj^.Handle;
      E^.Event := Event;
      E^.Param1 := Param1;
      E^.Param2 := Param2;

      // i�lemin olay sayac�n� art�r
      p^.FEvCount := p^.FEvCount + 1;
    end;
  end;
end;

{==============================================================================
  �ekirdek taraf�ndan i�lem i�in olu�turulan olay� kaydeder
  not: bu i�lev g�rsel olmayan nesneler i�indir
 ==============================================================================}
procedure TProcess.EventAdd2(APID: TPID; Ev: TEv);
var
  E: PEv;
  p: PProcess;
begin

  p := ArrProcesses[APID];

  if(p^.FState = psRunning) then
  begin

    // olay belle�i dolu de�ilse, olay� kaydet
    if(p^.EvCount < MAX_EVENT) then
    begin

      // i�lemin olay belle�ine konumlan
      E := p^.EvBuffer;
      Inc(E, p^.EvCount);

      // olay� i�lem belle�ine kaydet
      E^.Handle := Ev.Handle;
      E^.Event := Ev.Event;
      E^.Param1 := Ev.Param1;
      E^.Param2 := Ev.Param2;

      // i�lemin olay sayac�n� art�r
      p^.EvCount := p^.EvCount + 1;
    end;
  end;
end;

{==============================================================================
  i�lem i�in (kernel taraf�ndan) olu�turulan olay� al�r
 ==============================================================================}
function TProcess.EventGet(var Ev: TEv): Boolean;
var
  E, E2: PEv;
begin

  // default ��k�� de�eri
  Result := False;

  // i�lem i�in olu�turulan olay yoksa ��k
  if(EvCount = 0) then Exit;

  // default ��k�� de�eri
  Result := True;

  // i�lemin olay belle�ine konumlan
  E := EvBuffer;

  // olaylar� hedef alana kopyala
  Ev.Event := E^.Event;
  Ev.Handle := E^.Handle;
  Ev.Param1 := E^.Param1;
  Ev.Param2 := E^.Param2;

  // i�lemin olay sayac�n� azalt
  EvCount := EvCount - 1;

  // tek bir olay var ise olay belle�ini g�ncellemeye gerek yok
  if(EvCount = 0) then Exit;

  // event'i proses'in event buffer'�ndan sil
  E2 := E;
  Inc(E2);

  MoveEx(E2, E, SizeOf(TEv) * EvCount);
end;

{==============================================================================
  �al��an i�lemi sonland�r�r
 ==============================================================================}
function TProcess.Terminate(APID: TPID; const Reason: Byte = $FF): LongInt;
var
  p: PProcess;
begin

  cli;

  // �al��an i�lemi �ncelikle durdur
  p^.SetState(APID, psStopped);

  // i�lemin sonland�r�lma bilgisini ver
  if(Reason = $FF) then
  begin

    MSG_S('PROCESS.PP: ' + ArrProcesses[APID]^.FName + ' normal bir �ekilde sonland�r�ld�');
  end
  else
  begin

    MSG_S('PROCESS.PP: ' + ArrProcesses[APID]^.FName + ' program� sonland�r�ld�');
    MSG_S('PROCESS.PP: Hata Kodu: ' + IntToStr(Reason) + ' - ' + SException[Reason]);
  end;

  // i�leme ait zamanlay�c�lar� yok et
  DestroyTimers(APID);

  { TODO : G�rsel olmayan nesnelerin bellekten at�lmas�nda (TProcess.Terminate)
    g�rsel i�levlerin �al��mamas� sa�lanacak }

  // i�leme ait g�rsel nesneleri yok et
  DestroyProcessObjects(APID);

  // i�leme ait olay bellek b�lgesini iptal et
  GMem.Destroy(EvBuffer, 4096);

  // i�lem i�in ayr�lan bellek b�lgesini serbest b�rak
  GMem.Destroy(Pointer(LoadedMemAddr), FMemSize + PROGRAM_EXTRA_MEM);

  // �al��an i�lemi i�lem listesinden ��kart
  SetState(APID, psFree);

  // i�lem say�s�n� bir azalt
  Dec(CreatedProcess);

  GCurrentDesktop^.Update;

  sti;

  asm jmp OSControl; end;
end;

{==============================================================================
  i�lem ile ilgili bellek b�lgesini geri d�nd�r�r
 ==============================================================================}
function GetCreatedProcessInfo(Index: Integer): PProcess;
var
  i, j: Integer;
begin

  // aranacak index numaras�
  j := 0;

  // t�m i�lem bellek b�lgelerini ara�t�r
  for i := 1 to MAX_PROCESSES do
  begin

    // e�er i�lem bo� de�il ise index numaras�n� bir art�r
    if not(ArrProcesses[i]^.FState = psFree) then Inc(j);

    // aranan index ile i�lem s�ras� ayn� ise i�lem bellek b�lgesini geri d�nd�r
    if(Index = j) then
    begin

      Result := ArrProcesses[i];
      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  i�lemin bellek index numaras�n� geri d�nd�r�r
 ==============================================================================}
function GetCreatedProcessIndex(Index: Integer): TPID;
var
  i, j: Integer;
begin

  // aranacak index numaras�
  j := 0;

  // t�m i�lem bellek b�lgelerini ara�t�r
  for i := 1 to MAX_PROCESSES do
  begin

    // e�er i�lem �al���yor ise index numaras�n� bir art�r
    if(ArrProcesses[i]^.FState = psRunning) then Inc(j);

    // aranan index ile i�lem s�ras� ayn� ise i�lem bellek b�lgesini geri d�nd�r
    if(Index = j) then
    begin

      Result := i;
      Exit;
    end;
  end;

  Result := 0;
end;

{==============================================================================
  �al��t�r�lacak bir sonraki proses'i bulur
 ==============================================================================}
function FindNextProcessToRun: TPID;
var
  PID: TPID;
  i: Integer;
begin

  // �al��an proses'e konumlan
  PID := RunningProcess;

  // ve bir sonraki prosesten itibaren t�m prosesleri incele
  for i := 1 to MAX_PROCESSES do
  begin

    Inc(PID);
    if(PID > CreatedProcess) then PID := 1;

    // e�er �al��an proses ise �a��ran i�leve geri d�n
    if(ArrProcesses[PID]^.FState = psRunning) then Break;
  end;

  Result := PID;
end;

{==============================================================================
  dosya uzant�s� ile ili�kili program ad�n� geri d�nd�r�r
 ==============================================================================}
function GetRelatedPrograms(Ext: string): string;
var
  i: Byte;
begin

  // dosyalarla ili�kilendirilen default program
  Result := RelatedPrograms[0].Name;

  for i := 1 to DEFRELATED_PROGS - 1 do
  begin

    if(RelatedPrograms[i].Ext = Ext) then
    begin

      Result := RelatedPrograms[i].Name;
      Break;
    end;
  end;
end;

end.

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: process.pp
  Dosya Ýþlevi: program (proses) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 12/08/2017

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit process;

interface

uses shared, control, ports;

const
  // bir süreç (process) için tanýmlanan maximum olay sayýsý
  // olay belleði 4K olarak tanýmlanmýþtýr. 4096 / SizeOf(TEvent)
  MAX_EVENT = 64;
  PROGRAM_EXTRA_MEM = 0; // (4096 * 3); düzeltmeyi unutma

type
  PProcess = ^TProcess;
  TProcess = object
  private
    FMemSize: LongWord;             // iþlemin kullandýðý bellek uzunluðu
    FStartAddr: LongWord;           // iþlemin bellek baþlangýç adresi
    FStackAddr: LongWord;           // iþlemin yýðýn adresi
    FEvCount: LongWord;             // olay sayacý
    FEvBuffer: PEv;                 // olaylarýn yerleþtirileceði bellek bölgesi
    procedure SetTaskCounter(ATaskCounter: LongWord);
    procedure SetEvCount(AEvCount: LongWord);
    procedure SetName(APID: TPID; AName: string);
  protected
    function Create: PProcess;
    function FindProcesSlot: PProcess;
    procedure CreateSelectors;
  public
    FPID: TPID;                     // iþlem numarasý
    FState: TProcessState;          // iþlem durumu
    FTaskCounter: LongWord;         // görev deðiþim sayacý
    FLoadedMemAddr: LongWord;       // iþlemin yüklendiði bellek adresi
    FName: string;                  // iþlem adý
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
    ('Sýfýra Bölme Hatasý'),
    ('Hata Ayýklama'),
    ('Engellenemeyen Kesme'),
    ('Durma Noktasý'),
    ('Taþma Hatasý'),
    ('Dizi Aralýðý Aþma Hatasý'),
    ('Hatalý Ýþlemci Kodu'),
    ('Matematik Ýþlemci Mevcut Deðil'),
    ('Çifte Hata'),
    ('Matematik Ýþlemci Yazmaç Hatasý'),
    ('Hatalý TSS Giriþi'),
    ('Yazmaç Mevcut Deðil'),
    ('Yýðýn Hatasý'),
    ('Genel Koruma Hatasý'),
    ('Sayfa Hatasý'),
    ('Hata No: 15 - Tanýmlanmamýþ'));

type
  TRelatedPrograms = record
    Ext: string;
    Name: string;
  end;

const
  DEFRELATED_PROGS = 3;
  RelatedPrograms: array[0..DEFRELATED_PROGS - 1] of TRelatedPrograms = (
    (Ext: ''; Name: 'dsybil.c'),            // her dosya için default program
    (Ext: 'bmp'; Name: 'resimgor.c'),
    (Ext: 'txt'; Name: 'defter.c'));

{==============================================================================
  çalýþtýrýlacak iþlemlerin ana yükleme iþlevlerini içerir
 ==============================================================================}
procedure TProcess.Init;
var
  i: Integer;
  p: PProcess;
begin

  // iþlem bilgilerinin yerleþtirilmesi için bellek ayýr
  p := GMem.Alloc(SizeOf(TProcess) * MAX_PROCESSES);

  // bellek giriþlerini iþlem yapýlarýyla eþleþtir
  for i := 1 to MAX_PROCESSES do
  begin

    ArrProcesses[i] := p;

    // iþlemi boþ olarak belirle
    p^.FState := psFree;
    p^.FPID := i;

    Inc(p);
  end;
end;

{==============================================================================
  program dosyalarýný çalýþtýrýr
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

  // boþ iþlem giriþi bul
  p := p^.Create;
  if(p = nil) then
  begin

    //MSG_S('PROCESS.PP: ' + FullName + ' için proses oluþturulamýyor!');
    MSG_S('PROCESS.PP: program için proses oluþturulamýyor!');
    Result := nil;
    Exit;
  end;

  // dosyayý sürücü + dizin + dosya parçalarýna ayýr
  ProcessPath(FullName, Drive, Dir, FileName);

  // dosya adýnýn uzunluðunu al
  Size := Length(FileName);

  { TODO : .c dosyalarý ileride .ç (çalýþtýrýlabilir) olarak deðiþtirilecek. }

  // dosya uzantýsýný al
  i := Pos('.', FileName);
  if(i > 0) then Ext := Copy(FileName, i + 1, Size - i) else Ext := '';

  // dosya çalýþtýrýlabilir bir dosya deðil ise
  // dosya ile ilgili iliþkili programý bul
  if(Ext <> 'c') then
  begin

    // eðer dosya çalýþtýrýlabilir deðil ise
    // açýlýþ aygýtýndan iliþkili programý ata
    Params := Drive + ':\' + FileName;
    FileName := GetRelatedPrograms(Ext);
    FullPath := BootDev + ':\' + FileName;
  end
  else
  begin

    Params := '';
    FullPath := Drive + ':\' + FileName;
  end;

  // çalýþtýrýlacak dosyayý tanýmla ve aç
  AssignFile(FileHandle, FullPath);
  Reset(FileHandle);
  if(IOResult = 0) then
  begin

    // dosya uzunluðunu al
    Size := FileSize(FileHandle);
    //Size := 4096*4;

    // dosyanýn çalýþtýrýlmasý için bellekte yer rezerv et
    FileBuffer := GMem.Alloc(Size + PROGRAM_EXTRA_MEM);
    if(FileBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: program için yeterli bellek yok!');
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

    // dosyayý hedef adrese kopyala
    if(Read(FileHandle, FileBuffer) = 0) then
    begin

      // dosyayý kapat
      CloseFile(FileHandle);
      MSG_S('PROCESS.PP: ' + FullPath + ' dosyasý okunamýyor!');
      Result := nil;
      Exit;
    end;

    // dosyayý kapat
    CloseFile(FileHandle);

    // olay iþlemleri için bellekte yer rezerv et
    {EventBuffer := PEv(GMem.Alloc(4096));
    if(EventBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: Olay bilgisi için bellek ayrýlamýyor!');
      Result := nil;
      Exit;
    end;}

    // bellek baþlangýç adresi
    p^.FLoadedMemAddr := LongWord(FileBuffer);

    // bellek miktarý
    p^.FMemSize := Size + PROGRAM_EXTRA_MEM;

    // elf formatýndaki dosyanýn baþ tarafýna konumlan
    ELFHeader := FileBuffer;

    // iþlem baþlangýç adresi
    p^.FStartAddr := ELFHeader^.e_entry;
    //p^.FStartAddr := $1000;

    // iþlemin yýðým adresi
    p^.FStackAddr := (Size + PROGRAM_EXTRA_MEM) - 256;

    // dosyanýn çalýþtýrýlmasý için selektörleri oluþtur
    p^.CreateSelectors;

    // iþlemin görev deðiþim sayacýný sýfýrla
    p^.FTaskCounter := 0;

    // iþlemin olay sayacýný sýfýrla
    p^.FEvCount := 0;

    // iþlemin olay bellek bölgesini ata
    //p^.FEvBuffer := EventBuffer;
    p^.FEvBuffer := nil;

    // iþlemin adý
    p^.FName := FileName;

    // parametre gönderimi
    // ilk parametre - çalýþan iþlemin adý
    {PLongWord(FileBuffer)^ := 0;
    p1 := PChar(FileBuffer + 4);
    MoveEx(@FullPath[1], p1, Length(FullPath));
    p1 += Length(FullPath);
    p1^ := #0;}

    // eðer varsa ikinci parametre - çalýþan programýn kullanacaðý deðer
    {if(Params <> '') then
    begin

      PLongWord(FileBuffer)^ := 1;
      Inc(p1);
      MoveEx(@Params[1], p1, Length(Params));
      p1 += Length(Params);
      p1^ := #0;
    end;}

    // iþlemin durumunu çalýþýyor olarak belirle
    p^.FState := psRunning;

    // oluþturulan iþlem sayýsýný bir artýr
    Inc(CreatedProcess);

    // iþlemin bellek adresini geri döndür
    Result := @Self;

    asm sti end;
  end
  {else
  begin

    //CloseFile(FileHandle);
    p^.SetState(p^.PID, psFree);
    MSG_S('PROCESS.PP: ' + FullPath + ' dosyasý bulunamadý!');
  end;}
end;

{==============================================================================
  program dosyalarýný çalýþtýrýr
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

  // boþ iþlem giriþi bul
  p := p^.Create;
  if(p = nil) then
  begin

    //MSG_S('PROCESS.PP: ' + FullName + ' için proses oluþturulamýyor!');
    MSG_S('PROCESS.PP: program için proses oluþturulamýyor!');
    Result := nil;
    Exit;
  end;

  // dosyayý sürücü + dizin + dosya parçalarýna ayýr
  //ProcessPath(FullName, Drive, Dir, FileName);

  // dosya adýnýn uzunluðunu al
  //Size := Length(FileName);

  { TODO : .c dosyalarý ileride .ç (çalýþtýrýlabilir) olarak deðiþtirilecek. }

  // dosya uzantýsýný al
  {i := Pos('.', FileName);
  if(i > 0) then Ext := Copy(FileName, i + 1, Size - i) else Ext := '';}

  // dosya çalýþtýrýlabilir bir dosya deðil ise
  // dosya ile ilgili iliþkili programý bul
  {if(Ext <> 'c') then
  begin

    // eðer dosya çalýþtýrýlabilir deðil ise
    // açýlýþ aygýtýndan iliþkili programý ata
    Params := Drive + ':\' + FileName;
    FileName := GetRelatedPrograms(Ext);
    FullPath := BootDev + ':\' + FileName;
  end
  else
  begin

    Params := '';
    FullPath := Drive + ':\' + FileName;
  end;

  // çalýþtýrýlacak dosyayý tanýmla ve aç
  AssignFile(FileHandle, FullPath);
  Reset(FileHandle);
  if(IOResult = 0) then}
  begin

    // dosya uzunluðunu al
    //Size := FileSize(FileHandle);
    Size := 8191;

    // dosyanýn çalýþtýrýlmasý için bellekte yer rezerv et
    FileBuffer := GMem.Alloc(Size + PROGRAM_EXTRA_MEM);
    if(FileBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: program için yeterli bellek yok!');
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

    // dosyayý hedef adrese kopyala
    {if(Read(FileHandle, FileBuffer) = 0) then
    begin

      // dosyayý kapat
      CloseFile(FileHandle);
      MSG_S('PROCESS.PP: ' + FullPath + ' dosyasý okunamýyor!');
      Result := nil;
      Exit;
    end;

    // dosyayý kapat
    CloseFile(FileHandle);

    // olay iþlemleri için bellekte yer rezerv et
    EventBuffer := PEv(GMem.Alloc(4096));
    if(EventBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: Olay bilgisi için bellek ayrýlamýyor!');
      Result := nil;
      Exit;
    end;}

    // bellek baþlangýç adresi
    p^.FLoadedMemAddr := LongWord(FileBuffer);

    // bellek miktarý
    p^.FMemSize := Size + PROGRAM_EXTRA_MEM;

    // elf formatýndaki dosyanýn baþ tarafýna konumlan
    //ELFHeader := FileBuffer;

    // iþlem baþlangýç adresi
    //p^.FStartAddr := ELFHeader^.e_entry;
    p^.FStartAddr := $1000;

    // iþlemin yýðým adresi
    p^.FStackAddr := (Size + PROGRAM_EXTRA_MEM) - 256;

    // dosyanýn çalýþtýrýlmasý için selektörleri oluþtur
    p^.CreateSelectors;

    // iþlemin görev deðiþim sayacýný sýfýrla
    p^.FTaskCounter := 0;

    // iþlemin olay sayacýný sýfýrla
    p^.FEvCount := 0;

    // iþlemin olay bellek bölgesini ata
    //p^.FEvBuffer := EventBuffer;
    p^.FEvBuffer := nil;

    // iþlemin adý
    p^.FName := FileName;

    // parametre gönderimi
    // ilk parametre - çalýþan iþlemin adý
    {PLongWord(FileBuffer)^ := 0;
    p1 := PChar(FileBuffer + 4);
    MoveEx(@FullPath[1], p1, Length(FullPath));
    p1 += Length(FullPath);
    p1^ := #0;}

    // eðer varsa ikinci parametre - çalýþan programýn kullanacaðý deðer
    {if(Params <> '') then
    begin

      PLongWord(FileBuffer)^ := 1;
      Inc(p1);
      MoveEx(@Params[1], p1, Length(Params));
      p1 += Length(Params);
      p1^ := #0;
    end;}

    // iþlemin durumunu çalýþýyor olarak belirle
    p^.FState := psRunning;

    // oluþturulan iþlem sayýsýný bir artýr
    Inc(CreatedProcess);

    // iþlemin bellek adresini geri döndür
    Result := @Self;

    asm sti end;
  end
  {else
  begin

    //CloseFile(FileHandle);
    p^.SetState(p^.PID, psFree);
    MSG_S('PROCESS.PP: ' + FullPath + ' dosyasý bulunamadý!');
  end;}
end;

{==============================================================================
  program dosyalarýný çalýþtýrýr
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

  // boþ iþlem giriþi bul
  p := p^.Create;
  if(p = nil) then
  begin

    //MSG_S('PROCESS.PP: ' + FullName + ' için proses oluþturulamýyor!');
    MSG_S('PROCESS.PP: program için proses oluþturulamýyor!');
    Result := nil;
    Exit;
  end;

  // dosyayý sürücü + dizin + dosya parçalarýna ayýr
  ProcessPath(FullName, Drive, Dir, FileName);

  // dosya adýnýn uzunluðunu al
  Size := Length(FileName);

  { TODO : .c dosyalarý ileride .ç (çalýþtýrýlabilir) olarak deðiþtirilecek. }

  // dosya uzantýsýný al
  i := Pos('.', FileName);
  if(i > 0) then Ext := Copy(FileName, i + 1, Size - i) else Ext := '';

  // dosya çalýþtýrýlabilir bir dosya deðil ise
  // dosya ile ilgili iliþkili programý bul
  if(Ext <> 'c') then
  begin

    // eðer dosya çalýþtýrýlabilir deðil ise
    // açýlýþ aygýtýndan iliþkili programý ata
    Params := Drive + ':\' + FileName;
    FileName := GetRelatedPrograms(Ext);
    FullPath := BootDev + ':\' + FileName;
  end
  else
  begin

    Params := '';
    FullPath := Drive + ':\' + FileName;
  end;

  // çalýþtýrýlacak dosyayý tanýmla ve aç
  AssignFile(FileHandle, FullPath);
  Reset(FileHandle);
  if(IOResult = 0) then
  begin

    // dosya uzunluðunu al
    Size := FileSize(FileHandle);
    //Size := 4096*4;

    // dosyanýn çalýþtýrýlmasý için bellekte yer rezerv et
    FileBuffer := GMem.Alloc(Size + PROGRAM_EXTRA_MEM);
    if(FileBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: program için yeterli bellek yok!');
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

    // dosyayý hedef adrese kopyala
    if(Read(FileHandle, FileBuffer) = 0) then
    begin

      // dosyayý kapat
      CloseFile(FileHandle);
      MSG_S('PROCESS.PP: ' + FullPath + ' dosyasý okunamýyor!');
      Result := nil;
      Exit;
    end;

    // dosyayý kapat
    CloseFile(FileHandle);

    // olay iþlemleri için bellekte yer rezerv et
    {EventBuffer := PEv(GMem.Alloc(4096));
    if(EventBuffer = nil) then
    begin

      MSG_S('PROCESS.PP: Olay bilgisi için bellek ayrýlamýyor!');
      Result := nil;
      Exit;
    end;}

    MoveEx(FileBuffer, FileBuffer + $1000, 300);

    // bellek baþlangýç adresi
    p^.FLoadedMemAddr := LongWord(FileBuffer);

    // bellek miktarý
    p^.FMemSize := Size + PROGRAM_EXTRA_MEM;

    // elf formatýndaki dosyanýn baþ tarafýna konumlan
    //ELFHeader := FileBuffer;

    // iþlem baþlangýç adresi
    //p^.FStartAddr := ELFHeader^.e_entry;
    p^.FStartAddr := $1000;

    // iþlemin yýðým adresi
    p^.FStackAddr := (Size + PROGRAM_EXTRA_MEM) - 256;

    // dosyanýn çalýþtýrýlmasý için selektörleri oluþtur
    p^.CreateSelectors;

    // iþlemin görev deðiþim sayacýný sýfýrla
    p^.FTaskCounter := 0;

    // iþlemin olay sayacýný sýfýrla
    p^.FEvCount := 0;

    // iþlemin olay bellek bölgesini ata
    //p^.FEvBuffer := EventBuffer;
    p^.FEvBuffer := nil;

    // iþlemin adý
    p^.FName := FileName;

    // parametre gönderimi
    // ilk parametre - çalýþan iþlemin adý
    {PLongWord(FileBuffer)^ := 0;
    p1 := PChar(FileBuffer + 4);
    MoveEx(@FullPath[1], p1, Length(FullPath));
    p1 += Length(FullPath);
    p1^ := #0;}

    // eðer varsa ikinci parametre - çalýþan programýn kullanacaðý deðer
    {if(Params <> '') then
    begin

      PLongWord(FileBuffer)^ := 1;
      Inc(p1);
      MoveEx(@Params[1], p1, Length(Params));
      p1 += Length(Params);
      p1^ := #0;
    end;}

    // iþlemin durumunu çalýþýyor olarak belirle
    p^.FState := psRunning;

    // oluþturulan iþlem sayýsýný bir artýr
    Inc(CreatedProcess);

    // iþlemin bellek adresini geri döndür
    Result := @Self;

    asm sti end;
  end
  {else
  begin

    //CloseFile(FileHandle);
    p^.SetState(p^.PID, psFree);
    MSG_S('PROCESS.PP: ' + FullPath + ' dosyasý bulunamadý!');
  end;}
end;

{==============================================================================
  çalýþacak iþlem için boþ yer oluþturur
 ==============================================================================}
function TProcess.Create: PProcess;
var
  p: PProcess;
begin

  // boþ iþlem giriþi bul
  p := p^.FindProcesSlot;

  Result := p;
end;

{==============================================================================
  çalýþtýrýlacak iþlem için boþ iþlem giriþi bulur
 ==============================================================================}
function TProcess.FindProcesSlot: PProcess;
var
  p: PProcess;
  i: Byte;
begin

  // tüm iþlem giriþlerini incele
  for i := 2 to MAX_PROCESSES do
  begin

    p := ArrProcesses[i];

    // eðer iþlem giriþi boþ ise
    if(P^.FState = psFree) then
    begin

      // OLUÞTURULDU olarak iþaretle ve çaðýran iþleve geri dön
      P^.SetState(i, psCreated);
      Result := p;
      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  iþlem için tss giriþlerini oluþturur
 ==============================================================================}
procedure TProcess.CreateSelectors;
var
  SelCSIdx, SelDSIdx,
  SelTSSIdx, i: TPID;
  Limit: LongWord;
begin

  i := PID;

  Limit := FMemSize shr 12;

  // uygulamanýn TSS, CS, DS selektörlerini belirle
  SelTSSIdx := i * 3;
  SelDSIdx := SelTSSIdx - 1;
  SelCSIdx := SelDSIdx - 1;

  // uygulama için CS selektörünü oluþtur
  // access = p, dpl3, 1, 1, conforming, readable, accessed
  // gran = gran = 1, default = 1, 0, avl = 1, limit (4 bit)
  SetGDTEntry(SelCSIdx, FLoadedMemAddr, Limit, $FA, $D0);

  // uygulama için DS selektörünü oluþtur
  // access = p, dpl3, 1, 0, exp direction, writable, accessed
  // gran = gran = 1, big = 1, 0, avl = 1, limit (4 bit)
  SetGDTEntry(SelDSIdx, FLoadedMemAddr, Limit, $F2, $D0);

  // uygulama için TSS selektörünü oluþtur
  // access = p, dpl3, 0, 1, 0, 0 (non_busy), 1
  // gran = g = 0, 0, 0, avl = 1, limit (4 bit)
  SetGDTEntry(SelTSSIdx, LongWord(@TSSArr[i]), SizeOf(TTSS) - 1, $E9, $10);

  // TSS'nin içeriðini sýfýrla
  FillByte(TSSArr[i], SizeOf(TTSS), 0);

  // TSS içeriðini doldur
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
  iþlemin yeni çalýþma durumunu belirler
 ==============================================================================}
procedure TProcess.SetState(APID: TPID; AState: TProcessState);
var
  p: PProcess;
begin

  p := ArrProcesses[APID];
  if(AState <> p^.FState) then p^.FState := AState;
end;

{==============================================================================
  iþlemin görev sayacýný belirler
 ==============================================================================}
procedure TProcess.SetTaskCounter(ATaskCounter: LongWord);
begin

  if(ATaskCounter <> FTaskCounter) then FTaskCounter := ATaskCounter;
end;

{==============================================================================
  iþlemin olay sayacýný belirler
 ==============================================================================}
procedure TProcess.SetEvCount(AEvCount: LongWord);
begin

  if(AEvCount <> FEvCount) then FEvCount := AEvCount;
end;

{==============================================================================
  iþlemin olay adýný belirler
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
  çekirdek tarafýndan iþlem için oluþturulan olayý kaydeder
  not: bu iþlev görsel nesneler içindir
 ==============================================================================}
procedure TProcess.EventAdd1(APID: TPID; Obj: PControl; Event, Param1, Param2: Integer);
var
  E: PEv;
  p: PProcess;
begin

  p := ArrProcesses[APID];

  if(p^.FState = psRunning) then
  begin

    // olay belleði dolu deðilse, olayý kaydet
    if(p^.FEvCount < MAX_EVENT) then
    begin

      // iþlemin olay belleðine konumlan
      E := p^.FEvBuffer;
      Inc(E, p^.FEvCount);

      // olayý iþlem belleðine kaydet
      E^.Handle := Obj^.Handle;
      E^.Event := Event;
      E^.Param1 := Param1;
      E^.Param2 := Param2;

      // iþlemin olay sayacýný artýr
      p^.FEvCount := p^.FEvCount + 1;
    end;
  end;
end;

{==============================================================================
  çekirdek tarafýndan iþlem için oluþturulan olayý kaydeder
  not: bu iþlev görsel olmayan nesneler içindir
 ==============================================================================}
procedure TProcess.EventAdd2(APID: TPID; Ev: TEv);
var
  E: PEv;
  p: PProcess;
begin

  p := ArrProcesses[APID];

  if(p^.FState = psRunning) then
  begin

    // olay belleði dolu deðilse, olayý kaydet
    if(p^.EvCount < MAX_EVENT) then
    begin

      // iþlemin olay belleðine konumlan
      E := p^.EvBuffer;
      Inc(E, p^.EvCount);

      // olayý iþlem belleðine kaydet
      E^.Handle := Ev.Handle;
      E^.Event := Ev.Event;
      E^.Param1 := Ev.Param1;
      E^.Param2 := Ev.Param2;

      // iþlemin olay sayacýný artýr
      p^.EvCount := p^.EvCount + 1;
    end;
  end;
end;

{==============================================================================
  iþlem için (kernel tarafýndan) oluþturulan olayý alýr
 ==============================================================================}
function TProcess.EventGet(var Ev: TEv): Boolean;
var
  E, E2: PEv;
begin

  // default çýkýþ deðeri
  Result := False;

  // iþlem için oluþturulan olay yoksa çýk
  if(EvCount = 0) then Exit;

  // default çýkýþ deðeri
  Result := True;

  // iþlemin olay belleðine konumlan
  E := EvBuffer;

  // olaylarý hedef alana kopyala
  Ev.Event := E^.Event;
  Ev.Handle := E^.Handle;
  Ev.Param1 := E^.Param1;
  Ev.Param2 := E^.Param2;

  // iþlemin olay sayacýný azalt
  EvCount := EvCount - 1;

  // tek bir olay var ise olay belleðini güncellemeye gerek yok
  if(EvCount = 0) then Exit;

  // event'i proses'in event buffer'ýndan sil
  E2 := E;
  Inc(E2);

  MoveEx(E2, E, SizeOf(TEv) * EvCount);
end;

{==============================================================================
  çalýþan iþlemi sonlandýrýr
 ==============================================================================}
function TProcess.Terminate(APID: TPID; const Reason: Byte = $FF): LongInt;
var
  p: PProcess;
begin

  cli;

  // çalýþan iþlemi öncelikle durdur
  p^.SetState(APID, psStopped);

  // iþlemin sonlandýrýlma bilgisini ver
  if(Reason = $FF) then
  begin

    MSG_S('PROCESS.PP: ' + ArrProcesses[APID]^.FName + ' normal bir þekilde sonlandýrýldý');
  end
  else
  begin

    MSG_S('PROCESS.PP: ' + ArrProcesses[APID]^.FName + ' programý sonlandýrýldý');
    MSG_S('PROCESS.PP: Hata Kodu: ' + IntToStr(Reason) + ' - ' + SException[Reason]);
  end;

  // iþleme ait zamanlayýcýlarý yok et
  DestroyTimers(APID);

  { TODO : Görsel olmayan nesnelerin bellekten atýlmasýnda (TProcess.Terminate)
    görsel iþlevlerin çalýþmamasý saðlanacak }

  // iþleme ait görsel nesneleri yok et
  DestroyProcessObjects(APID);

  // iþleme ait olay bellek bölgesini iptal et
  GMem.Destroy(EvBuffer, 4096);

  // iþlem için ayrýlan bellek bölgesini serbest býrak
  GMem.Destroy(Pointer(LoadedMemAddr), FMemSize + PROGRAM_EXTRA_MEM);

  // çalýþan iþlemi iþlem listesinden çýkart
  SetState(APID, psFree);

  // iþlem sayýsýný bir azalt
  Dec(CreatedProcess);

  GCurrentDesktop^.Update;

  sti;

  asm jmp OSControl; end;
end;

{==============================================================================
  iþlem ile ilgili bellek bölgesini geri döndürür
 ==============================================================================}
function GetCreatedProcessInfo(Index: Integer): PProcess;
var
  i, j: Integer;
begin

  // aranacak index numarasý
  j := 0;

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 1 to MAX_PROCESSES do
  begin

    // eðer iþlem boþ deðil ise index numarasýný bir artýr
    if not(ArrProcesses[i]^.FState = psFree) then Inc(j);

    // aranan index ile iþlem sýrasý ayný ise iþlem bellek bölgesini geri döndür
    if(Index = j) then
    begin

      Result := ArrProcesses[i];
      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  iþlemin bellek index numarasýný geri döndürür
 ==============================================================================}
function GetCreatedProcessIndex(Index: Integer): TPID;
var
  i, j: Integer;
begin

  // aranacak index numarasý
  j := 0;

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 1 to MAX_PROCESSES do
  begin

    // eðer iþlem çalýþýyor ise index numarasýný bir artýr
    if(ArrProcesses[i]^.FState = psRunning) then Inc(j);

    // aranan index ile iþlem sýrasý ayný ise iþlem bellek bölgesini geri döndür
    if(Index = j) then
    begin

      Result := i;
      Exit;
    end;
  end;

  Result := 0;
end;

{==============================================================================
  çalýþtýrýlacak bir sonraki proses'i bulur
 ==============================================================================}
function FindNextProcessToRun: TPID;
var
  PID: TPID;
  i: Integer;
begin

  // çalýþan proses'e konumlan
  PID := RunningProcess;

  // ve bir sonraki prosesten itibaren tüm prosesleri incele
  for i := 1 to MAX_PROCESSES do
  begin

    Inc(PID);
    if(PID > CreatedProcess) then PID := 1;

    // eðer çalýþan proses ise çaðýran iþleve geri dön
    if(ArrProcesses[PID]^.FState = psRunning) then Break;
  end;

  Result := PID;
end;

{==============================================================================
  dosya uzantýsý ile iliþkili program adýný geri döndürür
 ==============================================================================}
function GetRelatedPrograms(Ext: string): string;
var
  i: Byte;
begin

  // dosyalarla iliþkilendirilen default program
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

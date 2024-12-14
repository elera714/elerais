{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: timer.pp
  Dosya ��levi: zamanlay�c� y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 09/08/2017

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit timer;

interface

uses shared, ports;

const
  MAX_TIMERS = 32;

type
  TTimerState = (tsFree, tsRunning, tsStopped);

type
  PTimer = ^TTimer;
  TTimer = object
  protected
    function FindFreeSlot: PTimer;
  private
    FHandle: THandle;
    FPID: TPID;
    FState: TTimerState;
    FTriggerVal, FCurrCounter: LongInt;
  public
    procedure Init;
    function Create(Value: Integer): PTimer;
    procedure Destroy;
    property PID: TPID read FPID write FPID;
    property Handle: THandle read FHandle;
    property State: TTimerState read FState write FState;
    property TriggerVal: Integer read FTriggerVal write FTriggerVal;
    property CurrCounter: Integer read FCurrCounter write FCurrCounter;
  end;

var
  TimerMemAddr: Pointer;
  CreatedTimerNum: Byte;
  Timers: array[1..MAX_TIMERS] of PTimer;

procedure DestroyTimers(PID: TPID);
procedure CheckTimers;
procedure Delay(Ms: LongWord);
procedure Delay1(Ms: LongWord);
procedure Schedule;
procedure ChangeTask;

implementation

uses gvars, process, drv_flp, arp, idt, irq, pit;

{==============================================================================
  zamanlay�c� nesnelerinin ana y�kleme i�levlerini i�erir
 ==============================================================================}
procedure TTimer.Init;
var
  p: PTimer;
  Addr: Pointer;
  i: LongInt;
begin

  // kesmeleri durdur
  cli;

  DisableIRQ(0);

  // irq0 giri� noktas�n� yeniden belirle
  SetIDTEntry($20, LongWord(@Schedule), $08, $8E);    //irq00

  // saat vuru� frekans�n� d�zenle. 100 tick = 1 saniye
  SetClockSpeed(100);

  // uygulamalar i�in zamanlay�c� bilgilerinin yerle�tirilece�i bellek olu�tur
  TimerMemAddr := GMem.Alloc(MAX_TIMERS * SizeOf(TTimer));

  // bellek giri�lerini timer yap�lar�yla e�le�tir
  Addr := TimerMemAddr;
  for i := 1 to MAX_TIMERS do
  begin

    p := Addr;
    Timers[i] := p;

    p^.FState := tsFree;
    p^.FHandle := i;

    Addr += SizeOf(TTimer);
  end;

  // uygulamalar i�in �al��an timer say�s�n� s�f�rla
  CreatedTimerNum := 0;

  // irq0'� etkinle�tir
  EnableIRQ(0);

  // kesmeleri aktifle�tir
  sti;
end;

{==============================================================================
  zamanlay�c� nesnesi olu�turur
 ==============================================================================}
function TTimer.Create(Value: LongInt): PTimer;
var
  p: PTimer;
begin

  // bo� bir zamanlay�c� nesnesi bul
  p := FindFreeSlot;

  if(p <> nil) then
  begin

    p^.FPID := RunningProcess;
    p^.FTriggerVal := Value;
    p^.FCurrCounter := Value;

    Inc(CreatedTimerNum);

    Result := p;
    Exit;
  end;

  // geri d�n�� de�eri
  Result := nil;
end;

{==============================================================================
  zamanlay�c� nesnesi i�in bellekte yer rezerv eder
 ==============================================================================}
function TTimer.FindFreeSlot: PTimer;
var
  i: LongInt;
begin

  // t�m zamanlay�c� nesnelerini ara
  for i := 1 to MAX_TIMERS do
  begin

    // e�er zamanlay�c� nesnesinin durumu bo� ise
    if(Timers[i]^.FState = tsFree) then
    begin

      // durduruldu olarak i�aretle ve �a��ran i�leve geri d�n
      Timers[i]^.FState := tsStopped;
      Result := Timers[i];
      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  zamanlay�c� nesnesini yok eder.
 ==============================================================================}
procedure TTimer.Destroy;
begin

  // e�er zamanlay�c� nesnesinin durumu bo� de�il ise
  if(State <> tsFree) then
  begin

    // bo� olarak i�aretle
    State := tsFree;

    // timer nesnesini bir azalt
    Dec(CreatedTimerNum);
  end;
end;

{==============================================================================
  bir s�re�e ait t�m zamanlay�c� nesnelerini yok eder.
 ==============================================================================}
procedure DestroyTimers(PID: TPID);
var
  i: LongInt;
  p: PTimer;
begin

  // t�m zamanlay�c� nesnelerini ara
  for i := 1 to MAX_TIMERS do
  begin

    p := Timers[i];

    // zamanlay�c� nesnesi aranan i�leme mi ait
    if(p^.PID = PID) then
    begin

      // nesneyi yok et
      p^.Destroy;
    end;
  end;
end;

{==============================================================================
  zamanlay�c� tetikleme s�resini denetler. (irq00 taraf�ndan �a�r�l�r)
 ==============================================================================}
procedure CheckTimers;
var
  Ev: TEv;
  i, Counter: LongInt;
  p: PProcess;
begin

  // e�er nesne olu�turulmam��sa ��k
  if(CreatedTimerNum = 0) then Exit;

  // t�m zamanlay�c� nesnelerini denetle
  for i := 1 to MAX_TIMERS do
  begin

    // e�er �al���yorsa
    if(Timers[i]^.State = tsRunning) then
    begin

      // saya� 0 de�erini bulmu�sa
      Counter := Timers[i]^.CurrCounter;
      Dec(Counter);
      Timers[i]^.CurrCounter := Counter;

      // uygulamaya mesaj g�nder
      if(Counter = 0) then
      begin

        Timers[i]^.CurrCounter := Timers[i]^.TriggerVal;

        Ev.Handle := i;
        Ev.Event := ONTIMER;
        Ev.Param1 := 0;
        Ev.Param2 := 0;

        p := ArrProcesses[Timers[i]^.PID];
        p^.EventAdd2(p^.PID, Ev);
      end;
    end;
  end;
end;

procedure Delay(Ms: LongWord);
var
  Counter: LongWord;
begin

  // timer sayac�na belirtilen de�eri ekle ve
  // timer sayac� bu de�erden b�y�k oluncaya bekle
  Counter := Ms * 100;
  while (Counter > 1) do
  begin

    Dec(Counter);
  end;
end;

{==============================================================================
  milisaniye cinsinden belirtilen s�re kadar bekleme i�levini ger�ekle�tirir.
 ==============================================================================}
procedure Delay1(Ms: LongWord);
var
  Counter: LongWord;
begin

  // timer sayac�na belirtilen de�eri ekle ve
  // timer sayac� bu de�erden b�y�k oluncaya bekle
  Counter := TimerCounter + Ms;
  while (Counter > TimerCounter) do
  begin

    ChangeTask;
  end;
end;

{==============================================================================
  donan�m taraf�ndan g�rev de�i�tirme i�levlerini yerine getirir.
 ==============================================================================}
procedure Schedule; nostackframe; assembler;
asm

  cli

  // de�i�ime u�rayacak yazma�lar� sakla
  pushad
  pushfd

  // �al��an proses'in ds yazmac�n� sakla
  // not : ds = es = ss = fs = gs oldu�u i�in tek yazmac�n saklanmas�
  // yeterlidir.
  mov   ax,ds
  push  eax

  // yazma�lar� sistem yazma�lar�na ayarla
  mov   ax,SELOS_DATA
  mov   ds,ax
  mov   es,ax

  // zamanlay�c�n� sayac�n� art�r. (bekleme i�leminde kullan�maktad�r)
  mov ecx,TimerCounter
  inc ecx
  mov TimerCounter,ecx

  mov   eax,MultitaskingStarted
  cmp   eax,1
  je    @@00

  // �al��an proses'in segment yazma�lar�n� eski konumuna geri d�nd�r
  pop   eax
  mov   ds,ax
  mov   es,ax

  mov   al,$20
  out   PIC1_CMD,al

  // genel yazma�lar� geri y�kle ve kesmeden ��k
  popfd
  popad
  sti
  iretd

@@00:

  // uygulamalar taraf�ndan olu�turulan timer nesnelerini denetle
  //call  CheckTimers;

@@0:

  // her 1 saniyede kontrol edilecek dahili i�levler
  mov edx,0
  mov eax,TimerCounter
  mov ecx,100
  div ecx
  cmp edx,0
  jg  @@1

  // sistem sayac�n� art�r
  mov eax,OsCounter
  inc eax
  mov OsCounter,eax

  // arp tablo g�ncellemesi
  //call  ArpTimer;

  // floppy motorunun aktivli�ini kontrol eder, gerekirse motoru kapat�r
  //call  CheckFloppyMotorStatus;

@@1:

  // tek bir g�rev �al���yorsa g�rev de�i�ikli�i yap�lamaz. o zaman ��k
  mov ecx,CreatedProcess
  cmp ecx,1
  jg  @@2

  // �al��an proses'in segment yazma�lar�n� eski konumuna geri d�nd�r
  pop   eax
  mov   ds,ax
  mov   es,ax

  mov   al,$20
  out   PIC1_CMD,al

  // genel yazma�lar� geri y�kle ve kesmeden ��k
  popfd
  popad
  iretd

@@2:

  // �al��t�r�lacak bir sonraki proses'i bul
  call  FindNextProcessToRun
  mov RunningProcess,eax

  // aktif proses'in bellek ba�lang�� adresini belirle
  dec eax
  shl eax,2
  mov esi,ArrProcesses[eax]
  mov eax,[esi+TProcess.FLoadedMemAddr]
  mov RunningProcessBase,eax

  // g�rev de�i�iklik sayac�n� bir art�r
  mov eax,[esi+TProcess.FTaskCounter]
  inc eax
  mov [esi+TProcess.FTaskCounter],eax

  // g�rev'in verilece�i tss giri�ini belirle
  mov   ecx,RunningProcess
  cmp   ecx,1
  je    @@tss_os

@@tss_prg:
  imul  ecx,3 * 8
//  add   ecx,3             // DPL3 - uygulama
  mov   @@sel,cx
  jmp   @@jump_tss

@@tss_os:
  imul  ecx,3 * 8         // DPL0 - sistem
  mov   @@sel,cx

@@jump_tss:

  // �al��an proses'in segment yazma�lar�n� eski konumuna geri d�nd�r
  pop   eax
  mov   ds,ax
  mov   es,ax

  // EOI
  mov   al,$20
  out   PIC1_CMD,al

  // �al��an proses'in genel yazma�lar�n� eski konumuna geri d�nd�r
  popfd
  popad

  sti

// i�lemi belirtilen proses'e devret
@@jmp:  db  $EA
@@ofs:  dd  0
@@sel:  dw  0
  iretd
end;

{==============================================================================
  yaz�l�m taraf�ndan g�rev de�i�tirme i�levlerini yerine getirir.
 ==============================================================================}
procedure ChangeTask; nostackframe; assembler;
asm
  // TODO ge�ici olarak iptal
  ret
  cli
  pushad
  pushfd

  mov   eax,MultitaskingStarted
  cmp   eax,1
  je    @@00

  // genel yazma�lar� geri y�kle ve kesmeden ��k
  popfd
  popad
  sti
  ret

@@00:

  cmp CreatedProcess,1
  jne @@0

  popfd
  popad
  sti
  ret

@@0:

  call  FindNextProcessToRun
  mov RunningProcess,eax

  // aktif proses'in bellek ba�lang�� adresini belirle
  mov eax,RunningProcess
  dec eax
  shl eax,2
  mov ebx,ArrProcesses[eax]
  mov eax,[ebx+TProcess.FLoadedMemAddr]
  mov RunningProcessBase,eax

  // g�rev de�i�iklik sayac�n� bir art�r
  mov eax,RunningProcess
  dec eax
  shl eax,2
  mov esi,ArrProcesses[eax]
  mov eax,[esi+TProcess.FTaskCounter]
  inc eax
  mov [esi+TProcess.FTaskCounter],eax

  cmp   RunningProcess,1
  je    @@tss_os

@@tss_prg:
  mov   eax,RunningProcess
  imul  eax,3 * 8
//  add   eax,3
  mov   @@sel,ax
  jmp   @@jump_tss

@@tss_os:
  mov   eax,RunningProcess
  imul  eax,3 * 8
  mov   @@sel,ax

@@jump_tss:
  popfd
  popad

@@jmp:  db  $EA
@@ofs:  dd  0
@@sel:  dw  0
  sti
  ret
end;

end.

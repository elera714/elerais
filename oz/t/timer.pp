{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: timer.pp
  Dosya Ýþlevi: zamanlayýcý yönetim iþlevlerini içerir

  Güncelleme Tarihi: 09/08/2017

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
  zamanlayýcý nesnelerinin ana yükleme iþlevlerini içerir
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

  // irq0 giriþ noktasýný yeniden belirle
  SetIDTEntry($20, LongWord(@Schedule), $08, $8E);    //irq00

  // saat vuruþ frekansýný düzenle. 100 tick = 1 saniye
  SetClockSpeed(100);

  // uygulamalar için zamanlayýcý bilgilerinin yerleþtirileceði bellek oluþtur
  TimerMemAddr := GMem.Alloc(MAX_TIMERS * SizeOf(TTimer));

  // bellek giriþlerini timer yapýlarýyla eþleþtir
  Addr := TimerMemAddr;
  for i := 1 to MAX_TIMERS do
  begin

    p := Addr;
    Timers[i] := p;

    p^.FState := tsFree;
    p^.FHandle := i;

    Addr += SizeOf(TTimer);
  end;

  // uygulamalar için çalýþan timer sayýsýný sýfýrla
  CreatedTimerNum := 0;

  // irq0'ý etkinleþtir
  EnableIRQ(0);

  // kesmeleri aktifleþtir
  sti;
end;

{==============================================================================
  zamanlayýcý nesnesi oluþturur
 ==============================================================================}
function TTimer.Create(Value: LongInt): PTimer;
var
  p: PTimer;
begin

  // boþ bir zamanlayýcý nesnesi bul
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

  // geri dönüþ deðeri
  Result := nil;
end;

{==============================================================================
  zamanlayýcý nesnesi için bellekte yer rezerv eder
 ==============================================================================}
function TTimer.FindFreeSlot: PTimer;
var
  i: LongInt;
begin

  // tüm zamanlayýcý nesnelerini ara
  for i := 1 to MAX_TIMERS do
  begin

    // eðer zamanlayýcý nesnesinin durumu boþ ise
    if(Timers[i]^.FState = tsFree) then
    begin

      // durduruldu olarak iþaretle ve çaðýran iþleve geri dön
      Timers[i]^.FState := tsStopped;
      Result := Timers[i];
      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  zamanlayýcý nesnesini yok eder.
 ==============================================================================}
procedure TTimer.Destroy;
begin

  // eðer zamanlayýcý nesnesinin durumu boþ deðil ise
  if(State <> tsFree) then
  begin

    // boþ olarak iþaretle
    State := tsFree;

    // timer nesnesini bir azalt
    Dec(CreatedTimerNum);
  end;
end;

{==============================================================================
  bir süreçe ait tüm zamanlayýcý nesnelerini yok eder.
 ==============================================================================}
procedure DestroyTimers(PID: TPID);
var
  i: LongInt;
  p: PTimer;
begin

  // tüm zamanlayýcý nesnelerini ara
  for i := 1 to MAX_TIMERS do
  begin

    p := Timers[i];

    // zamanlayýcý nesnesi aranan iþleme mi ait
    if(p^.PID = PID) then
    begin

      // nesneyi yok et
      p^.Destroy;
    end;
  end;
end;

{==============================================================================
  zamanlayýcý tetikleme süresini denetler. (irq00 tarafýndan çaðrýlýr)
 ==============================================================================}
procedure CheckTimers;
var
  Ev: TEv;
  i, Counter: LongInt;
  p: PProcess;
begin

  // eðer nesne oluþturulmamýþsa çýk
  if(CreatedTimerNum = 0) then Exit;

  // tüm zamanlayýcý nesnelerini denetle
  for i := 1 to MAX_TIMERS do
  begin

    // eðer çalýþýyorsa
    if(Timers[i]^.State = tsRunning) then
    begin

      // sayaç 0 deðerini bulmuþsa
      Counter := Timers[i]^.CurrCounter;
      Dec(Counter);
      Timers[i]^.CurrCounter := Counter;

      // uygulamaya mesaj gönder
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

  // timer sayacýna belirtilen deðeri ekle ve
  // timer sayacý bu deðerden büyük oluncaya bekle
  Counter := Ms * 100;
  while (Counter > 1) do
  begin

    Dec(Counter);
  end;
end;

{==============================================================================
  milisaniye cinsinden belirtilen süre kadar bekleme iþlevini gerçekleþtirir.
 ==============================================================================}
procedure Delay1(Ms: LongWord);
var
  Counter: LongWord;
begin

  // timer sayacýna belirtilen deðeri ekle ve
  // timer sayacý bu deðerden büyük oluncaya bekle
  Counter := TimerCounter + Ms;
  while (Counter > TimerCounter) do
  begin

    ChangeTask;
  end;
end;

{==============================================================================
  donaným tarafýndan görev deðiþtirme iþlevlerini yerine getirir.
 ==============================================================================}
procedure Schedule; nostackframe; assembler;
asm

  cli

  // deðiþime uðrayacak yazmaçlarý sakla
  pushad
  pushfd

  // çalýþan proses'in ds yazmacýný sakla
  // not : ds = es = ss = fs = gs olduðu için tek yazmacýn saklanmasý
  // yeterlidir.
  mov   ax,ds
  push  eax

  // yazmaçlarý sistem yazmaçlarýna ayarla
  mov   ax,SELOS_DATA
  mov   ds,ax
  mov   es,ax

  // zamanlayýcýný sayacýný artýr. (bekleme iþleminde kullanýmaktadýr)
  mov ecx,TimerCounter
  inc ecx
  mov TimerCounter,ecx

  mov   eax,MultitaskingStarted
  cmp   eax,1
  je    @@00

  // çalýþan proses'in segment yazmaçlarýný eski konumuna geri döndür
  pop   eax
  mov   ds,ax
  mov   es,ax

  mov   al,$20
  out   PIC1_CMD,al

  // genel yazmaçlarý geri yükle ve kesmeden çýk
  popfd
  popad
  sti
  iretd

@@00:

  // uygulamalar tarafýndan oluþturulan timer nesnelerini denetle
  //call  CheckTimers;

@@0:

  // her 1 saniyede kontrol edilecek dahili iþlevler
  mov edx,0
  mov eax,TimerCounter
  mov ecx,100
  div ecx
  cmp edx,0
  jg  @@1

  // sistem sayacýný artýr
  mov eax,OsCounter
  inc eax
  mov OsCounter,eax

  // arp tablo güncellemesi
  //call  ArpTimer;

  // floppy motorunun aktivliðini kontrol eder, gerekirse motoru kapatýr
  //call  CheckFloppyMotorStatus;

@@1:

  // tek bir görev çalýþýyorsa görev deðiþikliði yapýlamaz. o zaman çýk
  mov ecx,CreatedProcess
  cmp ecx,1
  jg  @@2

  // çalýþan proses'in segment yazmaçlarýný eski konumuna geri döndür
  pop   eax
  mov   ds,ax
  mov   es,ax

  mov   al,$20
  out   PIC1_CMD,al

  // genel yazmaçlarý geri yükle ve kesmeden çýk
  popfd
  popad
  iretd

@@2:

  // çalýþtýrýlacak bir sonraki proses'i bul
  call  FindNextProcessToRun
  mov RunningProcess,eax

  // aktif proses'in bellek baþlangýç adresini belirle
  dec eax
  shl eax,2
  mov esi,ArrProcesses[eax]
  mov eax,[esi+TProcess.FLoadedMemAddr]
  mov RunningProcessBase,eax

  // görev deðiþiklik sayacýný bir artýr
  mov eax,[esi+TProcess.FTaskCounter]
  inc eax
  mov [esi+TProcess.FTaskCounter],eax

  // görev'in verileceði tss giriþini belirle
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

  // çalýþan proses'in segment yazmaçlarýný eski konumuna geri döndür
  pop   eax
  mov   ds,ax
  mov   es,ax

  // EOI
  mov   al,$20
  out   PIC1_CMD,al

  // çalýþan proses'in genel yazmaçlarýný eski konumuna geri döndür
  popfd
  popad

  sti

// iþlemi belirtilen proses'e devret
@@jmp:  db  $EA
@@ofs:  dd  0
@@sel:  dw  0
  iretd
end;

{==============================================================================
  yazýlým tarafýndan görev deðiþtirme iþlevlerini yerine getirir.
 ==============================================================================}
procedure ChangeTask; nostackframe; assembler;
asm
  // TODO geçici olarak iptal
  ret
  cli
  pushad
  pushfd

  mov   eax,MultitaskingStarted
  cmp   eax,1
  je    @@00

  // genel yazmaçlarý geri yükle ve kesmeden çýk
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

  // aktif proses'in bellek baþlangýç adresini belirle
  mov eax,RunningProcess
  dec eax
  shl eax,2
  mov ebx,ArrProcesses[eax]
  mov eax,[ebx+TProcess.FLoadedMemAddr]
  mov RunningProcessBase,eax

  // görev deðiþiklik sayacýný bir artýr
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

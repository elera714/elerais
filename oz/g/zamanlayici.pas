{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: zamanlayici.pas
  Dosya Ýþlevi: zamanlayýcý yönetim iþlevlerini içerir

  Güncelleme Tarihi: 05/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit zamanlayici;

interface

uses paylasim, port, gorselnesne;

const
  AZAMI_ZAMANLAYICI_SAYISI = 32;

type
  TZamanlayiciDurum = (zdBos, zdCalisiyor, zdDurduruldu);

type
  PZamanlayici = ^TZamanlayici;
  TZamanlayici = object
  private
    FZamanlayiciDurum: TZamanlayiciDurum;
    FKimlik: TKimlik;
    FGorevKimlik: TKimlik;
    FTetiklemeSuresi, FGeriSayimSayaci: TSayi4;
  public
    FOlayYonlendirmeAdresi: TOlaylariIsle;
    procedure Yukle;
    function Olustur(AMiliSaniye: TISayi4): PZamanlayici;
    function BosZamanlayiciBul: PZamanlayici;
    procedure YokEt;
    property Durum: TZamanlayiciDurum read FZamanlayiciDurum write FZamanlayiciDurum;
    property Kimlik: TKimlik read FKimlik;
    property GorevKimlik: TKimlik read FGorevKimlik write FGorevKimlik;
    property TetiklemeSuresi: TSayi4 read FTetiklemeSuresi write FTetiklemeSuresi;
    property GeriSayimSayaci: TSayi4 read FGeriSayimSayaci write FGeriSayimSayaci;
  end;

var
  ZamanlayiciYapiBellekAdresi: Isaretci;
  OlusturulanZamanlayiciSayisi: TSayi4 = 0;
  ZamanlayiciListesi: array[1..AZAMI_ZAMANLAYICI_SAYISI] of PZamanlayici;

procedure ZamanlayicilariKontrolEt;
procedure ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
procedure BekleMS(AMilisaniye: TSayi4);
procedure TekGorevZamanlayiciIslevi;
procedure OtomatikGorevDegistir;
procedure ElleGorevDegistir;

implementation

uses genel, gorev, src_disket, arp, idt, irq, pit, pic;

{==============================================================================
  zamanlayýcý nesnelerinin ana yükleme iþlevlerini içerir
 ==============================================================================}
procedure TZamanlayici.Yukle;
var
  Zamanlayici: PZamanlayici;
  BellekAdresi: Isaretci;
  ZamanlayiciU, i: TSayi4;
begin

  // kesmeleri durdur
  cli;

  IRQPasiflestir(0);

  // IRQ0 giriþ noktasýný yeniden belirle
  // %10001110 = 1 = mevcut, 00 = DPL0, 0, 1 = 32 bit kod, 110 - kesme kapýsý
  KesmeGirisiBelirle($20, @OtomatikGorevDegistir, SECICI_SISTEM_KOD * 8, %10001110);

  // saat vuruþ frekansýný düzenle. 100 tick = 1 saniye
  ZamanlayiciFrekansiniDegistir(100);

  ZamanlayiciU := SizeOf(TZamanlayici);

  // uygulamalar için zamanlayýcý bilgilerinin yerleþtirileceði bellek oluþtur
  ZamanlayiciYapiBellekAdresi := GGercekBellek.Ayir(AZAMI_ZAMANLAYICI_SAYISI * ZamanlayiciU);

  // bellek giriþlerini zamanlayýcý yapýlarýyla eþleþtir
  BellekAdresi := ZamanlayiciYapiBellekAdresi;
  for i := 1 to AZAMI_ZAMANLAYICI_SAYISI do
  begin

    Zamanlayici := BellekAdresi;
    ZamanlayiciListesi[i] := Zamanlayici;

    Zamanlayici^.FZamanlayiciDurum := zdBos;
    Zamanlayici^.FKimlik := i;
    Zamanlayici^.FOlayYonlendirmeAdresi := nil;

    BellekAdresi += ZamanlayiciU;
  end;

  // çalýþan zamanlayýcý sayýsýný sýfýrla
  OlusturulanZamanlayiciSayisi := 0;

  // IRQ0'ý etkinleþtir
  IRQEtkinlestir(0);

  // kesmeleri aktifleþtir
  sti;
end;

{==============================================================================
  zamanlayýcý nesnesi oluþturur
 ==============================================================================}
function TZamanlayici.Olustur(AMiliSaniye: TISayi4): PZamanlayici;
var
  Zamanlayici: PZamanlayici;
begin

  // boþ bir zamanlayýcý nesnesi bul
  Zamanlayici := BosZamanlayiciBul;
  if(Zamanlayici <> nil) then
  begin

    Zamanlayici^.FGorevKimlik := CalisanGorev;
    Zamanlayici^.FTetiklemeSuresi := AMiliSaniye;
    Zamanlayici^.FGeriSayimSayaci := AMiliSaniye;
    Zamanlayici^.FOlayYonlendirmeAdresi := nil;

    Inc(OlusturulanZamanlayiciSayisi);

    Exit(Zamanlayici);
  end;

  // geri dönüþ deðeri
  Result := nil;
end;

{==============================================================================
  boþ zamanlayýcý bulur
 ==============================================================================}
function TZamanlayici.BosZamanlayiciBul: PZamanlayici;
var
  i: TSayi4;
begin

  // tüm zamanlayýcý nesnelerini ara
  for i := 1 to AZAMI_ZAMANLAYICI_SAYISI do
  begin

    // zamanlayýcý nesnesinin durumu boþ ise
    if(ZamanlayiciListesi[i]^.FZamanlayiciDurum = zdBos) then
    begin

      // durduruldu olarak iþaretle ve çaðýran iþleve geri dön
      ZamanlayiciListesi[i]^.FZamanlayiciDurum := zdDurduruldu;
      Result := ZamanlayiciListesi[i];
      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  zamanlayýcý nesnesini yok eder.
 ==============================================================================}
procedure TZamanlayici.YokEt;
begin

  // eðer zamanlayýcý nesnesinin durumu boþ deðil ise
  if(FZamanlayiciDurum <> zdBos) then
  begin

    // boþ olarak iþaretle
    FZamanlayiciDurum := zdBos;

    // zamanlayýcý nesnesini bir azalt
    Dec(OlusturulanZamanlayiciSayisi);
  end;
end;

{==============================================================================
  zamanlayýcýlarý tetikler (IRQ00 tarafýndan çaðrýlýr)
 ==============================================================================}
procedure ZamanlayicilariKontrolEt;
var
  Gorev: PGorev;
  Olay: TOlay;
  GeriSayimSayaci, i: TISayi4;
begin

  // zamanlayýcý nesnesi yok ise çýk
  if(OlusturulanZamanlayiciSayisi = 0) then Exit;

  // tüm zamanlayýcý nesnelerini denetle
  for i := 1 to AZAMI_ZAMANLAYICI_SAYISI do
  begin

    // eðer çalýþýyorsa
    if(ZamanlayiciListesi[i]^.FZamanlayiciDurum = zdCalisiyor) then
    begin

      // zamanlayýcý sayacýný 1 azalt
      GeriSayimSayaci := ZamanlayiciListesi[i]^.GeriSayimSayaci;
      Dec(GeriSayimSayaci);
      ZamanlayiciListesi[i]^.GeriSayimSayaci := GeriSayimSayaci;

      // sayaç 0 deðerini bulmuþsa
      if(GeriSayimSayaci = 0) then
      begin

        // yeni sayým için geri sayým deðerini yeniden yükle
        ZamanlayiciListesi[i]^.GeriSayimSayaci := ZamanlayiciListesi[i]^.TetiklemeSuresi;

        Olay.Kimlik := i;
        Olay.Olay := CO_ZAMANLAYICI;
        Olay.Deger1 := 0;
        Olay.Deger2 := 0;

        if not(ZamanlayiciListesi[i]^.FOlayYonlendirmeAdresi = nil) then

          ZamanlayiciListesi[i]^.FOlayYonlendirmeAdresi(nil, Olay)
        else
        begin

          Gorev := GorevListesi[ZamanlayiciListesi[i]^.GorevKimlik];
          Gorev^.OlayEkle(Gorev^.GorevKimlik, Olay);
        end;
      end;
    end;
  end;
end;

{==============================================================================
  bir süreçe ait tüm zamanlayýcý nesnelerini yok eder.
 ==============================================================================}
procedure ZamanlayicilariYokEt(AGorevKimlik: TKimlik);
var
  Zamanlayici: PZamanlayici = nil;
  i: TISayi4;
begin

  // tüm zamanlayýcý nesnelerini ara
  for i := 1 to AZAMI_ZAMANLAYICI_SAYISI do
  begin

    Zamanlayici := ZamanlayiciListesi[i];

    // zamanlayýcý nesnesi aranan iþleme mi ait
    if(Zamanlayici^.GorevKimlik = AGorevKimlik) then
    begin

      // nesneyi yok et
      Zamanlayici^.YokEt;
    end;
  end;
end;

{==============================================================================
  milisaniye cinsinden bekleme iþlemi yapar
  100 milisaniye = 1 saniye
 ==============================================================================}
{ TODO : önemli bilgi: bu iþlev ana thread'ý bekletmekte, dolayýsýyla sistemi
  belirtilen süre kadar kilitlemektedir. bu problemin önüne geçmek için thread
  çalýþmasý gerçekleþtirilecek }
procedure BekleMS(AMilisaniye: TSayi4);
var
  Sayac: TSayi4;
begin

  // AMilisaniye * 100 saniye bekle
  Sayac := ZamanlayiciSayaci + AMilisaniye;
  while (Sayac > ZamanlayiciSayaci) do begin asm int $20; end; end;
end;

{==============================================================================
  tek görevli ortamda (çoklu ortama geçmeden önce) çalýþan zamanlayýcý iþlevi
 ==============================================================================}
procedure TekGorevZamanlayiciIslevi;
begin

  { TODO : çalýþabilirliði test edilecek }
  Inc(ZamanlayiciSayaci);
end;

{==============================================================================
  donaným tarafýndan görev deðiþtirme iþlevlerini yerine getirir.
 ==============================================================================}
procedure OtomatikGorevDegistir; nostackframe; assembler;
asm

  cli

  // deðiþime uðrayacak yazmaçlarý sakla
  pushad
  pushfd

  // çalýþan görevin DS yazmacýný sakla
  // not : ds = es = ss = fs = gs olduðu için tek yazmacýn saklanmasý yeterlidir.
  mov   ax,ds
  push  eax

  // yazmaçlarý sistem yazmaçlarýna ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  // zamanlayýcý sayacýný artýr.
  mov ecx,ZamanlayiciSayaci
  inc ecx
  mov ZamanlayiciSayaci,ecx

  mov eax,GorevDegisimBayragi
  cmp eax,0
  je  @@cik

  mov   eax,CokluGorevBasladi
  cmp   eax,1
  je    @@kontrol1

@@cik:
  // çalýþan proses'in segment yazmaçlarýný eski konumuna geri döndür
  pop   eax
  mov   ds,ax
  mov   es,ax

  mov   al,$20
  out   PIC1_KOMUT,al

  // genel yazmaçlarý geri yükle ve kesmeden çýk
  popfd
  popad
  sti
  iretd

@@kontrol1:

  { rutin iþlev kontrollerinin gerçekleþtirildiði kýsým }

  // uygulamalar tarafýndan oluþturulan zamanlayýcý nesnelerini denetle
  call  ZamanlayicilariKontrolEt

  // her 1 saniyede kontrol edilecek dahili iþlevler
  mov edx,0
  mov eax,ZamanlayiciSayaci
  mov ecx,100
  div ecx
  cmp edx,0
  jg  @@yenigorev

  // ARP tablosunu güüncelle
  call  ARPTablosunuGuncelle

@@yenigorev:

  // tek bir görev çalýþýyorsa görev deðiþikliði yapma, çýk
  mov ecx,CalisanGorevSayisi
  cmp ecx,1
  je  @@cik

  // geçiþ yapýlacak bir sonraki görevi bul
  call  CalistirilacakBirSonrakiGoreviBul
  mov CalisanGorev,eax

  // aktif görevin bellek baþlangýç adresini al
  dec eax
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,[esi + TGorev.FBellekBaslangicAdresi]
  mov CalisanGorevBellekAdresi,eax

  // görev deðiþiklik sayacýný bir artýr
  mov eax,[esi + TGorev.FGorevSayaci]
  inc eax
  mov [esi + TGorev.FGorevSayaci],eax

  // GorevDegisimSayisi = kilitlenmeleri denetleyebilmek için eklenen deðiþken
  mov eax,GorevDegisimSayisi
  inc eax
  mov GorevDegisimSayisi,eax

  // görevin devredileceði TSS giriþini belirle
  mov   ecx,CalisanGorev
  cmp   ecx,1
  je    @@TSS_SISTEM
  cmp   ecx,2
  je    @@TSS_CAGRI
  cmp   ecx,3
  je    @@TSS_GRAFIK

@@TSS_UYGULAMA:
  sub   ecx,AYRILMIS_GOREV_SAYISI + 1
  imul  ecx,3
  add   ecx,AYRILMIS_SECICISAYISI + 2
  imul  ecx,8
  add   ecx,3                             // DPL3 - uygulama
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_SISTEM:
  mov   ecx,SECICI_SISTEM_TSS * 8         // DPL0 - sistem
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_CAGRI:
  mov   ecx,SECICI_CAGRI_TSS * 8          // DPL0 - sistem
//  add   ecx,3
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_GRAFIK:
  mov   ecx,SECICI_GRAFIK_TSS * 8         // DPL0 - sistem
//  add   ecx,3
  mov   @@SECICI,cx

@@son:

  // çalýþan görevin seçici (selector) yazmaçlarýný eski konumuna geri döndür
  pop   eax
  mov   ds,ax
  mov   es,ax

  // EOI - kesme sonu
  mov   al,$20
  out   PIC1_KOMUT,al

  // çalýþan görevin genel yazmaçlarýný eski konumuna geri döndür
  popfd
  popad

  sti

// iþlemi belirtilen proses'e devret
@@JMPKOD: db  $EA
@@ADRES:  dd  0       // donaným destekli görev deðiþimlerinde ADRES (offset) gözardý edilir
@@SECICI: dw  0
  iretd
end;

{==============================================================================
  yazýlým tarafýndan görev deðiþtirme iþlevlerini yerine getirir.
 ==============================================================================}
procedure ElleGorevDegistir; nostackframe; assembler;
asm

  int $20
  ret

  { TODO - aþaðýdaki kodlar geçici olarak devre dýþý }

  // alttaki kodlar iptal edilebilir mi? test edilecek - 10.11.2019
  cli
  pushad
  pushfd

  mov   eax,CokluGorevBasladi
  cmp   eax,1
  je    @@kontrol1

  // genel yazmaçlarý geri yükle ve iþlevden çýk
  popfd
  popad
  sti
  ret

@@kontrol1:

  mov ecx,CalisanGorevSayisi
  cmp ecx,1
  jg  @@yenigorev

  popfd
  popad
  sti
  ret

@@yenigorev:

  call  CalistirilacakBirSonrakiGoreviBul
  mov CalisanGorev,eax

  // aktif görevin bellek baþlangýç adresini al
  mov eax,CalisanGorev
  dec eax
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,[esi + TGorev.FBellekBaslangicAdresi]
  mov CalisanGorevBellekAdresi,eax

  // görev deðiþiklik sayacýný bir artýr
  mov eax,CalisanGorev
  dec eax
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,[esi + TGorev.FGorevSayaci]
  inc eax
  mov [esi + TGorev.FGorevSayaci],eax

  // görevin devredileceði TSS giriþini belirle
  mov   ecx,CalisanGorev
  cmp   ecx,1
  je    @@TSS_SISTEM
  cmp   ecx,2
  je    @@TSS_CAGRI
  cmp   ecx,3
  je    @@TSS_GRAFIK

@@TSS_UYGULAMA:
  sub   ecx,AYRILMIS_GOREV_SAYISI + 1
  imul  ecx,3
  add   ecx,AYRILMIS_SECICISAYISI + 2
  imul  ecx,8
  add   ecx,3                             // DPL3 - uygulama
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_SISTEM:
  mov   ecx,SECICI_SISTEM_TSS * 8         // DPL0 - sistem
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_CAGRI:
  mov   ecx,SECICI_CAGRI_TSS * 8          // DPL0 - sistem
//  add   ecx,3
  mov   @@SECICI,cx
  jmp   @@son

@@TSS_GRAFIK:
  mov   ecx,SECICI_GRAFIK_TSS * 8         // DPL0 - sistem
//  add   ecx,3
  mov   @@SECICI,cx

@@son:
  popfd
  popad

@@JMPKOD: db  $EA
@@ADRES:  dd  0
@@SECICI: dw  0
  sti
  ret
end;

end.

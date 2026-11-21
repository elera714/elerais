{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: kesme34.pas
  Dosya İşlevi: uygulamaların kesme ($34) isteklerini yönlendirir

  Güncelleme Tarihi: 21/11/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit kesme34;

interface

uses paylasim;

const
  USTSINIR_KESMESAYISI = 19;

procedure Kesme34CagriIslevleri;
function HataliCagriIslevi: TISayi4;

implementation

uses k_ekran, k_gorselnesne, k_olay, k_dosya, k_yazim, k_sayac, k_cizim, k_sistem,
  k_zamanlayici, k_sistemmesaj, k_bellek, k_gorev, k_pci, k_ag, k_depolama, k_fare,
  k_baglantilar, k_diger, k_giysi, gorev, sistem;

var
  UygulamaYiginAdresi: Isaretci;

{==============================================================================
  uygulama ana çağrı işlevlerini yönetir
 ==============================================================================}
procedure Kesme34CagriIslevleri; nostackframe; assembler;
asm

  // tüm yazmaçları yığına (stack) at
  pushad

  // istekte bulunan görevin veri bölütünü (segment) sakla
  mov   bx,ds
  push  ebx
{
  ESP + 0	- üstteki ebx

  ESP + 4	- pushad.edi
  ESP + 8	- pushad.esi
  ESP + 12 - pushad.ebp
  ESP + 16 - pushad.esp (pushad öncesi) ----> sistem esp (ring0)
  ESP + 20 - pushad.ebx
  ESP + 24 - pushad.edx
  ESP + 28 - pushad.ecx
  ESP + 32 - pushad.eax                 ----> geri dönüş değeri

  ESP + 36 - ring3 eip     0
  ESP + 40 - ring3 cs      4
  ESP + 44 - ring3 eflags  8
  ESP + 48 - ring3 esp    12 ---------------> program esp (ring3)
  ESP + 52 - ring3 ss     16
}
  // bölütleri sistem bölütlerine ayarla
  mov   ebx,SECICI_SISTEM_VERI
  shl   ebx,3
  mov   ds,bx
  mov   es,bx

  mov   esi,[GSistem]
  mov   ebx,[esi + TSistem.FCagriSayaci]
  inc   ebx
  mov   [esi + TSistem.FCagriSayaci],ebx

  // uygulamanın yığına sürdüğü değişken adresine konumlan
  mov   edx,[esp + 16]                          // sistem esp (ring0)
  mov   edx,[edx + 12]                          // program esp (ring3)
  mov   esi,[GGorevler]
  add   edx,[esi + TGorevler.FAktifGrvBelAdr]   // + program bellek başlangıç adresi
  mov   UygulamaYiginAdresi,edx

  // eax = işlev çağrı numarası
  mov ecx,eax
  and ecx,$FF
  cmp ecx,0
  jne @@ustsinif_kontrol

  call  HataliCagriIslevi
  jmp @@islem_tamam

@@ustsinif_kontrol:

  cmp ecx,USTSINIR_KESMESAYISI
  jbe @@kesme_cagir

  call  HataliCagriIslevi
  jmp @@islem_tamam

@@kesme_cagir:

  shr eax,8
  and eax,$FFFFFF
  mov edx,UygulamaYiginAdresi

  // uygulamanın istediği işlevi çağır
  call  DWORD PTR @@Islevler[ecx * 4]
  jmp @@islem_tamam

@@Islevler:
  dd  {00} 0, EkranCagriIslevleri, GorselNesneCagriIslevleri,
  dd  {03} OlayCagriIslevleri, DosyaCagriIslevleri, YazimCagriIslevleri,
  dd  {06} SayacCagriIslevleri, SistemCagriIslevleri, CizimCagriIslevleri,
  dd  {09} ZamanlayiciCagriIslevleri, SistemMesajCagriIslevleri, BellekCagriIslevleri,
  dd  {12} GorevCagriIslevleri, PCICagriIslevleri, AgCagriIslevleri
  dd  {15} DepolamaCagriIslevleri, FareCagriIslevleri, GiysiCagriIslevleri,
  dd  {18} AgBaglantiCagriIslevleri, DigerCagriIslevleri

@@islem_tamam:

  // geri dönüş değerini yığındaki eax'e yerleştir
  mov   [esp + 32],eax

  // istekte bulunan görevin veri bölütünü eski konumuna döndür
  pop   ebx
  mov   ds,bx
  mov   es,bx

  // yazmaçları yığından (stack) geri al
  popad

  // istekte bulunan uygulamaya geri dön
  iretd
end;

{==============================================================================
  hatalı uygulama çağrılarının yönlendirildiği işlev
 ==============================================================================}
function HataliCagriIslevi: TISayi4;
begin

  Result := HATA_ISLEV;
end;

end.

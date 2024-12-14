{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: kesme34.pas
  Dosya İşlevi: uygulamaların kesme ($34) isteklerini yönlendirir

  Güncelleme Tarihi: 10/08/2020

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
  k_iletisim, k_diger, k_giysi;

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

  // bölütleri sistem bölütlerine ayarla
  mov   bx,SECICI_CAGRI_VERI * 8
  mov   ds,bx
  mov   es,bx

  // uygulamanın yığına sürdüğü değişken adresine konumlan
  mov   edx,[esp + 12 + 04]               // sistem esp (ring0)
  mov   edx,[edx + 12]                    // program esp (ring3)
  add   edx,CalisanGorevBellekAdresi      // + program bellek başlangıç adresi
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
  dd  {18} AgIletisimCagriIslevleri, DigerCagriIslevleri

@@islem_tamam:

  // geri dönüş değerini yığındaki eax'e yerleştir
  mov   [esp + 28 + 04],eax

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

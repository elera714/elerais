{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: yukleyici.pas
  Dosya Ýþlevi: sistem ilk açýlýþ yükleme iþlevleri gerçekleþtirir

  Güncelleme Tarihi: 07/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE SRC_SB}
//{$DEFINE SRC_COM}
{$DEFINE AG_YUKLE}
unit yukleyici;

interface

procedure Yukle;
procedure YukleIslevindenOnceCalistir;
procedure YukleIslevindenSonraCalistir;

implementation

uses yonetim, gdt, idt, irq, pic, pci, src_klavye, genel, gorev, fdepolama, gercekbellek,
  gorselnesne, dosya, sistemmesaj, mdepolama, islemci, paylasim, usb, zamanlayici,
  ag, src_vesa20, src_com, src_sb, bmp, acpi, k_giysi, giysi_mac, giysi_normal,
  olayyonetim, giysi;

{==============================================================================
  çekirdek çevre donaným yükleme iþlevlerini gerçekleþtir
 ==============================================================================}
procedure Yukle;
begin

  CokluGorevBasladi := 0;

  // çekirdek yükleme öncesi iþlevleri gerçekleþtir
  YukleIslevindenOnceCalistir;

  // tüm kesmeleri pasifleþtir
  pic.TumKanallariPasiflestir;

  // sistem global tanýmlayýcý tabloyu (GDTRYazmac) ve içeriðini yükle
  gdt.Yukle;

  // kesme yazmacýný (IDTYazmac) ve içeriðini yükle
  idt.Yukle;

  // pic denetleyicisini ilk deðerlerle yükle
  pic.Yukle;

  // irq denetleyicisini ilk deðerlerle yükle
  // Bilgi: bu aþamaya kadar tüm irq istekleri kapalýdýr.
  // bu aþamadan itibaren yapýlacak IRQEtkinlestir, IRQIsleviAta
  // iþlevleri belirtilen irq isteklerini devreye sokacaktýr
  irq.Yukle;

  // bu iþlev çoklu görev ortamýna girmeden önce test edilmelidir
  IRQIsleviAta(0, @TekGorevZamanlayiciIslevi);
  IRQEtkinlestir(0);

  // belleði ilk kullaným için hazýrla
  // Önemli: GGercekBellek.Yukle iþlevinin diðer iþlevlere zemin hazýrlamasý için
  // öncelikle yüklenmesi gerekmektedir.
  GercekBellek0.Yukle;

  // NOT: SISTEM_MESAJ_'ler buradan itibaren sistem içerisine yönlendiriliyor

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Sistem içerisinde kullanýlacak görsel olmayan nesneler yükleniyor.', []);
  ListeleriIlkDegerlerleYukle;

  //SISTEM_MESAJ(RENK_LACIVERT, '+ Sistem mesaj servisi baþlatýlýyor...', []);
  SistemMesaj0.Yukle;

  // uygulama deðiþkenlerini ilk deðerlerle yükle
  Gorevler0.Yukle;

  // çekirdek deðiþken / iþlevlerini ilk deðerlerle yükle
  yonetim.Yukle;

  // vesa 2.0 grafik sürücüsünü yükle
  EkranKartSurucusu0.Yukle;

  // Bilgi: SISTEM_MESAJ_'ler buradan itibaren kullanýlabilir

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Ýþlemci bilgileri alýnýyor...', []);
  GIslemciBilgisi.Satici := IslemciSaticisiniAl;
  IslemciOzellikleriniAl1(GIslemciBilgisi.Ozellik1_EAX, GIslemciBilgisi.Ozellik1_EDX,
    GIslemciBilgisi.Ozellik1_ECX);

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Zamanlayýcý yükleniyor...', []);
  Zamanlayicilar0.Yukle;

  // Bilgi: Delay iþlevleri buradan itibaren kullanýlabilir

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ PCI aygýtlarý aranýyor...', []);
  PCIAygiti0.Yukle;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ ACPI donanýmý yükleniyor...', []);
  acpi.Yukle;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Klavye aygýtý yükleniyor...', []);
  src_klavye.Yukle;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ PS2 fare sürücüsü yükleniyor...', []);
  GFareSurucusu.Yukle;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ USB aygýtlarý yükleniyor...', []);
  usb.Yukle;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Depolama aygýtlarý yükleniyor...', []);
  FizikselDepolama0.Yukle;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Mantýksal sürücü atamalarý gerçekleþtiriliyor...', []);
  MantiksalDepolama0.Yukle;

  {$IFDEF SRC_COM}
  SISTEM_MESAJ(RENK_MAVI, '+ Ýletiþim (COM) portu yükleniyor...', []);
  src_com.Yukle;
  {$ENDIF}

  // sound blaster ses aygýtýný yükle
  {$IFDEF SRC_SB}
  SISTEM_MESAJ(RENK_MAVI, '+ Ses kartý yükleniyor...', []);
  src_sb.Yukle;
  {$ENDIF}

  // að bileþenlerini yükle
  {$IFDEF AG_YUKLE}
  ag.Yukle;
  {$ENDIF}

  // olay nesnesini ilk deðerlerini yükle
  GOlayYonetim := TOlayYonetim.Create;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Görsel nesne için bellek iþlemleri yapýlýyor.', []);
  GorselNesneler0.Yukle;

  // çekirdek yükleme sonrasý iþlevleri gerçekleþtir
  YukleIslevindenSonraCalistir;

  // pencere giysi birimini yükle
  Giysiler0.Yukle;

  // sistem mesajlarýný görmek için bekleme süresi.
  BekleMS(50);

  CokluGorevBasladi := 1;
end;

{==============================================================================
  çekirdek yükleme öncesi iþlevleri çalýþtýrýr.
 ==============================================================================}
procedure YukleIslevindenOnceCalistir;
var
  TSSBellekAdresi: Isaretci;
  i: TSayi4;
begin

  SistemSayaci := 0;
  ZamanlayiciSayaci := 0;

  // TSS giriþlerini bellek adresleriyle eþleþtir
  TSSBellekAdresi := Isaretci($520000);
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    GorevTSSListesi[i] := TSSBellekAdresi;
    TSSBellekAdresi += TSS_UZUNLUK;
  end;
end;

{==============================================================================
  çekirdek yükleme sonrasý iþlevleri çalýþtýrýr.
 ==============================================================================}
procedure YukleIslevindenSonraCalistir;
begin

  Dosyalar0.Yukle;

  // 24 x 24 sistem resimlerini yükle
  GSistemResimler := BMPDosyasiYukle('disk1:\resimler\sistem.bmp');
  GSistemResimler2 := BMPDosyasiYukle('disk1:\resimler\sistem2.bmp');

  SistemUyariBellekAdresi := Isaretci($3200000);
  DosyaUyari := DosyaOku('disket1:\suyari.c', SistemUyariBellekAdresi);
end;

end.

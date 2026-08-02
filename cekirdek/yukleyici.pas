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

type
  TYukleyici = object
  public
    procedure Yukle;
  end;

procedure YukleIslevindenOnceCalistir;
procedure YukleIslevindenSonraCalistir;

var
  GYukleyici0: TYukleyici;

implementation

uses yonetim, gdt, idt, irq, pic, pci, src_klavye, genel, gorev, fdepolama, gercekbellek,
  gorselnesne, dosya, sistemmesaj, mdepolama, islemci, paylasim, usb, zamanlayici,
  ag, src_vesa20, src_com, src_sb, bmp, acpi, k_giysi, giysi_mac, giysi_normal,
  olayyonetim, giysi, src_ps2, src_disket, src_ide, sistem;

{==============================================================================
  çekirdek çevre donaným yükleme iþlevlerini gerçekleþtir
 ==============================================================================}
procedure TYukleyici.Yukle;
begin

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
  GYonetim0.ListeleriIlkDegerlerleYukle;

  //SISTEM_MESAJ(RENK_LACIVERT, '+ Sistem mesaj servisi baþlatýlýyor...', []);
  GSistemMesaj := TSistemMesaj.Create;

  // uygulama deðiþkenlerini ilk deðerlerle yükle
  Gorevler0.Yukle;

  // çekirdek deðiþken / iþlevlerini ilk deðerlerle yükle
  GYonetim0.Yukle;

  // vesa 2.0 grafik sürücüsünü yükle
  GEkranKartSurucusu.Yukle;

  // Bilgi: SISTEM_MESAJ_'ler buradan itibaren kullanýlabilir

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Ýþlemci bilgileri alýnýyor...', []);
  GIslemci := TIslemci.Create;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Zamanlayýcý yükleniyor...', []);
  GZamanlayicilar.Yukle;

  // Bilgi: Delay iþlevleri buradan itibaren kullanýlabilir

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ PCI aygýtlarý aranýyor...', []);
  PCIAygiti0.Yukle;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ ACPI donanýmý yükleniyor...', []);
  GACPI := TACPI.Create;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Klavye aygýtý yükleniyor...', []);
  GKlavye := TKlavye.Create;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ PS2 fare sürücüsü yükleniyor...', []);
  GFareSurucusu := TFareSurucusu.Create;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ USB aygýtlarý yükleniyor...', []);
  GUSB := TUSB.Create;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Depolama aygýtlarý yükleniyor...', []);
  GFizikselDepolama.Create;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Mantýksal sürücü atamalarý gerçekleþtiriliyor...', []);
  GMantiksalDepolama := TMantiksalDepolama.Create;

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
  GAg0 := TAg.Create;
  {$ENDIF}

  // olay nesnesini ilk deðerlerini yükle
  GOlayYonetim := TOlayYonetim.Create;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Görsel nesne için bellek iþlemleri yapýlýyor.', []);
  GGorselNesneler := TGorselNesneler.Create;

  // çekirdek yükleme sonrasý iþlevleri gerçekleþtir
  YukleIslevindenSonraCalistir;

  // pencere giysi birimini yükle
  GGiysiler := TGiysiler.Create;

  GSistem := TSistem.Create;

  // sistem mesajlarýný görmek için bekleme süresi.
  BekleMS(50);
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
    TSSBellekAdresi := TSSBellekAdresi + TSS_UZUNLUK;
  end;
end;

{==============================================================================
  çekirdek yükleme sonrasý iþlevleri çalýþtýrýr.
 ==============================================================================}
procedure YukleIslevindenSonraCalistir;
var
  BMP: TBMP;
begin

  GDosyalar := TDosyalar.Create;

  // 24 x 24 sistem resimlerini yükle
  BMP := TBMP.Create;
  GSistemResimler := BMP.BMPDosyasiYukle('disk1:\resimler\sistem.bmp');
  GSistemResimler2 := BMP.BMPDosyasiYukle('disk1:\resimler\sistem2.bmp');
  BMP.Destroy;

  SistemUyariBellekAdresi := Isaretci($3200000);
  DosyaUyari := DosyaOku('disket1:\suyari.c', SistemUyariBellekAdresi);
end;

end.

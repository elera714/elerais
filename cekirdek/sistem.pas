{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: sistem.pas
  Dosya Ýþlevi: sistem yönetim iþlevlerini içerir

  Güncelleme Tarihi: 21/08/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit sistem;

interface

uses paylasim;

type
  TSistem = class
  public
    FSistemSayaci, FCagriSayaci,
    FGrafikSayaci: TSayi4;
    // 24 x 24 sistemler. yukleyici.pas dosyasýndan yükleme iþlemi yapýlýr
    FSistemResimler,
    FSistemResimler2: TGoruntuYapi;
    constructor Create;
    procedure BilgisayariKapat;
    procedure YenidenBaslat;
    procedure SistemAyarlariniKaydet(AKaydetmeSebebi: TSayi4);
    procedure CalisanUygulamalariKaydet;
  end;

var
  GSistem: TSistem;

implementation

uses port, dosya, gorselnesne, gorev, donusum, sistemmesaj, gn_masaustu, gn_islevler;

constructor TSistem.Create;
begin

  // sistem sayaçlarýný sýfýrla
  FSistemSayaci := 0;
  FCagriSayaci := 0;
  FGrafikSayaci := 0;
end;

procedure TSistem.BilgisayariKapat;
begin

  // öncelikle sistem ayarlarýný kaydet
  SistemAyarlariniKaydet(1);

  asm cli; hlt; end;
end;

procedure TSistem.YenidenBaslat;
var
  B1: TSayi1;
begin

  // öncelikle sistem ayarlarýný kaydet
  SistemAyarlariniKaydet(2);

  repeat

    B1 := PortAl1($64);
    if((B1 and 1) = 0) then PortAl1($60);     // = 1 = veri mevcut olduðu müddetçe porttan veriyi al
  until ((B1 and 2) = 0);                     // = 0 = veri yazýlabilir olmadýðý müddetçe tekrarla

  // porta veriyi yaz - yeniden baþlat
  PortYaz1($64, $FE);

  asm @@1: hlt; jmp @@1; end;
end;

procedure TSistem.SistemAyarlariniKaydet(AKaydetmeSebebi: TSayi4);
var
  DosyaAdi,
  TS, s: string;
begin

  CalisanUygulamalariKaydet;

  DosyaAdi := 'elera.ini';
  IzKaydiOlustur(DosyaAdi, 'sistem-adý=' + SistemAdi);

  if(AKaydetmeSebebi = 1) then
    s := 'kapatýldý.'
  else if(AKaydetmeSebebi = 2) then
    s := 'yeniden baþlatýldý.'
  else s := '?';

  // programýn iz kayýt dosyasýný oluþtur
  TS := TarihSaatBilgisiAl;

  DosyaAdi := 'elera.log';
  IzKaydiOlustur(DosyaAdi, 'Sistem ' + TS + ' itibariyle ' + s + #13#10, False);
end;

// çalýþan uygulama listesinin dosyaya kaydedilme iþlemi
procedure TSistem.CalisanUygulamalariKaydet;
var
  GN: TGorselNesne;
  P: TProgramKayit;
  CalisanPSayisi,
  i, j: TISayi4;
  Sonuc: TISayi4;
  DosyaKimlik: TKimlik;
  s: string;
begin

  AssignFile(DosyaKimlik, 'disk2:\yuklenecek_programlar.ini');
  ReWrite(DosyaKimlik);
  Sonuc := IOResult;
  if(Sonuc = HATA_YOK) then
  begin

    CalisanPSayisi := CalisanProgramSayisiniAl(GGNesneler.AktifMasaustu.Kimlik);

    for i := 0 to CalisanPSayisi - 1 do
    begin

      P := CalisanProgramBilgisiAl(i, GGNesneler.AktifMasaustu.Kimlik);
      j := Length(P.DosyaAdi);
      if(P.DosyaAdi[j] = 'c') then
      begin

        s := P.DosyaAdi;

        GN := GGNesneler.NesneAl(P.PencereKimlik);
        if not(GN = nil) then
        begin

          s := s + ';' + IntToStr(GN.FAtananAlan.Sol);
          s := s + ';' + IntToStr(GN.FAtananAlan.Ust);
          s := s + ';' + IntToStr(GN.FAtananAlan.Genislik);
          s := s + ';' + IntToStr(GN.FAtananAlan.Yukseklik);

          WriteLn(DosyaKimlik, s);
        end;
      end;
    end;

    CloseFile(DosyaKimlik);
  end
  else
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'disk2:\yuklenecek_programlar.ini dosyasý oluþturulamýyor!', []);
    CloseFile(DosyaKimlik);
  end;
end;

end.

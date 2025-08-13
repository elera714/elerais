{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: sistem.pas
  Dosya ��levi: sistem y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 25/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit sistem;

interface

uses paylasim;

procedure YenidenBaslat;
procedure BilgisayariKapat;
procedure SistemAyarlariniKaydet;
procedure CalisanUygulamalariKaydet;

implementation

uses port, dosya, gorselnesne, gorev, genel, donusum, sistemmesaj;

procedure YenidenBaslat;
var
  B1: TSayi1;
begin

  // �ncelikle sistem ayarlar�n� kaydet
  SistemAyarlariniKaydet;

  repeat

    B1 := PortAl1($64);
    if((B1 and 1) = 0) then PortAl1($60);     // = 1 = veri mevcut oldu�u m�ddet�e porttan veriyi al
  until ((B1 and 2) = 0);                     // = 0 = veri yaz�labilir olmad��� m�ddet�e tekrarla

  // porta veriyi yaz - yeniden ba�lat
  PortYaz1($64, $FE);

  asm @@1: hlt; jmp @@1; end;
end;

procedure BilgisayariKapat;
begin

  // �ncelikle sistem ayarlar�n� kaydet
  SistemAyarlariniKaydet;

  asm cli; hlt; end;
end;

procedure SistemAyarlariniKaydet;
var
  DosyaAdi: string;
begin

  CalisanUygulamalariKaydet;

  DosyaAdi := 'elera.ini';
  IzKaydiOlustur(DosyaAdi, 'sistem-ad�=' + SistemAdi);
end;

// �al��an uygulama listesinin dosyaya kaydetme i�lemi
procedure CalisanUygulamalariKaydet;
var
  GN: PGorselNesne;
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
  //if(Sonuc > HATA_YOK) then Append(DosyaKimlik);
  if(Sonuc = HATA_YOK) then
  begin

    CalisanPSayisi := CalisanProgramSayisiniAl(GAktifMasaustu^.Kimlik);

    for i := 0 to CalisanPSayisi - 1 do
    begin

      P := CalisanProgramBilgisiAl(i, GAktifMasaustu^.Kimlik);
      j := Length(P.DosyaAdi);
      if(P.DosyaAdi[j] = 'c') then
      begin

        s := P.DosyaAdi;

        GN := GorselNesneler0.NesneAl(P.PencereKimlik);
        if not(GN = nil) then
        begin

          s += ';' + IntToStr(GN^.FAtananAlan.Sol);
          s += ';' + IntToStr(GN^.FAtananAlan.Ust);
          s += ';' + IntToStr(GN^.FAtananAlan.Genislik);
          s += ';' + IntToStr(GN^.FAtananAlan.Yukseklik);

          WriteLn(DosyaKimlik, s);
        end;

      end;
    end;

    CloseFile(DosyaKimlik);
  end
  else
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'disk2:\yuklenecek_programlar.ini dosyas� olu�turulam�yor!', []);
    CloseFile(DosyaKimlik);
  end;
end;

end.

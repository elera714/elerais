program defter;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: defter.lpr
  Program Ýþlevi: metin düzenleme programý

  Güncelleme Tarihi: 20/09/2024

  Bilgi: çekirdek tarafýndan defter.c programýna bilgileri iþlemesi için
    Isaretci(4)^ adresinde 4096 * 10 byte yer tahsis edilmiþtir.

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_durumcubugu, gn_etiket, gn_giriskutusu, gn_dugme,
  gn_defter, gn_onaykutusu, gn_panel, n_genel;

const
  ProgramAdi: string = 'Dijital Defter';
  DOSYA_BELLEK_KAPASITESI = Integer(4096 * 10);

var
  Genel: TGenel;
  Gorev: TGorev;
  Pencere: TPencere;
  Panel: TPanel;
  DurumCubugu: TDurumCubugu;
  Defter0: TDefter;
  etiDosyaAdi: TEtiket;
  gkDosyaAdi: TGirisKutusu;
  okMetniSarmala: TOnayKutusu;
  dugYukle: TDugme;
  Olay: TOlay;
  DosyaKimlik: TKimlik;
  DosyaUzunluk: TSayi4;
  DosyaAdi: string;
  DosyaBellek: PChar;

procedure BellekTemizle;
var
  i: TSayi4;
  p: PChar;
begin

  p := DosyaBellek;
  for i := 0 to DOSYA_BELLEK_KAPASITESI - 1 do p[i] := #0;
end;

procedure DosyaAc;
var
  s: string;
begin

  BellekTemizle;

  Defter0.Temizle;

  Genel._AssignFile(DosyaKimlik, DosyaAdi);
  Genel._Reset(DosyaKimlik);

  DosyaUzunluk := Genel._FileSize(DosyaKimlik);

  if(DosyaUzunluk <= DOSYA_BELLEK_KAPASITESI) then
  begin

    //_IOResult;

    //_EOF(DosyaKimlik);

    Genel._FileRead(DosyaKimlik, DosyaBellek);
  end;

  Genel._CloseFile(DosyaKimlik);

  if(DosyaUzunluk > DOSYA_BELLEK_KAPASITESI) then
  begin

    Defter0.YaziEkle('Hata: dosya boyutu en fazla ' + IntToStr(DOSYA_BELLEK_KAPASITESI) + ' byte olmalýdýr.' + #0);

    s := 'Dosya: -';

    DurumCubugu.DurumYazisiDegistir(s);
  end
  else if(DosyaAdi <> '') then
  begin

    Defter0.YaziEkle(DosyaBellek);

    s := 'Dosya: ' + DosyaAdi + ', ' + IntToStr(DosyaUzunluk) + ' byte';

    DurumCubugu.DurumYazisiDegistir(s);
  end;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 10, 10, 490 + 10, 300 + 85, ptBoyutlanabilir, ProgramAdi,
    RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Panel.Olustur(Pencere.Kimlik, 0, 0, 100, 32, 2, RENK_GRI, $E0EEFA, 0, '');
  Panel.Hizala(hzUst);
  Panel.Goster;

  etiDosyaAdi.Olustur(Panel.Kimlik, 2, 9, $000000, 'Dosya Adý:');
  etiDosyaAdi.Goster;

  gkDosyaAdi.Olustur(Panel.Kimlik, 11 * 8, 6, 24 * 8, 22, '');
  gkDosyaAdi.IcerikYaz('disket1:\haklar.txt');
  gkDosyaAdi.Goster;

  dugYukle.Olustur(Panel.Kimlik, 36 * 8, 5, 60, 22, 'Yükle');
  dugYukle.Goster;

  okMetniSarmala.Olustur(Panel.Kimlik, 45 * 8, 8, 'Metni Sarmala');
  okMetniSarmala.Goster;

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 18, 'Dosya: -');
  DurumCubugu.Goster;

  Defter0.Olustur(Pencere.Kimlik, 0, 0, 10, 10, RENK_BEYAZ, RENK_SIYAH, False);
  Defter0.Hizala(hzTum);
  Defter0.Goster;

  Pencere.Gorunum := True;

  // programa tahsis edilmiþ bellek adresini al
  DosyaBellek := PChar(Isaretci(4)^);

  DosyaAdi := '';

  if(ParamCount > 0) then
  begin

    DosyaAdi := ParamStr1(1);

    gkDosyaAdi.IcerikYaz(DosyaAdi);

    DosyaAc;
  end;

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = FO_SOLTUS_BASILDI) then
    begin

      if(Olay.Kimlik = dugYukle.Kimlik) then
      begin

        DosyaAdi := gkDosyaAdi.IcerikAl;

        gkDosyaAdi.IcerikYaz(DosyaAdi);

        DosyaAc;
      end;
    end
    else if(Olay.Olay = CO_TUSBASILDI) then
    begin

      if(Olay.Deger1 = 10) then
      begin

        DosyaAdi := gkDosyaAdi.IcerikAl;

        gkDosyaAdi.IcerikYaz(DosyaAdi);

        DosyaAc;
      end;
    end
    else if(Olay.Olay = CO_DURUMDEGISTI) then
    begin

      if(Olay.Kimlik = okMetniSarmala.Kimlik) then
      begin

        if(Olay.Deger1 = 1) then
          Defter0.MetniSarmala(True)
        else Defter0.MetniSarmala(False);
      end;
    end;
  end;
end.

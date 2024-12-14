program takvim;
{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: takvim.lpr
  Program Ýþlevi: takvim uygulamasý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_genel, n_gorev, gn_pencere, gn_panel, gn_etiket, gn_karmaliste, gn_izgara;

const
  ProgramAdi: string = 'Takvim';

var
  Genel: TGenel;
  Gorev: TGorev;
  Pencere: TPencere;
  Panel: TPanel;
  EtkAy, EtkYil: TEtiket;
  KLAy, KLYil: TKarmaListe;
  Izgara: TIzgara;
  Olay: TOlay;
  BuYil, BuAy, BuGun,
  FIlkYil,                              // karma listedeki ilk yýl deðeri
  FSeciliYil, FSeciliAy, i: TISayi4;
  TarihDizi: array[0..3] of TSayi2;     // gün / ay / yýl / haftanýn günü

procedure TakvimiOlustur(AYil, AAy, ABugun: TISayi4);
var
  AyinGunleri: array[1..12] of TSayi1;
  SeciliYil, SeciliAy, D1, D2, D3,
  SeciliYilinIlkGunu, SeciliAyinIlkGunu: TISayi4;
  i: TISayi4;
begin

  AyinGunleri[01] := 31;
  AyinGunleri[02] := 29;
  AyinGunleri[03] := 31;
  AyinGunleri[04] := 30;
  AyinGunleri[05] := 31;
  AyinGunleri[06] := 30;
  AyinGunleri[07] := 31;
  AyinGunleri[08] := 31;
  AyinGunleri[09] := 30;
  AyinGunleri[10] := 31;
  AyinGunleri[11] := 30;
  AyinGunleri[12] := 31;

  Izgara.Temizle;
  Izgara.ElemanEkle('Pt');
  Izgara.ElemanEkle('Sa');
  Izgara.ElemanEkle('Ça');
  Izgara.ElemanEkle('Pe');
  Izgara.ElemanEkle('Cu');
  Izgara.ElemanEkle('Ct');
  Izgara.ElemanEkle('Pz');

	if((AYil mod 4) = 0) and ((AYil mod 100) <> 0) or ((AYil mod 400) = 0) then
	  AyinGunleri[2] := 29
  else AyinGunleri[2] := 28;

  SeciliYil := AYil;
  SeciliAy := AAy;

  D1 := (SeciliYil - 1) div 4;
  D2 := (SeciliYil - 1) div 100;
  D3 := (SeciliYil - 1) div 400;
  SeciliYilinIlkGunu := (SeciliYil + D1 - D2 + D3) mod 7;

  SeciliAyinIlkGunu := SeciliYilinIlkGunu;
  if(SeciliAy > 1) then for i := 1 to SeciliAy - 1 do SeciliAyinIlkGunu += AyinGunleri[i];

  SeciliAyinIlkGunu := SeciliAyinIlkGunu mod 7;
  if(SeciliAyinIlkGunu = 0) then SeciliAyinIlkGunu := 7;

  if(SeciliAyinIlkGunu > 1) then
    for i := 2 to SeciliAyinIlkGunu do Izgara.ElemanEkle(' ');

  Izgara.SeciliHucreyiYaz(-1, -1);
  for i := 1 to AyinGunleri[SeciliAy] do
  begin

    Izgara.ElemanEkle(IntToStr(i));
    if(AYil = BuYil) and (AAy = BuAy) and (i = ABuGun) then
      Izgara.SeciliHucreyiYaz((i + 1) mod 7, ((i + 1) div 7) + 1);
  end;

  Izgara.Ciz;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Genel.TarihAl(@TarihDizi);

  BuGun := TarihDizi[0];
  BuAy := TarihDizi[1];
  BuYil := TarihDizi[2];

  Pencere.Olustur(-1, 100, 100, 288, 164, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Panel.Olustur(Pencere.Kimlik, 0, 0, 10, 30, 2, RENK_SIYAH, RENK_BEYAZ, 0, '');
  Panel.Hizala(hzUst);
  Panel.Goster;

  EtkAy.Olustur(Panel.Kimlik, 6, 8, RENK_MAVI, 'Ay:');
  EtkAy.Goster;

  KLAy.Olustur(Panel.Kimlik, 36, 4, 90, 20);
  KLAy.Goster;

  KLAy.ElemanEkle('Ocak');
  KLAy.ElemanEkle('Þubat');
  KLAy.ElemanEkle('Mart');
  KLAy.ElemanEkle('Nisan');
  KLAy.ElemanEkle('Mayýs');
  KLAy.ElemanEkle('Haziran');
  KLAy.ElemanEkle('Temmuz');
  KLAy.ElemanEkle('Aðustos');
  KLAy.ElemanEkle('Eylül');
  KLAy.ElemanEkle('Ekim');
  KLAy.ElemanEkle('Kasým');
  KLAy.ElemanEkle('Aralýk');
  KLAy.BaslikSiraNo := BuAy - 1;

  EtkYil.Olustur(Panel.Kimlik, 156, 8, RENK_MAVI, 'Yýl:');
  EtkYil.Goster;

  KLYil.Olustur(Panel.Kimlik, 194, 4, 90, 20);
  KLYil.Goster;

  FIlkYil := BuYil - 5;

  // mevcut yýldan 5 yýl öncesi ve 5 yýl sonrasý
  for i := FIlkYil to BuYil + 5 do KLYil.ElemanEkle(IntToStr(i));
  KLYil.BaslikSiraNo := 5;

  Izgara.Olustur(Pencere.Kimlik, 3, 3, 100, 100);
  Izgara.Hizala(hzTum);
  Izgara.SabitHucreSayisiYaz(1, 0);
  Izgara.HucreSayisiYaz(7, 7);
  Izgara.HucreBoyutuYaz(18, 40);
  Izgara.KaydirmaCubuguGorunumYaz(False, False);

  FSeciliYil := BuYil;
  FSeciliAy := BuAy;

  TakvimiOlustur(BuYil, BuAy, BuGun);

  Izgara.Goster;

  Pencere.Gorunum := True;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_SECIMDEGISTI) then
    begin

      if(Olay.Kimlik = KLAy.Kimlik) then
      begin

        FSeciliAy := Olay.Deger1 + 1;
      end
      else if(Olay.Kimlik = KLYil.Kimlik) then
      begin

        FSeciliYil := Olay.Deger1 + FIlkYil;
      end;

      TakvimiOlustur(FSeciliYil, FSeciliAy, BuGun);
    end;
  end;
end.

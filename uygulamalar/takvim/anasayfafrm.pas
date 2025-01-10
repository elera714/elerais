{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_panel, gn_etiket, gn_karmaliste,
  gn_izgara;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FPanel: TPanel;
    FEtkAy, FEtkYil: TEtiket;
    FKLAy, FKLYil: TKarmaListe;
    FIzgara: TIzgara;
    procedure TakvimiOlustur(AYil, AAy, ABugun: TISayi4);
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Takvim';

var
  BuYil, BuAy, BuGun,
  FIlkYil,                              // karma listedeki ilk yýl deðeri
  FSeciliYil, FSeciliAy, i: TISayi4;
  TarihDizi: array[0..3] of TSayi2;     // gün / ay / yýl / haftanýn günü

procedure TfrmAnaSayfa.Olustur;
begin

  FGenel.TarihAl(@TarihDizi);

  BuGun := TarihDizi[0];
  BuAy := TarihDizi[1];
  BuYil := TarihDizi[2];

  FPencere.Olustur(-1, 100, 100, 288, 164, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FPanel.Olustur(FPencere.Kimlik, 0, 0, 10, 30, 2, RENK_SIYAH, RENK_BEYAZ, 0, '');
  FPanel.Hizala(hzUst);
  FPanel.Goster;

  FEtkAy.Olustur(FPanel.Kimlik, 6, 8, RENK_MAVI, 'Ay:');
  FEtkAy.Goster;

  FKLAy.Olustur(FPanel.Kimlik, 36, 4, 90, 20);
  FKLAy.Goster;

  FKLAy.ElemanEkle('Ocak');
  FKLAy.ElemanEkle('Þubat');
  FKLAy.ElemanEkle('Mart');
  FKLAy.ElemanEkle('Nisan');
  FKLAy.ElemanEkle('Mayýs');
  FKLAy.ElemanEkle('Haziran');
  FKLAy.ElemanEkle('Temmuz');
  FKLAy.ElemanEkle('Aðustos');
  FKLAy.ElemanEkle('Eylül');
  FKLAy.ElemanEkle('Ekim');
  FKLAy.ElemanEkle('Kasým');
  FKLAy.ElemanEkle('Aralýk');
  FKLAy.BaslikSiraNo := BuAy - 1;

  FEtkYil.Olustur(FPanel.Kimlik, 156, 8, RENK_MAVI, 'Yýl:');
  FEtkYil.Goster;

  FKLYil.Olustur(FPanel.Kimlik, 194, 4, 90, 20);
  FKLYil.Goster;

  FIlkYil := BuYil - 5;

  // mevcut yýldan 5 yýl öncesi ve 5 yýl sonrasý
  for i := FIlkYil to BuYil + 5 do FKLYil.ElemanEkle(IntToStr(i));
  FKLYil.BaslikSiraNo := 5;

  FIzgara.Olustur(FPencere.Kimlik, 3, 3, 100, 100);
  FIzgara.Hizala(hzTum);
  FIzgara.SabitHucreSayisiYaz(1, 0);
  FIzgara.HucreSayisiYaz(7, 7);
  FIzgara.HucreBoyutuYaz(18, 40);
  FIzgara.KaydirmaCubuguGorunumYaz(False, False);

  FSeciliYil := BuYil;
  FSeciliAy := BuAy;

  TakvimiOlustur(BuYil, BuAy, BuGun);

  FIzgara.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  Result := 1;
end;

procedure TfrmAnaSayfa.TakvimiOlustur(AYil, AAy, ABugun: TISayi4);
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

  FIzgara.Temizle;
  FIzgara.ElemanEkle('Pt');
  FIzgara.ElemanEkle('Sa');
  FIzgara.ElemanEkle('Ça');
  FIzgara.ElemanEkle('Pe');
  FIzgara.ElemanEkle('Cu');
  FIzgara.ElemanEkle('Ct');
  FIzgara.ElemanEkle('Pz');

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
    for i := 2 to SeciliAyinIlkGunu do FIzgara.ElemanEkle(' ');

  FIzgara.SeciliHucreyiYaz(-1, -1);
  for i := 1 to AyinGunleri[SeciliAy] do
  begin

    FIzgara.ElemanEkle(IntToStr(i));
    if(AYil = BuYil) and (AAy = BuAy) and (i = ABuGun) then
      FIzgara.SeciliHucreyiYaz((i + 1) mod 7, ((i + 1) div 7) + 1);
  end;

  FIzgara.Ciz;
end;

end.

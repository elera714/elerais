{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ftp.pas
  Dosya Ýþlevi: FTP (dosya) sunucu tutanak iþlevlerini yönetir

  Güncelleme Tarihi: 11/11/2026

 ==============================================================================}
{$mode objfpc}
unit ftp;

interface

uses paylasim, sunucular;

const
  USTSINIR_FTPISTEMCI     = 10;

  { TODO - yapýlandýrýlacak }
  KULLANICI_ADI           = 'elera';
  SIFRE                   = 'elera';

const
  Tanitim             : PChar = '220 ELERA Dosya Sunucusu' + #13 + #10;
  BaglantiKapatiliyor : PChar = '221 baðlantý kapatýlýyor' + #13 + #10;
  GirisBasarili       : PChar = '230 Giriþ baþarýlý' + #13 + #10;

  SifreGirisi         : PChar = '331 Þifre giriniz' + #13 + #10;

  GirisHatali         : PChar = '530 Kullanýcý adý veya þifre hatalý' + #13 + #10;

type
  TFTPSunucu = class(TTCPSunucu)
  private
    FBaglanti: TObject;
  public
    constructor Create(ABaglanti: TObject);
    procedure OIstemciBaglandi(ABaglanti: TObject); override;
    procedure OVeriGeldi(ABaglanti: TObject); override;
    procedure OVeriGonderildi(ABaglanti: TObject); override;
    function KomutDegeriniAl(ABellek: Isaretci; AVeriU: TSayi4): string;
  end;

var
  GFTPSunucu: TFTPSunucu;

implementation

uses baglantilar;

{==============================================================================
  ftp sunucusu ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TFTPSunucu.Create(ABaglanti: TObject);
begin

  FBaglanti := ABaglanti;
end;

{==============================================================================
  istemci baðlandýðýnda tetiklenen olay
 ==============================================================================}
procedure TFTPSunucu.OIstemciBaglandi(ABaglanti: TObject);
begin

  TBaglanti(ABaglanti).Yaz(Tanitim, Length(Tanitim));
end;

{==============================================================================
  istemcilerden veri geldiðinde tetiklenen olay
 ==============================================================================}
procedure TFTPSunucu.OVeriGeldi(ABaglanti: TObject);
var
  Veri: Isaretci;
  VeriU: TSayi4;
  s, Komut: string;
begin

  Veri := GetMem(4 * 4096);

  VeriU := TBaglanti(ABaglanti).Oku(Veri);
  if(VeriU = 0) then Exit;

  s := KomutDegeriniAl(Veri, VeriU);

  Komut := Copy(s, 1, 4);

  if(Komut = 'USER') then
  begin

    TBaglanti(ABaglanti).Yaz(SifreGirisi, Length(SifreGirisi));
  end
  else if(Komut = 'PASS') then
  begin

    TBaglanti(ABaglanti).Yaz(GirisBasarili, Length(GirisBasarili));
    //TBaglanti(ABaglanti).Yaz(GirisHatali, Length(GirisHatali));
  end
  else if(Komut = 'QUIT') then
  begin

    TBaglanti(ABaglanti).Yaz(BaglantiKapatiliyor, Length(BaglantiKapatiliyor));

    TBaglanti(ABaglanti).BaglantiyiKapat;
  end;

  FreeMem(Veri, 4 * 4096);

  //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Gelen Veri: [%s]', [s]);
end;

{==============================================================================
  bu sunucu istemciye veri gönderdiðinde (ve onaylandýðýnda) tetiklenen olay
 ==============================================================================}
procedure TFTPSunucu.OVeriGonderildi(ABaglanti: TObject);
begin

end;

{==============================================================================
  http istek baþlýk deðerinden istemcinin istediði sayfanýn adýný alýr
 ==============================================================================}
function TFTPSunucu.KomutDegeriniAl(ABellek: Isaretci; AVeriU: TSayi4): string;
var
  s: string;
  p: PChar;
begin

  Result := '';

  if(AVeriU = 0) then Exit;

  p := ABellek;
  s := '';

  while p^ <> #13 do
  begin

    s := s + p^;
    Inc(p);
  end;

  Result := s;
end;

end.

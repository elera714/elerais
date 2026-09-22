{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ftp.pas
  Dosya Ýþlevi: FTP (dosya) sunucu tutanak iþlevlerini yönetir

  Güncelleme Tarihi: 22/09/2026

 ==============================================================================}
{$mode objfpc}
unit ftp;

interface

uses paylasim, sunucular, tcp;

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
  TFTPSunucu = class(TSunucuServis)
  private
  public
    constructor Create;
    procedure OIstemciBaglandi(ATCP: TTCP); override;
    procedure OVeriGeldi(ATCP: TTCP); override;
    procedure OVeriGonderildi(ATCP: TTCP); override;
    function KomutDegeriniAl(ABellek: Isaretci; AVeriU: TSayi4): string;
  end;

var
  GFTPSunucu: TFTPSunucu;

implementation

uses sistemmesaj;

{==============================================================================
  ftp sunucusu ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TFTPSunucu.Create;
begin

end;

{==============================================================================
  istemci baðlandýðýnda tetiklenen olay
 ==============================================================================}
procedure TFTPSunucu.OIstemciBaglandi(ATCP: TTCP);
begin

  ATCP.VeriGonder(Tanitim, Length(Tanitim));
end;

{==============================================================================
  istemcilerden veri geldiðinde tetiklenen olay
 ==============================================================================}
procedure TFTPSunucu.OVeriGeldi(ATCP: TTCP);
var
  Veri: array[0..(4 * 4096) - 1] of Char;
  VeriU: TSayi4;
  s, Komut: string;
begin

  VeriU := 0;

  Veri := ATCP.GelenVeriyiAl(VeriU);

  s := KomutDegeriniAl(@Veri, VeriU);

  Komut := Copy(s, 1, 4);

  if(Komut = 'USER') then
  begin

    ATCP.VeriGonder(SifreGirisi, Length(SifreGirisi));
  end
  else if(Komut = 'PASS') then
  begin

    ATCP.VeriGonder(GirisBasarili, Length(GirisBasarili));
    //ATCP.VeriGonder(GirisHatali, Length(GirisHatali));
  end
  else if(Komut = 'QUIT') then
  begin

    ATCP.VeriGonder(BaglantiKapatiliyor, Length(BaglantiKapatiliyor));
  end;

  //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Gelen Veri: [%s]', [s]);
end;

{==============================================================================
  bu sunucu istemciye veri gönderdiðinde (ve onaylandýðýnda) tetiklenen olay
 ==============================================================================}
procedure TFTPSunucu.OVeriGonderildi(ATCP: TTCP);
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

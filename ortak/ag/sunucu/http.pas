{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: http.pas
  Dosya Ýþlevi: http sunucu tutanak iþlevlerini yönetir

  Güncelleme Tarihi: 22/09/2026

 ==============================================================================}
{$mode objfpc}
unit http;

interface

uses paylasim, sunucular, tcp;

const
  USTSINIR_HTTPISTEMCI = 10;

const
  WebSiteBaslik: PChar = 'HTTP/1.1 200 OK' + #13 + #10 +
    'Server: ELERA Web Sunucusu v1.0.6' + #13 + #10 +
    'Date: Mon, 01 Jun 2026 12:34:56 GMT' + #13 + #10 +
    { TODO - 332 deðeri WebSiteIcerik deðiþkenindeki karakter sayýsý olacak }
    'Content-Length: 332' + #13 + #10 +
    'Content-Type: text/html' + #13 + #10 +
    'Connection: close' + #13 + #10 + #13 + #10;

  WebSiteIcerik: PChar = '<!doctype html>' + #13 + #10 +
    '<html>' + #13 + #10 +
    '<head>' + #13 + #10 +
    '    <title>ELERA Web Sunucusu</title>' + #13 + #10 +
    '</head>' + #13 + #10 +
    '<body>' + #13 + #10 +
    '    <h1>ELERA Web Sunucusu</h1>' + #13 + #10 +
    '    <hr>' + #13 + #10 +
    '    <p>ELERA Web Sunucusu''na hoþ geldiniz.</p>' + #13 + #10 +
    '    <p>Sistem çalýþmalarýna eriþmek icin <a href="https://github.com/elera714">ELERA Ýþletim Sistemi</a> sayfasýný ziyaret ediniz.</p>' + #13 + #10 +
    '</body>' + #13 + #10 +
    '</html>';

  AnaSayfaHataBaslik: PChar = 'HTTP/1.1 404 Not Found' + #13 + #10 +
    'Server: ELERA Web Sunucusu v1.0' + #13 + #10 +
    'Date: Mon, 01 Jun 2026 12:34:56 GMT' + #13 + #10 +
    'Content-Length: 254' + #13 + #10 +
    'Connection: close' + #13 + #10 + #13 + #10;

  AnaSayfaHataIcerik: PChar = '<!doctype html>' + #13 + #10 +
    '<html>' + #13 + #10 +
    '<head>' + #13 + #10 +
    '  <title>ELERA Web Sunucusu - Hata [404]</title>' + #13 + #10 +
    '</head>' + #13 + #10 +
    '<body>' + #13 + #10 +
    '  <div align=''center''>' + #13 + #10 +
    '    <h1>Sayfa Mevcut Deðil [404]</h1>' + #13 + #10 +
    '    <hr>' + #13 + #10 +
    '    <p>Ýstenen ''x'' sayfasý sunucuda mevcut deðil!</p>' + #13 + #10 +
    '  </div>' + #13 + #10 +
    '</body>' + #13 + #10 +
    '</html>';

type
  THTTPSunucu = class(TSunucuServis)
  private
    FIstenenSayfa: string;
  public
    constructor Create;
    procedure OIstemciBaglandi(ATCP: TTCP); override;
    procedure OVeriGeldi(ATCP: TTCP); override;
    procedure OVeriGonderildi(ATCP: TTCP); override;
    function IstenenSayfaDegeriniAl(ABellek: Isaretci; AVeriU: TSayi4): string;
  end;

var
  GHTTPSunucu: THTTPSunucu;
  SayfaGonderildi: Boolean;

implementation

uses sistemmesaj;

{==============================================================================
  http sunucusu ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor THTTPSunucu.Create;
begin

  FIstenenSayfa := '';

  SayfaGonderildi := False;
end;

{==============================================================================
  istemci baðlandýðýnda tetiklenen olay
 ==============================================================================}
procedure THTTPSunucu.OIstemciBaglandi(ATCP: TTCP);
begin

end;

{==============================================================================
  istemcilerden veri geldiðinde tetiklenen olay
 ==============================================================================}
procedure THTTPSunucu.OVeriGeldi(ATCP: TTCP);
var
  Veri: array[0..(4 * 4096) - 1] of Char;
  VeriU: TSayi4;
begin

  VeriU := 0;

  Veri := ATCP.GelenVeriyiAl(VeriU);

  FIstenenSayfa := IstenenSayfaDegeriniAl(@Veri, VeriU);
  //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Sayfa: [%s]', [FIstenenSayfa]);

  if(FIstenenSayfa = '/') then
    ATCP.VeriGonder(WebSiteBaslik, Length(WebSiteBaslik))
  else ATCP.VeriGonder(AnaSayfaHataBaslik, Length(AnaSayfaHataBaslik));
end;

{==============================================================================
  bu sunucu istemciye veri gönderdiðinde (ve onaylandýðýnda) tetiklenen olay
 ==============================================================================}
procedure THTTPSunucu.OVeriGonderildi(ATCP: TTCP);
begin

  if(SayfaGonderildi) then
  begin

    ATCP.BaglantiyiKapat;

    SayfaGonderildi := False;
  end
  else
  begin

    if(FIstenenSayfa = '/') then
      ATCP.VeriGonder(WebSiteIcerik, Length(WebSiteIcerik))
    else ATCP.VeriGonder(AnaSayfaHataIcerik, Length(AnaSayfaHataIcerik));

    SayfaGonderildi := True;
  end;
end;

{==============================================================================
  http istek baþlýk deðerinden istemcinin istediði sayfanýn adýný alýr
 ==============================================================================}
function THTTPSunucu.IstenenSayfaDegeriniAl(ABellek: Isaretci; AVeriU: TSayi4): string;
var
  s, s2: string;
  i: TSayi4;
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

  i := Length(s);

  if(i > 0) then
  begin

    s2 := Copy(s, 1, 5);
    if(s2 = 'GET /') then
    begin

      s2 := '';
      p := @s[5];
      while p^ <> ' ' do
      begin

        s2 := s2 + p^;
        Inc(p);
      end;

      Exit(s2);
    end;
  end;

  Result := '/?';
end;

end.

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: srv_arp.pas
  Dosya Ýþlevi: dahili servis: arp tablo güncelliðini gerçekleþtirir

  Güncelleme Tarihi: 28/10/2026

 ==============================================================================}
{$mode objfpc}
unit srv_arp;

interface

uses thread;

type
  TServisARP = class(TThread)
  public
    constructor Create(AIslemAdi: string; CreateSuspended: Boolean = True); override;
    procedure Execute; override;
  end;

implementation

uses baglantilar;

{==============================================================================
  servis oluþturma kýsmý
 ==============================================================================}
constructor TServisARP.Create(AIslemAdi: string; CreateSuspended: Boolean = True);
begin

  inherited Create(AIslemAdi, CreateSuspended);
end;

{==============================================================================
  servis çalýþma kýsmý
 ==============================================================================}
procedure TServisARP.Execute;
begin

  repeat

    if not(GAgBaglantilari.AB.FARP = nil) then GAgBaglantilari.AB.FARP.ARPTablosunuGuncelle;

  until True = False;
end;

end.

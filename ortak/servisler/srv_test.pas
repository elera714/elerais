{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: srv_test.pas
  Dosya Ýþlevi: dahili servis: test amaçlý

  Güncelleme Tarihi: 31/10/2026

 ==============================================================================}
{$mode objfpc}
unit srv_test;

interface

uses thread, paylasim, zamanlayici;

type
  TPrgTest = class(TThread)
  public
    constructor Create(AIslemAdi: string; CreateSuspended: Boolean = True); override;
    procedure Execute; override;
  end;

implementation

uses sistemmesaj;

constructor TPrgTest.Create(AIslemAdi: string; CreateSuspended: Boolean = True);
begin

  inherited Create(AIslemAdi, CreateSuspended);
end;

procedure TPrgTest.Execute;
begin

  repeat

    GZamanlayicilar.BekleMS(1 * CALISMA_FREKANSI);

    SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'test servis kontrol...', []);

  until True = False;
end;

end.

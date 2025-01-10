{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms, gn_panel, gn_dugme,
  gn_karmaliste, gn_degerlistesi;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FUstPanel: TPanel;
    FKarmaListe: TKarmaListe;
    FYenile: TDugme;
    FDegerListesi: TDegerListesi;
    FZamanlayici: TZamanlayici;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Yazmaçlar';

var
  GorevKayit: TGorevKayit;
  TSS: TTSS;
  GorevNo: TISayi4;
  UstSinirGorevSayisi, CalisanGorevSayisi, i: TSayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  GorevNo := -1;

  FPencere.Olustur(-1, 0, 0, 220, 440, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FUstPanel.Olustur(FPencere.Kimlik, 0, 0, 100, 29, 0, 0, 0, 0, '');
  FUstPanel.Hizala(hzUst);
  FUstPanel.Goster;

  FKarmaListe.Olustur(FUstPanel.Kimlik, 2, 3, 140, 28);
  FKarmaListe.Goster;

  FYenile.Olustur(FUstPanel.Kimlik, 145, 2, 70, 24, 'Yenile');
  FYenile.Goster;

  FDegerListesi.Olustur(FPencere.Kimlik, 0, 0, 100, 100);
  FDegerListesi.Hizala(hzTum);
  FDegerListesi.BaslikBelirle('Yazmaç', 'Deðer', 100);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FDegerListesi.Goster;

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(200);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    if(GorevNo > -1) then
    begin

      FDegerListesi.Temizle;

      if(FGorev.GorevYazmacBilgisiAl(GorevNo, @TSS) >= 0) then
      begin

        FDegerListesi.DegerEkle('EIP|0x' + hexStr(TSS.EIP, 8));
        FDegerListesi.DegerEkle('EFLAGS|0x' + hexStr(TSS.EFLAGS, 8));
        FDegerListesi.DegerEkle('CR3|0x' + hexStr(TSS.CR3, 8));
        FDegerListesi.DegerEkle('CS|0x' + hexStr(TSS.CS, 8));
        FDegerListesi.DegerEkle('DS|0x' + hexStr(TSS.DS, 8));
        FDegerListesi.DegerEkle('ES|0x' + hexStr(TSS.ES, 8));
        FDegerListesi.DegerEkle('FS|0x' + hexStr(TSS.FS, 8));
        FDegerListesi.DegerEkle('GS|0x' + hexStr(TSS.GS, 8));
        FDegerListesi.DegerEkle('EAX|0x' + hexStr(TSS.EAX, 8));
        FDegerListesi.DegerEkle('EBX|0x' + hexStr(TSS.EBX, 8));
        FDegerListesi.DegerEkle('ECX|0x' + hexStr(TSS.ECX, 8));
        FDegerListesi.DegerEkle('EDX|0x' + hexStr(TSS.EDX, 8));
        FDegerListesi.DegerEkle('ESI|0x' + hexStr(TSS.ESI, 8));
        FDegerListesi.DegerEkle('EDI|0x' + hexStr(TSS.EDI, 8));
        FDegerListesi.DegerEkle('EBP|0x' + hexStr(TSS.EBP, 8));
        FDegerListesi.DegerEkle('SS|0x' + hexStr(TSS.SS, 8));
        FDegerListesi.DegerEkle('ESP|0x' + hexStr(TSS.ESP, 8));
        FDegerListesi.DegerEkle('SS0|0x' + hexStr(TSS.SS0, 8));
        FDegerListesi.DegerEkle('ESP0|0x' + hexStr(TSS.ESP0, 8));
        FDegerListesi.DegerEkle('SS1|0x' + hexStr(TSS.SS1, 8));
        FDegerListesi.DegerEkle('ESP1|0x' + hexStr(TSS.ESP1, 8));
        FDegerListesi.DegerEkle('SS2|0x' + hexStr(TSS.SS2, 8));
        FDegerListesi.DegerEkle('ESP2|0x' + hexStr(TSS.ESP2, 8));
        FDegerListesi.DegerEkle('LDT|0x' + hexStr(TSS.LDT, 8));
      end;
    end;
  end
  else if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = FYenile.Kimlik) then
  begin

    GorevNo := -1;

    FDegerListesi.Temizle;

    FKarmaListe.Temizle;

    UstSinirGorevSayisi := 0;
    CalisanGorevSayisi := 0;
    FGorev.GorevSayilariniAl(UstSinirGorevSayisi, CalisanGorevSayisi);

    if(CalisanGorevSayisi > 0) then
    begin

      for i := 1 to CalisanGorevSayisi do
      begin

        if(FGorev.GorevBilgisiAl(i, @GorevKayit) = 0) then
        begin

          FKarmaListe.ElemanEkle(GorevKayit.ProgramAdi);
        end;
      end;
    end;
  end
  else if(AOlay.Olay = CO_SECIMDEGISTI) and (AOlay.Kimlik = FKarmaListe.Kimlik) then
  begin

    GorevNo := FGorev.GorevKimligiAl(FKarmaListe.SeciliYaziAl);
  end;

  Result := 1;
end;

end.

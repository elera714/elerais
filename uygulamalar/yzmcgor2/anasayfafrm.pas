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
  OncekiTSS, TSS: TTSS;
  GorevNo: TISayi4;
  UstSinirGorevSayisi, CalisanGorevSayisi, i: TSayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  GorevNo := -1;

  FPencere.Olustur(-1, 10, 10, 220, 560, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
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

  FillByte(OncekiTSS, SizeOf(OncekiTSS), 0);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FDegerListesi.Goster;

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(200);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
var
  YaziRengi: TRenk;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    if(GorevNo > -1) then
    begin

      FDegerListesi.Temizle;

      if(FGorev.GorevYazmacBilgisiAl(GorevNo, @TSS) >= 0) then
      begin

        if(OncekiTSS.EFLAGS <> TSS.EFLAGS) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('EFLAGS|0x' + hexStr(TSS.EFLAGS, 8), YaziRengi);

        if(OncekiTSS.EIP <> TSS.EIP) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('EIP|0x' + hexStr(TSS.EIP, 8), YaziRengi);

        if(OncekiTSS.CS <> TSS.CS) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('CS|0x' + hexStr(TSS.CS, 8), YaziRengi);

        if(OncekiTSS.DS <> TSS.DS) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('DS|0x' + hexStr(TSS.DS, 8), YaziRengi);

        if(OncekiTSS.ES <> TSS.ES) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('ES|0x' + hexStr(TSS.ES, 8), YaziRengi);

        if(OncekiTSS.FS <> TSS.FS) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('FS|0x' + hexStr(TSS.FS, 8), YaziRengi);

        if(OncekiTSS.GS <> TSS.GS) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('GS|0x' + hexStr(TSS.GS, 8), YaziRengi);

        if(OncekiTSS.EAX <> TSS.EAX) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('EAX|0x' + hexStr(TSS.EAX, 8), YaziRengi);

        if(OncekiTSS.EBX <> TSS.EBX) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('EBX|0x' + hexStr(TSS.EBX, 8), YaziRengi);

        if(OncekiTSS.ECX <> TSS.ECX) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('ECX|0x' + hexStr(TSS.ECX, 8), YaziRengi);

        if(OncekiTSS.EDX <> TSS.EDX) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('EDX|0x' + hexStr(TSS.EDX, 8), YaziRengi);

        if(OncekiTSS.ESI <> TSS.ESI) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('ESI|0x' + hexStr(TSS.ESI, 8), YaziRengi);

        if(OncekiTSS.EDI <> TSS.EDI) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('EDI|0x' + hexStr(TSS.EDI, 8), YaziRengi);

        if(OncekiTSS.EBP <> TSS.EBP) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('EBP|0x' + hexStr(TSS.EBP, 8), YaziRengi);

        if(OncekiTSS.SS <> TSS.SS) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('SS|0x' + hexStr(TSS.SS, 8), YaziRengi);

        if(OncekiTSS.ESP <> TSS.ESP) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('ESP|0x' + hexStr(TSS.ESP, 8), YaziRengi);

        if(OncekiTSS.SS0 <> TSS.SS0) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('SS0|0x' + hexStr(TSS.SS0, 8), YaziRengi);

        if(OncekiTSS.ESP0 <> TSS.ESP0) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('ESP0|0x' + hexStr(TSS.ESP0, 8), YaziRengi);

        if(OncekiTSS.SS1 <> TSS.SS1) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('SS1|0x' + hexStr(TSS.SS1, 8), YaziRengi);

        if(OncekiTSS.ESP1 <> TSS.ESP1) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('ESP1|0x' + hexStr(TSS.ESP1, 8), YaziRengi);

        if(OncekiTSS.SS2 <> TSS.SS2) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('SS2|0x' + hexStr(TSS.SS2, 8), YaziRengi);

        if(OncekiTSS.ESP2 <> TSS.ESP2) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('ESP2|0x' + hexStr(TSS.ESP2, 8), YaziRengi);

        if(OncekiTSS.CR3 <> TSS.CR3) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('CR3|0x' + hexStr(TSS.CR3, 8), YaziRengi);

        if(OncekiTSS.LDT <> TSS.LDT) then
          YaziRengi := RENK_KIRMIZI
        else YaziRengi := RENK_SIYAH;
        FDegerListesi.DegerEkle('LDT|0x' + hexStr(TSS.LDT, 8), YaziRengi);

        OncekiTSS := TSS;
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

      for i := 0 to CalisanGorevSayisi - 1 do
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

program yzmcgor2;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: yzmcgor2.lpr
  Program Ýþlevi: programýn yazmaç içeriðini görüntüler

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}

uses n_gorev, gn_pencere, gn_panel, gn_dugme, gn_karmaliste, gn_degerlistesi, n_zamanlayici;

const
  ProgramAdi: string = 'Yazmaçlar';

var
  Gorev: TGorev;
  Pencere: TPencere;
  UstPanel: TPanel;
  KarmaListe: TKarmaListe;
  Yenile: TDugme;
  DegerListesi: TDegerListesi;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  GorevKayit: TGorevKayit;
  TSS: TTSS;
  GorevNo: TISayi4;
  UstSinirGorevSayisi, CalisanGorevSayisi, i: TSayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  GorevNo := -1;

  Pencere.Olustur(-1, 0, 0, 220, 440, ptBoyutlanabilir, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  UstPanel.Olustur(Pencere.Kimlik, 0, 0, 100, 29, 0, 0, 0, 0, '');
  UstPanel.Hizala(hzUst);
  UstPanel.Goster;

  KarmaListe.Olustur(UstPanel.Kimlik, 2, 3, 140, 28);
  KarmaListe.Goster;

  Yenile.Olustur(UstPanel.Kimlik, 145, 2, 70, 24, 'Yenile');
  Yenile.Goster;

  DegerListesi.Olustur(Pencere.Kimlik, 0, 0, 100, 100);
  DegerListesi.Hizala(hzTum);
  DegerListesi.BaslikBelirle('Yazmaç', 'Deðer', 100);
  DegerListesi.Goster;

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(200);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      if(GorevNo > -1) then
      begin

        DegerListesi.Temizle;

        if(Gorev.GorevYazmacBilgisiAl(GorevNo, @TSS) >= 0) then
        begin

          DegerListesi.DegerEkle('EIP|0x' + hexStr(TSS.EIP, 8));
          DegerListesi.DegerEkle('EFLAGS|0x' + hexStr(TSS.EFLAGS, 8));
          DegerListesi.DegerEkle('CR3|0x' + hexStr(TSS.CR3, 8));
          DegerListesi.DegerEkle('CS|0x' + hexStr(TSS.CS, 8));
          DegerListesi.DegerEkle('DS|0x' + hexStr(TSS.DS, 8));
          DegerListesi.DegerEkle('ES|0x' + hexStr(TSS.ES, 8));
          DegerListesi.DegerEkle('FS|0x' + hexStr(TSS.FS, 8));
          DegerListesi.DegerEkle('GS|0x' + hexStr(TSS.GS, 8));
          DegerListesi.DegerEkle('EAX|0x' + hexStr(TSS.EAX, 8));
          DegerListesi.DegerEkle('EBX|0x' + hexStr(TSS.EBX, 8));
          DegerListesi.DegerEkle('ECX|0x' + hexStr(TSS.ECX, 8));
          DegerListesi.DegerEkle('EDX|0x' + hexStr(TSS.EDX, 8));
          DegerListesi.DegerEkle('ESI|0x' + hexStr(TSS.ESI, 8));
          DegerListesi.DegerEkle('EDI|0x' + hexStr(TSS.EDI, 8));
          DegerListesi.DegerEkle('EBP|0x' + hexStr(TSS.EBP, 8));
          DegerListesi.DegerEkle('SS|0x' + hexStr(TSS.SS, 8));
          DegerListesi.DegerEkle('ESP|0x' + hexStr(TSS.ESP, 8));
          DegerListesi.DegerEkle('SS0|0x' + hexStr(TSS.SS0, 8));
          DegerListesi.DegerEkle('ESP0|0x' + hexStr(TSS.ESP0, 8));
          DegerListesi.DegerEkle('SS1|0x' + hexStr(TSS.SS1, 8));
          DegerListesi.DegerEkle('ESP1|0x' + hexStr(TSS.ESP1, 8));
          DegerListesi.DegerEkle('SS2|0x' + hexStr(TSS.SS2, 8));
          DegerListesi.DegerEkle('ESP2|0x' + hexStr(TSS.ESP2, 8));
          DegerListesi.DegerEkle('LDT|0x' + hexStr(TSS.LDT, 8));
        end;
      end;
    end
    else if(Olay.Olay = FO_TIKLAMA) and (Olay.Kimlik = Yenile.Kimlik) then
    begin

      GorevNo := -1;

      DegerListesi.Temizle;

      KarmaListe.Temizle;

      UstSinirGorevSayisi := 0;
      CalisanGorevSayisi := 0;
      Gorev.GorevSayilariniAl(UstSinirGorevSayisi, CalisanGorevSayisi);

      if(CalisanGorevSayisi > 0) then
      begin

        for i := 1 to CalisanGorevSayisi do
        begin

          if(Gorev.GorevBilgisiAl(i, @GorevKayit) = 0) then
          begin

            KarmaListe.ElemanEkle(GorevKayit.ProgramAdi);
          end;
        end;
      end;
    end
    else if(Olay.Olay = CO_SECIMDEGISTI) and (Olay.Kimlik = KarmaListe.Kimlik) then
    begin

      GorevNo := Gorev.GorevKimligiAl(KarmaListe.SeciliYaziAl);
    end
  end;
end.

program yzmcgor;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: yzmcgor.lpr
  Program Ýþlevi: programýn yazmaç içeriðini görüntüler

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, n_zamanlayici;

const
  ProgramAdi: string = 'Program Yazmaç Görüntüleyici';

  Baslik0: string = 'GRV     EAX      EBX      ECX      EDX      ESI      EDI      EBP      ESP';
  Baslik1: string = '----  -------- -------- -------- -------- -------- -------- -------- --------';

var
  Gorev: TGorev;
  Pencere: TPencere;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  TSS: TTSS;
  UstSinirGorevSayisi, CalisanGorevSayisi,
  i: TSayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 5, 55, 630, 300, ptBoyutlanabilir, ProgramAdi, $E6EAED);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      Pencere.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      Gorev.GorevSayilariniAl(UstSinirGorevSayisi, CalisanGorevSayisi);

      Pencere.Tuval.KalemRengi := RENK_SIYAH;
      Pencere.Tuval.YaziYaz(0, 0, Baslik0);
      Pencere.Tuval.YaziYaz(0, 1*16, Baslik1);

      for i := 1 to UstSinirGorevSayisi do
      begin

        if(Gorev.GorevYazmacBilgisiAl(i, @TSS) >= 0) then
        begin

          Pencere.Tuval.SayiYaz16(00 * 0, (1 + i) * 16, False, 4, i);
          Pencere.Tuval.SayiYaz16(06 * 8, (1 + i) * 16, False, 8, TSS.EAX);
          Pencere.Tuval.SayiYaz16(15 * 8, (1 + i) * 16, False, 8, TSS.EBX);
          Pencere.Tuval.SayiYaz16(24 * 8, (1 + i) * 16, False, 8, TSS.ECX);
          Pencere.Tuval.SayiYaz16(33 * 8, (1 + i) * 16, False, 8, TSS.EDX);
          Pencere.Tuval.SayiYaz16(42 * 8, (1 + i) * 16, False, 8, TSS.ESI);
          Pencere.Tuval.SayiYaz16(51 * 8, (1 + i) * 16, False, 8, TSS.EDI);
          Pencere.Tuval.SayiYaz16(60 * 8, (1 + i) * 16, False, 8, TSS.EBP);
          Pencere.Tuval.SayiYaz16(69 * 8, (1 + i) * 16, False, 8, TSS.ESP);
        end;
      end;
    end;
  end;
end.

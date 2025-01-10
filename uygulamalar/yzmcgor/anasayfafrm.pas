{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
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
  PencereAdi: string = 'Program Yazmaç Görüntüleyici';

  Baslik0: string = 'GRV     EAX      EBX      ECX      EDX      ESI      EDI      EBP      ESP';
  Baslik1: string = '----  -------- -------- -------- -------- -------- -------- -------- --------';

var
  TSS: TTSS;
  UstSinirGorevSayisi, CalisanGorevSayisi,
  i: TSayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 5, 55, 630, 300, ptBoyutlanabilir, PencereAdi, $E6EAED);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FGorev.GorevSayilariniAl(UstSinirGorevSayisi, CalisanGorevSayisi);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 0, Baslik0);
    FPencere.Tuval.YaziYaz(0, 1*16, Baslik1);

    for i := 1 to UstSinirGorevSayisi do
    begin

      if(FGorev.GorevYazmacBilgisiAl(i, @TSS) >= 0) then
      begin

        FPencere.Tuval.SayiYaz16(00 * 0, (1 + i) * 16, False, 4, i);
        FPencere.Tuval.SayiYaz16(06 * 8, (1 + i) * 16, False, 8, TSS.EAX);
        FPencere.Tuval.SayiYaz16(15 * 8, (1 + i) * 16, False, 8, TSS.EBX);
        FPencere.Tuval.SayiYaz16(24 * 8, (1 + i) * 16, False, 8, TSS.ECX);
        FPencere.Tuval.SayiYaz16(33 * 8, (1 + i) * 16, False, 8, TSS.EDX);
        FPencere.Tuval.SayiYaz16(42 * 8, (1 + i) * 16, False, 8, TSS.ESI);
        FPencere.Tuval.SayiYaz16(51 * 8, (1 + i) * 16, False, 8, TSS.EDI);
        FPencere.Tuval.SayiYaz16(60 * 8, (1 + i) * 16, False, 8, TSS.EBP);
        FPencere.Tuval.SayiYaz16(69 * 8, (1 + i) * 16, False, 8, TSS.ESP);
      end;
    end;
  end;

  Result := 1;
end;

end.

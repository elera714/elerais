unit thread;

{$mode objfpc}{$H+}

interface

uses gorev;

type

  { TThread }

  TThread = class
  private
    G: PGorev;
    procedure Calistir;
  public
    constructor Create(CreateSuspended: Boolean);
    procedure Start;
    procedure Execute; virtual; abstract;
  end;


implementation

uses sistemmesaj, paylasim, gdt, genel;

procedure TThread.Calistir;
begin

  repeat

    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Calistir:', []);
    //Execute;

  until True = False;
end;

constructor TThread.Create(CreateSuspended: Boolean);
var
  // yazmaçların girdi içerisindeki sıra numaraları
  SNYazmacCS, SNYazmacDS, SNYazmacTSS,
  i: TSayi4;
begin

  G := GGorevler.BosGorevBul;
  if not(G = nil) then
  begin

    i := G^.FGorevKimlik;

    // uygulamanın TSS, CS, DS seçicilerini belirle, her bir program 3 seçici içerir
    SNYazmacCS := (i * 3) + 1;
    SNYazmacDS := SNYazmacCS + 1;
    SNYazmacTSS := SNYazmacDS + 1;

    // kod seçicisi (CS)
    // Erişim  : 1 = mevcut, 00 = DPL0, 11 = kod yazmaç, 0 = dallanılamaz, 1 = okunabilir, 0 = erişilmedi
    // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
    GDTRGirdisiEkle(SNYazmacCS, 0, $FFFFFFFF, %10011010, %11011111);
    // veri seçicisi (DS)
    // Erişim  : 1 = mevcut, 00 = DPL0, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazılabilir, 0 = erişilmedi
    // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
    GDTRGirdisiEkle(SNYazmacDS, 0, $FFFFFFFF, %10010010, %11011111);
    // görev seçicisi (TSS)
    // Erişim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanılabilir TSS, 0 = meşgul biti (meşgul değil), 1
    // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
    GDTRGirdisiEkle(SNYazmacTSS, TSayi4(GorevTSSListesi[i]), 104,
      %10001001, %00010000);

    // denetçinin kullanacağı TSS'nin içeriğini sıfırla
    FillByte(GorevTSSListesi[i]^, 104, $00);

    GorevTSSListesi[i]^.EIP := TSayi4(@Calistir);    // DPL 0
    GorevTSSListesi[i]^.EFLAGS := $202;
    GorevTSSListesi[i]^.ESP := $3300000; // AYiginDegeri;
    GorevTSSListesi[i]^.CS := SNYazmacCS * 8;
    GorevTSSListesi[i]^.DS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.ES := SNYazmacDS * 8;
    GorevTSSListesi[i]^.SS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.FS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.GS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.SS0 := SNYazmacDS * 8;
    GorevTSSListesi[i]^.ESP0 := $3300000; // AYiginDegeri;

    // sistem görev değerlerini belirle
    GorevListesi[i]^.G0.FSeviyeNo := 0; // ASeviyeNo;
    GorevListesi[i]^.G0.FGorevSayaci := 0;
    GorevListesi[i]^.G0.FBellekBaslangicAdresi := TSayi4(@Calistir);
    GorevListesi[i]^.BellekUzunlugu := $FFFFFFFF;
    GorevListesi[i]^.FOlaySayisi := 0;
    GorevListesi[i]^.OlayBellekAdresi := nil;
    GorevListesi[i]^.AktifMasaustu := nil;
    GorevListesi[i]^.AktifPencere := nil;

    // sistem görev adı (dosya adı)
    GorevListesi[i]^.FDosyaAdi := 'cekirdek.bin';
    GorevListesi[i]^.FProgramAdi := 'AGorevAdi';

    // sistem görevini çalışıyor olarak işaretle
    G := GorevListesi[i];
    GGorevler.DurumDegistir(i, gdDurduruldu);

    // çalışan ve oluşturulan görev değerlerini belirle
    Inc(CalisanGorevSayisi);

    //Result := SNYazmacCS;

    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'thread: tamam', []);
  end;
end;

procedure TThread.Start;
var
  i: Integer;
begin

  //i := 1001;
  //SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'thread: %d', [i]);

{  repeat

    Execute;

  until True = False;}

  GGorevler.DurumDegistir(G^.FGorevKimlik, gdCalisiyor);
end;

end.


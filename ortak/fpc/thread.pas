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

  G := Gorevler0.BosGorevBul;
  if not(G = nil) then
  begin

    i := G^.Kimlik;

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
    G := GetMem(SizeOf(TGorev));
    Gorevler0.Gorev[i] := G;
    G^.SeviyeNo := 0; // ASeviyeNo;
    G^.GorevSayaci := 0;
    G^.BellekBaslangicAdresi := TSayi4(@Calistir);
    G^.BellekUzunlugu := $FFFFFFFF;
    G^.OlaySayisi := 0;
    G^.OlayBellekAdresi := nil;
    G^.AktifMasaustu := nil;
    G^.AktifPencere := nil;

    // sistem görev adı (dosya adı)
    G^.DosyaAdi := 'cekirdek.bin';
    G^.ProgramAdi := 'AGorevAdi';

    // sistem görevini çalışıyor olarak işaretle
    Gorevler0.DurumDegistir(i, gdDurduruldu);

    // çalışan ve oluşturulan görev değerlerini belirle
    Inc(FCalisanGorevSayisi);

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

  Gorevler0.DurumDegistir(G^.Kimlik, gdCalisiyor);
end;

end.


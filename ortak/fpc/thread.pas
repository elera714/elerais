{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: thread.pas
  Dosya İşlevi: çekirdek içerisinde ayrı olarak çalışarak işlem yapacak (process)
    iş birimini (thread) oluşturur

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
unit thread;

interface

uses gorev, paylasim;

type
  TThread = class
  private
    FYiginAdresi: Isaretci;
    FGorev: PGorev;
  public
    constructor Create(AIslemAdi: string; CreateSuspended: Boolean = True); virtual;
    procedure Start;
    procedure Execute; virtual; abstract;
    function Ozellestir(AGorevAdi: string; AIslev: TOIslev; AYiginDegeri: TSayi4;
      ASeviyeNo: TSayi4; ACalistir: Boolean = False): PGorev;
  end;

implementation

uses gdt;

const
  YIGIN_MIKTARI = 4096;

{==============================================================================
  çekirdek içerisinde kendi kaynaklarıyla çalışan, belli bir görevi yerine
    getiren işlev oluşturur - (thread)
 ==============================================================================}
constructor TThread.Create(AIslemAdi: string; CreateSuspended: Boolean = True);
begin

  // 4k miktarı yığın (stack) bellek ayır
  FYiginAdresi := GetMem(YIGIN_MIKTARI);

  // işlevi özelleştir
  FGorev := Ozellestir(AIslemAdi, @Execute, TSayi4(FYiginAdresi + (YIGIN_MIKTARI - 32)),
    CALISMA_SEVIYE0, CreateSuspended);
end;

{==============================================================================
  çalışma işlevini özelleştir
 ==============================================================================}
function TThread.Ozellestir(AGorevAdi: string; AIslev: TOIslev; AYiginDegeri: TSayi4;
  ASeviyeNo: TSayi4; ACalistir: Boolean = False): PGorev;
var
  G: PGorev;
  // yazmaçların girdi içerisindeki sıra numaraları
  SNYazmacCS, SNYazmacDS, SNYazmacTSS,
  i: TSayi4;
begin

  Result := nil;

  //while KritikBolgeyeGir(GorevKilit) = False do;

  G := GGorevler.BosGorevBul;
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
    GDTRGirdisiEkle(SNYazmacTSS, TSayi4(GorevTSSListesi[i]), 104, %10001001, %00010000);

    // denetçinin kullanacağı TSS'nin içeriğini sıfırla
    FillByte(GorevTSSListesi[i]^, 104, $00);

    GorevTSSListesi[i]^.EIP := TSayi4(AIslev);
    GorevTSSListesi[i]^.EFLAGS := $202;
    GorevTSSListesi[i]^.ESP := AYiginDegeri;
    GorevTSSListesi[i]^.CS := SNYazmacCS * 8;
    GorevTSSListesi[i]^.DS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.ES := SNYazmacDS * 8;
    GorevTSSListesi[i]^.SS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.FS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.GS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.SS0 := SNYazmacDS * 8;
    GorevTSSListesi[i]^.ESP0 := AYiginDegeri;

    // işlemin olay bellek bölgesini ata
    G^.OlayBellekAdresi := nil;

    // görev olay sayacını sıfırla
    G^.OlaySayisi := 0;

    // görev çalışma seviye numarası - öncelik derecesi
    G^.SeviyeNo := ASeviyeNo;

    // görev değişim sayacını sıfırla
    G^.GrvSayac := 0;

    // bellek başlangıç adresi
    G^.BellekBasAdr := TSayi4(@AIslev);

    // görev çalışma süreleri
    G^.CalismaSureMS := DPL0_SUREMS;
    G^.CalismaSureSayac := DPL0_SUREMS;

    // bellek miktarı
    G^.BellekUz := $FFFFFFFF;
    G^.YiginBellekUz := YIGIN_MIKTARI;

    // işlem başlangıç adresi
    G^.KodBasAdresi := TSayi4(@AIslev);

    // işlemin yığın adresi
    G^.YiginBasAdresi := TSayi4(FYiginAdresi);

    G^.AktifMasaustu := nil;
    G^.AktifPencere := nil;

    // işlemin adı
    G^.DosyaAdi := '*' + AGorevAdi;

    // program öndeğer adı
    G^.ProgramAdi := '*' + AGorevAdi;

    // görevin durumunu belirle
    if(ACalistir) then
      GGorevler.DurumDegistir(i, gdCalisiyor)
    else GGorevler.DurumDegistir(i, gdDurduruldu);

    // görev işlem sayısını bir artır
    Inc(GGorevler.FCalisanGorevSayisi);

    // görev bayrak değerini artır
    Inc(GGorevler.FGorevBayrakDegeri);

    Result := G;
  end;

  //KritikBolgedenCik(GorevKilit);
end;

procedure TThread.Start;
begin

  FGorev^.Durum := gdCalisiyor;
end;

end.

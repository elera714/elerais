{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: netbios.pas
  Dosya İşlevi: netbios api işlevlerini yönetir

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
unit netbios;

interface

uses udp, baglantilar, paylasim;

type
  PNetBiosServis = ^TNetBiosServis;
  TNetBiosServis = packed record
  	Tanimlayici,
    Bayrak,
    SorguSayisi,
    YanitSayisi,
    YetkiSayisi,
    DigerSayisi: TSayi2;
    Veriler: Isaretci;
  end;

type
  TNetBios = class
  public
    constructor Create;
    procedure SorgulariYanitla(AIPPaket: PIP4Paket; AUDPBaslik: PUDPPaket);
  end;

var
  GNetBios: TNetBios;

procedure EkleByte(AHedef: Isaretci; const ADeger: TSayi1);
procedure Ekle2Byte(AHedef: Isaretci; const ADeger: TSayi2);
procedure Ekle4Byte(AHedef: Isaretci; const ADeger: TSayi4);

implementation

uses sistemmesaj, donusum, islevler, ag;

constructor TNetBios.Create;
begin

end;

{==============================================================================
  netbios sorgularını yanıtlar
 ==============================================================================}
procedure TNetBios.SorgulariYanitla(AIPPaket: PIP4Paket; AUDPBaslik: PUDPPaket);
var
  NB, NB2: PNetBiosServis;
  Veri: array[0..511] of TSayi1;
  SorguSayisi, DigerSayisi,
  IstekTipi, IstekSinifi: TSayi2;
  NetBIOSAdi, s, IPAdresi: string;
  PB1: PByte;
  PB2: PSayi2;
  B1, B2, B3: TSayi1;
  B: TBaglanti;
  p: Isaretci;
  VeriSN, VeriUzunlukSN,
  VeriBaslangic: TSayi4;
begin

  NB := @AUDPBaslik^.Veri;

{  SISTEM_MESAJ(RENK_MOR, 'UDP: NetBios', []);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> IslemKimlik: ', ntohs(NB^.Tanimlayici), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> Bayrak: ', ntohs(NB^.Bayrak), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> SorguSayisi: ', ntohs(NB^.SorguSayisi), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> YanitSayisi: ', ntohs(NB^.YanitSayisi), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> YetkiSayisi: ', ntohs(NB^.YetkiSayisi), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> DigerSayisi: ', ntohs(NB^.DigerSayisi), 4); }

  // sorgu sayısı ve yanıt sayısı kontrolü
  SorguSayisi := ntohs(NB^.SorguSayisi);
  DigerSayisi := ntohs(NB^.DigerSayisi);

  // SADECE 1 adet sorguya sahip başlık değerlendirilecek
  if(SorguSayisi <> 1) then Exit;
  //if(DigerSayisi <> 1) then Exit;

  // sorgu ile gönderilen verilerin yerleştirileceği bellek alanının sıra numarası (index)
  VeriSN := 0;

  NetBIOSAdi := '';

  PB1 := @NB^.Veriler;

  Veri[VeriSN] := PSayi1(PB1)^; Inc(VeriSN);

  Inc(PB1);    // uzunluğu atla
  while PB1^ <> 0 do
  begin

    B1 := PB1^;
    Inc(PB1);
    B2 := PB1^;
    Inc(PB1);

    Veri[VeriSN] := B1; Inc(VeriSN);
    Veri[VeriSN] := B2; Inc(VeriSN);

    B3 := (B1 - Ord('A')) shl 4;
    B3 := (B2 - Ord('A')) or B3;

    NetBIOSAdi := NetBIOSAdi + Char(B3);
  end;
  NetBIOSAdi := Trim(NetBIOSAdi);

  // istek ad sıfır sonlandırma işareti
  Veri[VeriSN] := PSayi1(PB1)^; Inc(VeriSN);

  // sıfır sonlandırmayı atla
  Inc(PB1);

  // type ve sınıf değerini atla
  PB2 := PSayi2(PB1);
  IstekTipi := ntohs(PB2^);
  Inc(PB2);
  IstekSinifi := ntohs(PB2^);

  // yapıyı gönderilecek verilerle doldur ------------------------------------->

  if(NetBIOSAdi = '*') and (IstekTipi = $21) and (IstekSinifi = $01) then
  begin

    // IstekTipi = nbstat
    Ekle2Byte(@Veri[VeriSN], $0021); Inc(VeriSN, 2);

    // gönderilen yanıt = sınıf = IM
    Ekle2Byte(@Veri[VeriSN], $0001); Inc(VeriSN, 2);

    // TTL
    Ekle4Byte(@Veri[VeriSN], $00000000); Inc(VeriSN, 4);

    // veri uzunluğu
    // değer ataması tüm veriler atandıktan sonra aşağıda gerçekleşecektir
    VeriUzunlukSN := VeriSN;
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    VeriBaslangic := VeriSN;

    // yanıt olarak gönderilecek ad sayısı
    EkleByte(@Veri[VeriSN], $04); Inc(VeriSN);

    // aktif
    s := BuyutVeTamamla(GTamBilgisayarAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $0400); Inc(VeriSN, 2);

    // grup adı / aktif
    s := BuyutVeTamamla(GGrupAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $8400); Inc(VeriSN, 2);

    // aktif
    s := BuyutVeTamamla(GTamBilgisayarAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $20); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $0400); Inc(VeriSN, 2);

    // grup adı / aktif
    s := BuyutVeTamamla(GGrupAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $1E); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $8400); Inc(VeriSN, 2);

    // mac adresi
    Tasi2(@GAg.MACAdres, @Veri[VeriSN], 6); Inc(VeriSN, 6);
    // atlayıcı (jumpers)
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    // test sonucu
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    // sürüm numarası
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // istatistik aralığı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // crc sayısı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // hizalama hata sayısı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // çarpışan/uyumsuz sayısı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // gönderimi iptal edilenlerin sayısı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // güzel gönderilenlerin sayısı
    Ekle4Byte(@Veri[VeriSN], $00000000); Inc(VeriSN, 4);
    // güzel alınanların sayısı
    Ekle4Byte(@Veri[VeriSN], $00000000); Inc(VeriSN, 4);
    // yeniden iletim sayısı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // kaynak koşul sayısı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // komut blok sayısı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // bekleyen oturum saysı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // azami bekleyen oturum sayısı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // azami toplam oturum olasılığı
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // oturum veri paket uzunluğu
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);

    // fazladan 4 byte
    Ekle4Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 4);

    // veri uzunluğu
    Ekle2Byte(@Veri[VeriUzunlukSN], VeriSN - VeriBaslangic);

    //SISTEM_MESAJ(RENK_MOR, 'NetBios -> Gönderilen Veri U: %d', [VeriSN]);

    NB2 := GetMem(4096);

    NB2^.Tanimlayici := NB^.Tanimlayici;
    NB2^.Bayrak := htons(TSayi2($8400));
    NB2^.SorguSayisi := $0000;
    NB2^.YanitSayisi := htons(TSayi2($0001));
    NB2^.YetkiSayisi := $0000;
    NB2^.DigerSayisi := $0000;
    p := @NB2^.Veriler;
    Tasi2(@Veri[0], p, VeriSN);

    IPAdresi := IP_KarakterKatari4(AIPPaket^.KaynakIP);
    B := GBaglantilar.BaglantiOlustur(itIP4, btPasif, ptUDP, IPAdresi,
      ntohs(AUDPBaslik^.KaynakPort), ntohs(AUDPBaslik^.HedefPort));
    if not(B = nil) then
    begin

      if(B.Baglan(btYayin) <> -1) then
      begin

        B.Yaz(NB2, VeriSN + 12);

        B.BaglantiyiKes;
      end;
    end;

    FreeMem(NB2, 4096);

    SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'NetBios yanıtı gönderildi...', []);
  end
  else
  begin

    SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'Yanıtlanmayan NetBios isteği:', []);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, ' -> Sorgulanan Ad: %s', [NetBIOSAdi]);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, ' -> İstek Tipi: %d', [IstekTipi]);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, ' -> İstek Sınıfı: %d', [IstekSinifi]);
  end;
end;

// indy yardımcı işlev - veriye word değer ekleme (veriler big-endian biçiminde)
procedure EkleByte(AHedef: Isaretci; const ADeger: TSayi1);
begin

  PSayi1(AHedef)^ := ADeger;
end;

// indy yardımcı işlev - veriye word değer ekleme (veriler big-endian biçiminde)
procedure Ekle2Byte(AHedef: Isaretci; const ADeger: TSayi2);
begin

  EkleByte(AHedef + 0, Byte(ADeger shr 8));
  EkleByte(AHedef + 1, Byte(ADeger and $FF));
end;

// indy yardımcı işlev - veriye dword değer ekleme (veriler big-endian biçiminde)
procedure Ekle4Byte(AHedef: Isaretci; const ADeger: TSayi4);
begin

  EkleByte(AHedef + 0, Byte(ADeger shr 24));
  EkleByte(AHedef + 1, Byte(ADeger shr 16));
  EkleByte(AHedef + 2, Byte(ADeger shr 8));
  EkleByte(AHedef + 3, Byte(ADeger and $FF));
end;

end.

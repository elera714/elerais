{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: netbios.pas
  Dosya Ýþlevi: netbios api iþlevlerini yönetir

  Güncelleme Tarihi: 22/06/2026

 ==============================================================================}
{$mode objfpc}
unit netbios;

interface

uses udp, baglanti, paylasim;

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

procedure DNSSorgulariniYanitla(AIPPaket: PIP4Paket; AUDPBaslik: PUDPPaket);

implementation

uses sistemmesaj, donusum, genel, islevler;

{==============================================================================
  dns sorgularýný yanýtlar
 ==============================================================================}
procedure DNSSorgulariniYanitla(AIPPaket: PIP4Paket; AUDPBaslik: PUDPPaket);
var
  NB, NB2: PNetBiosServis;
  Veri: array[0..511] of TSayi1;
  SorguSayisi, DigerSayisi,
  IstekTipi, IstekSinifi: TSayi2;
  NetBIOSAdi, s, IPAdresi: string;
  PB1: PByte;
  PB2: PSayi2;
  B1, B2, B3: TSayi1;
  B: PBaglanti;
  p: Isaretci;
  VeriSN, VeriUzunlukSN,
  VeriBaslangic: TSayi4;
begin

  {$IFDEF UDP_BILGI}
  UDPBaslikBilgileriniGoruntule(AUDPBaslik);
  {$ENDIF}

  NB := @AUDPBaslik^.Veri;

{  SISTEM_MESAJ(RENK_MOR, 'UDP: NetBios', []);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> IslemKimlik: ', ntohs(NB^.Tanimlayici), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> Bayrak: ', ntohs(NB^.Bayrak), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> SorguSayisi: ', ntohs(NB^.SorguSayisi), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> YanitSayisi: ', ntohs(NB^.YanitSayisi), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> YetkiSayisi: ', ntohs(NB^.YetkiSayisi), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> DigerSayisi: ', ntohs(NB^.DigerSayisi), 4); }

  // sorgu sayýsý ve yanýt sayýsý kontrolü
  SorguSayisi := ntohs(NB^.SorguSayisi);
  DigerSayisi := ntohs(NB^.DigerSayisi);

  // SADECE 1 adet sorguya sahip baþlýk deðerlendirilecek
  if(SorguSayisi <> 1) then Exit;
  //if(DigerSayisi <> 1) then Exit;

  // sorgu ile gönderilen verilerin yerleþtirileceði bellek alanýnýn sýra numarasý (index)
  VeriSN := 0;

  NetBIOSAdi := '';

  PB1 := @NB^.Veriler;

  Veri[VeriSN] := PSayi1(PB1)^; Inc(VeriSN);

  Inc(PB1);    // uzunluðu atla
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

  // istek ad sýfýr sonlandýrma iþareti
  Veri[VeriSN] := PSayi1(PB1)^; Inc(VeriSN);

  // sýfýr sonlandýrmayý atla
  Inc(PB1);

  // type ve sýnýf deðerini atla
  PB2 := PSayi2(PB1);
  IstekTipi := ntohs(PB2^);
  Inc(PB2);
  IstekSinifi := ntohs(PB2^);

  // yapýyý gönderilecek verilerle doldur ------------------------------------->

  if(NetBIOSAdi = '*') and (IstekTipi = $21) and (IstekSinifi = $01) then
  begin

    // IstekTipi = nbstat
    Ekle2Byte(@Veri[VeriSN], $0021); Inc(VeriSN, 2);

    // gönderilen yanýt = sýnýf = IM
    Ekle2Byte(@Veri[VeriSN], $0001); Inc(VeriSN, 2);

    // TTL
    Ekle4Byte(@Veri[VeriSN], $00000000); Inc(VeriSN, 4);

    // veri uzunluðu
    // deðer atamasý tüm veriler atandýktan sonra aþaðýda gerçekleþecektir
    VeriUzunlukSN := VeriSN;
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    VeriBaslangic := VeriSN;

    // yanýt olarak gönderilecek ad sayýsý
    EkleByte(@Veri[VeriSN], $04); Inc(VeriSN);

    // aktif
    s := BuyutVeTamamla(GTamBilgisayarAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $0400); Inc(VeriSN, 2);

    // grup adý / aktif
    s := BuyutVeTamamla(GGrupAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $8400); Inc(VeriSN, 2);

    // aktif
    s := BuyutVeTamamla(GTamBilgisayarAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $20); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $0400); Inc(VeriSN, 2);

    // grup adý / aktif
    s := BuyutVeTamamla(GGrupAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $1E); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $8400); Inc(VeriSN, 2);

    // mac adresi
    Tasi2(@GAgBilgisi.MACAdres, @Veri[VeriSN], 6); Inc(VeriSN, 6);
    // atlayýcý (jumpers)
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    // test sonucu
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    // sürüm numarasý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // istatistik aralýðý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // crc sayýsý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // hizalama hata sayýsý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // çarpýþan/uyumsuz sayýsý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // gönderimi iptal edilenlerin sayýsý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // güzel gönderilenlerin sayýsý
    Ekle4Byte(@Veri[VeriSN], $00000000); Inc(VeriSN, 4);
    // güzel alýnanlarýn sayýsý
    Ekle4Byte(@Veri[VeriSN], $00000000); Inc(VeriSN, 4);
    // yeniden iletim sayýsý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // kaynak koþul sayýsý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // komut blok sayýsý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // bekleyen oturum saysý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // azami bekleyen oturum sayýsý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // azami toplam oturum olasýlýðý
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // oturum veri paket uzunluðu
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);

    // fazladan 4 byte
    Ekle4Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 4);

    // veri uzunluðu
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
    B := Baglantilar0.BaglantiOlustur(itIP4, btBelirsiz, ptUDP, IPAdresi, ntohs(AUDPBaslik^.KaynakPort),
      ntohs(AUDPBaslik^.HedefPort));
    if not(B = nil) then
    begin

      if(Baglantilar0.Baglan(itIP4, B^.Kimlik, btYayin) <> -1) then
      begin

        Baglantilar0.Yaz(PROTOKOL_IP4, B^.Kimlik, NB2, VeriSN + 12);

        Baglantilar0.BaglantiyiKes(B^.Kimlik);
      end;
    end;

    FreeMem(NB2, 4096);

    SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'NetBios yanýtý gönderildi...', []);
  end
  else
  begin

    SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'NetBios yanýtý gönderilmedi!', []);
    SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'NetBios Bilgileri................: ', []);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Sorgulanan Ad: %s', [NetBIOSAdi]);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Ýstek Tipi: %d', [IstekTipi]);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Ýstek Sýnýfý: %d', [IstekSinifi]);
  end;
end;

end.

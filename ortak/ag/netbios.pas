{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: netbios.pas
  Dosya ��levi: netbios api i�levlerini y�netir

  G�ncelleme Tarihi: 07/02/2025

 ==============================================================================}
{$mode objfpc}
unit netbios;

interface

uses udp, iletisim, paylasim;

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

procedure DNSSorgulariniYanitla(AIPPaket: PIPPaket; AUDPBaslik: PUDPPaket);

implementation

uses sistemmesaj, donusum, genel, islevler;

{==============================================================================
  dns sorgular�n� yan�tlar
 ==============================================================================}
procedure DNSSorgulariniYanitla(AIPPaket: PIPPaket; AUDPBaslik: PUDPPaket);
var
  NB, NB2: PNetBiosServis;
  Veri: array[0..511] of TSayi1;
  SorguSayisi, DigerSayisi,
  IstekTipi, IstekSinifi: TSayi2;
  NetBIOSAdi, s, IPAdresi: string;
  PB1: PByte;
  PB2: PSayi2;
  B1, B2, B3: TSayi1;
  Baglanti: PBaglanti;
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

  // sorgu say�s� ve yan�t say�s� kontrol�
  SorguSayisi := ntohs(NB^.SorguSayisi);
  DigerSayisi := ntohs(NB^.DigerSayisi);

  // SADECE 1 adet sorguya sahip ba�l�k de�erlendirilecek
  if(SorguSayisi <> 1) then Exit;
  //if(DigerSayisi <> 1) then Exit;

  // sorgu ile g�nderilen verilerin yerle�tirilece�i bellek alan�n�n s�ra numaras� (index)
  VeriSN := 0;

  NetBIOSAdi := '';

  PB1 := @NB^.Veriler;

  Veri[VeriSN] := PSayi1(PB1)^; Inc(VeriSN);

  Inc(PB1);    // uzunlu�u atla
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

  // istek ad s�f�r sonland�rma i�areti
  Veri[VeriSN] := PSayi1(PB1)^; Inc(VeriSN);

  // s�f�r sonland�rmay� atla
  Inc(PB1);

  // type ve s�n�f de�erini atla
  PB2 := PSayi2(PB1);
  IstekTipi := ntohs(PB2^);
  Inc(PB2);
  IstekSinifi := ntohs(PB2^);

  // yap�y� g�nderilecek verilerle doldur ------------------------------------->

  if(NetBIOSAdi = '*') and (IstekTipi = $21) and (IstekSinifi = $01) then
  begin

    // IstekTipi = nbstat
    Ekle2Byte(@Veri[VeriSN], $0021); Inc(VeriSN, 2);

    // g�nderilen yan�t = s�n�f = IM
    Ekle2Byte(@Veri[VeriSN], $0001); Inc(VeriSN, 2);

    // TTL
    Ekle4Byte(@Veri[VeriSN], $00000000); Inc(VeriSN, 4);

    // veri uzunlu�u
    // de�er atamas� t�m veriler atand�ktan sonra a�a��da ger�ekle�ecektir
    VeriUzunlukSN := VeriSN;
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    VeriBaslangic := VeriSN;

    // yan�t olarak g�nderilecek ad say�s�
    EkleByte(@Veri[VeriSN], $04); Inc(VeriSN);

    // aktif
    s := BuyutVeTamamla(GTamBilgisayarAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $0400); Inc(VeriSN, 2);

    // grup ad� / aktif
    s := BuyutVeTamamla(GGrupAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $8400); Inc(VeriSN, 2);

    // aktif
    s := BuyutVeTamamla(GTamBilgisayarAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $20); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $0400); Inc(VeriSN, 2);

    // grup ad� / aktif
    s := BuyutVeTamamla(GGrupAdi, 15);
    Tasi2(@s[1], @Veri[VeriSN], 15); Inc(VeriSN, 15);
    EkleByte(@Veri[VeriSN], $1E); Inc(VeriSN);
    Ekle2Byte(@Veri[VeriSN], $8400); Inc(VeriSN, 2);

    // mac adresi
    Tasi2(@GAgBilgisi.MACAdres, @Veri[VeriSN], 6); Inc(VeriSN, 6);
    // atlay�c� (jumpers)
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    // test sonucu
    EkleByte(@Veri[VeriSN], $00); Inc(VeriSN);
    // s�r�m numaras�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // istatistik aral���
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // crc say�s�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // hizalama hata say�s�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // �arp��an/uyumsuz say�s�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // g�nderimi iptal edilenlerin say�s�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // g�zel g�nderilenlerin say�s�
    Ekle4Byte(@Veri[VeriSN], $00000000); Inc(VeriSN, 4);
    // g�zel al�nanlar�n say�s�
    Ekle4Byte(@Veri[VeriSN], $00000000); Inc(VeriSN, 4);
    // yeniden iletim say�s�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // kaynak ko�ul say�s�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // komut blok say�s�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // bekleyen oturum says�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // azami bekleyen oturum say�s�
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // azami toplam oturum olas�l���
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);
    // oturum veri paket uzunlu�u
    Ekle2Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 2);

    // fazladan 4 byte
    Ekle4Byte(@Veri[VeriSN], $0000); Inc(VeriSN, 4);

    // veri uzunlu�u
    Ekle2Byte(@Veri[VeriUzunlukSN], VeriSN - VeriBaslangic);

    //SISTEM_MESAJ(RENK_MOR, 'NetBios -> G�nderilen Veri U: %d', [VeriSN]);

    NB2 := GGercekBellek.Ayir(4095);

    NB2^.Tanimlayici := NB^.Tanimlayici;
    NB2^.Bayrak := htons(TSayi2($8400));
    NB2^.SorguSayisi := $0000;
    NB2^.YanitSayisi := htons(TSayi2($0001));
    NB2^.YetkiSayisi := $0000;
    NB2^.DigerSayisi := $0000;
    p := @NB2^.Veriler;
    Tasi2(@Veri[0], p, VeriSN);

    IPAdresi := IP_KarakterKatari(AIPPaket^.KaynakIP);
    Baglanti := GBaglanti^.Olustur2(ptUDP, IPAdresi, ntohs(AUDPBaslik^.KaynakPort),
      ntohs(AUDPBaslik^.HedefPort));
    if not(Baglanti = nil) then
    begin

      if(Baglanti^.Baglan(btYayin) <> -1) then
      begin

        Baglanti^.Yaz(NB2, VeriSN + 12);

        Baglanti^.BaglantiyiKes;
      end;
    end;

    GGercekBellek.YokEt(NB2, 4095);

    SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'NetBios yan�t� g�nderildi...', []);
  end
  else
  begin

    SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'NetBios yan�t� g�nderilmedi!', []);
    SISTEM_MESAJ(mtUyari, RENK_MAVI, 'NetBios Bilgileri: ', []);
    SISTEM_MESAJ(mtUyari, RENK_SIYAH, '-> Sorgulanan Ad: %s', [NetBIOSAdi]);
    SISTEM_MESAJ(mtUyari, RENK_SIYAH, '-> �stek Tipi: %d', [IstekTipi]);
    SISTEM_MESAJ(mtUyari, RENK_SIYAH, '-> �stek S�n�f�: %d', [IstekSinifi]);
  end;
end;

end.

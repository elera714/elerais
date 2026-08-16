{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_baglantilar.pas
  Dosya İşlevi: ağ bağlantı (socket) yönetim işlevlerini içerir

  Güncelleme Tarihi: 15/08/2026

 ==============================================================================}
{$mode objfpc}
unit k_baglantilar;

interface

uses paylasim;

function AgBaglantiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses baglantilar, dns, gorev;

{==============================================================================
  ağ bağlantı (soket) yönetim işlevlerini içerir
 ==============================================================================}
function AgBaglantiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  B: TBaglanti;
  ProtokolTipi: TProtokolTipi;
  BaglantiKimlik: TKimlik;
  AnaIslevNo, AltIslevNo,
  i, j: TSayi4;
  YerelPort, HedefPort: TSayi2;
  s: string;
begin

  Result := HATA_ISLEV;

  AnaIslevNo := (AIslevNo and $FF);
  AltIslevNo := ((AIslevNo shr 8) and $FFFF);

  // tcp / udp ham bağlantı işlevleri
  if(AnaIslevNo = 1) then
  begin

    // yeni bağlantı oluştur
    if(AltIslevNo = 1) then
    begin

      ProtokolTipi := PProtokolTipi(ADegiskenler + 00)^;
      s := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^;
      HedefPort := PSayi4(ADegiskenler + 08)^;

      //SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'IP Adresi: %s', [s]);

      { TODO - udp yerel port ve uzak port eşitlenerek porta gelen verilerin alınması sağlanmakta.
        geçicidir, sunucu / istemci yapısı kurulduğunda bu yapının olması gerektiği gibi
        yapılanması gerekmektedir }
      if(ProtokolTipi = ptTCP) then
        YerelPort := GBaglantilar.YerelPortAl
      else YerelPort := HedefPort;

      { TODO - ip v6'ya göre düzenlenecek }
      if(ProtokolTipi = ptTCP) then
        B := GBaglantilar.BaglantiOlustur(itIP4, btAktif, ProtokolTipi, s, YerelPort, HedefPort)
      else B := GBaglantilar.BaglantiOlustur(itIP4, btAktif, ProtokolTipi, s, YerelPort, HedefPort);

      if not(B = nil) then

        Result := B.Kimlik
      else Result := HATA_KIMLIK
    end

    // mevcut bağlantı ile hedef porta bağlan
    else if(AltIslevNo = 2) then
    begin

      BaglantiKimlik := PISayi4(ADegiskenler + 00)^;

      B := GBaglantilar.Baglanti[BaglantiKimlik];
      if not(B = nil) then

        Result := B.Baglan(btIP)
      else Result := -1;
    end

    // bağlantının varlığını kontrol et
    else if(AltIslevNo = 3) then
    begin

      BaglantiKimlik := PISayi4(ADegiskenler + 00)^;

      B := GBaglantilar.Baglanti[BaglantiKimlik];
      if not(B = nil) then

        Result := TSayi4(B.BagliMi)
      else Result := TSayi4(False);
    end

    // porta gelen veri uzunluğunu al
    else if(AltIslevNo = 4) then
    begin

      BaglantiKimlik := PISayi4(ADegiskenler + 00)^;

      B := GBaglantilar.Baglanti[BaglantiKimlik];
      if not(B = nil) then

        Result := B.VeriUzunlugu
      else Result := 0;
    end

    // bağlantıya gelen veriyi oku
    else if(AltIslevNo = 5) then
    begin

      BaglantiKimlik := PISayi4(ADegiskenler + 00)^;
      i := PSayi4(ADegiskenler + 04)^;

      B := GBaglantilar.Baglanti[BaglantiKimlik];
      if not(B = nil) then

        Result := B.Oku(Isaretci(i + GGorevler.FAktifGrvBelAdr))
      else Result := 0;
    end

    // bağlantıya veri gönder
    else if(AltIslevNo = 6) then
    begin

      BaglantiKimlik := PISayi4(ADegiskenler + 00)^;
      i := PSayi4(ADegiskenler + 04)^;
      j := PSayi4(ADegiskenler + 08)^;

      B := GBaglantilar.Baglanti[BaglantiKimlik];
      if not(B = nil) then B.Yaz(Isaretci(i + GGorevler.FAktifGrvBelAdr), j);
    end

    // bağlantıyı kapat
    else if(AltIslevNo = 7) then
    begin

      { TODO : kaynakların yok edilmesi test edilecek }
      BaglantiKimlik := PISayi4(ADegiskenler + 00)^;

      B := GBaglantilar.Baglanti[BaglantiKimlik];
      if not(B = nil) then

        Result := B.BaglantiyiKes
      else Result := -1;
    end;
  end

  // dns bağlantı işlevleri
  else if(AnaIslevNo = 2) then
  begin

    Result := DNSIletisimCagriIslevleri(AltIslevNo, ADegiskenler);
  end;
end;

end.

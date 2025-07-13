{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_baglanti.pas
  Dosya İşlevi: ağ bağlantı (socket) yönetim işlevlerini içerir

  Güncelleme Tarihi: 13/07/2025

 ==============================================================================}
{$mode objfpc}
unit k_baglanti;

interface

uses paylasim;

function AgBaglantiCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;

implementation

uses baglanti, genel, dns, gorev;

{==============================================================================
  ağ bağlantı (soket) yönetim işlevlerini içerir
 ==============================================================================}
function AgBaglantiCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  B: PBaglanti;
  ProtokolTipi: TProtokolTipi;
  BaglantiKimlik: TKimlik;
  AnaIslev, i, j, AltIslev: TSayi4;
  YerelPort, HedefPort: TSayi2;
  s: string;
begin

  AnaIslev := (IslevNo and $FF);
  AltIslev := ((IslevNo shr 8) and $FFFF);

  // tcp / udp ham bağlantı işlevleri
  if(AnaIslev = 1) then
  begin

    // yeni bağlantı oluştur
    if(AltIslev = 1) then
    begin

      ProtokolTipi := PProtokolTipi(Degiskenler + 00)^;
      s := PKarakterKatari(PSayi4(Degiskenler + 04)^ + FAktifGorevBellekAdresi)^;
      HedefPort := PSayi4(Degiskenler + 08)^;

      //SISTEM_MESAJ(RENK_KIRMIZI, 'IP Adresi: %s', [s]);
      //SISTEM_MESAJ_IP(RENK_KIRMIZI, 'IP Adresi: ', IPAdres);

      { TODO - udp yerel port ve uzak port eşitlenerek porta gelen verilerin alınması sağlanmakta.
        geçicidir, sunucu / istemci yapısı kurulduğunda bu yapının olması gerektiği gibi
        yapılanması gerekmektedir }
      if(ProtokolTipi = ptTCP) then
        YerelPort := Baglantilar0.YerelPortAl
      else YerelPort := HedefPort;

      B := Baglantilar0.BaglantiOlustur(ProtokolTipi, s, YerelPort, HedefPort);
      if not(B = nil) then

        Result := B^.Kimlik
      else Result := HATA_KIMLIK
    end
    // mevcut bağlantı ile hedef porta bağlan
    else if(AltIslev = 2) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      B := Baglantilar0.Baglanti[BaglantiKimlik];
      if not(B = nil) then
        Result := Baglantilar0.Baglan(B^.Kimlik, btIP)
      else Result := -1;
    end
    // bağlantının varlığını kontrol et
    else if(AltIslev = 3) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      B := Baglantilar0.Baglanti[BaglantiKimlik];
      if not(B = nil) then
        Result := TSayi4(Baglantilar0.BagliMi(B^.Kimlik))
      else Result := TSayi4(False);
    end
    // porta gelen veri uzunluğunu al
    else if(AltIslev = 4) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      B := Baglantilar0.Baglanti[BaglantiKimlik];
      if not(B = nil) then
        Result := Baglantilar0.VeriUzunlugu(B^.Kimlik)
      else Result := 0;
    end
    // bağlantıya gelen veriyi oku
    else if(AltIslev = 5) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      i := PSayi4(Degiskenler + 04)^;

      B := Baglantilar0.Baglanti[BaglantiKimlik];
      if not(B = nil) then
        Result := Baglantilar0.Oku(B^.Kimlik, Isaretci(i + FAktifGorevBellekAdresi))
      else Result := 0;
    end
    // bağlantıya veri gönder
    else if(AltIslev = 6) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      i := PSayi4(Degiskenler + 04)^;
      j := PSayi4(Degiskenler + 08)^;

      B := Baglantilar0.Baglanti[BaglantiKimlik];
      if not(B = nil) then
        Baglantilar0.Yaz(B^.Kimlik, Isaretci(i + FAktifGorevBellekAdresi), j);
    end
    // bağlantıyı kapat
    else if(AltIslev = 7) then
    begin

      { TODO : kaynakların yok edilmesi test edilecek }
      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      B := Baglantilar0.Baglanti[BaglantiKimlik];
      if not(B = nil) then
        Result := Baglantilar0.BaglantiyiKes(B^.Kimlik)
      else Result := -1;
    end

    else Result := HATA_ISLEV;
  end
  // dns bağlantı işlevleri
  else if(AnaIslev = 2) then
  begin

    Result := DNSIletisimCagriIslevleri(AltIslev, Degiskenler);
  end

  else Result := HATA_ISLEV;
end;

end.

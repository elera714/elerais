{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_iletisim.pas
  Dosya İşlevi: ağ bağlantı (socket) yönetim işlevlerini içerir

  Güncelleme Tarihi: 25/01/2025

 ==============================================================================}
{$mode objfpc}
unit k_iletisim;

interface

uses paylasim;

function AgIletisimCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;

implementation

uses iletisim, genel, donusum, dns, sistemmesaj;

{==============================================================================
  ağ iletişim (soket) yönetim işlevlerini içerir
 ==============================================================================}
function AgIletisimCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  Bag: PBaglanti;
  ProtokolTipi: TProtokolTipi;
  IPAdres: TIPAdres;
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
      s := PKarakterKatari(PSayi4(Degiskenler + 04)^ + CalisanGorevBellekAdresi)^;
      HedefPort := PSayi4(Degiskenler + 08)^;

      //SISTEM_MESAJ(RENK_KIRMIZI, 'IP Adresi: %s', [s]);
      //SISTEM_MESAJ_IP(RENK_KIRMIZI, 'IP Adresi: ', IPAdres);

      { TODO - udp yerel port ve uzak port eşitlenerek porta gelen verilerin alınması sağlanmakta.
        geçicidir, sunucu / istemci yapısı kurulduğunda bu yapının olması gerektiği gibi
        yapılanması gerekmektedir }
      if(ProtokolTipi = ptTCP) then
        YerelPort := YerelPortAl
      else YerelPort := HedefPort;

      Bag := Bag^.Olustur2(ProtokolTipi, s, YerelPort, HedefPort);
      if not(Bag = nil) then

        Result := Bag^.FKimlik
      else Result := HATA_KIMLIK
    end
    // mevcut bağlantı ile hedef porta bağlan
    else if(AltIslev = 2) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      Bag := GAgIletisimListesi[BaglantiKimlik];
      Result := Bag^.Baglan(btIP);
    end
    // bağlantının varlığını kontrol et
    else if(AltIslev = 3) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      Bag := GAgIletisimListesi[BaglantiKimlik];
      Result := TISayi4(Bag^.BagliMi);
    end
    // porta gelen veri uzunluğunu al
    else if(AltIslev = 4) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      Bag := GAgIletisimListesi[BaglantiKimlik];
      Result := Bag^.VeriUzunlugu;
    end
    // bağlantıya gelen veriyi oku
    else if(AltIslev = 5) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      i := PSayi4(Degiskenler + 04)^;

      Bag := GAgIletisimListesi[BaglantiKimlik];
      Result := Bag^.Oku(Isaretci(i + CalisanGorevBellekAdresi));
    end
    // bağlantıya veri gönder
    else if(AltIslev = 6) then
    begin

      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      i := PSayi4(Degiskenler + 04)^;
      j := PSayi4(Degiskenler + 08)^;

      Bag := GAgIletisimListesi[BaglantiKimlik];
      Bag^.Yaz(Isaretci(i + CalisanGorevBellekAdresi), j);
    end
    // bağlantıyı kapat
    else if(AltIslev = 7) then
    begin

      { TODO : kaynakların yok edilmesi test edilecek }
      BaglantiKimlik := PISayi4(Degiskenler + 00)^;
      Bag := GAgIletisimListesi[BaglantiKimlik];
      Result := Bag^.BaglantiyiKes;
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

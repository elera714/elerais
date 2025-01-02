{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_iletisim.pas
  Dosya İşlevi: ağ bağlantı (socket) yönetim işlevlerini içerir

  Güncelleme Tarihi: 02/01/2025

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
  Baglanti: PBaglanti;
  ProtokolTipi: TProtokolTipi;
  IPAdres: TIPAdres;
  s: string;
  AnaIslev, i, j, AltIslev: TSayi4;
  YerelPort, HedefPort: TSayi2;
  BaglantiKimlik: TKimlik;
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

      IPAdres := StrToIP(s);

      { TODO - udp yerel port ve uzak port eşitlenerek porta gelen verilerin alınması sağlanmakta.
        geçicidir, sunucu / istemci yapısı kurulduğunda bu yapının olması gerektiği bigi
        yapılanması gerekmektedir }
      if(ProtokolTipi = ptTCP) then
        YerelPort := YerelPortAl
      else YerelPort := HedefPort;

      Baglanti := Baglanti^.Olustur(ProtokolTipi, IPAdres, YerelPort, HedefPort);
      if not(Baglanti = nil) then

        Result := Baglanti^.FKimlik
      else Result := HATA_KIMLIK
    end
    // mevcut bağlantı ile hedef porta bağlan
    else if(AltIslev = 2) then
    begin

      BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      Baglanti := GAgIletisimListesi[BaglantiKimlik];
      Result := Baglanti^.Baglan(btIP);
    end
    // bağlantının varlığını kontrol et
    else if(AltIslev = 3) then
    begin

      BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      Baglanti := GAgIletisimListesi[BaglantiKimlik];
      Result := TISayi4(Baglanti^.BagliMi);
    end
    // porta gelen veri uzunluğunu al
    else if(AltIslev = 4) then
    begin

      BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      Baglanti := GAgIletisimListesi[BaglantiKimlik];
      Result := Baglanti^.VeriUzunlugu;
    end
    // bağlantıya gelen veriyi al
    else if(AltIslev = 5) then
    begin

      BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      i := PSayi4(Degiskenler + 04)^;

      Baglanti := GAgIletisimListesi[BaglantiKimlik];
      Result := Baglanti^.Oku(Isaretci(i + CalisanGorevBellekAdresi));
    end
    // bağlantıya veri gönder
    else if(AltIslev = 6) then
    begin

      BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      i := PSayi4(Degiskenler + 04)^;
      j := PSayi4(Degiskenler + 08)^;

      Baglanti := GAgIletisimListesi[BaglantiKimlik];
      Baglanti^.Yaz(Isaretci(i + CalisanGorevBellekAdresi), j);
    end
    // bağlantıyı kapat
    else if(AltIslev = 7) then
    begin

      { TODO : kaynakların yok edilmesi test edilecek }
      BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      Baglanti := GAgIletisimListesi[BaglantiKimlik];
      Result := Baglanti^.BaglantiyiKes;
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

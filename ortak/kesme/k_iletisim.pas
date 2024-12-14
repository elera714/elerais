{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_iletisim.pas
  Dosya İşlevi: ağ bağlantı (socket) yönetim işlevlerini içerir

  Güncelleme Tarihi: 18/04/2020

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
  _Baglanti: PBaglanti;
  _ProtokolTip: TProtokolTip;
  _IPAdres2: TIPAdres;
  _IPAdres: string;
  _AnaIslev, _YerelPort,
  _HedefPort, i, j, _AltIslev: TSayi4;
  _BaglantiKimlik: TKimlik;
begin

  _AnaIslev := (IslevNo and $FF);
  _AltIslev := ((IslevNo shr 8) and $FFFF);

  // tcp / udp ham bağlantı işlevleri
  if(_AnaIslev = 1) then
  begin

    // bağlantı oluştur ve hedef porta bağlan
    if(_AltIslev = 1) then
    begin

      _ProtokolTip := PProtokolTip(Degiskenler + 00)^;
      _IPAdres := PKarakterKatari(PSayi4(Degiskenler + 04)^ + CalisanGorevBellekAdresi)^;
      _HedefPort := PSayi4(Degiskenler + 08)^;

      _IPAdres2 := StrToIP(_IPAdres);

      // udp iletişiminde yerelport = hedefport
      if(_ProtokolTip = ptTCP) then
        _YerelPort := YerelPortAl
      else _YerelPort := _HedefPort;

      _Baglanti := _Baglanti^.Olustur(_ProtokolTip, _IPAdres2, Lo(_YerelPort), Lo(_HedefPort));
      if not(_Baglanti = nil) then

        Result := _Baglanti^.Baglan(btIP)
      else Result := HATA_KIMLIK
    end
    // bağlantının varlığını kontrol et
    else if(_AltIslev = 2) then
    begin

      _BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      _Baglanti := AgIletisimListesi[_BaglantiKimlik];
      Result := TISayi4(_Baglanti^.BagliMi);
    end
    // porta gelen veri uzunluğunu al
    else if(_AltIslev = 3) then
    begin

      _BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      _Baglanti := AgIletisimListesi[_BaglantiKimlik];
      Result := _Baglanti^.VeriUzunlugu;
    end
    // bağlantıya gelen veriyi al
    else if(_AltIslev = 4) then
    begin

      _BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      i := PSayi4(Degiskenler + 04)^;

      _Baglanti := AgIletisimListesi[_BaglantiKimlik];
      Result := _Baglanti^.Oku(Isaretci(i + CalisanGorevBellekAdresi));
    end
    // bağlantıya veri gönder
    else if(_AltIslev = 5) then
    begin

      _BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      i := PSayi4(Degiskenler + 04)^;
      j := PSayi4(Degiskenler + 08)^;

      _Baglanti := AgIletisimListesi[_BaglantiKimlik];
      _Baglanti^.Yaz(Isaretci(i + CalisanGorevBellekAdresi), j);
    end
    // bağlantıyı kapat
    else if(_AltIslev = 6) then
    begin

      { TODO : kaynakların yok edilmesi test edilecek }
      _BaglantiKimlik := PSayi4(Degiskenler + 00)^;
      _Baglanti := AgIletisimListesi[_BaglantiKimlik];
      Result := _Baglanti^.BaglantiyiKes;
    end

    else Result := HATA_ISLEV;
  end
  // dns bağlantı işlevleri
  else if(_AnaIslev = 2) then
  begin

    Result := DNSIletisimCagriIslevleri(_AltIslev, Degiskenler);
  end

  else Result := HATA_ISLEV;
end;

end.

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_baglantilar.pas
  Dosya İşlevi: ağ bağlantı (socket) yönetim işlevlerini içerir

  Güncelleme Tarihi: 12/11/2026

 ==============================================================================}
{$mode objfpc}
unit k_baglantilar;

interface

uses paylasim;

function AgBaglantiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses baglantilar, dnsi, gorev, donusum;

{==============================================================================
  ağ bağlantı yönetim işlevlerini içerir
 ==============================================================================}
function AgBaglantiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  B: TBaglanti;
  TT: TTutanakTipi;
  HedefIPAdres: TIP4Adres;
  BagKimlik: TKimlik;
  AnaIslevNo, AltIslevNo,
  i, j: TSayi4;
  YerelPort, HedefPort: TSayi2;
  s: string;
begin

  Result := HATA_ISLEV;

  AnaIslevNo := (AIslevNo and $FF);
  AltIslevNo := ((AIslevNo shr 8) and $FFFF);

  // tcp / udp ham bağlantı işlevleri
  { TODO - tüm işlevler ipv6'ya göre kontrol edilecek }
  if(AnaIslevNo = 1) then
  begin

    // yeni bağlantı oluştur
    if(AltIslevNo = 1) then
    begin

      TT := PTutanakTipi(ADegiskenler + 00)^;
      s := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^;
      HedefIPAdres := StrToIP4(s);
      HedefPort := PSayi4(ADegiskenler + 08)^;
      YerelPort := GAgBaglantilari.AB.YerelPortOlustur;

      {if(AIletisimTipi = itIP6) then
      begin
        IP6Adr := StrToIP6(s);
        //B.HedefIP6Adres := IP6Adr;
      end
      else
      begin

        IP4Adr := StrToIP4(s);
        //B.HedefIP4Adres := IP4Adr;
      end;}

      //SISTEM_MESAJ_IP4(mtBilgi, RENK_PEMBE, 'IP Adresi: ', HedefIPAdres);

      if(TT = ttTCP) then
      begin

        B := GAgBaglantilari.AB.BaglantiOlustur(bnTCP, itIP4, btYAktif,
          TT, YerelPort, HedefPort);

        B.FTCP.FIP4.FKaynakIPAdres := GAgBaglantilari.AB.IP4Adresim;
        B.FTCP.FIP4.FHedefIPAdres := HedefIPAdres;
      end
      else
      begin

        B := GAgBaglantilari.AB.BaglantiOlustur(bnUDP, itIP4, btYAktif,
          TT, YerelPort, HedefPort);

        B.FUDP.FIP4.FKaynakIPAdres := GAgBaglantilari.AB.IP4Adresim;
        B.FUDP.FIP4.FHedefIPAdres := HedefIPAdres;
      end;

      if not(B = nil) then
        Result := B.FKimlik
      else Result := HATA_KIMLIK;
    end

    // mevcut bağlantı ile hedef porta bağlan
    else if(AltIslevNo = 2) then
    begin

      BagKimlik := PISayi4(ADegiskenler + 00)^;

      B := GAgBaglantilari.AB.Baglanti[BagKimlik];
      if not(B = nil) then B.Baglan;

      // bu işlevden dönen değer önemsizdir
      // bağlantının gerçekleşip gerçekleşmediği AltIslevNo = 3 ile kontrol edilmelidir
      Result := HATA_YOK;
    end

    // bağlantının varlığını kontrol et
    else if(AltIslevNo = 3) then
    begin

      BagKimlik := PISayi4(ADegiskenler + 00)^;

      B := GAgBaglantilari.AB.Baglanti[BagKimlik];
      if not(B = nil) then
        Result := TSayi4(B.BagliMi)
      else Result := TSayi4(False);
    end

    // porta gelen veri uzunluğunu al
    else if(AltIslevNo = 4) then
    begin

      BagKimlik := PISayi4(ADegiskenler + 00)^;

      B := GAgBaglantilari.AB.Baglanti[BagKimlik];
      if not(B = nil) then
        Result := B.VeriUzunlugunuAl
      else Result := 0;
    end

    // bağlantıya gelen veriyi oku
    else if(AltIslevNo = 5) then
    begin

      BagKimlik := PISayi4(ADegiskenler + 00)^;
      i := PSayi4(ADegiskenler + 04)^;

      B := GAgBaglantilari.AB.Baglanti[BagKimlik];
      if not(B = nil) then
        Result := B.Oku(Isaretci(i + GGorevler.FAktifGrvBelAdr))
      else Result := 0;
    end

    // bağlantı üzerinden veri gönder
    else if(AltIslevNo = 6) then
    begin

      BagKimlik := PISayi4(ADegiskenler + 00)^;
      i := PSayi4(ADegiskenler + 04)^;
      j := PSayi4(ADegiskenler + 08)^;

      B := GAgBaglantilari.AB.Baglanti[BagKimlik];
      if not(B = nil) then
        B.Yaz(Isaretci(i + GGorevler.FAktifGrvBelAdr), j);
    end

    // bağlantıyı kapat
    else if(AltIslevNo = 7) then
    begin

      BagKimlik := PISayi4(ADegiskenler + 00)^;

      B := GAgBaglantilari.AB.Baglanti[BagKimlik];
      if not(B = nil) then
      begin

        B.BaglantiyiKapat;

        GAgBaglantilari.AB.BaglantiyiYoket(B);
      end;
    end;
  end

  // dns bağlantı işlevleri
  else if(AnaIslevNo = 2) then
  begin

    Result := DNSIletisimCagriIslevleri(AltIslevNo, ADegiskenler);
  end;
end;

end.

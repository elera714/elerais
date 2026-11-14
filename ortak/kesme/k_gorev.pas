{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_gorev.pas
  Dosya İşlevi: görev (program) yönetim işlevlerini içerir

  Güncelleme Tarihi: 14/11/2026

 ==============================================================================}
{$mode objfpc}
unit k_gorev;

interface

uses paylasim;

function GorevCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gorev, islevler;

{==============================================================================
  uygulama kesme çağrılarını yönetir
 ==============================================================================}
function GorevCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  G: TGorev;
  GKimlik: TKimlik;
  GKayit3: PGorevKayit3;
  PKayit: TProgramKayit;
  PKayit2: PProgramKayit;
  TSS: PTSS;
  p4: Isaretci;
  s: string;
  p2: PSayi4;
  IslevNo: TSayi4;
  i, j: TISayi4;
begin

  Result := HATA_ISLEV;

  IslevNo := (AIslevNo and $FF);

  // program çalıştır
  if(IslevNo = 1) then
  begin

    s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + GGorevler.FAktifGrvBelAdr)^;

    G := GGorevler.Calistir(s, CALISMA_SEVIYE3);
    if(G <> nil) then

      Result := G.FKimlik
    else Result := -1;
  end

  // program sonlandır
  else if(IslevNo = 2) then
  begin

    i := PISayi4(ADegiskenler + 00)^;

    // -1 = o an çalışan uygulamayı (programın kendisi) sonlandır
    if(i = -1) then
    begin

      G := GGorevler.GorevAl;
      GGorevler.Isaretle(GGorevler.FAktifGrv);
    end
    else if(i >= 0) and (i < USTSINIR_GOREVSAYISI) then
    begin

      G := GGorevler.GorevAl(i);
      GGorevler.Isaretle(i);
    end;
  end

  // görev sayaç değerlerini al
  else if(IslevNo = 3) then
  begin

    p2 := PSayi4(PSayi4(ADegiskenler + 00)^ + GGorevler.FAktifGrvBelAdr);
    p2^ := USTSINIR_GOREVSAYISI;
    p2 := PSayi4(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
    p2^ := GGorevler.FCalisanGorevSayisi;

    Result := 1;
  end

  // görev hakkında detaylı bilgi al
  else if(IslevNo = 4) then
  begin

    i := PISayi4(ADegiskenler + 00)^;
    if(i >= 0) and (i < USTSINIR_GOREVSAYISI) then
    begin

      G := GGorevler.GorevBilgisiAl(i);
      if(G <> nil) then
      begin

        GKayit3 := PGorevKayit3(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
        GKayit3^.GorevDurum := G.FDurum;
        GKayit3^.GorevKimlik := G.FKimlik;
        GKayit3^.GorevSayaci := G.FGrvSayac;
        GKayit3^.BellekBasAdresi := G.FBellekBaslAdr;
        GKayit3^.BellekUz := G.FBellekUz + G.FYiginBellekUz;
        GKayit3^.OlaySayisi := G.FOlaySayisi;
        GKayit3^.DosyaAdi := G.FDosyaAdi;

        Result := HATA_YOK;
      end else Result := HATA_GOREVNO;
    end else Result := HATA_GOREVNO;
  end

  // görev yazmaç içerik bilgilerini al
  else if(IslevNo = 5) then
  begin

    i := PISayi4(ADegiskenler + 00)^;
    if(i >= 0) and (i < USTSINIR_GOREVSAYISI) then
    begin

      GKimlik := GGorevler.GorevSiraNumarasiniAl(i);
      if(GKimlik >= 0) then
      begin

        p4 := Isaretci(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
        TSS := GorevTSSListesi[GKimlik];
        Tasi2(TSS, p4, 104);

        Result := HATA_YOK;
      end else Result := HATA_GOREVNO;
    end else Result := HATA_GOREVNO;
  end

  // pencereye sahip (ptBasliksiz pencere hariç) çalışan program sayısını al
  else if(IslevNo = 6) then
  begin

    // masaüstü kimlik numarası
    i := PISayi4(ADegiskenler + 00)^;
    Result := GGorevler.PencereSahipGorevSayisiniAl(i);
  end

  // program hakkında bilgi al
  else if(IslevNo = 7) then
  begin

    i := PISayi4(ADegiskenler + 00)^;
    j := PISayi4(ADegiskenler + 04)^;
    PKayit := GGorevler.PencereSahipGorevBilgisiAl(i, j);

    PKayit2 := PProgramKayit(PSayi4(ADegiskenler + 08)^ + GGorevler.FAktifGrvBelAdr);
    PKayit2^.PencereKimlik := PKayit.PencereKimlik;
    PKayit2^.GorevKimlik := PKayit.GorevKimlik;
    PKayit2^.PencereTipi := PKayit.PencereTipi;
    PKayit2^.PencereDurum := PKayit.PencereDurum;
    PKayit2^.DosyaAdi := PKayit.DosyaAdi;
  end

  // pencereye sahip aktif programı al
  else if(IslevNo = 8) then
  begin

    // gn_pencere nesnesine taşındı
  end

  // görev adından görev kimliğini al
  else if(IslevNo = 9) then
  begin

    s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + GGorevler.FAktifGrvBelAdr)^;
    Result := GGorevler.GorevKimligiAl(s);
  end

  // görev / program adını belirle
  else if(IslevNo = $A) then
  begin

    G := GGorevler.GorevAl;
    s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + GGorevler.FAktifGrvBelAdr)^;
    G.FProgramAdi := s;
  end

  // görev bayrak değerini al
  else if(IslevNo = $B) then
  begin

    Result := GGorevler.GorevBayrakDegeriniAl;
  end;
end;

end.

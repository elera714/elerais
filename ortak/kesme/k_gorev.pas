{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_gorev.pas
  Dosya İşlevi: görev (program) yönetim işlevlerini içerir

  Güncelleme Tarihi: 23/07/2025

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
  GK: TKimlik;
  s: string;
  GorevKayit: PGorevKayit;
  p: PGorev;
  p2: PSayi4;
  p4: Isaretci;
  IslevNo: TSayi4;
  i, j: TISayi4;
  TSS: PTSS;
  ProgramKayit: TProgramKayit;
  ProgramKayit2: PProgramKayit;
begin

  IslevNo := (AIslevNo and $FF);

  // program çalıştır
  if(IslevNo = 1) then
  begin

    s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi)^;

    p := Gorevler0.Calistir(s, CALISMA_SEVIYE3);
    if(p <> nil) then

      Result := p^.Kimlik
    else Result := -1;
  end

  // program sonlandır
  else if(IslevNo = 2) then
  begin

    i := PISayi4(ADegiskenler + 00)^;

    // -1 = çalışan uygulamayı sonlandır
    if(i = -1) then
    begin

      p := GorevAl;
      Gorevler0.Isaretle(FAktifGorev);
    end
    else if(i >= 0) and (i < USTSINIR_GOREVSAYISI) then
    begin

      p := GorevAl(i);
      Gorevler0.Isaretle(i);
    end;
  end

  // görev sayaç değerlerini al
  else if(IslevNo = 3) then
  begin

    p2 := PSayi4(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi);
    p2^ := USTSINIR_GOREVSAYISI;
    p2 := PSayi4(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
    p2^ := FCalisanGorevSayisi;

    Result := 1;
  end

  // görev hakkında detaylı bilgi al
  else if(IslevNo = 4) then
  begin

    i := PISayi4(ADegiskenler + 00)^;
    if(i >= 0) and (i < USTSINIR_GOREVSAYISI) then
    begin

      p := GorevBilgisiAl(i);
      if(p <> nil) then
      begin

        GorevKayit := PGorevKayit(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
        GorevKayit^.GorevDurum := p^.Durum;
        GorevKayit^.GorevKimlik := p^.Kimlik;
        GorevKayit^.GorevSayaci := p^.GorevSayaci;
        GorevKayit^.BellekBaslangicAdresi := p^.BellekBaslangicAdresi;
        GorevKayit^.BellekUzunlugu := p^.BellekUzunlugu;
        GorevKayit^.OlaySayisi := p^.OlaySayisi;
        GorevKayit^.DosyaAdi := p^.DosyaAdi;

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

      GK := GorevSiraNumarasiniAl(i);
      if(GK >= 0) then
      begin

        p4 := Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
        TSS := GorevTSSListesi[GK];
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
    Result := CalisanProgramSayisiniAl(i);
  end

  // program hakkında bilgi al
  else if(IslevNo = 7) then
  begin

    i := PISayi4(ADegiskenler + 00)^;
    j := PISayi4(ADegiskenler + 04)^;
    ProgramKayit := CalisanProgramBilgisiAl(i, j);

    ProgramKayit2 := PProgramKayit(PSayi4(ADegiskenler + 08)^ + FAktifGorevBellekAdresi);
    ProgramKayit2^.PencereKimlik := ProgramKayit.PencereKimlik;
    ProgramKayit2^.GorevKimlik := ProgramKayit.GorevKimlik;
    ProgramKayit2^.PencereTipi := ProgramKayit.PencereTipi;
    ProgramKayit2^.PencereDurum := ProgramKayit.PencereDurum;
    ProgramKayit2^.DosyaAdi := ProgramKayit.DosyaAdi;
  end

  // pencereye sahip aktif programı al
  else if(IslevNo = 8) then
  begin

    // gn_pencere nesnesine taşındı
  end

  // görev adından görev kimliğini al
  else if(IslevNo = 9) then
  begin

    s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi)^;
    Result := Gorevler0.GorevKimligiAl(s);
  end

  // görev / program adını belirle
  else if(IslevNo = $A) then
  begin

    s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi)^;
    p^.ProgramAdi := s;
  end

  // görev bayrak değerini al
  else if(IslevNo = $B) then
  begin

    Result := GorevBayrakDegeriniAl;
  end

  // işlev belirtilen aralıkta değilse hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.

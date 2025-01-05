{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_gorev.pas
  Dosya İşlevi: görev (program) yönetim işlevlerini içerir

  Güncelleme Tarihi: 01/01/2025

 ==============================================================================}
{$mode objfpc}
unit k_gorev;

interface

uses paylasim;

function GorevCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel, gorev, sistemmesaj;

{==============================================================================
  uygulama kesme çağrılarını yönetir
 ==============================================================================}
function GorevCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorevKimlik: TKimlik;
  s: string;
  GorevKayit: PGorevKayit;
  p: PGorev;
  p2: PSayi4;
  p4: Isaretci;
  IslevNo: TSayi4;
  i: TISayi4;
  TSS: PTSS;
  ProgramKayit: TProgramKayit;
  ProgramKayit2: PProgramKayit;
begin

  IslevNo := (AIslevNo and $FF);

  // program çalıştır
  if(IslevNo = 1) then
  begin

    s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi)^;

    p := p^.Calistir(s);
    if(p <> nil) then

      Result := p^.GorevKimlik
    else Result := -1;
  end

  // program sonlandır
  else if(IslevNo = 2) then
  begin

    i := PISayi4(ADegiskenler + 00)^;

    // -1 = çalışan uygulamayı sonlandır
    if(i = -1) then
    begin

      p := GorevListesi[CalisanGorev];
      p^.Isaretle(CalisanGorev);
    end
    else if(i >= 0) and (i < USTSINIR_GOREVSAYISI) then
    begin

      p := GorevListesi[i];
      p^.Isaretle(i);
    end;
  end

  // görev sayaç değerlerini al
  else if(IslevNo = 3) then
  begin

    p2 := PSayi4(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi);
    p2^ := USTSINIR_GOREVSAYISI;
    p2 := PSayi4(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    p2^ := CalisanGorevSayisi;

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

        GorevKayit := PGorevKayit(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
        GorevKayit^.GorevDurum := p^.FGorevDurum;
        GorevKayit^.GorevKimlik := p^.GorevKimlik;
        GorevKayit^.GorevSayaci := p^.GorevSayaci;
        GorevKayit^.BellekBaslangicAdresi := p^.BellekBaslangicAdresi;
        GorevKayit^.BellekUzunlugu := p^.BellekUzunlugu;
        GorevKayit^.OlaySayisi := p^.OlaySayisi;
        GorevKayit^.DosyaAdi := p^.FDosyaAdi;

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

      GorevKimlik := GorevSiraNumarasiniAl(i);
      if(GorevKimlik >= 0) then
      begin

        p4 := Isaretci(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
        TSS := GorevTSSListesi[GorevKimlik];
        Tasi2(TSS, p4, 104);

        Result := HATA_YOK;
      end else Result := HATA_GOREVNO;
    end else Result := HATA_GOREVNO;
  end

  // pencereye sahip (ptBasliksiz pencere hariç) çalışan program sayısını al
  else if(IslevNo = 6) then
  begin

    Result := CalisanProgramSayisiniAl;
  end

  // program hakkında bilgi al
  else if(IslevNo = 7) then
  begin

    i := PISayi4(ADegiskenler + 00)^;
    ProgramKayit := CalisanProgramBilgisiAl(i);

    ProgramKayit2 := PProgramKayit(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    ProgramKayit2^.PencereKimlik := ProgramKayit.PencereKimlik;
    ProgramKayit2^.GorevKimlik := ProgramKayit.GorevKimlik;
    ProgramKayit2^.PencereTipi := ProgramKayit.PencereTipi;
    ProgramKayit2^.PencereDurum := ProgramKayit.PencereDurum;
    ProgramKayit2^.DosyaAdi := ProgramKayit.DosyaAdi;
  end

  // pencereye sahip aktif programı al
  else if(IslevNo = 8) then
  begin

    Result := AktifProgramiAl;
  end

  // görev adından görev kimliğini al
  else if(IslevNo = 9) then
  begin

    s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi)^;
    Result := p^.GorevKimligiAl(s);
  end

  // görev / program adını belirle
  else if(IslevNo = $A) then
  begin

    s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi)^;
    p^.FProgramAdi := s;
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

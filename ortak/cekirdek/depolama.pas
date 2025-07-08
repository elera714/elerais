{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: depolama.pas
  Dosya Ýþlevi: depolama aygýt iþlevlerini yönetir

  Güncelleme Tarihi: 07/07/2025

 ==============================================================================}
{$mode objfpc}
unit depolama;

interface

uses paylasim;

type
  TDepolama = class
  public
    function FizikselSurucuAl(ASiraNo: TISayi4): PFizikselDepolama;
    function FizikselSurucuAl2(AKimlik: TKimlik): PFizikselDepolama;
    function FizikselDepolamaVeriOku(AFizikselDepolama: PFizikselDepolama; ASektorNo,
      ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
    function FizikselDepolamaVeriYaz(AFizikselDepolama: PFizikselDepolama; ASektorNo,
      ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
    function MantiksalSurucuAl(ASiraNo: TISayi4): PMantiksalDepolama;
    function MantiksalSurucuAl(AAygitAdi: string): PMantiksalDepolama;
    function MantiksalSurucuAl2(AKimlik: TKimlik): PMantiksalDepolama;
    function MantiksalDepolamaVeriOku(AMantiksalDepolama: PMantiksalDepolama; ASektorNo,
      ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
  end;

implementation

uses sistemmesaj;

{==============================================================================
  sýra numarasýna göre fiziksel depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TDepolama.FizikselSurucuAl(ASiraNo: TISayi4): PFizikselDepolama;
var
  FD: TFizikselDepolama;
  SiraNo, i: TISayi4;
begin

  if(ASiraNo >= Low(FizikselDepolamaAygitListesi)) and (ASiraNo <= High(FizikselDepolamaAygitListesi)) then
  begin

    SiraNo := -1;
    for i := Low(FizikselDepolamaAygitListesi) to High(FizikselDepolamaAygitListesi) do
    begin

      FD := FizikselDepolamaAygitListesi[i];
      if(FD.Mevcut0) then Inc(SiraNo);

      if(SiraNo = ASiraNo) then Exit(@FizikselDepolamaAygitListesi[i]);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  kimlik deðerine göre fiziksel depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TDepolama.FizikselSurucuAl2(AKimlik: TKimlik): PFizikselDepolama;
var
  FD: TFizikselDepolama;
  i: TISayi4;
begin

  for i := Low(FizikselDepolamaAygitListesi) to High(FizikselDepolamaAygitListesi) do
  begin

    FD := FizikselDepolamaAygitListesi[i];
    if(FD.Mevcut0) and (FD.FD3.Kimlik = AKimlik) then Exit(@FizikselDepolamaAygitListesi[i]);
  end;

  Result := nil;
end;

{==============================================================================
  fiziksel depolama aygýtýndan veri oku
 ==============================================================================}
function TDepolama.FizikselDepolamaVeriOku(AFizikselDepolama: PFizikselDepolama; ASektorNo,
  ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
begin

{  SISTEM_MESAJ(RENK_MAVI, 'Depolama Kimlik: %d', [AFizikselDepolama^.FD3.Kimlik]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Sürücü Tipi: %d', [AFizikselDepolama^.FD3.SurucuTipi]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Adý: %s', [AFizikselDepolama^.FD3.AygitAdi]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Ýlk Sektör: %d', [ASektorNo]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Sektör Sayýsý: %d', [ASektorSayisi]); }

  Result := AFizikselDepolama^.SektorOku(AFizikselDepolama, ASektorNo,
    ASektorSayisi, ABellek);
end;

{==============================================================================
  fiziksel depolama aygýtýna veri yaz
 ==============================================================================}
function TDepolama.FizikselDepolamaVeriYaz(AFizikselDepolama: PFizikselDepolama; ASektorNo,
  ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
begin

  Result := AFizikselDepolama^.SektorYaz(AFizikselDepolama, ASektorNo,
    ASektorSayisi, ABellek);
end;

{==============================================================================
  sýra numarasýna göre mantýksal depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TDepolama.MantiksalSurucuAl(ASiraNo: TISayi4): PMantiksalDepolama;
var
  MD: TMantiksalDepolama;
  SiraNo, i: TISayi4;
begin

  if(ASiraNo >= Low(MantiksalDepolamaAygitListesi)) and (ASiraNo <= High(MantiksalDepolamaAygitListesi)) then
  begin

    SiraNo := -1;
    for i := Low(MantiksalDepolamaAygitListesi) to High(MantiksalDepolamaAygitListesi) do
    begin

      MD := MantiksalDepolamaAygitListesi[i];
      if(MD.Mevcut) then Inc(SiraNo);

      if(SiraNo = ASiraNo) then Exit(@MantiksalDepolamaAygitListesi[i]);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  aygýt adýna (örnek: disk2) göre mantýksal depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TDepolama.MantiksalSurucuAl(AAygitAdi: string): PMantiksalDepolama;
var
  MD: PMantiksalDepolama;
  i: TISayi4;
begin

  for i := Low(MantiksalDepolamaAygitListesi) to High(MantiksalDepolamaAygitListesi) do
  begin

    MD := @MantiksalDepolamaAygitListesi[i];
    if(MD^.Mevcut) and (MD^.MD3.AygitAdi = AAygitAdi) then Exit(MD);
  end;

  Result := nil;
end;

{==============================================================================
  kimlik deðerine göre mantýksal depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TDepolama.MantiksalSurucuAl2(AKimlik: TKimlik): PMantiksalDepolama;
var
  MD: TMantiksalDepolama;
  i: TISayi4;
begin

  for i := Low(MantiksalDepolamaAygitListesi) to High(MantiksalDepolamaAygitListesi) do
  begin

    MD := MantiksalDepolamaAygitListesi[i];
    if(MD.Mevcut) and (MD.MD3.Kimlik = AKimlik) then Exit(@MantiksalDepolamaAygitListesi[i]);
  end;

  Result := nil;
end;

{==============================================================================
  mantýksal depolama aygýtýndan veri okur
 ==============================================================================}
function TDepolama.MantiksalDepolamaVeriOku(AMantiksalDepolama: PMantiksalDepolama; ASektorNo,
  ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
begin


{  SISTEM_MESAJ(RENK_MAVI, 'Depolama Kimlik: %d', [AMantiksalDepolama^.MD3.Kimlik]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Sürücü Tipi: %d', [AMantiksalDepolama^.MD3.SurucuTipi]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Adý: %s', [AMantiksalDepolama^.MD3.AygitAdi]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Ýlk Sektör: %d', [ASektorNo]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Sektör Sayýsý: %d', [ASektorSayisi]); }

  Result := AMantiksalDepolama^.FD^.SektorOku(AMantiksalDepolama, ASektorNo,
    ASektorSayisi, ABellek);
end;

end.

{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: fareimlec.pas
  Dosya İşlevi: sistem fare gösterge resimlerini içerir

  Güncelleme Tarihi: 06/10/2019

 ==============================================================================}
{$mode objfpc}
unit fareimlec;

interface

uses paylasim;

const
  WW = 1;     // siyah olarak işaretlenecek
  oo = 2;     // beyaz olarak işaretlenecek
  ii = 100;   // işaretlenmeyecek

type
  PFareImlec = ^TFareImlec;
  TFareImlec = record
    Genislik,                 // fare gösterge genişliği
    Yukseklik,                // fare gösterge yüksekliği
    YatayOdak,                // yatay odak nokta değeri
    DikeyOdak: TSayi1;        // dikey odak nokta değeri
    BellekAdresi: Isaretci;   // fare gösterge resim bellek adresi
  end;

{==============================================================================
  fare gösterge tanımlamaları
 ==============================================================================}
const
  ImlecOK: array[1..21, 1..12] of TSayi1 = (
    (WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii),
    (WW,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii),
    (WW,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii),
    (WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii),
    (WW,oo,oo,oo,oo,oo,oo,WW,WW,WW,WW,WW),
    (WW,oo,oo,oo,WW,oo,oo,WW,ii,ii,ii,ii),
    (WW,oo,oo,WW,WW,oo,oo,WW,ii,ii,ii,ii),
    (WW,oo,WW,ii,ii,WW,oo,oo,WW,ii,ii,ii),
    (WW,WW,ii,ii,ii,WW,oo,oo,WW,ii,ii,ii),
    (WW,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii,ii),
    (ii,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii),
    (ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii),
    (ii,ii,ii,ii,ii,ii,ii,ii,WW,WW,ii,ii));

  ImlecGiris: array[1..16, 1..7] of TSayi1 = (
    (WW,WW,WW,ii,WW,WW,WW),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (ii,ii,ii,WW,ii,ii,ii),
    (WW,WW,WW,ii,WW,WW,WW));

  ImlecEl: array[1..22, 1..17] of TSayi1 = (
    (ii,ii,ii,ii,ii,WW,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,WW,WW,WW,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,WW,oo,oo,WW,WW,WW,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,WW,oo,oo,WW,oo,oo,WW,WW,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,WW,oo,oo,WW,oo,oo,WW,oo,WW,ii),
    (WW,WW,WW,ii,WW,oo,oo,WW,oo,oo,WW,oo,oo,WW,oo,oo,WW),
    (WW,oo,oo,WW,WW,oo,oo,oo,oo,oo,oo,oo,oo,WW,oo,oo,WW),
    (WW,oo,oo,oo,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW),
    (ii,WW,oo,oo,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW),
    (ii,ii,WW,oo,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW),
    (ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW),
    (ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW),
    (ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii),
    (ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii),
    (ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii),
    (ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii),
    (ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii),
    (ii,ii,ii,ii,ii,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,ii,ii));

  ImlecBoyutKBGD: array[1..15, 1..15] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW,WW,WW,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,WW,ii,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii),
    (WW,ii,ii,ii,ii,ii,WW,oo,WW,ii,ii,ii,ii,ii,WW),
    (ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,ii,WW,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,oo,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,WW,WW,WW,WW,WW,WW,WW,WW));

  ImlecBoyutKG: array[1..21, 1..9] of TSayi1 = (
    (ii,ii,ii,ii,WW,ii,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,WW,oo,oo,oo,WW,ii,ii),
    (ii,WW,oo,oo,oo,oo,oo,WW,ii),
    (WW,oo,oo,oo,oo,oo,oo,oo,WW),
    (WW,WW,WW,WW,oo,WW,WW,WW,WW),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (WW,WW,WW,WW,oo,WW,WW,WW,WW),
    (WW,oo,oo,oo,oo,oo,oo,oo,WW),
    (ii,WW,oo,oo,oo,oo,oo,WW,ii),
    (ii,ii,WW,oo,oo,oo,WW,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,ii,WW,ii,ii,ii,ii));

  ImlecIslem: array[1..21, 1..22] of TSayi1 = (
    (WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,WW,oo,oo,oo,oo,oo,oo,WW,WW),
    (WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,WW,ii),
    (WW,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,WW,ii),
    (WW,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW,oo,oo,WW,ii),
    (WW,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,WW,WW,oo,WW,oo,oo,WW,WW,ii),
    (WW,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,WW,WW,oo,oo,WW,WW,ii,ii),
    (WW,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,WW,WW,oo,WW,ii,ii,ii),
    (WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii,WW,WW,oo,oo,WW,WW,ii,ii),
    (WW,oo,oo,oo,oo,oo,oo,WW,WW,WW,WW,WW,ii,WW,WW,oo,oo,oo,oo,WW,WW,ii),
    (WW,oo,oo,oo,WW,oo,oo,WW,ii,ii,ii,ii,ii,WW,oo,oo,WW,oo,oo,oo,WW,ii),
    (WW,oo,oo,WW,WW,oo,oo,WW,ii,ii,ii,ii,ii,WW,oo,WW,oo,WW,oo,oo,WW,ii),
    (WW,oo,WW,ii,ii,WW,oo,oo,WW,ii,ii,ii,ii,WW,WW,oo,WW,oo,WW,oo,WW,ii),
    (WW,WW,ii,ii,ii,WW,oo,oo,WW,ii,ii,ii,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii,ii,WW,WW,oo,oo,oo,oo,oo,oo,WW,WW),
    (ii,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii,ii,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW),
    (ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,ii,WW,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii));

  ImlecBekle: array[1..22, 1..13] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW),
    (ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii),
    (ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii),
    (ii,WW,oo,oo,WW,oo,WW,oo,WW,oo,oo,WW,ii),
    (ii,WW,oo,oo,oo,WW,oo,WW,oo,oo,oo,WW,ii),
    (ii,WW,WW,oo,oo,oo,WW,oo,oo,oo,WW,WW,ii),
    (ii,ii,WW,WW,oo,oo,oo,oo,oo,WW,WW,ii,ii),
    (ii,ii,ii,WW,WW,oo,WW,oo,WW,WW,ii,ii,ii),
    (ii,ii,ii,ii,WW,WW,oo,WW,WW,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,WW,oo,WW,WW,ii,ii,ii,ii),
    (ii,ii,ii,WW,WW,oo,oo,oo,WW,WW,ii,ii,ii),
    (ii,ii,WW,WW,oo,oo,WW,oo,oo,WW,WW,ii,ii),
    (ii,WW,WW,oo,oo,oo,oo,oo,oo,oo,WW,WW,ii),
    (ii,WW,oo,oo,oo,oo,WW,oo,oo,oo,oo,WW,ii),
    (ii,WW,oo,oo,oo,WW,oo,WW,oo,oo,oo,WW,ii),
    (ii,WW,oo,oo,WW,oo,WW,oo,WW,oo,oo,WW,ii),
    (ii,WW,oo,WW,oo,WW,oo,WW,oo,WW,oo,WW,ii),
    (WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW));

  ImlecYasak: array[1..20, 1..20] of TSayi1 = (
    (ii,ii,ii,ii,ii,ii,ii,WW,WW,WW,WW,WW,WW,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,WW,WW,oo,oo,oo,oo,oo,oo,WW,WW,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii),
    (ii,ii,ii,WW,oo,oo,oo,oo,WW,WW,WW,WW,oo,oo,oo,oo,WW,ii,ii,ii),
    (ii,ii,WW,oo,oo,oo,WW,WW,ii,ii,ii,ii,WW,WW,oo,oo,oo,WW,ii,ii),
    (ii,WW,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW,ii),
    (ii,WW,oo,oo,WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii),
    (WW,oo,oo,oo,WW,WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW),
    (WW,oo,oo,WW,ii,ii,WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,WW,oo,oo,WW),
    (WW,oo,oo,WW,ii,ii,ii,WW,oo,oo,oo,WW,ii,ii,ii,ii,WW,oo,oo,WW),
    (WW,oo,oo,WW,ii,ii,ii,ii,WW,oo,oo,oo,WW,ii,ii,ii,WW,oo,oo,WW),
    (WW,oo,oo,WW,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW,ii,ii,WW,oo,oo,WW),
    (WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW,WW,oo,oo,oo,WW),
    (ii,WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW,oo,oo,WW,ii),
    (ii,WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,WW,ii),
    (ii,ii,WW,oo,oo,oo,WW,WW,ii,ii,ii,ii,WW,WW,oo,oo,oo,WW,ii,ii),
    (ii,ii,ii,WW,oo,oo,oo,oo,WW,WW,WW,WW,oo,oo,oo,oo,WW,ii,ii,ii),
    (ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,WW,WW,oo,oo,oo,oo,oo,oo,WW,WW,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,WW,WW,WW,WW,WW,WW,ii,ii,ii,ii,ii,ii,ii));

  ImlecBD: array[1..9, 1..21] of TSayi1 = (
    (ii,ii,ii,ii,WW,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,WW,ii,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii,ii),
    (ii,WW,oo,oo,oo,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,oo,oo,oo,WW,ii),
    (WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW),
    (ii,WW,oo,oo,oo,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,oo,oo,oo,WW,ii),
    (ii,ii,WW,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,WW,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,ii,WW,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,WW,ii,ii,ii,ii));

  ImlecBoyutKDGB: array[1..15, 1..15] of TSayi1 = (
    (ii,ii,ii,ii,ii,ii,ii,ii,WW,WW,WW,WW,WW,WW,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,oo,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,ii,WW,oo,WW),
    (ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,WW),
    (ii,ii,ii,ii,ii,ii,WW,oo,WW,ii,ii,ii,ii,ii,ii),
    (WW,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,WW,ii,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii),
    (WW,WW,WW,WW,WW,WW,WW,ii,ii,ii,ii,ii,ii,ii,ii));

  ImlecBoyutTum: array[1..21, 1..21] of TSayi1 = (
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,WW,WW,WW,WW,oo,WW,WW,WW,WW,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,WW,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,WW,ii,ii,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,WW,oo,oo,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,oo,oo,WW,ii,ii),
    (ii,WW,oo,oo,oo,WW,WW,WW,WW,WW,oo,WW,WW,WW,WW,WW,oo,oo,oo,WW,ii),
    (WW,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,WW),
    (ii,WW,oo,oo,oo,WW,WW,WW,WW,WW,oo,WW,WW,WW,WW,WW,oo,oo,oo,WW,ii),
    (ii,ii,WW,oo,oo,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,oo,oo,WW,ii,ii),
    (ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii),
    (ii,ii,ii,ii,WW,WW,ii,ii,ii,WW,oo,WW,ii,ii,ii,WW,WW,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,WW,WW,WW,WW,oo,WW,WW,WW,WW,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,oo,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,oo,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii,ii,ii,ii,WW,ii,ii,ii,ii,ii,ii,ii,ii,ii,ii));

{==============================================================================
  fare gösterge tanım tablosu
 ==============================================================================}
const
  CursorList: array[0..10] of TFareImlec = (
    (Genislik: 12;  Yukseklik: 21;  YatayOdak: 0;   DikeyOdak: 0;   BellekAdresi: @ImlecOK),
    (Genislik: 7;   Yukseklik: 16;  YatayOdak: 4;   DikeyOdak: 8;   BellekAdresi: @ImlecGiris),
    (Genislik: 17;  Yukseklik: 22;  YatayOdak: 5;   DikeyOdak: 0;   BellekAdresi: @ImlecEl),
    (Genislik: 15;  Yukseklik: 15;  YatayOdak: 8;   DikeyOdak: 8;   BellekAdresi: @ImlecBoyutKBGD),
    (Genislik: 9;   Yukseklik: 21;  YatayOdak: 5;   DikeyOdak: 10;  BellekAdresi: @ImlecBoyutKG),
    (Genislik: 22;  Yukseklik: 21;  YatayOdak: 0;   DikeyOdak: 0;   BellekAdresi: @ImlecIslem),
    (Genislik: 13;  Yukseklik: 22;  YatayOdak: 7;   DikeyOdak: 11;  BellekAdresi: @ImlecBekle),
    (Genislik: 20;  Yukseklik: 20;  YatayOdak: 10;  DikeyOdak: 10;  BellekAdresi: @ImlecYasak),
    (Genislik: 21;  Yukseklik: 9;   YatayOdak: 10;  DikeyOdak: 5;   BellekAdresi: @ImlecBD),
    (Genislik: 15;  Yukseklik: 15;  YatayOdak: 8;   DikeyOdak: 8;   BellekAdresi: @ImlecBoyutKDGB),
    (Genislik: 21;  Yukseklik: 21;  YatayOdak: 10;  DikeyOdak: 10;  BellekAdresi: @ImlecBoyutTum));

implementation

end.

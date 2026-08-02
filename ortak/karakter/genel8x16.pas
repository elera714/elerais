{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: genel8x16.pas
  Dosya İşlevi: sistem öndeğer yazı tipi karakter setini içerir

  Güncelleme Tarihi: 02/08/2026

 ==============================================================================}
{$mode objfpc}
unit genel8x16;

{==============================================================================
  yazı tipi bilgisi:
    - Courier New
    - Normal
    - 8x16 pixel
    - türkçe karakterler mevcut
 ==============================================================================}
interface

uses paylasim;

type
  PKarakter = ^TKarakter;
  TKarakter = record
    Genislik,                   // karakter genişliği
    Yukseklik,                  // karakter yüksekliği
    YT,                         // yatay +/- tolerans değeri
    DT: TISayi4;                // dikey +/- tolerans değeri
    Adres: Isaretci;            // karakter resim başlangıç adresi
  end;

const
  MM = 1;   // işaretlenecek
  ii = 0;   // işaretlenmeyecek

{==============================================================================
  font tanımlamaları
 ==============================================================================}
const
  // bu karakter boşluk karakteri olup, boşluğun çizilmesi için değil
  // tasarımsal olarak zeminin çizilmesi için tanımlanmıştır
  KAR032: array[1..1, 1..8] of TSayi1 = (
    (ii,ii,ii,ii,ii,ii,ii,ii));

  KAR033: array[1..10, 1..1] of TSayi1 = (
    (MM),
    (MM),
    (MM),
    (MM),
    (MM),
    (MM),
    (MM),
    (ii),
    (MM),
    (MM));

  KAR034: array[1..4, 1..5] of TSayi1 = (
    (MM,MM,ii,MM,MM),
    (MM,MM,ii,MM,MM),
    (MM,ii,ii,MM,ii),
    (MM,ii,ii,MM,ii));

  KAR035: array[1..10, 1..6] of TSayi1 = (
    (ii,ii,MM,ii,ii,MM),
    (ii,ii,MM,ii,ii,MM),
    (ii,MM,ii,ii,MM,ii),
    (MM,MM,MM,MM,MM,MM),
    (ii,MM,ii,ii,MM,ii),
    (ii,MM,ii,ii,MM,ii),
    (MM,MM,MM,MM,MM,MM),
    (ii,MM,ii,ii,MM,ii),
    (MM,ii,ii,MM,ii,ii),
    (MM,ii,ii,MM,ii,ii));

  KAR036: array[1..10, 1..4] of TSayi1 = (
    (ii,ii,MM,ii),
    (ii,MM,MM,MM),
    (MM,ii,ii,MM),
    (MM,ii,ii,ii),
    (ii,MM,MM,ii),
    (ii,ii,ii,MM),
    (MM,ii,ii,MM),
    (MM,MM,MM,ii),
    (ii,ii,MM,ii),
    (ii,ii,MM,ii));

  KAR037: array[1..8, 1..5] of TSayi1 = (
    (ii,MM,ii,ii,ii),
    (MM,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,MM),
    (MM,MM,MM,ii,ii),
    (ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,MM),
    (ii,ii,ii,MM,ii));

  KAR038: array[1..7, 1..5] of TSayi1 = (
    (ii,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii),
    (ii,MM,ii,ii,ii),
    (ii,MM,MM,ii,ii),
    (MM,ii,MM,ii,MM),
    (MM,ii,ii,MM,ii),
    (ii,MM,MM,MM,MM));

  KAR039: array[1..4, 1..1] of TSayi1 = (
    (MM),
    (MM),
    (MM),
    (MM));

  KAR040: array[1..10, 1..2] of TSayi1 = (
    (ii,MM),
    (ii,MM),
    (MM,ii),
    (MM,ii),
    (MM,ii),
    (MM,ii),
    (MM,ii),
    (MM,ii),
    (ii,MM),
    (ii,MM));

  KAR041: array[1..10, 1..2] of TSayi1 = (
    (MM,ii),
    (MM,ii),
    (ii,MM),
    (ii,MM),
    (ii,MM),
    (ii,MM),
    (ii,MM),
    (ii,MM),
    (MM,ii),
    (MM,ii));

  KAR042: array[1..5, 1..5] of TSayi1 = (
    (ii,ii,MM,ii,ii),
    (MM,MM,MM,MM,MM),
    (ii,ii,MM,ii,ii),
    (ii,MM,ii,MM,ii),
    (ii,MM,ii,MM,ii));

  KAR043: array[1..7, 1..7] of TSayi1 = (
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (MM,MM,MM,MM,MM,MM,MM),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii));

  KAR044: array[1..4, 1..3] of TSayi1 = (
    (ii,MM,MM),
    (ii,MM,ii),
    (MM,MM,ii),
    (MM,ii,ii));

  KAR045: array[1..1, 1..6] of TSayi1 = (
    (MM,MM,MM,MM,MM,MM));

  KAR046: array[1..2, 1..2] of TSayi1 = (
    (MM,MM),
    (MM,MM));

  KAR047: array[1..10, 1..5] of TSayi1 = (
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,MM,ii),
    (ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii),
    (ii,MM,ii,ii,ii),
    (MM,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii));

  KAR048: array[1..8, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii));

  KAR049: array[1..8, 1..5] of TSayi1 = (
    (ii,ii,MM,ii,ii),
    (MM,MM,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (MM,MM,MM,MM,MM));

  KAR050: array[1..8, 1..5] of TSayi1 = (
    (ii,MM,MM,MM,ii),
    (MM,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii),
    (MM,ii,ii,ii,MM),
    (MM,MM,MM,MM,MM));

  KAR051: array[1..8, 1..5] of TSayi1 = (
    (ii,MM,MM,MM,ii),
    (MM,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,MM,MM,ii),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,MM),
    (ii,MM,MM,MM,ii));

  KAR052: array[1..8, 1..6] of TSayi1 = (
    (ii,ii,ii,MM,MM,ii),
    (ii,ii,MM,ii,MM,ii),
    (ii,MM,ii,ii,MM,ii),
    (ii,MM,ii,ii,MM,ii),
    (MM,MM,MM,MM,MM,MM),
    (ii,ii,ii,ii,MM,ii),
    (ii,ii,ii,ii,MM,ii),
    (ii,ii,ii,MM,MM,MM));

  KAR053: array[1..8, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,MM,MM),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,MM,MM,MM,ii),
    (ii,ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii));

  KAR054: array[1..8, 1..5] of TSayi1 = (
    (ii,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii),
    (MM,ii,ii,ii,ii),
    (MM,MM,MM,MM,ii),
    (MM,ii,ii,ii,MM),
    (MM,ii,ii,ii,MM),
    (MM,ii,ii,ii,MM),
    (ii,MM,MM,MM,ii));

  KAR055: array[1..8, 1..6] of TSayi1 = (
    (MM,MM,MM,MM,MM,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM,ii),
    (ii,ii,ii,ii,MM,ii),
    (ii,ii,ii,MM,ii,ii),
    (ii,ii,ii,MM,ii,ii),
    (ii,ii,ii,MM,ii,ii));

  KAR056: array[1..8, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii));

  KAR057: array[1..8, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,MM),
    (ii,ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM,ii),
    (MM,MM,MM,MM,ii,ii));

  KAR058: array[1..6, 1..2] of TSayi1 = (
    (MM,MM),
    (MM,MM),
    (ii,ii),
    (ii,ii),
    (MM,MM),
    (MM,MM));

  KAR059: array[1..7, 1..3] of TSayi1 = (
    (ii,MM,MM),
    (ii,MM,MM),
    (ii,ii,ii),
    (ii,ii,ii),
    (ii,MM,MM),
    (MM,MM,ii),
    (MM,ii,ii));

  KAR060: array[1..7, 1..6] of TSayi1 = (
    (ii,ii,ii,ii,ii,MM),
    (ii,ii,ii,MM,MM,ii),
    (ii,ii,MM,ii,ii,ii),
    (MM,MM,ii,ii,ii,ii),
    (ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,MM,ii),
    (ii,ii,ii,ii,ii,MM));

  KAR061: array[1..3, 1..6] of TSayi1 = (
    (MM,MM,MM,MM,MM,MM),
    (ii,ii,ii,ii,ii,ii),
    (MM,MM,MM,MM,MM,MM));

  KAR062: array[1..7, 1..6] of TSayi1 = (
    (MM,ii,ii,ii,ii,ii),
    (ii,MM,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii),
    (ii,ii,ii,ii,MM,MM),
    (ii,ii,ii,MM,ii,ii),
    (ii,MM,MM,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii));

  KAR063: array[1..8, 1..5] of TSayi1 = (
    (ii,MM,MM,MM,ii),
    (MM,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,ii,ii,ii),
    (ii,MM,MM,ii,ii));

  KAR064: array[1..10, 1..5] of TSayi1 = (
    (ii,MM,MM,MM,ii),
    (MM,ii,ii,ii,MM),
    (MM,ii,ii,ii,MM),
    (MM,ii,ii,MM,MM),
    (MM,ii,MM,ii,MM),
    (MM,ii,MM,ii,MM),
    (MM,ii,ii,MM,MM),
    (MM,ii,ii,ii,ii),
    (MM,ii,ii,ii,MM),
    (ii,MM,MM,MM,ii));

  KAR065: array[1..8, 1..7] of TSayi1 = (
    (ii,ii,MM,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,MM,ii,MM,ii,ii),
    (ii,ii,MM,ii,MM,ii,ii),
    (ii,ii,MM,ii,MM,ii,ii),
    (ii,ii,MM,MM,MM,ii,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,MM,MM,ii,MM,MM,MM));

  KAR066: array[1..8, 1..6] of TSayi1 = (
    (MM,MM,MM,MM,MM,ii),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (MM,MM,MM,MM,MM,ii));

  KAR067: array[1..8, 1..6] of TSayi1 = (
    (ii,ii,MM,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,MM),
    (ii,ii,MM,MM,MM,ii));

  KAR068: array[1..8, 1..6] of TSayi1 = (
    (MM,MM,MM,MM,ii,ii),
    (ii,MM,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,MM,ii),
    (MM,MM,MM,MM,ii,ii));

  KAR069: array[1..8, 1..6] of TSayi1 = (
    (MM,MM,MM,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,MM,ii,ii),
    (ii,MM,MM,MM,ii,ii),
    (ii,MM,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,MM),
    (MM,MM,MM,MM,MM,MM));

  KAR070: array[1..8, 1..6] of TSayi1 = (
    (MM,MM,MM,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,MM,ii,ii),
    (ii,MM,MM,MM,ii,ii),
    (ii,MM,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (MM,MM,MM,ii,ii,ii));

  KAR071: array[1..8, 1..7] of TSayi1 = (
    (ii,ii,MM,MM,MM,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,MM,MM,MM),
    (MM,ii,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii,ii));

  KAR072: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,MM,MM,MM,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,MM,MM,ii,MM,MM,MM));

  KAR073: array[1..8, 1..5] of TSayi1 = (
    (MM,MM,MM,MM,MM),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (MM,MM,MM,MM,MM));

  KAR074: array[1..8, 1..6] of TSayi1 = (
    (ii,ii,MM,MM,MM,MM),
    (ii,ii,ii,ii,MM,ii),
    (ii,ii,ii,ii,MM,ii),
    (ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,MM,ii),
    (ii,MM,MM,MM,ii,ii));

  KAR075: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,MM,ii,ii),
    (ii,MM,ii,MM,ii,ii,ii),
    (ii,MM,MM,MM,ii,ii,ii),
    (ii,MM,ii,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,MM,MM,ii,ii,MM,MM));

  KAR076: array[1..8, 1..6] of TSayi1 = (
    (MM,MM,MM,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (MM,MM,MM,MM,MM,MM));

  KAR077: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,MM,ii,MM,MM,ii),
    (ii,MM,MM,ii,MM,MM,ii),
    (ii,MM,ii,MM,ii,MM,ii),
    (ii,MM,ii,MM,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,MM,MM,ii,MM,MM,MM));

  KAR078: array[1..8, 1..8] of TSayi1 = (
    (MM,MM,MM,ii,ii,MM,MM,MM),
    (ii,MM,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,MM,ii,ii,MM,ii),
    (ii,MM,ii,MM,ii,ii,MM,ii),
    (ii,MM,ii,ii,MM,ii,MM,ii),
    (ii,MM,ii,ii,MM,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,MM,ii),
    (MM,MM,MM,ii,ii,MM,MM,ii));

  KAR079: array[1..8, 1..7] of TSayi1 = (
    (ii,ii,MM,MM,MM,ii,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii,ii));

  KAR080: array[1..8, 1..6] of TSayi1 = (
    (MM,MM,MM,MM,MM,ii),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (MM,MM,MM,ii,ii,ii));

  KAR081: array[1..9, 1..7] of TSayi1 = (
    (ii,ii,MM,MM,MM,ii,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii,ii),
    (ii,ii,MM,MM,MM,MM,MM));

  KAR082: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,MM,MM,ii,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,MM,MM,MM,ii,ii),
    (ii,MM,ii,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,MM,MM,ii,ii,ii,MM));

  KAR083: array[1..8, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,ii,MM),
    (MM,ii,ii,ii,MM,MM),
    (MM,ii,ii,ii,ii,ii),
    (ii,MM,MM,MM,MM,ii),
    (ii,ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,ii,MM),
    (MM,MM,ii,ii,ii,MM),
    (MM,ii,MM,MM,MM,ii));

  KAR084: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,MM,MM,MM,MM),
    (MM,ii,ii,MM,ii,ii,MM),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,MM,MM,MM,ii,ii));

  KAR085: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii,ii));

  KAR086: array[1..8, 1..8] of TSayi1 = (
    (MM,MM,MM,ii,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii,MM,ii,ii),
    (ii,ii,ii,MM,MM,ii,ii,ii),
    (ii,ii,ii,MM,MM,ii,ii,ii));

  KAR087: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,MM,ii,MM,ii),
    (ii,MM,ii,MM,ii,MM,ii),
    (ii,MM,ii,MM,ii,MM,ii),
    (ii,MM,ii,MM,ii,MM,ii),
    (ii,ii,MM,ii,MM,ii,ii));

  KAR088: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,MM,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,MM,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,MM,MM,ii,MM,MM,MM));

  KAR089: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,MM,ii,ii),
    (ii,ii,MM,ii,MM,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,MM,MM,MM,ii,ii));

  KAR090: array[1..8, 1..5] of TSayi1 = (
    (MM,MM,MM,MM,MM),
    (MM,ii,ii,ii,MM),
    (ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii),
    (MM,ii,ii,ii,MM),
    (MM,MM,MM,MM,MM));

  KAR091: array[1..10, 1..3] of TSayi1 = (
    (MM,MM,MM),
    (MM,ii,ii),
    (MM,ii,ii),
    (MM,ii,ii),
    (MM,ii,ii),
    (MM,ii,ii),
    (MM,ii,ii),
    (MM,ii,ii),
    (MM,ii,ii),
    (MM,MM,MM));

  KAR092: array[1..10, 1..4] of TSayi1 = (
    (MM,ii,ii,ii),
    (MM,ii,ii,ii),
    (ii,MM,ii,ii),
    (ii,MM,ii,ii),
    (ii,ii,MM,ii),
    (ii,ii,MM,ii),
    (ii,ii,MM,ii),
    (ii,ii,ii,MM),
    (ii,ii,ii,MM),
    (ii,ii,ii,MM));

  KAR093: array[1..10, 1..3] of TSayi1 = (
    (MM,MM,MM),
    (ii,ii,MM),
    (ii,ii,MM),
    (ii,ii,MM),
    (ii,ii,MM),
    (ii,ii,MM),
    (ii,ii,MM),
    (ii,ii,MM),
    (ii,ii,MM),
    (MM,MM,MM));

  KAR094: array[1..4, 1..5] of TSayi1 = (
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,MM,ii,MM,ii),
    (MM,ii,ii,ii,MM));

  KAR095: array[1..1, 1..8] of TSayi1 = (
    (MM,MM,MM,MM,MM,MM,MM,MM));

  KAR096: array[1..2, 1..2] of TSayi1 = (
    (MM,ii),
    (ii,MM));

  KAR097: array[1..6, 1..7] of TSayi1 = (
    (ii,MM,MM,MM,MM,ii,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (ii,MM,MM,MM,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,MM,MM,ii),
    (ii,MM,MM,MM,ii,MM,MM));

  KAR098: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,ii,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii,ii),
    (ii,MM,ii,MM,MM,MM,ii),
    (ii,MM,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,ii,ii,ii,MM),
    (MM,MM,ii,MM,MM,MM,ii));

  KAR099: array[1..6, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,ii,MM),
    (MM,ii,ii,ii,MM,MM),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii));

  KAR100: array[1..8, 1..7] of TSayi1 = (
    (ii,ii,ii,ii,MM,MM,ii),
    (ii,ii,ii,ii,ii,MM,ii),
    (ii,MM,MM,MM,ii,MM,ii),
    (MM,ii,ii,ii,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,MM,MM,ii),
    (ii,MM,MM,MM,ii,MM,MM));

  KAR101: array[1..6, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM),
    (MM,MM,MM,MM,MM,MM),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii),
    (ii,MM,MM,MM,MM,MM));

  KAR102: array[1..8, 1..6] of TSayi1 = (
    (ii,ii,ii,MM,MM,MM),
    (ii,ii,MM,ii,ii,ii),
    (MM,MM,MM,MM,MM,MM),
    (ii,ii,MM,ii,ii,ii),
    (ii,ii,MM,ii,ii,ii),
    (ii,ii,MM,ii,ii,ii),
    (ii,ii,MM,ii,ii,ii),
    (MM,MM,MM,MM,MM,MM));

  KAR103: array[1..8, 1..7] of TSayi1 = (
    (ii,MM,MM,MM,ii,MM,MM),
    (MM,ii,ii,ii,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,MM,MM,ii),
    (ii,MM,MM,MM,ii,MM,ii),
    (ii,ii,ii,ii,ii,MM,ii),
    (ii,MM,MM,MM,MM,ii,ii));

  KAR104: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,ii,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii,ii),
    (ii,MM,ii,MM,MM,ii,ii),
    (ii,MM,MM,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,MM,MM,ii,MM,MM,MM));

  KAR105: array[1..8, 1..5] of TSayi1 = (
    (ii,ii,MM,ii,ii),
    (ii,ii,ii,ii,ii),
    (MM,MM,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (MM,MM,MM,MM,MM));

  KAR106: array[1..10, 1..5] of TSayi1 = (
    (ii,ii,ii,MM,ii),
    (ii,ii,ii,ii,ii),
    (ii,MM,MM,MM,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,MM),
    (MM,MM,MM,MM,ii));

  KAR107: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,ii,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii,ii),
    (ii,MM,ii,MM,MM,MM,MM),
    (ii,MM,ii,ii,MM,ii,ii),
    (ii,MM,MM,MM,ii,ii,ii),
    (ii,MM,ii,MM,ii,ii,ii),
    (ii,MM,ii,ii,MM,ii,ii),
    (MM,MM,ii,ii,MM,MM,MM));

  KAR108: array[1..8, 1..5] of TSayi1 = (
    (ii,MM,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (MM,MM,MM,MM,MM));

  KAR109: array[1..6, 1..8] of TSayi1 = (
    (MM,MM,ii,MM,ii,ii,MM,ii),
    (ii,MM,MM,ii,MM,MM,ii,MM),
    (ii,MM,ii,ii,MM,ii,ii,MM),
    (ii,MM,ii,ii,MM,ii,ii,MM),
    (ii,MM,ii,ii,MM,ii,ii,MM),
    (MM,MM,MM,ii,MM,MM,ii,MM));

  KAR110: array[1..6, 1..7] of TSayi1 = (
    (MM,MM,ii,MM,MM,ii,ii),
    (ii,MM,MM,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,MM,MM,ii,MM,MM,MM));

  KAR111: array[1..6, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii));

  KAR112: array[1..8, 1..6] of TSayi1 = (
    (MM,MM,ii,MM,MM,ii),
    (ii,MM,MM,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii),
    (ii,MM,ii,ii,ii,ii),
    (MM,MM,MM,ii,ii,ii));

  KAR113: array[1..8, 1..7] of TSayi1 = (
    (ii,MM,MM,MM,ii,MM,MM),
    (MM,ii,ii,ii,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,MM,MM,ii),
    (ii,MM,MM,MM,ii,MM,ii),
    (ii,ii,ii,ii,ii,MM,ii),
    (ii,ii,ii,ii,MM,MM,MM));

  KAR114: array[1..6, 1..6] of TSayi1 = (
    (MM,MM,ii,MM,MM,MM),
    (ii,MM,MM,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (MM,MM,MM,MM,MM,ii));

  KAR115: array[1..6, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,MM,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii),
    (ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,MM,MM,MM,MM,ii));

  KAR116: array[1..7, 1..6] of TSayi1 = (
    (ii,MM,ii,ii,ii,ii),
    (MM,MM,MM,MM,MM,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,MM),
    (ii,ii,MM,MM,MM,ii));

  KAR117: array[1..6, 1..7] of TSayi1 = (
    (MM,MM,ii,ii,MM,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,MM,MM,ii),
    (ii,ii,MM,MM,ii,MM,MM));

  KAR118: array[1..6, 1..8] of TSayi1 = (
    (MM,MM,MM,ii,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii,MM,ii,ii),
    (ii,ii,ii,MM,MM,ii,ii,ii),
    (ii,ii,ii,MM,MM,ii,ii,ii));

  KAR119: array[1..6, 1..7] of TSayi1 = (
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,MM,ii,MM,ii),
    (ii,MM,ii,MM,ii,MM,ii),
    (ii,MM,ii,MM,ii,MM,ii),
    (ii,ii,MM,ii,MM,ii,ii));

  KAR120: array[1..6, 1..6] of TSayi1 = (
    (MM,MM,ii,ii,MM,MM),
    (ii,MM,ii,ii,MM,ii),
    (ii,ii,MM,MM,ii,ii),
    (ii,ii,MM,MM,ii,ii),
    (ii,MM,ii,ii,MM,ii),
    (MM,MM,ii,ii,MM,MM));

  KAR121: array[1..8, 1..7] of TSayi1 = (
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,ii,MM,ii,ii),
    (ii,ii,MM,ii,MM,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii,ii),
    (ii,MM,MM,MM,ii,ii,ii));

  KAR122: array[1..6, 1..5] of TSayi1 = (
    (MM,MM,MM,MM,MM),
    (MM,ii,ii,MM,ii),
    (ii,ii,MM,ii,ii),
    (ii,MM,ii,ii,ii),
    (MM,ii,ii,ii,MM),
    (MM,MM,MM,MM,MM));

  KAR123: array[1..9, 1..3] of TSayi1 = (
    (ii,ii,MM),
    (ii,MM,ii),
    (ii,MM,ii),
    (ii,MM,ii),
    (MM,ii,ii),
    (ii,MM,ii),
    (ii,MM,ii),
    (ii,MM,ii),
    (ii,ii,MM));

  KAR124: array[1..10, 1..1] of TSayi1 = (
    (MM),
    (MM),
    (MM),
    (MM),
    (MM),
    (MM),
    (MM),
    (MM),
    (MM),
    (MM));

  KAR125: array[1..9, 1..3] of TSayi1 = (
    (MM,ii,ii),
    (ii,MM,ii),
    (ii,MM,ii),
    (ii,MM,ii),
    (ii,ii,MM),
    (ii,MM,ii),
    (ii,MM,ii),
    (ii,MM,ii),
    (MM,ii,ii));

  KAR126: array[1..2, 1..6] of TSayi1 = (
    (ii,MM,MM,ii,ii,MM),
    (MM,ii,ii,MM,MM,ii));

  KAR128: array[1..11, 1..6] of TSayi1 = (
    (ii,ii,MM,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,MM),
    (ii,ii,MM,MM,MM,ii),
    (ii,ii,ii,MM,ii,ii),
    (ii,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii));

  KAR153: array[1..10, 1..7] of TSayi1 = (
    (ii,ii,MM,ii,ii,MM,ii),
    (ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,MM,MM,MM,ii,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,ii,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii,ii));

  KAR154: array[1..10, 1..7] of TSayi1 = (
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,ii,ii,ii,ii,ii),
    (MM,MM,MM,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii,ii));

  KAR189: array[1..8, 1..8] of TSayi1 = (
    (MM,MM,ii,ii,ii,ii,ii,ii),
    (ii,MM,ii,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii,ii),
    (MM,MM,MM,MM,MM,ii,ii,ii),
    (ii,ii,MM,ii,ii,MM,MM,MM),
    (ii,MM,ii,ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,ii,ii,MM,ii),
    (ii,ii,ii,ii,ii,MM,MM,MM));

  KAR208: array[1..11, 1..7] of TSayi1 = (
    (ii,MM,ii,ii,MM,ii,ii),
    (ii,ii,MM,MM,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii),
    (ii,ii,MM,MM,MM,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,MM,MM,MM),
    (MM,ii,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii,ii));

  KAR221: array[1..10, 1..5] of TSayi1 = (
    (ii,ii,MM,ii,ii),
    (ii,ii,ii,ii,ii),
    (MM,MM,MM,MM,MM),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (MM,MM,MM,MM,MM));

  KAR222: array[1..11, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,ii,MM),
    (MM,ii,ii,ii,MM,MM),
    (MM,ii,ii,ii,ii,ii),
    (ii,MM,MM,MM,MM,ii),
    (ii,ii,ii,ii,ii,MM),
    (ii,ii,ii,ii,ii,MM),
    (MM,MM,ii,ii,ii,MM),
    (MM,ii,MM,MM,MM,ii),
    (ii,ii,ii,MM,ii,ii),
    (ii,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii));

  KAR231: array[1..9, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,ii,MM),
    (MM,ii,ii,ii,MM,MM),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,ii),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii),
    (ii,ii,ii,MM,ii,ii),
    (ii,ii,ii,ii,MM,ii),
    (ii,ii,MM,MM,MM,ii));

  KAR240: array[1..11, 1..7] of TSayi1 = (
    (ii,MM,ii,ii,MM,ii,ii),
    (ii,ii,MM,MM,ii,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii),
    (ii,MM,MM,MM,ii,MM,MM),
    (MM,ii,ii,ii,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,ii,MM,ii),
    (MM,ii,ii,ii,MM,MM,ii),
    (ii,MM,MM,MM,ii,MM,ii),
    (ii,ii,ii,ii,ii,MM,ii),
    (ii,MM,MM,MM,MM,ii,ii));

  KAR246: array[1..8, 1..6] of TSayi1 = (
    (ii,MM,ii,ii,MM,ii),
    (ii,ii,ii,ii,ii,ii),
    (ii,MM,MM,MM,MM,ii),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii));

  KAR252: array[1..8, 1..7] of TSayi1 = (
    (ii,MM,ii,ii,MM,ii,ii),
    (ii,ii,ii,ii,ii,ii,ii),
    (MM,MM,ii,ii,MM,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,ii,MM,ii),
    (ii,MM,ii,ii,MM,MM,ii),
    (ii,ii,MM,MM,ii,MM,MM));

  KAR253: array[1..6, 1..5] of TSayi1 = (
    (MM,MM,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (ii,ii,MM,ii,ii),
    (MM,MM,MM,MM,MM));

  KAR254: array[1..9, 1..6] of TSayi1 = (
    (ii,MM,MM,MM,MM,MM),
    (MM,ii,ii,ii,ii,MM),
    (ii,MM,MM,MM,MM,ii),
    (ii,ii,ii,ii,ii,MM),
    (MM,ii,ii,ii,ii,MM),
    (MM,MM,MM,MM,MM,ii),
    (ii,ii,MM,ii,ii,ii),
    (ii,ii,ii,MM,ii,ii),
    (ii,MM,MM,MM,ii,ii));

  KAR255: array[1..14, 1..8] of TSayi1 = (
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM),
    (MM,MM,MM,MM,MM,MM,MM,MM));

{==============================================================================
  KARakter tanım tablosu
 ==============================================================================}
const
  KarakterListesi: array[0..255] of TKarakter = (
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 01; Yukseklik: 08; YT: 00; DT: 15; Adres: @KAR032),  // boşluk karakteri
    (Genislik: 01; Yukseklik: 10; YT: 04; DT: 02; Adres: @KAR033),  // !
    (Genislik: 05; Yukseklik: 04; YT: 02; DT: 03; Adres: @KAR034),  // "
    (Genislik: 06; Yukseklik: 10; YT: 02; DT: 02; Adres: @KAR035),  // #
    (Genislik: 04; Yukseklik: 10; YT: 03; DT: 02; Adres: @KAR036),  // $
    (Genislik: 05; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR037),  // %
    (Genislik: 05; Yukseklik: 07; YT: 02; DT: 04; Adres: @KAR038),  // &
    (Genislik: 01; Yukseklik: 04; YT: 03; DT: 03; Adres: @KAR039),  // '
    (Genislik: 02; Yukseklik: 10; YT: 04; DT: 03; Adres: @KAR040),  // (
    (Genislik: 02; Yukseklik: 10; YT: 04; DT: 03; Adres: @KAR041),  // )
    (Genislik: 05; Yukseklik: 05; YT: 02; DT: 03; Adres: @KAR042),  // *
    (Genislik: 07; Yukseklik: 07; YT: 01; DT: 04; Adres: @KAR043),  // +
    (Genislik: 03; Yukseklik: 04; YT: 02; DT: 08; Adres: @KAR044),  // ,
    (Genislik: 06; Yukseklik: 01; YT: 02; DT: 07; Adres: @KAR045),  // -
    (Genislik: 02; Yukseklik: 02; YT: 03; DT: 09; Adres: @KAR046),  // .
    (Genislik: 05; Yukseklik: 10; YT: 01; DT: 02; Adres: @KAR047),  // /
    (Genislik: 06; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR048),  // 0
    (Genislik: 05; Yukseklik: 08; YT: 03; DT: 03; Adres: @KAR049),  // 1
    (Genislik: 05; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR050),  // 2
    (Genislik: 05; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR051),  // 3
    (Genislik: 06; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR052),  // 4
    (Genislik: 06; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR053),  // 5
    (Genislik: 05; Yukseklik: 08; YT: 03; DT: 03; Adres: @KAR054),  // 6
    (Genislik: 06; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR055),  // 7
    (Genislik: 06; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR056),  // 8
    (Genislik: 06; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR057),  // 9
    (Genislik: 02; Yukseklik: 06; YT: 04; DT: 05; Adres: @KAR058),  // :
    (Genislik: 03; Yukseklik: 07; YT: 02; DT: 05; Adres: @KAR059),  // ;
    (Genislik: 06; Yukseklik: 07; YT: 02; DT: 04; Adres: @KAR060),  // <
    (Genislik: 06; Yukseklik: 03; YT: 01; DT: 05; Adres: @KAR061),  // =
    (Genislik: 06; Yukseklik: 07; YT: 02; DT: 04; Adres: @KAR062),  // >
    (Genislik: 05; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR063),  // ?
    (Genislik: 05; Yukseklik: 10; YT: 01; DT: 02; Adres: @KAR064),  // @
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR065),  // A
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR066),  // B
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR067),  // C
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR068),  // D
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR069),  // E
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR070),  // F
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR071),  // G
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR072),  // H
    (Genislik: 05; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR073),  // I
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR074),  // J
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR075),  // K
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR076),  // L
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR077),  // M
    (Genislik: 08; Yukseklik: 08; YT: 00; DT: 03; Adres: @KAR078),  // N
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR079),  // O
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR080),  // P
    (Genislik: 07; Yukseklik: 09; YT: 01; DT: 03; Adres: @KAR081),  // Q
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR082),  // R
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR083),  // S
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR084),  // T
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR085),  // U
    (Genislik: 08; Yukseklik: 08; YT: 00; DT: 03; Adres: @KAR086),  // V
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR087),  // W
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR088),  // X
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR089),  // Y
    (Genislik: 05; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR090),  // Z
    (Genislik: 03; Yukseklik: 10; YT: 03; DT: 03; Adres: @KAR091),  // [
    (Genislik: 04; Yukseklik: 10; YT: 01; DT: 02; Adres: @KAR092),  // \
    (Genislik: 03; Yukseklik: 10; YT: 01; DT: 03; Adres: @KAR093),  // ]
    (Genislik: 05; Yukseklik: 04; YT: 01; DT: 02; Adres: @KAR094),  // ^
    (Genislik: 08; Yukseklik: 01; YT: 00; DT: 14; Adres: @KAR095),  // _
    (Genislik: 02; Yukseklik: 02; YT: 03; DT: 03; Adres: @KAR096),  // `
    (Genislik: 07; Yukseklik: 06; YT: 01; DT: 05; Adres: @KAR097),  // a
    (Genislik: 07; Yukseklik: 08; YT: 00; DT: 03; Adres: @KAR098),  // b
    (Genislik: 06; Yukseklik: 06; YT: 01; DT: 05; Adres: @KAR099),  // c
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR100),  // d
    (Genislik: 06; Yukseklik: 06; YT: 01; DT: 05; Adres: @KAR101),  // e
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR102),  // f
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 05; Adres: @KAR103),  // g
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR104),  // h
    (Genislik: 05; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR105),  // i
    (Genislik: 05; Yukseklik: 10; YT: 01; DT: 03; Adres: @KAR106),  // j
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR107),  // k
    (Genislik: 05; Yukseklik: 08; YT: 02; DT: 03; Adres: @KAR108),  // l
    (Genislik: 08; Yukseklik: 06; YT: 00; DT: 05; Adres: @KAR109),  // m
    (Genislik: 07; Yukseklik: 06; YT: 01; DT: 05; Adres: @KAR110),  // n
    (Genislik: 06; Yukseklik: 06; YT: 01; DT: 05; Adres: @KAR111),  // o
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 05; Adres: @KAR112),  // p
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 05; Adres: @KAR113),  // q
    (Genislik: 06; Yukseklik: 06; YT: 01; DT: 05; Adres: @KAR114),  // r
    (Genislik: 06; Yukseklik: 06; YT: 01; DT: 05; Adres: @KAR115),  // s
    (Genislik: 06; Yukseklik: 07; YT: 01; DT: 04; Adres: @KAR116),  // t
    (Genislik: 07; Yukseklik: 06; YT: 01; DT: 05; Adres: @KAR117),  // u
    (Genislik: 08; Yukseklik: 06; YT: 00; DT: 05; Adres: @KAR118),  // v
    (Genislik: 07; Yukseklik: 06; YT: 01; DT: 05; Adres: @KAR119),  // w
    (Genislik: 06; Yukseklik: 06; YT: 02; DT: 05; Adres: @KAR120),  // x
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 05; Adres: @KAR121),  // y
    (Genislik: 05; Yukseklik: 06; YT: 02; DT: 05; Adres: @KAR122),  // z
    (Genislik: 03; Yukseklik: 09; YT: 02; DT: 03; Adres: @KAR123),  // {
    (Genislik: 01; Yukseklik: 10; YT: 04; DT: 03; Adres: @KAR124),  // |
    (Genislik: 03; Yukseklik: 09; YT: 02; DT: 03; Adres: @KAR125),  // }
    (Genislik: 06; Yukseklik: 02; YT: 01; DT: 06; Adres: @KAR126),  // ~
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 06; Yukseklik: 11; YT: 01; DT: 03; Adres: @KAR128),  // Ç
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 05; Yukseklik: 04; YT: 02; DT: 03; Adres: @KAR034),  // sıra: 152
    (Genislik: 07; Yukseklik: 10; YT: 01; DT: 01; Adres: @KAR153),  // Ö
    (Genislik: 07; Yukseklik: 10; YT: 01; DT: 01; Adres: @KAR154),  // Ü
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 08; Yukseklik: 08; YT: 00; DT: 03; Adres: @KAR189),  // ½
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 06; Yukseklik: 11; YT: 01; DT: 03; Adres: @KAR128),  // Ç  (199)
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 07; Yukseklik: 11; YT: 01; DT: 00; Adres: @KAR208),  // Ğ
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 07; Yukseklik: 10; YT: 01; DT: 01; Adres: @KAR153),  // Ö  (214)
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 07; Yukseklik: 10; YT: 01; DT: 01; Adres: @KAR154),  // Ü  (220)
    (Genislik: 05; Yukseklik: 10; YT: 02; DT: 01; Adres: @KAR221),  // İ
    (Genislik: 06; Yukseklik: 11; YT: 01; DT: 03; Adres: @KAR222),  // Ş
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 06; Yukseklik: 09; YT: 01; DT: 05; Adres: @KAR231),  // ç
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 07; Yukseklik: 11; YT: 01; DT: 02; Adres: @KAR240),  // ğ
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 06; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR246),  // ö
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // tanımlanmadı
    (Genislik: 07; Yukseklik: 08; YT: 01; DT: 03; Adres: @KAR252),  // ü
    (Genislik: 05; Yukseklik: 06; YT: 02; DT: 05; Adres: @KAR253),  // ı
    (Genislik: 06; Yukseklik: 09; YT: 01; DT: 05; Adres: @KAR254),  // ş
    (Genislik: 08; Yukseklik: 14; YT: 01; DT: 00; Adres: @KAR255)); // klavye kursörü

implementation

end.

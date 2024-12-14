{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: genel8x16.pas
  Dosya İşlevi: sistem öndeğer yazı tipi karakter setini içerir

  Güncelleme Tarihi: 10/10/2019

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

const
  WW = 1;   // işaretlenecek
  oo = 0;   // işaretlenmeyecek

{==============================================================================
  font tanımlamaları
 ==============================================================================}
const
  KAR033: array[1..10, 1..1] of TSayi1 = (
    (WW),
    (WW),
    (WW),
    (WW),
    (WW),
    (WW),
    (WW),
    (oo),
    (WW),
    (WW));

  KAR034: array[1..4, 1..5] of TSayi1 = (
    (WW,WW,oo,WW,WW),
    (WW,WW,oo,WW,WW),
    (WW,oo,oo,WW,oo),
    (WW,oo,oo,WW,oo));

  KAR035: array[1..10, 1..6] of TSayi1 = (
    (oo,oo,WW,oo,oo,WW),
    (oo,oo,WW,oo,oo,WW),
    (oo,WW,oo,oo,WW,oo),
    (WW,WW,WW,WW,WW,WW),
    (oo,WW,oo,oo,WW,oo),
    (oo,WW,oo,oo,WW,oo),
    (WW,WW,WW,WW,WW,WW),
    (oo,WW,oo,oo,WW,oo),
    (WW,oo,oo,WW,oo,oo),
    (WW,oo,oo,WW,oo,oo));

  KAR036: array[1..10, 1..4] of TSayi1 = (
    (oo,oo,WW,oo),
    (oo,WW,WW,WW),
    (WW,oo,oo,WW),
    (WW,oo,oo,oo),
    (oo,WW,WW,oo),
    (oo,oo,oo,WW),
    (WW,oo,oo,WW),
    (WW,WW,WW,oo),
    (oo,oo,WW,oo),
    (oo,oo,WW,oo));

  KAR037: array[1..8, 1..5] of TSayi1 = (
    (oo,WW,oo,oo,oo),
    (WW,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,WW),
    (WW,WW,WW,oo,oo),
    (oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,WW),
    (oo,oo,oo,WW,oo));

  KAR038: array[1..7, 1..5] of TSayi1 = (
    (oo,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo),
    (oo,WW,oo,oo,oo),
    (oo,WW,WW,oo,oo),
    (WW,oo,WW,oo,WW),
    (WW,oo,oo,WW,oo),
    (oo,WW,WW,WW,WW));

  KAR039: array[1..4, 1..1] of TSayi1 = (
    (WW),
    (WW),
    (WW),
    (WW));

  KAR040: array[1..10, 1..2] of TSayi1 = (
    (oo,WW),
    (oo,WW),
    (WW,oo),
    (WW,oo),
    (WW,oo),
    (WW,oo),
    (WW,oo),
    (WW,oo),
    (oo,WW),
    (oo,WW));

  KAR041: array[1..10, 1..2] of TSayi1 = (
    (WW,oo),
    (WW,oo),
    (oo,WW),
    (oo,WW),
    (oo,WW),
    (oo,WW),
    (oo,WW),
    (oo,WW),
    (WW,oo),
    (WW,oo));

  KAR042: array[1..5, 1..5] of TSayi1 = (
    (oo,oo,WW,oo,oo),
    (WW,WW,WW,WW,WW),
    (oo,oo,WW,oo,oo),
    (oo,WW,oo,WW,oo),
    (oo,WW,oo,WW,oo));

  KAR043: array[1..7, 1..7] of TSayi1 = (
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (WW,WW,WW,WW,WW,WW,WW),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo));

  KAR044: array[1..4, 1..3] of TSayi1 = (
    (oo,WW,WW),
    (oo,WW,oo),
    (WW,WW,oo),
    (WW,oo,oo));

  KAR045: array[1..1, 1..6] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW));

  KAR046: array[1..2, 1..2] of TSayi1 = (
    (WW,WW),
    (WW,WW));

  KAR047: array[1..10, 1..5] of TSayi1 = (
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,WW,oo),
    (oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo),
    (oo,WW,oo,oo,oo),
    (WW,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo));

  KAR048: array[1..8, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo));

  KAR049: array[1..8, 1..5] of TSayi1 = (
    (oo,oo,WW,oo,oo),
    (WW,WW,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (WW,WW,WW,WW,WW));

  KAR050: array[1..8, 1..5] of TSayi1 = (
    (oo,WW,WW,WW,oo),
    (WW,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo),
    (WW,oo,oo,oo,WW),
    (WW,WW,WW,WW,WW));

  KAR051: array[1..8, 1..5] of TSayi1 = (
    (oo,WW,WW,WW,oo),
    (WW,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,WW,WW,oo),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,WW),
    (oo,WW,WW,WW,oo));

  KAR052: array[1..8, 1..6] of TSayi1 = (
    (oo,oo,oo,WW,WW,oo),
    (oo,oo,WW,oo,WW,oo),
    (oo,WW,oo,oo,WW,oo),
    (oo,WW,oo,oo,WW,oo),
    (WW,WW,WW,WW,WW,WW),
    (oo,oo,oo,oo,WW,oo),
    (oo,oo,oo,oo,WW,oo),
    (oo,oo,oo,WW,WW,WW));

  KAR053: array[1..8, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,WW,WW),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,WW,WW,WW,oo),
    (oo,oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo));

  KAR054: array[1..8, 1..5] of TSayi1 = (
    (oo,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo),
    (WW,oo,oo,oo,oo),
    (WW,WW,WW,WW,oo),
    (WW,oo,oo,oo,WW),
    (WW,oo,oo,oo,WW),
    (WW,oo,oo,oo,WW),
    (oo,WW,WW,WW,oo));

  KAR055: array[1..8, 1..6] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW,oo),
    (oo,oo,oo,oo,WW,oo),
    (oo,oo,oo,WW,oo,oo),
    (oo,oo,oo,WW,oo,oo),
    (oo,oo,oo,WW,oo,oo));

  KAR056: array[1..8, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo));

  KAR057: array[1..8, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,WW),
    (oo,oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW,oo),
    (WW,WW,WW,WW,oo,oo));

  KAR058: array[1..6, 1..2] of TSayi1 = (
    (WW,WW),
    (WW,WW),
    (oo,oo),
    (oo,oo),
    (WW,WW),
    (WW,WW));

  KAR059: array[1..7, 1..3] of TSayi1 = (
    (oo,WW,WW),
    (oo,WW,WW),
    (oo,oo,oo),
    (oo,oo,oo),
    (oo,WW,WW),
    (WW,WW,oo),
    (WW,oo,oo));

  KAR060: array[1..7, 1..6] of TSayi1 = (
    (oo,oo,oo,oo,oo,WW),
    (oo,oo,oo,WW,WW,oo),
    (oo,oo,WW,oo,oo,oo),
    (WW,WW,oo,oo,oo,oo),
    (oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,WW,oo),
    (oo,oo,oo,oo,oo,WW));

  KAR061: array[1..3, 1..6] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW),
    (oo,oo,oo,oo,oo,oo),
    (WW,WW,WW,WW,WW,WW));

  KAR062: array[1..7, 1..6] of TSayi1 = (
    (WW,oo,oo,oo,oo,oo),
    (oo,WW,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo),
    (oo,oo,oo,oo,WW,WW),
    (oo,oo,oo,WW,oo,oo),
    (oo,WW,WW,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo));

  KAR063: array[1..8, 1..5] of TSayi1 = (
    (oo,WW,WW,WW,oo),
    (WW,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,oo,oo,oo),
    (oo,WW,WW,oo,oo));

  KAR064: array[1..10, 1..5] of TSayi1 = (
    (oo,WW,WW,WW,oo),
    (WW,oo,oo,oo,WW),
    (WW,oo,oo,oo,WW),
    (WW,oo,oo,WW,WW),
    (WW,oo,WW,oo,WW),
    (WW,oo,WW,oo,WW),
    (WW,oo,oo,WW,WW),
    (WW,oo,oo,oo,oo),
    (WW,oo,oo,oo,WW),
    (oo,WW,WW,WW,oo));

  KAR065: array[1..8, 1..7] of TSayi1 = (
    (oo,oo,WW,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,WW,oo,WW,oo,oo),
    (oo,oo,WW,oo,WW,oo,oo),
    (oo,oo,WW,oo,WW,oo,oo),
    (oo,oo,WW,WW,WW,oo,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,WW,WW,oo,WW,WW,WW));

  KAR066: array[1..8, 1..6] of TSayi1 = (
    (WW,WW,WW,WW,WW,oo),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (WW,WW,WW,WW,WW,oo));

  KAR067: array[1..8, 1..6] of TSayi1 = (
    (oo,oo,WW,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,WW),
    (oo,oo,WW,WW,WW,oo));

  KAR068: array[1..8, 1..6] of TSayi1 = (
    (WW,WW,WW,WW,oo,oo),
    (oo,WW,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,WW,oo),
    (WW,WW,WW,WW,oo,oo));

  KAR069: array[1..8, 1..6] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,WW,oo,oo),
    (oo,WW,WW,WW,oo,oo),
    (oo,WW,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,WW),
    (WW,WW,WW,WW,WW,WW));

  KAR070: array[1..8, 1..6] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,WW,oo,oo),
    (oo,WW,WW,WW,oo,oo),
    (oo,WW,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (WW,WW,WW,oo,oo,oo));

  KAR071: array[1..8, 1..7] of TSayi1 = (
    (oo,oo,WW,WW,WW,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,WW,WW,WW),
    (WW,oo,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo,oo));

  KAR072: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,WW,WW,WW,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,WW,WW,oo,WW,WW,WW));

  KAR073: array[1..8, 1..5] of TSayi1 = (
    (WW,WW,WW,WW,WW),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (WW,WW,WW,WW,WW));

  KAR074: array[1..8, 1..6] of TSayi1 = (
    (oo,oo,WW,WW,WW,WW),
    (oo,oo,oo,oo,WW,oo),
    (oo,oo,oo,oo,WW,oo),
    (oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,WW,oo),
    (oo,WW,WW,WW,oo,oo));

  KAR075: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,WW,oo,oo),
    (oo,WW,oo,WW,oo,oo,oo),
    (oo,WW,WW,WW,oo,oo,oo),
    (oo,WW,oo,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,WW,WW,oo,oo,WW,WW));

  KAR076: array[1..8, 1..6] of TSayi1 = (
    (WW,WW,WW,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (WW,WW,WW,WW,WW,WW));

  KAR077: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,WW,oo,WW,WW,oo),
    (oo,WW,WW,oo,WW,WW,oo),
    (oo,WW,oo,WW,oo,WW,oo),
    (oo,WW,oo,WW,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,WW,WW,oo,WW,WW,WW));

  KAR078: array[1..8, 1..8] of TSayi1 = (
    (WW,WW,WW,oo,oo,WW,WW,WW),
    (oo,WW,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,WW,oo,oo,WW,oo),
    (oo,WW,oo,WW,oo,oo,WW,oo),
    (oo,WW,oo,oo,WW,oo,WW,oo),
    (oo,WW,oo,oo,WW,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,WW,oo),
    (WW,WW,WW,oo,oo,WW,WW,oo));

  KAR079: array[1..8, 1..7] of TSayi1 = (
    (oo,oo,WW,WW,WW,oo,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo,oo));

  KAR080: array[1..8, 1..6] of TSayi1 = (
    (WW,WW,WW,WW,WW,oo),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (WW,WW,WW,oo,oo,oo));

  KAR081: array[1..9, 1..7] of TSayi1 = (
    (oo,oo,WW,WW,WW,oo,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo,oo),
    (oo,oo,WW,WW,WW,WW,WW));

  KAR082: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,WW,WW,oo,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,WW,WW,WW,oo,oo),
    (oo,WW,oo,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,WW,WW,oo,oo,oo,WW));

  KAR083: array[1..8, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,oo,WW),
    (WW,oo,oo,oo,WW,WW),
    (WW,oo,oo,oo,oo,oo),
    (oo,WW,WW,WW,WW,oo),
    (oo,oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,oo,WW),
    (WW,WW,oo,oo,oo,WW),
    (WW,oo,WW,WW,WW,oo));

  KAR084: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW,WW),
    (WW,oo,oo,WW,oo,oo,WW),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,WW,WW,WW,oo,oo));

  KAR085: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo,oo));

  KAR086: array[1..8, 1..8] of TSayi1 = (
    (WW,WW,WW,oo,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo,WW,oo,oo),
    (oo,oo,oo,WW,WW,oo,oo,oo),
    (oo,oo,oo,WW,WW,oo,oo,oo));

  KAR087: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,WW,oo,WW,oo),
    (oo,WW,oo,WW,oo,WW,oo),
    (oo,WW,oo,WW,oo,WW,oo),
    (oo,WW,oo,WW,oo,WW,oo),
    (oo,oo,WW,oo,WW,oo,oo));

  KAR088: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,WW,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,WW,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,WW,WW,oo,WW,WW,WW));

  KAR089: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,WW,oo,oo),
    (oo,oo,WW,oo,WW,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,WW,WW,WW,oo,oo));

  KAR090: array[1..8, 1..5] of TSayi1 = (
    (WW,WW,WW,WW,WW),
    (WW,oo,oo,oo,WW),
    (oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo),
    (WW,oo,oo,oo,WW),
    (WW,WW,WW,WW,WW));

  KAR091: array[1..10, 1..3] of TSayi1 = (
    (WW,WW,WW),
    (WW,oo,oo),
    (WW,oo,oo),
    (WW,oo,oo),
    (WW,oo,oo),
    (WW,oo,oo),
    (WW,oo,oo),
    (WW,oo,oo),
    (WW,oo,oo),
    (WW,WW,WW));

  KAR092: array[1..10, 1..4] of TSayi1 = (
    (WW,oo,oo,oo),
    (WW,oo,oo,oo),
    (oo,WW,oo,oo),
    (oo,WW,oo,oo),
    (oo,oo,WW,oo),
    (oo,oo,WW,oo),
    (oo,oo,WW,oo),
    (oo,oo,oo,WW),
    (oo,oo,oo,WW),
    (oo,oo,oo,WW));

  KAR093: array[1..10, 1..3] of TSayi1 = (
    (WW,WW,WW),
    (oo,oo,WW),
    (oo,oo,WW),
    (oo,oo,WW),
    (oo,oo,WW),
    (oo,oo,WW),
    (oo,oo,WW),
    (oo,oo,WW),
    (oo,oo,WW),
    (WW,WW,WW));

  KAR094: array[1..4, 1..5] of TSayi1 = (
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,WW,oo,WW,oo),
    (WW,oo,oo,oo,WW));

  KAR095: array[1..1, 1..8] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW,WW,WW));

  KAR096: array[1..2, 1..2] of TSayi1 = (
    (WW,oo),
    (oo,WW));

  KAR097: array[1..6, 1..7] of TSayi1 = (
    (oo,WW,WW,WW,WW,oo,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (oo,WW,WW,WW,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,WW,WW,oo),
    (oo,WW,WW,WW,oo,WW,WW));

  KAR098: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,oo,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo,oo),
    (oo,WW,oo,WW,WW,WW,oo),
    (oo,WW,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,oo,oo,oo,WW),
    (WW,WW,oo,WW,WW,WW,oo));

  KAR099: array[1..6, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,oo,WW),
    (WW,oo,oo,oo,WW,WW),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo));

  KAR100: array[1..8, 1..7] of TSayi1 = (
    (oo,oo,oo,oo,WW,WW,oo),
    (oo,oo,oo,oo,oo,WW,oo),
    (oo,WW,WW,WW,oo,WW,oo),
    (WW,oo,oo,oo,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,WW,WW,oo),
    (oo,WW,WW,WW,oo,WW,WW));

  KAR101: array[1..6, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW),
    (WW,WW,WW,WW,WW,WW),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo),
    (oo,WW,WW,WW,WW,WW));

  KAR102: array[1..8, 1..6] of TSayi1 = (
    (oo,oo,oo,WW,WW,WW),
    (oo,oo,WW,oo,oo,oo),
    (WW,WW,WW,WW,WW,WW),
    (oo,oo,WW,oo,oo,oo),
    (oo,oo,WW,oo,oo,oo),
    (oo,oo,WW,oo,oo,oo),
    (oo,oo,WW,oo,oo,oo),
    (WW,WW,WW,WW,WW,WW));

  KAR103: array[1..8, 1..7] of TSayi1 = (
    (oo,WW,WW,WW,oo,WW,WW),
    (WW,oo,oo,oo,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,WW,WW,oo),
    (oo,WW,WW,WW,oo,WW,oo),
    (oo,oo,oo,oo,oo,WW,oo),
    (oo,WW,WW,WW,WW,oo,oo));

  KAR104: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,oo,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo,oo),
    (oo,WW,oo,WW,WW,oo,oo),
    (oo,WW,WW,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,WW,WW,oo,WW,WW,WW));

  KAR105: array[1..8, 1..5] of TSayi1 = (
    (oo,oo,WW,oo,oo),
    (oo,oo,oo,oo,oo),
    (WW,WW,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (WW,WW,WW,WW,WW));

  KAR106: array[1..10, 1..5] of TSayi1 = (
    (oo,oo,oo,WW,oo),
    (oo,oo,oo,oo,oo),
    (oo,WW,WW,WW,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,WW),
    (WW,WW,WW,WW,oo));

  KAR107: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,oo,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo,oo),
    (oo,WW,oo,WW,WW,WW,WW),
    (oo,WW,oo,oo,WW,oo,oo),
    (oo,WW,WW,WW,oo,oo,oo),
    (oo,WW,oo,WW,oo,oo,oo),
    (oo,WW,oo,oo,WW,oo,oo),
    (WW,WW,oo,oo,WW,WW,WW));

  KAR108: array[1..8, 1..5] of TSayi1 = (
    (oo,WW,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (WW,WW,WW,WW,WW));

  KAR109: array[1..6, 1..8] of TSayi1 = (
    (WW,WW,oo,WW,oo,oo,WW,oo),
    (oo,WW,WW,oo,WW,WW,oo,WW),
    (oo,WW,oo,oo,WW,oo,oo,WW),
    (oo,WW,oo,oo,WW,oo,oo,WW),
    (oo,WW,oo,oo,WW,oo,oo,WW),
    (WW,WW,WW,oo,WW,WW,oo,WW));

  KAR110: array[1..6, 1..7] of TSayi1 = (
    (WW,WW,oo,WW,WW,oo,oo),
    (oo,WW,WW,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,WW,WW,oo,WW,WW,WW));

  KAR111: array[1..6, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo));

  KAR112: array[1..8, 1..6] of TSayi1 = (
    (WW,WW,oo,WW,WW,oo),
    (oo,WW,WW,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo),
    (oo,WW,oo,oo,oo,oo),
    (WW,WW,WW,oo,oo,oo));

  KAR113: array[1..8, 1..7] of TSayi1 = (
    (oo,WW,WW,WW,oo,WW,WW),
    (WW,oo,oo,oo,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,WW,WW,oo),
    (oo,WW,WW,WW,oo,WW,oo),
    (oo,oo,oo,oo,oo,WW,oo),
    (oo,oo,oo,oo,WW,WW,WW));

  KAR114: array[1..6, 1..6] of TSayi1 = (
    (WW,WW,oo,WW,WW,WW),
    (oo,WW,WW,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (WW,WW,WW,WW,WW,oo));

  KAR115: array[1..6, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,WW,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo),
    (oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,WW,WW,WW,WW,oo));

  KAR116: array[1..7, 1..6] of TSayi1 = (
    (oo,WW,oo,oo,oo,oo),
    (WW,WW,WW,WW,WW,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,WW),
    (oo,oo,WW,WW,WW,oo));

  KAR117: array[1..6, 1..7] of TSayi1 = (
    (WW,WW,oo,oo,WW,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,WW,WW,oo),
    (oo,oo,WW,WW,oo,WW,WW));

  KAR118: array[1..6, 1..8] of TSayi1 = (
    (WW,WW,WW,oo,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo,WW,oo,oo),
    (oo,oo,oo,WW,WW,oo,oo,oo),
    (oo,oo,oo,WW,WW,oo,oo,oo));

  KAR119: array[1..6, 1..7] of TSayi1 = (
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,WW,oo,WW,oo),
    (oo,WW,oo,WW,oo,WW,oo),
    (oo,WW,oo,WW,oo,WW,oo),
    (oo,oo,WW,oo,WW,oo,oo));

  KAR120: array[1..6, 1..6] of TSayi1 = (
    (WW,WW,oo,oo,WW,WW),
    (oo,WW,oo,oo,WW,oo),
    (oo,oo,WW,WW,oo,oo),
    (oo,oo,WW,WW,oo,oo),
    (oo,WW,oo,oo,WW,oo),
    (WW,WW,oo,oo,WW,WW));

  KAR121: array[1..8, 1..7] of TSayi1 = (
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,oo,WW,oo,oo),
    (oo,oo,WW,oo,WW,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo,oo),
    (oo,WW,WW,WW,oo,oo,oo));

  KAR122: array[1..6, 1..5] of TSayi1 = (
    (WW,WW,WW,WW,WW),
    (WW,oo,oo,WW,oo),
    (oo,oo,WW,oo,oo),
    (oo,WW,oo,oo,oo),
    (WW,oo,oo,oo,WW),
    (WW,WW,WW,WW,WW));

  KAR123: array[1..9, 1..3] of TSayi1 = (
    (oo,oo,WW),
    (oo,WW,oo),
    (oo,WW,oo),
    (oo,WW,oo),
    (WW,oo,oo),
    (oo,WW,oo),
    (oo,WW,oo),
    (oo,WW,oo),
    (oo,oo,WW));

  KAR124: array[1..10, 1..1] of TSayi1 = (
    (WW),
    (WW),
    (WW),
    (WW),
    (WW),
    (WW),
    (WW),
    (WW),
    (WW),
    (WW));

  KAR125: array[1..9, 1..3] of TSayi1 = (
    (WW,oo,oo),
    (oo,WW,oo),
    (oo,WW,oo),
    (oo,WW,oo),
    (oo,oo,WW),
    (oo,WW,oo),
    (oo,WW,oo),
    (oo,WW,oo),
    (WW,oo,oo));

  KAR126: array[1..2, 1..6] of TSayi1 = (
    (oo,WW,WW,oo,oo,WW),
    (WW,oo,oo,WW,WW,oo));

  KAR128: array[1..11, 1..6] of TSayi1 = (
    (oo,oo,WW,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,WW),
    (oo,oo,WW,WW,WW,oo),
    (oo,oo,oo,WW,oo,oo),
    (oo,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo));

  KAR153: array[1..10, 1..7] of TSayi1 = (
    (oo,oo,WW,oo,oo,WW,oo),
    (oo,oo,oo,oo,oo,oo,oo),
    (oo,oo,WW,WW,WW,oo,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,oo,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo,oo));

  KAR154: array[1..10, 1..7] of TSayi1 = (
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,oo,oo,oo,oo,oo),
    (WW,WW,WW,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo,oo));

  KAR189: array[1..8, 1..8] of TSayi1 = (
    (WW,WW,oo,oo,oo,oo,oo,oo),
    (oo,WW,oo,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo,oo),
    (WW,WW,WW,WW,WW,oo,oo,oo),
    (oo,oo,WW,oo,oo,WW,WW,WW),
    (oo,WW,oo,oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,oo,oo,WW,oo),
    (oo,oo,oo,oo,oo,WW,WW,WW));

  KAR208: array[1..11, 1..7] of TSayi1 = (
    (oo,WW,oo,oo,WW,oo,oo),
    (oo,oo,WW,WW,oo,oo,oo),
    (oo,oo,oo,oo,oo,oo,oo),
    (oo,oo,WW,WW,WW,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,WW,WW,WW),
    (WW,oo,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo,oo));

  KAR221: array[1..10, 1..5] of TSayi1 = (
    (oo,oo,WW,oo,oo),
    (oo,oo,oo,oo,oo),
    (WW,WW,WW,WW,WW),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (WW,WW,WW,WW,WW));

  KAR222: array[1..11, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,oo,WW),
    (WW,oo,oo,oo,WW,WW),
    (WW,oo,oo,oo,oo,oo),
    (oo,WW,WW,WW,WW,oo),
    (oo,oo,oo,oo,oo,WW),
    (oo,oo,oo,oo,oo,WW),
    (WW,WW,oo,oo,oo,WW),
    (WW,oo,WW,WW,WW,oo),
    (oo,oo,oo,WW,oo,oo),
    (oo,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo));

  KAR231: array[1..9, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,oo,WW),
    (WW,oo,oo,oo,WW,WW),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,oo),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo),
    (oo,oo,oo,WW,oo,oo),
    (oo,oo,oo,oo,WW,oo),
    (oo,oo,WW,WW,WW,oo));

  KAR240: array[1..11, 1..7] of TSayi1 = (
    (oo,WW,oo,oo,WW,oo,oo),
    (oo,oo,WW,WW,oo,oo,oo),
    (oo,oo,oo,oo,oo,oo,oo),
    (oo,WW,WW,WW,oo,WW,WW),
    (WW,oo,oo,oo,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,oo,WW,oo),
    (WW,oo,oo,oo,WW,WW,oo),
    (oo,WW,WW,WW,oo,WW,oo),
    (oo,oo,oo,oo,oo,WW,oo),
    (oo,WW,WW,WW,WW,oo,oo));

  KAR246: array[1..8, 1..6] of TSayi1 = (
    (oo,WW,oo,oo,WW,oo),
    (oo,oo,oo,oo,oo,oo),
    (oo,WW,WW,WW,WW,oo),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo));

  KAR252: array[1..8, 1..7] of TSayi1 = (
    (oo,WW,oo,oo,WW,oo,oo),
    (oo,oo,oo,oo,oo,oo,oo),
    (WW,WW,oo,oo,WW,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,oo,WW,oo),
    (oo,WW,oo,oo,WW,WW,oo),
    (oo,oo,WW,WW,oo,WW,WW));

  KAR253: array[1..6, 1..5] of TSayi1 = (
    (WW,WW,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (oo,oo,WW,oo,oo),
    (WW,WW,WW,WW,WW));

  KAR254: array[1..9, 1..6] of TSayi1 = (
    (oo,WW,WW,WW,WW,WW),
    (WW,oo,oo,oo,oo,WW),
    (oo,WW,WW,WW,WW,oo),
    (oo,oo,oo,oo,oo,WW),
    (WW,oo,oo,oo,oo,WW),
    (WW,WW,WW,WW,WW,oo),
    (oo,oo,WW,oo,oo,oo),
    (oo,oo,oo,WW,oo,oo),
    (oo,WW,WW,WW,oo,oo));

  KAR255: array[1..14, 1..8] of TSayi1 = (
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW),
    (WW,WW,WW,WW,WW,WW,WW,WW));

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
    (Genislik: 00; Yukseklik: 00; YT: 00; DT: 00; Adres: nil),      // boşluk karakteri
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

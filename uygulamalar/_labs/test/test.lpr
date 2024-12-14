program test;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: test.lpr
  Program İşlevi: ELERA İşletim Sistemi programları için test işlemlerini gerçekleştirir

  Güncelleme Tarihi: 16/03/2013

 ==============================================================================}
{$mode objfpc}
type

  { TObj }

  PObj = ^TObj;
  TObj = object
    //procedure Init;
  private
    Say1: Integer;
    Yazi: string;
  public
    function Create1: TObj;
    constructor Create;
  end;

var
  Obj1: TObj;

function TObj.Create1: TObj;
begin

end;

constructor TObj.Create;
begin

end;

{ TObj }
{
constructor TObj.Create;
begin

end;

procedure TObj.Init;
  var
  a: Pointer;
begin
  a := @self;
end;
}
begin

  //Obj1.Create;
  Obj1 := Obj1.Create1;// := Obj.Create;

  //Obj1 := Pointer(1000);

  Obj1.Say1 := 100;
  Obj1.Yazi := 'merhaba';

end.

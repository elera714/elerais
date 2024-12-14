{$mode objfpc}
{$asmmode intel}
unit test2;

interface

uses global, shared;

type
//  PListe2 = ^TListe2;

//  PListe1 = ^TListe1;
  TListe1 = class
  private
    //FList: PListe2;
  public
    FCount: Integer;
    constructor Create;
  end;

  { TList2 }

{  TListe2 = object(TListe1)
  public
    constructor Create;
  published
    property Count: Integer read FCount write FCount;
  end;}

//procedure TestList;
//procedure SetP32(X, Y: Integer; Color: TColor);

implementation

uses macmsg;

//var
//  T: TListe2;

constructor TListe1.Create;
begin

  FCount := 10;

  //MSG_SH('TList2.Init', FCount, 8);
end;

procedure SetP32(X, Y: Integer; Color: TColor);
  var
  Addr: LongWord;
begin

  // belirtilen koordinata konumlan
  Addr := (Y * 3000) + (X * 4);
  Addr += $E0000000;

  // pixel'i belirtilen renk ile iþaretle
  Addr := Color;
end;

procedure TestList;
  var
  C: Integer;
begin

//  T.Create; //:= TList1.Create; //.Count;

  //t.Count := 10;

  //MSG_SH('Deðer1: ', LongWord(@T), 8);
  //MSG_SH('Deðer2: ', LongWord(@T.Count), 8);
//  MSG_SH('Deðer2: ', T.Count, 8);
end;

{ TList2 }

{constructor TListe2.Create;
  var
  i: Integer;
begin

  inherited Create;
  i := Count;
  Inc(i);
  Count := i;

  MSG_SH('TList2.Init', FCount, 8);
end;}

{ TList1 }

end.


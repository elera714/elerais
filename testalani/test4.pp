// aşağıdaki en basit yapı, derleyicinin assembler kodları incelenerek elera işletim sistemine kazandırılmalıdır. 22062019

unit test4;

{$mode objfpc}

interface

type
  PTest1 = ^TTest1;
  TTest1 = class
  private
    FVal1: Integer;
  protected
    procedure Test1(AVal1: Integer); virtual; abstract;
  published
    property Val1: Integer read FVal1;
  end;

  PTest2 = ^TTest2;
  TTest2 = class(TTest1)
  public
    procedure Test1(AVal1: Integer); override;
  end; 

implementation

procedure TTest2.Test1(AVal1: Integer);
begin

	FVal1 := AVal1;
end;

end.
unit UStringTable;

interface

uses
  Classes, SysUtils;

type
  { TStringTable }

  TStringTable = class
  private
    FCells: array of array of string;
    FSize: TPoint;
    function GetCell(X, Y: Integer): string;
    function GetColCount: Integer;
    function GetRowCount: Integer;
    procedure SetCell(X, Y: Integer; AValue: string);
    procedure SetColCount(AValue: Integer);
    procedure SetRowCount(AValue: Integer);
    procedure SetSize(AValue: TPoint);
  public
    property Cells[X, Y: Integer]: string read GetCell write SetCell;
    property ColCount: Integer read GetColCount write SetColCount;
    property RowCount: Integer read GetRowCount write SetRowCount;
    property Size: TPoint read FSize write SetSize;
  end;


implementation

{ TStringTable }

function TStringTable.GetCell(X, Y: Integer): string;
begin
  Result := FCells[Y, X];
end;

function TStringTable.GetColCount: Integer;
begin
  Result := Size.x;
end;

function TStringTable.GetRowCount: Integer;
begin
  Result := Size.Y;
end;

procedure TStringTable.SetCell(X, Y: Integer; AValue: string);
begin
  FCells[Y, X] := AValue;
end;

procedure TStringTable.SetColCount(AValue: Integer);
begin
  Size := Point(AValue, RowCount);
end;

procedure TStringTable.SetRowCount(AValue: Integer);
begin
  Size := Point(ColCount, AValue);
end;

procedure TStringTable.SetSize(AValue: TPoint);
begin
  if (FSize.X = AValue.X) and (FSize.Y = AValue.Y) then Exit;
  FSize := AValue;
  SetLength(FCells, FSize.Y, FSize.X);
end;


end.


unit UMemory;

interface

uses
  Classes, SysUtils;

type

  { TMemory }

  TMemory = class
  private
    FData: PByte;
    FSize: Integer;
    function GetItem(Index: Integer): Byte;
    procedure SetItem(Index: Integer; AValue: Byte);
    procedure SetSize(AValue: Integer); virtual;
  public
    procedure Clear(Value: Byte = 0);
    procedure Assign(Source: TMemory);
    constructor Create;
    destructor Destroy; override;
    procedure WriteMemory(Position: Integer; Memory: TMemory);
    procedure ReadMemory(Position: Integer; Memory: TMemory);
    property Data: PByte read FData;
    property Size: Integer read FSize write SetSize;
    property Items[Index: Integer]: Byte read GetItem write SetItem; default;
  end;

  { TPositionMemory }

  TPositionMemory = class(TMemory)
  private
    FPosition: Integer;
  protected
    procedure SetSize(AValue: Integer); override;
  public
    procedure WriteByte(Value: Byte);
    function ReadByte: Byte;
    property Position: Integer read FPosition write FPosition;
  end;


implementation

{ TPositionMemory }

procedure TPositionMemory.SetSize(AValue: Integer);
begin
  inherited;
  if FPosition > FSize then FPosition := FSize;
end;

procedure TPositionMemory.WriteByte(Value: Byte);
begin
  if FPosition >= Size then Size := FPosition + 1;
  Items[FPosition] := Value;
  Inc(FPosition);
end;

function TPositionMemory.ReadByte: Byte;
begin
  if FPosition >= Size then Size := FPosition + 1;
  Result := Items[FPosition];
  Inc(FPosition);
end;

{ TMemory }

procedure TMemory.SetSize(AValue: Integer);
begin
  if FSize = AValue then Exit;
  FSize := AValue;
  FData := ReAllocMem(FData, FSize);
end;

function TMemory.GetItem(Index: Integer): Byte;
begin
  Result := PByte(FData + Index)^;
end;

procedure TMemory.SetItem(Index: Integer; AValue: Byte);
begin
  PByte(FData + Index)^ := AValue;
end;

procedure TMemory.Clear(Value: Byte);
begin
  FillChar(FData^, Size, Value);
end;

procedure TMemory.Assign(Source: TMemory);
begin
  Size := Source.Size;
  Move(Source.Data^, FData^, Size);
end;

constructor TMemory.Create;
begin
  FData := nil;
  FSize := 0;
end;

destructor TMemory.Destroy;
begin
  Size := 0;
  inherited;
end;

procedure TMemory.WriteMemory(Position: Integer; Memory: TMemory);
begin
  Move(Memory.FData, PByte(PByte(@FData) + Position)^, Memory.Size);
end;

procedure TMemory.ReadMemory(Position: Integer; Memory: TMemory);
begin
  Move(PByte(PByte(@FData) + Position)^, Memory.FData, Memory.Size);
end;

end.


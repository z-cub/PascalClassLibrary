unit USyncCounter;

interface

uses
  Classes, SysUtils, SyncObjs;

type

  { TSyncCounter }

  TSyncCounter = class
  private
    Top: Integer;
    Current: Integer;
  public
    Lock: TCriticalSection;
    function Allocate: Integer;
    function CurrentEqualTo(AValue: Integer): Boolean;
    procedure Increment;
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TSyncCounter);
  end;


implementation

{ TSyncCounter }

function TSyncCounter.Allocate: Integer;
begin
  try
    Lock.Acquire;
    Result := Top;
    Inc(Top);
  finally
    Lock.Release;
  end;
end;

function TSyncCounter.CurrentEqualTo(AValue: Integer): Boolean;
begin
  try
    Lock.Acquire;
    Result := AValue = Current;
  finally
    Lock.Release;
  end;
end;

procedure TSyncCounter.Increment;
begin
  try
    Lock.Acquire;
    Inc(Current);
  finally
    Lock.Release;
  end;
end;

constructor TSyncCounter.Create;
begin
  Lock := TCriticalSection.Create;
end;

destructor TSyncCounter.Destroy;
begin
  Lock.Free;
  inherited;
end;

procedure TSyncCounter.Assign(Source: TSyncCounter);
begin
  Current := Source.Current;
  Top := Source.Top;
end;

end.


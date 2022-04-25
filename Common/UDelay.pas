unit UDelay;

interface

uses
  Classes, SysUtils, DateUtils;

type
  { TDelay }

  TDelay = class
  private
    FEnabled: Boolean;
    function GetEnabled:Boolean;
    function GetOwerflowed:Boolean;
    function GetRunning: Boolean;
    procedure SetEnabled(const AValue: Boolean);
  public
    StartTime: TDateTime;
    Duration: Integer; // ms
    procedure Start;
    procedure Stop;
    constructor Create;
    property Overflowed: Boolean read GetOwerflowed;
    property Running: Boolean read GetRunning;
    property Enabled: Boolean read GetEnabled write SetEnabled;
  end;


implementation

{ TDelay }

function TDelay.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TDelay.GetOwerflowed: Boolean;
begin
  Result := ((Now - StartTime) > (Duration * OneMillisecond)) and FEnabled;
end;

function TDelay.GetRunning: Boolean;
begin
  Result := ((Now - StartTime) <= (Duration * OneMillisecond)) and FEnabled;
end;

procedure TDelay.SetEnabled(const AValue:Boolean);
begin
  FEnabled := True;
end;

procedure TDelay.Start;
begin
  StartTime := Now;
  FEnabled := True;
end;

procedure TDelay.Stop;
begin
  FEnabled := False;
end;

constructor TDelay.Create;
begin
  Duration := 1000;
  StartTime := 0;
  FEnabled := False;
end;

end.


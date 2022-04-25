// Taken from http://delphi.about.com/od/windowsshellapi/a/delphi-high-performance-timer-tstopwatch.htm 
unit StopWatch;

interface

uses
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  SysUtils, DateUtils;

type
  TLargeInteger = Int64;

  TStopWatch = class
  private
    fFrequency : TLargeInteger;
    fIsRunning: Boolean;
    fIsHighResolution: Boolean;
    fStartCount, fStopCount : TLargeInteger;
    procedure SetTickStamp(var lInt : TLargeInteger) ;
    function GetElapsedTicks: TLargeInteger;
    function GetElapsedMiliseconds: TLargeInteger;
    function GetElapsed: string;
  public
    constructor Create(const startOnCreate : Boolean = False) ;
    procedure Start;
    procedure Stop;
    property IsHighResolution : Boolean read fIsHighResolution;
    property ElapsedTicks : TLargeInteger read GetElapsedTicks;
    property ElapsedMiliseconds : TLargeInteger read GetElapsedMiliseconds;
    property Elapsed : string read GetElapsed;
    property IsRunning : Boolean read fIsRunning;
  end;


implementation

constructor TStopWatch.Create(const startOnCreate : boolean = false) ;
begin
  inherited Create;

  fIsRunning := False;

  {$IFDEF WINDOWS}
  fIsHighResolution := QueryPerformanceFrequency(fFrequency) ;
  {$ELSE}
  fIsHighResolution := False;
  {$ENDIF}
  if NOT fIsHighResolution then fFrequency := MSecsPerSec;

  if StartOnCreate then Start;
end;

function TStopWatch.GetElapsedTicks: TLargeInteger;
begin
  Result := fStopCount - fStartCount;
end;

procedure TStopWatch.SetTickStamp(var lInt : TLargeInteger) ;
begin
  if fIsHighResolution then
    {$IFDEF Windows}
    QueryPerformanceCounter(lInt)
    {$ELSE}
    {$ENDIF}
  else
    lInt := MilliSecondOf(Now) ;
end;

function TStopWatch.GetElapsed: string;
var
  dt: TDateTime;
begin
  dt := ElapsedMiliseconds / MSecsPerSec / SecsPerDay;
  result := Format('%d days, %s', [Trunc(dt), FormatDateTime('hh:nn:ss.z', Frac(dt))]) ;
end;

function TStopWatch.GetElapsedMiliseconds: TLargeInteger;
begin
  Result := (MSecsPerSec * (fStopCount - fStartCount)) div fFrequency;
end;

procedure TStopWatch.Start;
begin
  SetTickStamp(fStartCount);
  fIsRunning := True;
end;

procedure TStopWatch.Stop;
begin
  SetTickStamp(fStopCount);
  fIsRunning := False;
end;

end.
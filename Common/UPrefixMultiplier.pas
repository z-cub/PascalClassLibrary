unit UPrefixMultiplier;

// Date: 2010-06-01

interface

uses
  Classes, SysUtils, Math;

type
  TPrefixMultiplierItem = record
    ShortText: string;
    FullText: string;
    Value: Double;
  end;

  TPrefixMultiplierDef = array[0..16] of TPrefixMultiplierItem;

  { TPrefixMultiplier }

  TPrefixMultiplier = class(TComponent)
  private
    function TruncateDigits(Value: Double; Digits: Integer = 3): Double;
  public
    function Add(Value: Double; PrefixMultipliers: TPrefixMultiplierDef;
      UnitText: string; Digits: Integer = 3): string;
  end;

const
  BasePrefixMultipliers: TPrefixMultiplierDef =
  (
    (ShortText: 'y'; FullText: 'yocto'; Value: 1e-24),
	  (ShortText: 'z'; FullText: 'zepto'; Value: 1e-21),
    (ShortText: 'a'; FullText: 'atto'; Value: 1e-18),
    (ShortText: 'f'; FullText: 'femto'; Value: 1e-15),
    (ShortText: 'p'; FullText: 'piko'; Value: 1e-12),
    (ShortText: 'n'; FullText: 'nano'; Value: 1e-9),
    (ShortText: 'u'; FullText: 'mikro'; Value: 1e-6),
    (ShortText: 'm'; FullText: 'mili'; Value: 1e-3),
    (ShortText: ''; FullText: ''; Value: 1e0),
    (ShortText: 'k'; FullText: 'kilo'; Value: 1e3),
    (ShortText: 'M'; FullText: 'mega'; Value: 1e6),
    (ShortText: 'G'; FullText: 'giga'; Value: 1e9),
    (ShortText: 'T'; FullText: 'tera'; Value: 1e12),
    (ShortText: 'P'; FullText: 'peta'; Value: 1e15),
    (ShortText: 'E'; FullText: 'exa'; Value: 1e18),
    (ShortText: 'Z'; FullText: 'zetta'; Value: 1e21),
    (ShortText: 'Y'; FullText: 'yotta'; Value: 1e24)
  );

  TimePrefixMultipliers: TPrefixMultiplierDef =
  (
    (ShortText: 'ys'; FullText: 'yocto'; Value: 1e-24),
	  (ShortText: 'zs'; FullText: 'zepto'; Value: 1e-21),
    (ShortText: 'as'; FullText: 'atto'; Value: 1e-18),
    (ShortText: 'fs'; FullText: 'femto'; Value: 1e-15),
    (ShortText: 'ps'; FullText: 'piko'; Value: 1e-12),
    (ShortText: 'ns'; FullText: 'nano'; Value: 1e-9),
    (ShortText: 'us'; FullText: 'mikro'; Value: 1e-6),
    (ShortText: 'ms'; FullText: 'mili'; Value: 1e-3),
    (ShortText: 's'; FullText: 'sekunda'; Value: 1),
    (ShortText: 'min'; FullText: 'minuta'; Value: 60),
    (ShortText: 'hod'; FullText: 'hodina'; Value: 3600),
    (ShortText: 'den'; FullText: 'den'; Value: 24 * 3600),
    (ShortText: 'týd'; FullText: 'týden'; Value: 7 * 24 * 3600),
    (ShortText: 'měs'; FullText: 'měsíc'; Value: 30 * 24 * 3600),
    (ShortText: 'rok'; FullText: 'rok'; Value: 365 * 24 * 3600),
    (ShortText: 'století'; FullText: 'století'; Value: 3153600000),
    (ShortText: 'tisíciletí'; FullText: 'tisíciletí'; Value: 3153600000)
  );

procedure Register;


implementation

procedure Register;
begin
  RegisterComponents('Common', [TPrefixMultiplier]);
end;

{ TPrefixMultiplier }

function TPrefixMultiplier.TruncateDigits(Value: Double; Digits: Integer = 3): Double;
var
  II: Integer;
  RealDigits: Integer;
begin
  Result := 0;
  for II := 2 downto -1 do begin
    if Value >= Power(10, II) then begin
      if Digits < (II + 1) then RealDigits := II + 1
        else RealDigits := Digits;
      Result := Round(Value / Power(10, II - RealDigits + 1)) * Power(10, II - RealDigits + 1);
      Break;
    end;
  end;
end;

function TPrefixMultiplier.Add(Value: Double; PrefixMultipliers: TPrefixMultiplierDef
  ; UnitText:string; Digits: Integer): string;
var
  I: Integer;
begin
  if UnitText = '' then Result := FloatToStr(TruncateDigits(Value, Digits));
  I := 8;
  if Value = 0 then
  else
  if Value > 1 then begin
    while(((Value / PrefixMultipliers[I + 1].Value) > 1) and ((I + 1) >= 0) and
      ((I + 1) <= Length(PrefixMultipliers))) do Inc(I);
  end else
  if Value < 1 then begin
    while(((Value / PrefixMultipliers[I + 1].Value) < 1) and ((I - 1) >= 0) and
      ((I - 1) <= Length(PrefixMultipliers))) do Dec(I);
    Inc(I);
  end;
  Value := Value / PrefixMultipliers[I].Value;

  // Truncate digits count
  Result := FloatToStr(TruncateDigits(Value, Digits)) + ' ' +
    PrefixMultipliers[I].ShortText + UnitText;
end;

end.


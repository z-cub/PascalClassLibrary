unit UGenerics;

interface

uses
  Classes, SysUtils, Generics.Collections;

type

  { TListString }

  TListString = class(TList<string>)
    procedure Assign(Source: TListString);
    procedure Explode(Separator: Char; Text: string; MaxCount: Integer = -1);
    function Implode(Separator: Char): string;
  end;

  { TDictionaryStringString }

  TDictionaryStringString = class(TDictionary<string, string>)
    procedure Assign(Source: TDictionaryStringString);
  end;


implementation

{ TListString }

procedure TListString.Assign(Source: TListString);
var
  I: Integer;
begin
  Count := Source.Count;
  for I := 0 to Source.Count - 1 do
    Items[I] := Source[I];
end;

function TListString.Implode(Separator: Char): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do begin
    Result := Result + Items[I];
    if I < Count - 1 then Result := Result + Separator;
  end;
end;

procedure TListString.Explode(Separator: Char; Text: string; MaxCount: Integer = -1);
var
  Index: Integer;
begin
  Clear;
  repeat
    Index := Pos(Separator, Text);
    if Index > 0 then begin
      Add(Copy(Text, 1, Index - 1));
      System.Delete(Text, 1, Index);
      if (MaxCount <> -1) and (Count >= MaxCount) then Break;
    end else Break;
  until False;
  if Text <> '' then begin
    Add(Text);
  end;
end;

{ TDictionaryStringString }

procedure TDictionaryStringString.Assign(Source: TDictionaryStringString);
var
  Item: TPair<string, string>;
begin
  Clear;
  for Item in Source do
    Add(Item.Key, Item.Value);
end;

end.


{$IFDEF INTERFACE}

{$DEFINE TGListIndex := TGListStringIndex}
{$DEFINE TGListItem := TGListStringItem}
{$DEFINE TGList := TGListStringList}
{$DEFINE TGListSortCompare := TGListStringSortCompare}
{$DEFINE TGListToStringConverter := TGListStringToStringConverter}
{$DEFINE TGListFromStringConverter := TGListStringFromStringConverter}
{$DEFINE TGListItemArray := TGListStringItemArray}
{$DEFINE INTERFACE}
{$I 'GenericList.inc'}

  // TGListString<TListStringIndex, TListStringItem> = class(TGList)
  TGListString = class(TGList)
  private
  public
    procedure Delete(Index: TGListStringIndex); override;
    procedure Clear; override;
    procedure Assign(Source: TGList); override;
    constructor Create;
    destructor Destroy; override;
  end;

{$UNDEF INTERFACE}
{$ENDIF}

{$IFDEF IMPLEMENTATION_USES}

  {$DEFINE IMPLEMENTATION_USES}
  {$I 'GenericList.inc'}

{$UNDEF IMPLEMENTATION_USES}
{$ENDIF}

{$IFDEF IMPLEMENTATION}

{$DEFINE TGListIndex := TGListStringIndex}
{$DEFINE TGListItem := TGListStringItem}
{$DEFINE TGList := TGListStringList}
{$DEFINE TGListSortCompare := TGListStringSortCompare}
{$DEFINE TGListToStringConverter := TGListStringToStringConverter}
{$DEFINE TGListFromStringConverter := TGListStringFromStringConverter}
{$DEFINE TGListItemArray := TGListStringItemArray}
{$DEFINE IMPLEMENTATION}
{$I 'GenericList.inc'}

{ TGListString }

procedure TGListString.Assign(Source: TGList);
begin
  Clear;
  inherited;
end;

procedure TGListString.Delete(Index: TGListStringIndex);
begin
  FItems[Index] := '';
  inherited Delete(Index);
end;

procedure TGListString.Clear;
var
  I: TGListStringIndex;
begin
  I := 0;
  while I < Count do begin
    FItems[I] := '';
    I := I + 1;
  end;
  inherited Clear;
end;

constructor TGListString.Create;
begin
  inherited;
end;

destructor TGListString.Destroy;
begin
  Clear;
  inherited Destroy;
end;

{$UNDEF IMPLEMENTATION}
{$ENDIF}
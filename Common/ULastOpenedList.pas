unit ULastOpenedList;

{$mode delphi}

interface

uses
  Classes, SysUtils, Registry, URegistry, Menus, XMLConf, DOM;

type

  { TLastOpenedList }

  TLastOpenedList = class(TComponent)
  private
    FMaxCount: Integer;
    FOnChange: TNotifyEvent;
    procedure SetMaxCount(AValue: Integer);
    procedure LimitMaxCount;
    procedure ItemsChange(Sender: TObject);
    procedure DoChange;
  public
    Items: TStringList;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadToMenuItem(MenuItem: TMenuItem; ClickAction: TNotifyEvent);
    procedure LoadFromRegistry(Context: TRegistryContext);
    procedure SaveToRegistry(Context: TRegistryContext);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; Path: string);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; Path: string);
    procedure AddItem(FileName: string);
    function GetFirstFileName: string;
  published
    property MaxCount: Integer read FMaxCount write SetMaxCount;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

procedure Register;


implementation

procedure Register;
begin
  RegisterComponents('Common', [TLastOpenedList]);
end;


{ TLastOpenedList }

procedure TLastOpenedList.SetMaxCount(AValue: Integer);
begin
  if FMaxCount = AValue then Exit;
  FMaxCount := AValue;
  if FMaxCount < 0 then FMaxCount := 0;
  LimitMaxCount;
end;

procedure TLastOpenedList.LimitMaxCount;
begin
  while Items.Count > MaxCount do
    Items.Delete(Items.Count - 1);
end;

procedure TLastOpenedList.ItemsChange(Sender: TObject);
begin
  DoChange;
end;

procedure TLastOpenedList.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TLastOpenedList.Create(AOwner: TComponent);
begin
  inherited;
  Items := TStringList.Create;
  Items.OnChange := ItemsChange;
  MaxCount := 10;
end;

destructor TLastOpenedList.Destroy;
begin
  FreeAndNil(Items);
  inherited;
end;

procedure TLastOpenedList.LoadToMenuItem(MenuItem: TMenuItem; ClickAction: TNotifyEvent);
var
  NewMenuItem: TMenuItem;
  I: Integer;
begin
  if Assigned(MenuItem) then begin
    while MenuItem.Count > Items.Count do
      MenuItem.Delete(MenuItem.Count - 1);
    while MenuItem.Count < Items.Count do begin
      NewMenuItem := TMenuItem.Create(MenuItem);
      MenuItem.Add(NewMenuItem);
    end;
    for I := 0 to Items.Count - 1 do begin
      MenuItem.Items[I].Caption := Items[I];
      MenuItem.Items[I].OnClick := ClickAction;
    end;
  end;
end;

procedure TLastOpenedList.LoadFromRegistry(Context: TRegistryContext);
var
  I: Integer;
  Registry: TRegistryEx;
  FileName: string;
begin
  Registry := TRegistryEx.Create;
  with Registry do
  try
    RootKey := Context.RootKey;
    OpenKey(Context.Key, True);
    Items.Clear;
    I := 0;
    while ValueExists('File' + IntToStr(I)) and (I < MaxCount) do begin
      FileName := UTF8Encode(ReadStringWithDefault('File' + IntToStr(I), ''));
      if Trim(FileName) <> '' then Items.Add(FileName);
      Inc(I);
    end;
    if Assigned(FOnChange) then
      FOnChange(Self);
  finally
    Free;
  end;
end;

procedure TLastOpenedList.SaveToRegistry(Context: TRegistryContext);
var
  I: Integer;
  Registry: TRegistryEx;
begin
  Registry := TRegistryEx.Create;
  with Registry do
  try
    RootKey := Context.RootKey;
    OpenKey(Context.Key, True);
    for I := 0 to Items.Count - 1 do
      WriteString('File' + IntToStr(I), Items[I]);
  finally
    Free;
  end;
end;

procedure TLastOpenedList.LoadFromXMLConfig(XMLConfig: TXMLConfig; Path: string
  );
var
  I: Integer;
  Value: string;
  Count: Integer;
begin
  with XMLConfig do begin
    Count := GetValue(DOMString(Path + '/Count'), 0);
    if Count > MaxCount then Count := MaxCount;
    Items.Clear;
    for I := 0 to Count - 1 do begin
      Value := string(GetValue(DOMString(Path + '/File' + IntToStr(I)), ''));
      if Trim(Value) <> '' then Items.Add(Value);
    end;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TLastOpenedList.SaveToXMLConfig(XMLConfig: TXMLConfig; Path: string);
var
  I: Integer;
begin
  with XMLConfig do begin
    SetValue(DOMString(Path + '/Count'), Items.Count);
    for I := 0 to Items.Count - 1 do
      SetValue(DOMString(Path + '/File' + IntToStr(I)), DOMString(Items[I]));
    Flush;
  end;
end;

procedure TLastOpenedList.AddItem(FileName:string);
begin
  if Items.IndexOf(FileName) <> -1 then Items.Delete(Items.IndexOf(FileName));
  Items.Insert(0, FileName);
  LimitMaxCount;
  DoChange;
end;

function TLastOpenedList.GetFirstFileName: string;
begin
  if Items.Count > 0 then Result := Items[0]
    else Result := '';
end;

end.


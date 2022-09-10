unit UPDClient;

interface

uses
  Classes, SysUtils, Generics.Collections, UGenerics;

const
  SystemVersionObject = 'SystemVersion';

type
  EClientNotSet = class(Exception);

  TPDClient = class;
  TPDType = class;

  TOrderDirection = (odNone, odAscending, odDescending);

  { TObjectProxy }

  TObjectProxy = class
    Id: Integer;
    Properties: TDictionaryStringString;
    Client: TPDClient;
    ObjectName: string;
    Path: string;
    procedure Load;
    procedure Save;
    procedure Delete;
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TObjectProxy);
  end;

  { TObjectProxies }

  TObjectProxies = class(TObjectList<TObjectProxy>)
    function AddProxy: TObjectProxy;
  end;

  TOperation = (opUndefined, opDefined, opEqual, opNotEqual,
    opLess, opMore, opLessOrEqual, opMoreOrEqual);

  TCondition = class
    Column: string;
    Operation: TOperation;
    Value: string;
  end;

  { TListProxy }

  TListProxy = class
    Client: TPDClient;
    OrderColumn: string;
    OrderDirection: TOrderDirection;
    OrderUse: Boolean;
    PageItemFirst: Integer;
    PageItemCount: Integer;
    PageUse: Boolean;
    ColumnsFilter: TListString;
    ColummsFilterUse: Boolean;
    Condition: string;
    ObjectName: string;
    Path: string;
    Objects: TObjectList<TObjectProxy>;
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
    procedure Load; virtual;
    procedure Save; virtual;
  end;

  TPDTypeProperty = class
    Name: string;
    DbType: TPDType;
    Unique: Boolean;
    Index: Boolean;
  end;

  { TPDTypeProperties }

  TPDTypeProperties = class(TObjectList<TPDTypeProperty>)
    Client: TPDClient;
    function AddSimple(Name: string; TypeName: string; Unique: Boolean = False;
      Index: Boolean = False): TPDTypeProperty;
  end;

  { TPDType }

  TPDType = class
  private
    FClient: TPDClient;
    procedure SetClient(AValue: TPDClient);
  public
    Name: string;
    DbType: string;
    Properties: TPDTypeProperties;
    function IsDefined: Boolean;
    procedure Define;
    procedure Undefine;
    constructor Create;
    destructor Destroy; override;
    property Client: TPDClient read FClient write SetClient;
  end;

  { TPDTypes }

  TPDTypes = class(TObjectList<TPDType>)
    Client: TPDClient;
    function AddType(Name: string; DbType: string = ''): TPDType;
    function SearchByName(Name: string): TPDType;
  end;

  { TPDClient }

  TPDClient = class(TComponent)
  private
    FSchema: string;
    procedure SetConnected(AValue: Boolean);
  protected
    procedure InitSystemTypes; virtual;
    procedure Init; virtual;
    function GetConnected: Boolean; virtual;
    function GetConnectionString: string; virtual;
    procedure SetConnectionString(AValue: string); virtual;
  public
    Types: TPDTypes;
    Version: string;
    BackendName: string;
    procedure ObjectLoad(AObject: TObjectProxy); virtual; abstract;
    procedure ObjectSave(AObject: TObjectProxy); virtual; abstract;
    procedure ObjectDelete(AObject: TObjectProxy); virtual; abstract;
    procedure ListLoad(AList: TListProxy); virtual; abstract;
    procedure ListSave(AList: TListProxy); virtual; abstract;
    function TypeIsDefined(AType: TPDType): Boolean; virtual; abstract;
    procedure TypeDefine(AType: TPDType); virtual; abstract;
    procedure TypeUndefine(AType: TPDType); virtual; abstract;
    procedure CheckTypes;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect; virtual;
    procedure Disconnect; virtual;
    procedure Install; virtual;
    procedure Uninstall; virtual;
    procedure Update; virtual;
  published
    property Schema: string read FSchema write FSchema;
    property Connected: Boolean read GetConnected write SetConnected;
    property ConnectionString: string read GetConnectionString
      write SetConnectionString;
  end;

  TPDClientClass = class of TPDClient;

resourcestring
  SClientNotSet = 'Client not set';
  SNotSupported = 'Not supported';
  SVersionMismatch = 'Version mismatch, client: %0:s, server: %1:s. Please upgrade database.';
  SCantLoadObjectWithoutId = 'Can''t load object without id';


implementation

{ TObjectProxies }

function TObjectProxies.AddProxy: TObjectProxy;
begin
  Result := TObjectProxy.Create;
  Add(Result);
end;

{ TPDTypeProperties }

function TPDTypeProperties.AddSimple(Name: string; TypeName: string;
  Unique: Boolean = False; Index: Boolean = False): TPDTypeProperty;
begin
  Result := TPDTypeProperty.Create;
  Result.Name := Name;
  Result.DbType := Client.Types.SearchByName(TypeName);
  Result.Unique := Unique;
  Result.Index := Index;
  Add(Result);
end;

{ TPDTypes }

function TPDTypes.AddType(Name: string; DbType: string = ''): TPDType;
begin
  Result := TPDType.Create;
  Result.Client := Client;
  Result.Name := Name;
  Result.DbType := DbType;
  Add(Result);
end;

function TPDTypes.SearchByName(Name: string): TPDType;
var
  I: Integer;
begin
  I := 0;
  while (I < Count) and (TPDType(Items[I]).Name <> Name) do Inc(I);
  if I < Count then Result := TPDType(Items[I])
    else Result := nil;
end;

procedure TPDType.SetClient(AValue: TPDClient);
begin
  if FClient = AValue then Exit;
  FClient := AValue;
  Properties.Client := AValue;
end;

function TPDType.IsDefined: Boolean;
begin
  if Assigned(Client) then Result := Client.TypeIsDefined(Self)
    else raise EClientNotSet.Create(SClientNotSet);
end;

procedure TPDType.Define;
begin
  if Assigned(Client) then Client.TypeDefine(Self)
    else raise EClientNotSet.Create(SClientNotSet);
end;

procedure TPDType.Undefine;
begin
  if Assigned(Client) then Client.TypeUndefine(Self)
    else raise EClientNotSet.Create(SClientNotSet);
end;

constructor TPDType.Create;
begin
  Properties := TPDTypeProperties.Create;
end;

destructor TPDType.Destroy;
begin
  FreeAndNil(Properties);
  inherited;
end;

{ TObjectProxy }

procedure TObjectProxy.Load;
begin
  if Assigned(Client) then Client.ObjectLoad(Self)
    else raise EClientNotSet.Create(SClientNotSet);
end;

procedure TObjectProxy.Save;
begin
  if Assigned(Client) then Client.ObjectSave(Self)
    else raise EClientNotSet.Create(SClientNotSet);
end;

procedure TObjectProxy.Delete;
begin
  if Assigned(Client) then Client.ObjectDelete(Self)
    else raise EClientNotSet.Create(SClientNotSet);
end;

constructor TObjectProxy.Create;
begin
  Properties := TDictionaryStringString.Create;
end;

destructor TObjectProxy.Destroy;
begin
  FreeAndNil(Properties);
  inherited;
end;

procedure TObjectProxy.Assign(Source: TObjectProxy);
begin
  Path := Source.Path;
  Client := Source.Client;
  ObjectName := Source.ObjectName;
  Id := Source.Id;
  Properties.Assign(Source.Properties);
end;

{ TListProxy }

procedure TListProxy.Clear;
begin
  PageUse := False;
  ColummsFilterUse := False;
  OrderUse := False;
  Objects.Free;
end;

constructor TListProxy.Create;
begin
  ColumnsFilter := TListString.Create;
  Objects := TObjectList<TObjectProxy>.Create;
end;

destructor TListProxy.Destroy;
begin
  FreeAndNil(Objects);
  FreeAndNil(ColumnsFilter);
  inherited;
end;

procedure TListProxy.Load;
begin
  if Assigned(Client) then Client.ListLoad(Self)
    else raise EClientNotSet.Create(SClientNotSet);
end;

procedure TListProxy.Save;
begin
  if Assigned(Client) then Client.ListSave(Self)
    else raise EClientNotSet.Create(SClientNotSet);
end;

{ TPDClient }

function TPDClient.GetConnectionString: string;
begin
  Result := '';
end;

procedure TPDClient.SetConnectionString(AValue: string);
begin
end;

procedure TPDClient.SetConnected(AValue: Boolean);
begin
  if AValue then Connect else Disconnect;
end;

procedure TPDClient.InitSystemTypes;
begin
end;

procedure TPDClient.Init;
var
  NewProxy: TListProxy;
  NewType: TPDType;
  NewObject: TObjectProxy;
  DbVersion: string;
begin
  NewProxy := TListProxy.Create;
  NewProxy.Client := Self;
  NewProxy.Path := 'information_schema';
  NewProxy.ObjectName := 'TABLES';
  NewProxy.Condition := '(TABLE_SCHEMA = "' + Schema +
    '") AND (TABLE_NAME = "' + SystemVersionObject + '")';
  NewProxy.Load;
  if NewProxy.Objects.Count > 0 then begin
    NewObject := TObjectProxy.Create;
    NewObject.Client := Self;
    NewObject.Path := Schema;
    NewObject.ObjectName := SystemVersionObject;
    NewObject.Id := 1;
    NewObject.Load;

    DbVersion := NewObject.Properties.Items['Version'];
    if Version <> DbVersion then
      raise Exception.Create(Format(SVersionMismatch, [Version, DbVersion]));
  end else begin
    NewType := TPDType.Create;
    NewType.Client := Self;
    NewType.Name := SystemVersionObject;
    NewType.Properties.AddSimple('Version', 'String');
    NewType.Properties.AddSimple('Time', 'DateTime');
    NewType.Define;

    NewObject := TObjectProxy.Create;
    NewObject.Client := Self;
    NewObject.Path := Schema;
    NewObject.ObjectName := SystemVersionObject;
    NewObject.Properties.Add('Version', Version);
    NewObject.Properties.Add('Time', 'NOW()');
    NewObject.Save;

    Install;
  end;
end;

function TPDClient.GetConnected: Boolean;
begin
  Result := False;
end;

procedure TPDClient.CheckTypes;
var
  StructureVersion: string;
  Data: TDictionaryStringString;
  ObjectId: Integer;
  Tables: TListString;
  I: Integer;
  NewProxy: TListProxy;
begin
  try
    Tables := TListString.Create;
    Data := TDictionaryStringString.Create;

    NewProxy := TListProxy.Create;
    NewProxy.Client := Self;
    NewProxy.Path := 'information_schema';
    NewProxy.ObjectName := 'TABLES';
    NewProxy.Condition := 'TABLE_SCHEMA = "' + Schema + '"';
    NewProxy.Load;
    //Database.Query(DbRows, 'SHOW TABLES');
    Tables.Count := NewProxy.Objects.Count;
    for I := 0 to NewProxy.Objects.Count - 1 do
      Tables[I] := TObjectProxy(NewProxy.Objects[I]).Properties.Items['TABLE_NAME'];

    for I := 0 to Types.Count - 1 do
    with TPDType(Types[I]) do begin
      if (DbType = '') and (Tables.IndexOf(Name) = -1) then begin
        Define;
      end;
    end;
  finally
    NewProxy.Free;
    Data.Free;
    Tables.Free;
  end;
end;

constructor TPDClient.Create(AOwner: TComponent);
begin
  inherited;
  Types := TPDTypes.Create;
  Types.Client := Self;
  InitSystemTypes;
end;

destructor TPDClient.Destroy;
begin
  FreeAndNil(Types);
  inherited;
end;

procedure TPDClient.Connect;
begin
end;

procedure TPDClient.Disconnect;
begin
end;

procedure TPDClient.Install;
begin
end;

procedure TPDClient.Uninstall;
begin
  //Types.Uninstall;
end;

procedure TPDClient.Update;
begin
end;

end.


unit UPDClientMySQL;

interface

uses
  Classes, SysUtils, USqlDatabase, UPDClient, UGenerics;

type

  { TPDClientMySQL }

  TPDClientMySQL = class(TPDClient)
  protected
    FHost: string;
    FPort: Word;
    FUser: string;
    FPassword: string;
    FDatabase: TSqlDatabase;
    procedure InitSystemTypes; override;
    function GetConnected: Boolean; override;
    procedure Init; override;
    function GetConnectionString: string; override;
  public
    procedure ObjectLoad(AObject: TObjectProxy); override;
    procedure ObjectSave(AObject: TObjectProxy); override;
    procedure ObjectDelete(AObject: TObjectProxy); override;
    procedure ListLoad(AList: TListProxy); override;
    procedure ListSave(AList: TListProxy); override;
    procedure TypeDefine(AType: TPDType); override;
    procedure TypeUndefine(AType: TPDType); override;
    function TypeIsDefined(AType: TPDType): Boolean; override;
    procedure Install;
    procedure Uninstall;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect; override;
    procedure Disconnect; override;
  published
    property Database: TSqlDatabase read FDatabase write FDatabase;
    property Host: string read FHost write FHost;
    property Port: Word read FPort write FPort;
    property User: string read FUser write FUser;
    property Password: string read FPassword write FPassword;
  end;


implementation

resourcestring
  SMissingBaseType = 'Missing base typ for %s';
  SUndefinedType = 'Undefined type in %0:s.%1:s';

{ TPDClientMySQL }

procedure TPDClientMySQL.InitSystemTypes;
begin
  inherited InitSystemTypes;
  Types.AddType('Integer', 'int(11)');
  Types.AddType('String', 'varchar(255)');
  Types.AddType('RelationOne', 'int(11)');
  Types.AddType('Double', 'double');
  Types.AddType('DateTime', 'datetime');
  Types.AddType('Date', 'date');
  Types.AddType('Time', 'time');
  Types.AddType('Text', 'text');
  Types.AddType('Boolean', 'bool');
end;

function TPDClientMySQL.GetConnected: Boolean;
begin
  Result := Database.Connected;
end;

procedure TPDClientMySQL.ObjectLoad(AObject: TObjectProxy);
var
  DbRows: TDbRows;
  NewObject: TObjectProxy;
  Table: string;
begin
  if AObject.Id = 0 then raise Exception.Create(SCantLoadObjectWithoutId);
  try
    DbRows := TDbRows.Create;
    Table := '`' + AObject.ObjectName + '`';
    if AObject.Path <> '' then Table := '`' + AObject.Path + '`.' + Table;
    Database.Query(DbRows, 'SELECT * FROM ' + Table +
      ' WHERE `Id`=' + IntToStr(AObject.Id));
    AObject.Properties.Assign(TDictionaryStringString(DbRows[0]));
  finally
    DbRows.Free;
  end;
end;

procedure TPDClientMySQL.ObjectSave(AObject: TObjectProxy);
var
  DbRows: TDbRows;
  NewObject: TObjectProxy;
  Table: string;
begin
  try
    DbRows := TDbRows.Create;
    if AObject.Id = 0 then begin
      Database.Insert(AObject.ObjectName, AObject.Properties, AObject.Path);
      AObject.Id := Database.LastInsertId;
    end else Database.Update(AObject.ObjectName, AObject.Properties,
      'Id=' + IntToStr(AObject.Id), AObject.Path);
  finally
    DbRows.Free;
  end;
end;

procedure TPDClientMySQL.ObjectDelete(AObject: TObjectProxy);
begin
  Database.Delete(AObject.ObjectName, 'Id=' + IntToStr(AObject.Id),
    AObject.Path);
end;

procedure TPDClientMySQL.ListLoad(AList: TListProxy);
var
  DbRows: TDbRows;
  Filter: string;
  DbCondition: string;
  I: Integer;
  NewObject: TObjectProxy;
  Table: string;
begin
  try
    DbRows := TDbRows.Create;
    if AList.ColummsFilterUse then begin
      Filter := '';
      for I := 0 to AList.ColumnsFilter.Count - 1 do
        Filter := Filter + '`' + AList.ColumnsFilter[I] + '`, ';
      Delete(Filter, Length(Filter) - 1, 2);
    end else Filter := '*';
    if AList.Condition <> '' then DbCondition := ' WHERE ' + AList.Condition
      else DbCondition := '';
    Table := '`' + AList.ObjectName + '`';
    if AList.Path <> '' then Table := '`' + AList.Path + '`.' + Table;
    Database.Query(DbRows, 'SELECT ' + Filter + ' FROM ' + Table + DbCondition);
    AList.Objects.Clear;
    for I := 0 to DbRows.Count - 1 do begin
      NewObject := TObjectProxy.Create;
      NewObject.Client := AList.Client;
      NewObject.ObjectName := AList.ObjectName;
      NewObject.Path := AList.Path;
      NewObject.Properties.Assign(TDictionaryStringString(DbRows[I]));
      AList.Objects.Add(NewObject);
    end;
  finally
    DbRows.Free;
  end;
end;

procedure TPDClientMySQL.ListSave(AList: TListProxy);
begin
end;

procedure TPDClientMySQL.TypeDefine(AType: TPDType);
var
  DbRows: TDbRows;
  I: Integer;
  Query: string;
  RefType: TPDType;
begin
  try
    DbRows := TDbRows.Create;
    Query := 'CREATE TABLE IF NOT EXISTS `' + AType.Name + '` ( ' +
      '`Id` int(11) NOT NULL AUTO_INCREMENT,';
    for I := 0 to AType.Properties.Count - 1 do
    with AType.Properties do begin
      RefType := TPDTypeProperty(Items[I]).DbType;
      if not Assigned(RefType) then
        raise Exception.Create(Format(SUndefinedType, [AType.Name, TPDTypeProperty(Items[I]).Name]));
      if RefType.DbType = '' then
        raise Exception.Create(Format(SMissingBaseType, [RefType.Name]));

      Query := Query + '`' + TPDTypeProperty(Items[I]).Name + '` ' + RefType.DbType + ' NULL,';
    end;
    Query := Query + 'PRIMARY KEY (`Id`)' +
      ') ENGINE=InnoDB  DEFAULT CHARSET=utf8';
    Database.Query(DbRows, Query);
  finally
    DbRows.Free;
  end;
end;

procedure TPDClientMySQL.TypeUndefine(AType: TPDType);
var
  DbRows: TDbRows;
  I: Integer;
  Query: string;
  RefType: TPDType;
begin
  try
    DbRows := TDbRows.Create;
    Query := 'DROP TABLE IF EXISTS `' + AType.Name + '`';
    Database.Query(DbRows, Query);
  finally
    DbRows.Free;
  end;
end;

function TPDClientMySQL.TypeIsDefined(AType: TPDType): Boolean;
var
  NewProxy: TListProxy;
begin
  try
    NewProxy := TListProxy.Create;
    NewProxy.Client := Self;
    NewProxy.Path := 'information_schema';
    NewProxy.ObjectName := 'TABLES';
    NewProxy.Condition := '(TABLE_SCHEMA = "' + Schema +
      '") AND (TABLE_NAME = "' + AType.Name + '")';
    NewProxy.Load;
    Result := NewProxy.Objects.Count > 0;
  finally
    NewProxy.Free;
  end;
end;

procedure TPDClientMySQL.Install;
begin
(*  if Tables.IndexOf(InformationTable) = -1 then begin
    Database.Query(DbRows, 'CREATE TABLE IF NOT EXISTS `' + InformationTable + '` ( ' +
'`Version` varchar(255) NOT NULL,' +
'`LastUpdateTime` datetime NOT NULL' +
') ENGINE=InnoDB DEFAULT CHARSET=utf8;');
    Database.Query(DbRows, 'INSERT INTO `' + InformationTable + '` (`Version`, `LastUpdateTime`) VALUES ' +
'("0.1", "0000-00-00 00:00:00");');
  end;
  Database.Select(DbRows, InformationTable);
  StructureVersion := DbRows[0].Values['Version'];*)
end;

procedure TPDClientMySQL.Uninstall;
begin

end;

procedure TPDClientMySQL.Init;
begin
  inherited;
end;

function TPDClientMySQL.GetConnectionString: string;
begin
  Result := 'Host:' + Host + ',Port:' + IntToStr(Port) + ',User:' + User +
    ',Password:' + Password + ',Schema:' + Schema;
end;

constructor TPDClientMySQL.Create(AOwner: TComponent);
begin
  inherited;
  FDatabase := TSqlDatabase.Create(nil);
  BackendName := 'MySQL';
end;

destructor TPDClientMySQL.Destroy;
begin
  FreeAndNil(FDatabase);
  inherited;
end;

procedure TPDClientMySQL.Connect;
begin
  if not Connected then begin
    Database.Port := Port;
    Database.UserName := User;
    Database.Password := Password;
    Database.HostName := Host;
    Database.Database := Schema;
    Database.Connect;
    Init;
  end;
end;

procedure TPDClientMySQL.Disconnect;
begin
  if Connected then Database.Disconnect;
end;

end.


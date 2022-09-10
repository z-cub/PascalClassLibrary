unit UPersistentData;

interface

uses
  Classes, SysUtils, UPDClient, Generics.Collections;

type
  TPDManagerItem = class
    Name: string;
    ClientClass: TPDClientClass;
  end;

  TPDManagerItems = class(TObjectList<TPDManagerItem>)
  end;

  { TPDManager }

  TPDManager = class(TComponent)
  public
    Items: TPDManagerItems;
    procedure Register(ClientClass: TPDClientClass);
    procedure LoadToStrings(Strings: TStrings);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  DefaultManager: TPDManager;

procedure Register;


implementation

uses
  UPDClientXMLRPC, UPDClientMemory, UPDClientMySQL, UPDClientRegistry,
  UPDClientINI;

procedure Register;
begin
  RegisterComponents('PersistentData', [TPDManager, TPDClientXMLRPC, TPDClientMemory,
    TPDClientMySQL, TPDClientRegistry, TPDClientINI]);
end;

{ TPDManager }

procedure TPDManager.Register(ClientClass: TPDClientClass);
var
  NewItem : TPDManagerItem;
  TempClass: TPDClient;
begin
  try
    TempClass := ClientClass.Create(nil);
    NewItem := TPDManagerItem.Create;
    NewItem.Name := TempClass.BackendName;
    NewItem.ClientClass := ClientClass;
    Items.Add(NewItem);
  finally
    TempClass.Free;
  end;
end;

procedure TPDManager.LoadToStrings(Strings: TStrings);
var
  I: Integer;
begin
  try
    Strings.BeginUpdate;
    Strings.Clear;
    for I := 0 to Items.Count - 1 do
      Strings.AddObject(TPDManagerItem(Items[I]).Name, TObject(TPDManagerItem(Items[I]).ClientClass));
  finally
    Strings.EndUpdate;
  end;
end;

constructor TPDManager.Create(AOwner: TComponent);
begin
  inherited;
  Items := TPDManagerItems.Create;
end;

destructor TPDManager.Destroy;
begin
  FreeAndNil(Items);
  inherited;
end;


initialization

DefaultManager := TPDManager.Create(nil);
DefaultManager.Register(TPDClientINI);
DefaultManager.Register(TPDClientRegistry);
DefaultManager.Register(TPDClientMemory);
DefaultManager.Register(TPDClientXMLRPC);
DefaultManager.Register(TPDClientMySQL);

finalization

FreeAndNil(DefaultManager);

end.


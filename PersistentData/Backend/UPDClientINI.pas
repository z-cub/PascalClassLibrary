unit UPDClientINI;

interface

uses
  Classes, SysUtils, UPDClient, IniFiles;

type

  { TPDClientINI }

  TPDClientINI = class(TPDClient)
  public
    IniFile: TIniFile;
    //procedure GetItemList(Condition: TCondition; ItemList: TItemList); override;
    //procedure SetItemList(Condition: TCondition; ItemList: TItemList); override;
    FileName: string;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect; override;
    procedure Disconnect; override;
  end;


implementation

{ TPDClientINI }

(*procedure TPDClientINI.GetItemList(Condition: TCondition;
  ItemList: TItemList);
begin
  inherited GetItemList(Condition, ItemList);
end;

procedure TPDClientINI.SetItemList(Condition: TCondition;
  ItemList: TItemList);
begin
  inherited SetItemList(Condition, ItemList);
end;*)

constructor TPDClientINI.Create(AOwner: TComponent);
begin
  inherited;
  BackendName := 'INI';
end;

destructor TPDClientINI.Destroy;
begin
  Disconnect;
  inherited;
end;

procedure TPDClientINI.Connect;
begin
  IniFile := TIniFile.Create(FileName);
end;

procedure TPDClientINI.Disconnect;
begin
  FreeAndNil(IniFile);
end;

end.


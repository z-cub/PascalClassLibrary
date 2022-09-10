unit UPDClientRegistry;

interface

uses
  Classes, SysUtils, UPDClient, Registry;

type

  { TPDClientRegistry }

  TPDClientRegistry = class(TPDClient)
  public
    Reg: TRegistry;
    //procedure GetItemList(Condition: TCondition; ItemList: TItemList); override;
    //procedure SetItemList(Condition: TCondition; ItemList: TItemList); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;


implementation

{ TPDClientRegistry }

(*procedure TPDClientRegistry.GetItemList(Condition: TCondition;
  ItemList: TItemList);
begin
  inherited GetItemList(Condition, ItemList);
end;

procedure TPDClientRegistry.SetItemList(Condition: TCondition;
  ItemList: TItemList);
begin
  inherited SetItemList(Condition, ItemList);
end;*)

constructor TPDClientRegistry.Create(AOwner: TComponent);
begin
  inherited;
  Reg := TRegistry.Create;
  BackendName := 'Windows registry';
end;

destructor TPDClientRegistry.Destroy;
begin
  Reg.Free;
  inherited;
end;

end.


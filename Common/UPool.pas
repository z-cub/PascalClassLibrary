unit UPool;

interface

uses
  Classes, SysUtils, syncobjs, Generics.Collections, UThreading;

type
  TPoolItemClass = class of TObject;

  { TPool }

  TPool = class
  private
    FReleaseEvent: TEvent;
    function GetTotalCount: Integer;
    function GetUsedCount: Integer; virtual;
    procedure SetTotalCount(const AValue: Integer);
  protected
    function NewItemObject: TObject; virtual;
  public
    Items: TObjectList<TObject>;
    FreeItems: TObjectList<TObject>;
    function Acquire: TObject; virtual;
    procedure Release(Item: TObject); virtual;
    constructor Create; virtual;
    destructor Destroy; override;
    property TotalCount: Integer read GetTotalCount write SetTotalCount;
    property UsedCount: Integer read GetUsedCount;
  end;

  { TThreadedPool }

  TThreadedPool = class(TPool)
  private
    procedure SetTotalCount(const AValue: Integer);
    function GetUsedCount: Integer; override;
  public
    Lock: TCriticalSection;
    function Acquire: TObject; override;
    procedure Release(Item: TObject); override;
    constructor Create; override;
    destructor Destroy; override;
  end;

resourcestring
  SObjectPoolEmpty = 'Object pool is empty';
  SReleaseError = 'Unknown object for release from pool';


implementation

{ TThreadedPool }

procedure TThreadedPool.SetTotalCount(const AValue: Integer);
begin
  try
    Lock.Acquire;
    inherited SetTotalCount(AValue);
  finally
    Lock.Release;
  end;
end;

function TThreadedPool.GetUsedCount: Integer;
begin
  try
    Lock.Acquire;
    Result := inherited GetUsedCount;
  finally
    Lock.Release;
  end;
end;

function TThreadedPool.Acquire: TObject;
begin
  try
    Lock.Acquire;
    if Items.Count = 0 then
      raise Exception.Create(SObjectPoolEmpty);
    while FreeItems.Count = 0 do begin
      try
        Lock.Release;
        //FReleaseEvent.WaitFor(1);
        Sleep(1);
      finally
        Lock.Acquire;
      end;
    end;
    Result := inherited Acquire;
  finally
    Lock.Release;
  end;
end;

procedure TThreadedPool.Release(Item: TObject);
begin
  try
    Lock.Acquire;
    inherited Release(Item);
  finally
    Lock.Release;
  end;
end;

constructor TThreadedPool.Create;
begin
  inherited;
  Lock := TCriticalSection.Create;
end;

destructor TThreadedPool.Destroy;
begin
  TotalCount := 0;
  Lock.Free;
  inherited;
end;

{ TPool }

function TPool.NewItemObject: TObject;
begin
  // Overload this method in descendand classes for automatic creation propert item class
  Result := TObject.Create;
end;

function TPool.GetUsedCount: Integer;
begin
  Result := Items.Count - FreeItems.Count;
end;

function TPool.GetTotalCount: Integer;
begin
  Result := Items.Count;
end;

procedure TPool.SetTotalCount(const AValue: Integer);
var
  I: Integer;
begin
  if AValue > Items.Count then begin
    for I := Items.Count to AValue - 1 do begin
      Items.Add(NewItemObject);
      FreeItems.Add(Items.Last);
    end;
  end else
  if AValue < Items.Count then begin
    for I := Items.Count - 1 downto AValue do begin
      while FreeItems.IndexOf(Items[I]) = -1 do
        Sleep(1);
      FreeItems.Delete(FreeItems.IndexOf(Items[I]));
      Items.Delete(I);
    end;
  end;
end;

function TPool.Acquire: TObject;
begin
  while FreeItems.Count = 0 do begin
    //FReleaseEvent.WaitFor(1);
    Sleep(1);
  end;
  Result := FreeItems.Last;
  FreeItems.Count := FreeItems.Count - 1;
  //if not Assigned(Item) then
  //  raise Exception.Create(Format(S);
end;

procedure TPool.Release(Item: TObject);
var
  Index: Integer;
begin
  Index := Items.IndexOf(Item);
  if Index = -1 then
    raise Exception.Create(SReleaseError);

  FreeItems.Add(Item);
  //if FUsedCount < TotalCount then
  //  FReleaseEvent.SetEvent;
end;

constructor TPool.Create;
begin
  inherited;
  Items := TObjectList<TObject>.Create;
  FreeItems := TObjectList<TObject>.Create;
  FreeItems.OwnsObjects := False;
  FReleaseEvent := TEvent.Create(nil, False, False, '');
end;

destructor TPool.Destroy;
begin
  TotalCount := 0;
  FreeAndNil(FReleaseEvent);
  FreeAndNil(FreeItems);
  FreeAndNil(Items);
  inherited;
end;

end.


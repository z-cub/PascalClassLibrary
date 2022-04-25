unit UDebugLog; 

interface

uses
  Classes, SysUtils, FileUtil, Generics.Collections, SyncObjs;

type
  TDebugLogAddEvent = procedure (Group: string; Text: string) of object;

  TDebugLogItem = class
    Time: TDateTime;
    Group: string;
    Text: string;
  end;

  TDebugLogItems = class(TObjectList<TDebugLogItem>)
  end;

  TNewItemEvent = procedure (NewItem: TDebugLogItem) of object;

  { TDebugLog }

  TDebugLog = class(TComponent)
  private
    FFileName: string;
    FMaxCount: Integer;
    FOnNewItem: TNewItemEvent;
    FWriteToFileEnable: Boolean;
    procedure SetMaxCount(const AValue: Integer);
  public
    Items: TDebugLogItems;
    Lock: TCriticalSection;
    procedure Add(Text: string; Group: string = '');
    procedure WriteToFile(Text: string);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property WriteToFileEnable: Boolean read FWriteToFileEnable
      write FWriteToFileEnable;
    property FileName: string read FFileName write FFileName;
    property MaxCount: Integer read FMaxCount write SetMaxCount;
    property OnNewItem: TNewItemEvent read FOnNewItem write FOnNewItem;
  end;

procedure Register;


implementation

resourcestring
  SFileNameNotDefined = 'Filename not defined';

procedure Register;
begin
  RegisterComponents('Common', [TDebugLog]);
end;

{ TDebugLog }

procedure TDebugLog.SetMaxCount(const AValue: Integer);
begin
  if FMaxCount = AValue then Exit;
  FMaxCount := AValue;
  try
    Lock.Acquire;
    if Items.Count > FMaxCount then Items.Count := AValue;
  finally
    Lock.Release;
  end;
end;

procedure TDebugLog.Add(Text: string; Group: string = '');
var
  NewItem: TDebugLogItem;
begin
  NewItem := TDebugLogItem.Create;
  NewItem.Time := Now;
  NewItem.Group := Group;
  NewItem.Text := Text;

  try
    Lock.Acquire;
    Items.Insert(0, NewItem);
    if Items.Count > MaxCount then begin
      Items.Delete(Items.Count - 1);
    end;

    if WriteToFileEnable then begin
      if Group <> '' then Group := Group + '[' + Group + '] ';
      WriteToFile(Group + Text);
    end;
  finally
    Lock.Release;
  end;
  if Assigned(FOnNewItem) then
    FOnNewItem(NewItem);
end;

procedure TDebugLog.WriteToFile(Text: string);
var
  LogFile: TFileStream;
begin
  if FileName = '' then raise Exception.Create(SFileNameNotDefined);
  try
    if ExtractFileDir(FileName) <> '' then
      ForceDirectories(ExtractFileDir(FileName));
    if FileExists(FileName) then LogFile := TFileStream.Create(FileName, fmOpenWrite)
      else LogFile := TFileStream.Create(FileName, fmCreate);
    LogFile.Seek(0, soFromEnd);
    Text := FormatDateTime('hh:nn:ss.zzz', Now) + ': ' + Text + LineEnding;
    LogFile.WriteBuffer(Text[1], Length(Text));
  finally
    FreeAndNil(LogFile);
  end;
end;

constructor TDebugLog.Create(AOwner: TComponent);
begin
  inherited;
  Items := TDebugLogItems.Create;
  Lock := TCriticalSection.Create;
  MaxCount := 100;
  FileName := 'DebugLog.txt';
  WriteToFileEnable := False;
end;

destructor TDebugLog.Destroy;
begin
  FreeAndNil(Items);
  FreeAndNil(Lock);
  inherited;
end;

end.


unit UDataFile;

interface

uses
  Classes, SysUtils, Generics.Collections;

type
  { TDataFile }

  TDataFile = class(TComponent)
  private
    FFileName: string;
    FModified: Boolean;
    FOnModify: TNotifyEvent;
    procedure SetFileName(AValue: string);
    procedure SetModified(AValue: Boolean);
    procedure DoOnModify;
  public
    function GetFileExt: string; virtual;
    function GetFileName: string; virtual;
    function GetFileFilter: string; virtual;
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromFile(FileName: string); virtual;
    procedure SaveToFile(FileName: string); virtual;
    constructor Create(AOwner: TComponent); override;
    property FileName: string read FFileName write SetFileName;
    property Modified: Boolean read FModified write SetModified;
  published
    property OnModify: TNotifyEvent read FOnModify write FOnModify;
  end;

  TDataFileClass = class of TDataFile;

  TDataFiles = class(TObjectList<TDataFile>)
  end;

resourcestring
  SDataFileName = 'Data file';
  SAllFiles = 'All files';

const
  AnyFileExt = '.*';


implementation

{ TDataFile }

procedure TDataFile.SetModified(AValue: Boolean);
begin
  if FModified = AValue then Exit;
  FModified := AValue;
  DoOnModify;
end;

procedure TDataFile.DoOnModify;
begin
  if Assigned(FOnModify) then FOnModify(Self);
end;

function TDataFile.GetFileExt: string;
begin
  Result := '.dat';
end;

function TDataFile.GetFileName: string;
begin
  Result := SDataFileName;
end;

function TDataFile.GetFileFilter: string;
begin
  Result := SAllFiles + '|*' + AnyFileExt;
end;

procedure TDataFile.Assign(Source: TPersistent);
begin
  inherited;
  if Source is TDataFile then begin
    FFileName := TDataFile(Source).FFileName;
    FModified := TDataFile(Source).FModified;
  end;
end;

procedure TDataFile.LoadFromFile(FileName: string);
begin
  FModified := False;
  Self.FileName := FileName;
end;

procedure TDataFile.SaveToFile(FileName: string);
begin
  FModified := False;
  Self.FileName := FileName;
end;

constructor TDataFile.Create(AOwner: TComponent);
begin
  inherited;
  FileName := GetFileName + GetFileExt;
end;

procedure TDataFile.SetFileName(AValue: string);
begin
  if FFileName = AValue then Exit;
  FFileName := AValue;
end;

end.


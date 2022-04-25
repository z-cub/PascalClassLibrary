unit UURI;

// Date: 2011-04-04

interface

uses
  Classes, SysUtils;

const
  URIPathSeparator = '/';

type

  { TPath }

  TPath = class
  private
    function GetAsString: string;
    procedure SetAsString(AValue: string);
  public
    Items: TStringList;
    IsAbsolute: Boolean;
    DirSeparator: string;
    procedure Assign(Source: TPath);
    constructor Create;
    destructor Destroy; override;
    property AsString: string read GetAsString write SetAsString;
  end;

  { TFileName }

  TFileNamePart = (fnpDrive, fnpDirectory, fnpName, fnpExtension);
  TFileNameParts = set of TFileNamePart;

  TFileName = class
  private
  public
    Drive: string;
    Directory: TPath;
    Name: string;
    Extension: string;
    function Combine(Parts: TFileNameParts = [fnpDrive, fnpDirectory, fnpName, fnpExtension]): string;
    procedure Parse(AValue: string);
    procedure Assign(Source: TFileName);
    constructor Create;
    destructor Destroy; override;
  end;

  { TURI }

  TURI = class(TPersistent)
  private
    function GetAsString: string;
    procedure SetAsString(Value: string);
  public
    Scheme: string;
    Authority: string;
    Path: TFileName;
    Query: string;
    Fragment: string;
    constructor Create;
    procedure Clear;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    property AsString: string read GetAsString write SetAsString;
  end;

  { TURL }

  TURL = class(TURI)
  private
    function GetAsString: string;
    procedure SetAsString(Value: string);
  public
    UserName: string;
    Password: string;
    Host: string;
    Port: Word;
    constructor Create;
    destructor Destroy; override;
    property AsString: string read GetAsString write SetAsString;
  end;


implementation

function LeftCutString(var Source: string; out Output: string; Delimiter: string; Allowed: string = ''): Boolean;
var
  I: Integer;
  Matched: Boolean;
begin
  I := 1;
  Matched := True;
  while (I < Length(Source)) and Matched do begin
    Matched := True;
    if (Source[I] = Delimiter) then Matched := False;
    //for J := 1 to Length(Allowed) do
    //  if Source[I] = Allowed[J] then Matched := True;
    if Matched then Inc(I);
  end;
  if (Delimiter = Copy(Source, I, Length(Delimiter))) or (I = Length(Source)) then begin
    Output := Copy(Source, 1, I - 1);
    Delete(Source, 1, Length(Output) + Length(Delimiter));
    Result := True;
  end else begin
    Output := '';
    Result := False;
  end;
end;

function RightCutString(var Source: string; out Output: string; Delimiter: string; Allowed: string = ''): Boolean;
var
  I: Integer;
  Matched: Boolean;
begin
  I := Length(Source);
  Matched := True;
  while (I > 0) and Matched do begin
    Matched := True;
    if (Source[I] = Delimiter) then Matched := False;
    //for J := 1 to Length(Allowed) do
    //  if Source[I] = Allowed[J] then Matched := True;
    if Matched then Dec(I);
  end;
  if (Delimiter = Copy(Source, I - Length(Delimiter) + 1, Length(Delimiter))) or (I = 0) then begin
    Output := Copy(Source, I + 1, Length(Source) - I);
    Delete(Source, I, Length(Output) + Length(Delimiter));
    Result := True;
  end else begin
    Output := '';
    Result := False;
  end;
end;

{ TPath }

function TPath.GetAsString: string;
var
  I: Integer;
begin
  if IsAbsolute then Result := DirSeparator
    else Result := '';
  for I := 0 to Items.Count - 1 do
    Result := Result + Items[I] + DirSeparator;
end;

procedure TPath.SetAsString(AValue: string);
var
  Name: string;
begin
  Items.Clear;
  if Length(AValue) > 0 then begin
    if AValue[1] = DirSeparator then begin
      IsAbsolute := True;
      Delete(AValue, 1, 1);
    end else IsAbsolute := False;
    while Pos(DirSeparator, AValue) > 0 do begin
      Name := Copy(AValue, 1, Pos(DirSeparator, AValue) - 1);
      Delete(AValue, 1, Pos(DirSeparator, AValue));
      Items.Add(Name);
    end;
    if Length(AValue) > 0 then
      Items.Add(AValue);
  end else IsAbsolute := False;
end;

procedure TPath.Assign(Source: TPath);
begin
  IsAbsolute := Source.IsAbsolute;
  Items.Assign(Source.Items);
  DirSeparator := Source.DirSeparator;
end;

constructor TPath.Create;
begin
  Items := TStringList.Create;
  DirSeparator := DirectorySeparator;
end;

destructor TPath.Destroy;
begin
  Items.Free;
  inherited Destroy;
end;

{ TURI }

function TURI.GetAsString: string;
begin
  Result := '';
  if Scheme <> '' then Result := Scheme + ':';
  if Path.Combine <> '' then begin
    Result := Result + '//' + Authority;
    if Scheme = 'file' then Result := Result + URIPathSeparator;
    Result := Result + Path.Combine;
  end;
  if Query <> '' then Result := Result + '?' + Query;
  if Fragment <> '' then Result := Result + '#' + Fragment;
end;

procedure TURI.SetAsString(Value: string);
begin
  LeftCutString(Value, Scheme, ':');
  if Copy(Value, 1, 2) = '//' then begin
    Value := Copy(Value, 3, Length(Value));
    LeftCutString(Value, Authority, URIPathSeparator);
  end;
  RightCutString(Value, Fragment, '#');
  RightCutString(Value, Query, '?', '=&');
  //if Scheme = 'file' then Delete(Value, 1, 1); // Remove beginning slash
  Path.Parse(Value);
end;

constructor TURI.Create;
begin
  Path := TFileName.Create;
  Path.Directory.DirSeparator := URIPathSeparator;
end;

procedure TURI.Clear;
begin
  Scheme := '';
  Authority := '';
  Path.Parse('');
  Fragment := '';
  Query := '';
end;

destructor TURI.Destroy;
begin
  Path.Free;
  inherited Destroy;
end;

procedure TURI.Assign(Source: TPersistent);
begin
  if Source is TURI then begin
    Scheme := TURI(Source).Scheme;
    Authority := TURI(Source).Authority;
    Path.Assign(TURI(Source).Path);
    Fragment := TURI(Source).Fragment;
    Query := TURI(Source).Query;
  end else inherited Assign(Source);
end;

{ TURL }

function TURL.GetAsString: string;
begin
  Result := '';
  if Scheme <> '' then Result := Scheme + '://';
  if UserName <> '' then begin
    Result := Result + UserName;
    if UserName <> '' then Result := Result + ':' + Password;
    Result := Result + '@';
  end;
  if Host <> '' then Result := Result + Host;
  if Port <> 0 then Result := Result + ':' + IntToStr(Port);
  if Path.Combine <> '' then Result := Result + Path.Combine;
  if Query <> '' then Result := Result + '?' + Query;
  if Fragment <> '' then Result := Result + '#' + Fragment;
end;

procedure TURL.SetAsString(Value: string);
var
  HostAddr: string;
  HostPort: string;
  TempPath: string;
begin
  LeftCutString(Value, Scheme, '://');
  if LeftCutString(Value, UserName, ':') then LeftCutString(Value, Password, '@')
    else LeftCutString(Value, UserName, '@');
  RightCutString(Value, Fragment, '#');
  RightCutString(Value, Query, '?', '=&');
  if LeftCutString(Value, HostAddr, ':', '.') then begin
    LeftCutString(Value, HostPort, '');
    Port := StrToInt(HostPort);
  end else LeftCutString(Value, HostAddr, '', '.');
  Host := HostAddr;
  LeftCutString(Value, TempPath, '', URIPathSeparator + '.');
  Path.Parse(TempPath);
end;

constructor TURL.Create;
begin

end;

destructor TURL.Destroy;
begin
  inherited Destroy;
end;

{ TFileName }

function TFileName.Combine(Parts: TFileNameParts): string;
begin
  Result := '';
  if (fnpDrive in Parts) and (Drive <> '') then Result := Result + Drive;
  if (fnpDirectory in Parts) and (Directory.AsString <> '') then
    Result := Result + Directory.AsString;
  if (fnpName in Parts) then Result := Result + Name;
  if (fnpExtension in Parts) and (Extension <> '') then
    Result := Result + Extension;
end;

procedure TFileName.Parse(AValue: string);
begin
  if Pos(ExtensionSeparator, AValue) > 0 then begin
    RightCutString(AValue, Extension, ExtensionSeparator);
    Extension := ExtensionSeparator + Extension;
  end else Extension := '';
  if Pos(Directory.DirSeparator, AValue) > 0 then
    RightCutString(AValue, Name, Directory.DirSeparator)
    else begin
      Name := AValue;
      AValue := '';
    end;
  if Pos(DriveSeparator, AValue) > 0 then begin
    LeftCutString(AValue, Drive, DriveSeparator);
    Drive := Drive + DriveSeparator;
  end else Drive := '';
  if (Drive <> '') and (AValue = '') then
    Directory.AsString := Directory.DirSeparator
    else Directory.AsString := AValue;
end;

procedure TFileName.Assign(Source: TFileName);
begin
  Name := Source.Name;
  Extension := Source.Extension;
  Drive := Source.Drive;
  Directory.Assign(Source.Directory);
end;

constructor TFileName.Create;
begin
  Directory := TPath.Create;
end;

destructor TFileName.Destroy;
begin
  Directory.Free;
  inherited Destroy;
end;


end.


unit UCommon;

interface

uses
  Windows, Classes, SysUtils, SpecializedList, StrUtils; //, ShFolder, ShellAPI;

type
  TArrayOfByte = array of Byte;
  TArrayOfString = array of string;
  TExceptionEvent = procedure(Sender: TObject; E: Exception) of object;

  TUserNameFormat = (
    unfNameUnknown = 0, // Unknown name type.
    unfNameFullyQualifiedDN = 1,  // Fully qualified distinguished name
    unfNameSamCompatible = 2, // Windows NT® 4.0 account name
    unfNameDisplay = 3,  // A "friendly" display name
    unfNameUniqueId = 6, // GUID string that the IIDFromString function returns
    unfNameCanonical = 7,  // Complete canonical name
    unfNameUserPrincipal = 8, // User principal name
    unfNameCanonicalEx = 9,
    unfNameServicePrincipal = 10,  // Generalized service principal name
    unfDNSDomainName = 11);

var
  ExceptionHandler: TExceptionEvent;

function IntToBin(Data: Cardinal; Count: Byte): string;
function TryHexToInt(Data: string; var Value: Integer): Boolean;
function TryBinToInt(Data: string; var Value: Integer): Boolean;
//function DelTree(DirName : string): Boolean;
//function GetSpecialFolderPath(Folder: Integer): string;
function BCDToInt(Value: Byte): Byte;
function CompareByteArray(Data1, Data2: TArrayOfByte): Boolean;
function GetUserName: string;
function LoggedOnUserNameEx(Format: TUserNameFormat): string;
function SplitString(var Text: string; Count: Word): string;
function GetBit(Variable: QWord; Index: Byte): Boolean;
procedure SetBit(var Variable: QWord; Index: Byte; State: Boolean);
procedure SetBit(var Variable: Cardinal; Index: Byte; State: Boolean);
procedure SetBit(var Variable: Word; Index: Byte; State: Boolean);
function AddLeadingZeroes(const aNumber, Length : integer) : string;
function LastPos(const SubStr: String; const S: String): Integer;

implementation

(*function DelTree(DirName : string): Boolean;
var
  SHFileOpStruct : TSHFileOpStruct;
  DirBuf : array [0..255] of char;
begin
  DirName := UTF8Decode(DirName);
  try
    Fillchar(SHFileOpStruct,Sizeof(SHFileOpStruct),0) ;
    FillChar(DirBuf, Sizeof(DirBuf), 0 ) ;
    StrPCopy(DirBuf, DirName) ;
    with SHFileOpStruct do begin
      Wnd := 0;
      pFrom := @DirBuf;
      wFunc := FO_DELETE;
      fFlags := FOF_ALLOWUNDO;
      fFlags := fFlags or FOF_NOCONFIRMATION;
      fFlags := fFlags or FOF_SILENT;
    end;
    Result := (SHFileOperation(SHFileOpStruct) = 0) ;
  except
     Result := False;
  end;
end;*)

function LastPos(const SubStr: String; const S: String): Integer;
begin
  Result := Pos(ReverseString(SubStr), ReverseString(S));
  if (Result <> 0) then
    Result := ((Length(S) - Length(SubStr)) + 1) - Result + 1;
end;

function BCDToInt(Value: Byte): Byte;
begin
  Result := (Value shr 4) * 10 + (Value and 15);
end;

(*function GetSpecialFolderPath(Folder: Integer): string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  Path: array[0..MAX_PATH] of Char;
begin
  Result := 'C:\Test';
  if SUCCEEDED(SHGetFolderPath(0, Folder, 0, SHGFP_TYPE_CURRENT, @path[0])) then
    Result := path
  else
    Result := '';
end;*)

function IntToBin(Data: Cardinal; Count: Byte): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
    Result := IntToStr((Data shr I) and 1) + Result;
end;

function IntToHex(Data: Cardinal; Count: Byte): string;
const
  Chars: array[0..15] of Char = '0123456789ABCDEF';
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
    Result := Result + Chars[(Data shr (I * 4)) and 15];
end;

function TryHexToInt(Data: string; var Value: Integer): Boolean;
var
  I: Integer;
begin
  Data := UpperCase(Data);
  Result := True;
  Value := 0;
  for I := 0 to Length(Data) - 1 do begin
    if (Data[I + 1] >= '0') and (Data[I + 1] <= '9') then
      Value := Value or (Ord(Data[I + 1]) - Ord('0')) shl ((Length(Data) - I - 1) * 4)
    else if (Data[I + 1] >= 'A') and (Data[I + 1] <= 'F') then
      Value := Value or (Ord(Data[I + 1]) - Ord('A') + 10) shl ((Length(Data) - I - 1) * 4)
    else Result := False;
  end;
end;

function TryBinToInt(Data: string; var Value: Integer): Boolean;
var
  I: Integer;
begin
  Result := True;
  Value := 0;
  for I := 0 to Length(Data) - 1 do begin
    if (Data[I + 1] >= '0') and (Data[I + 1] <= '1') then
      Value := Value or (Ord(Data[I + 1]) - Ord('0')) shl ((Length(Data) - I - 1))
    else Result := False;
  end;
end;

function CompareByteArray(Data1, Data2: TArrayOfByte): Boolean;
var
  I: Integer;
begin
  if Length(Data1) = Length(Data2) then begin
    Result := True;
    for I := 0 to Length(Data1) - 1 do begin
      if Data1[I] <> Data2[I] then begin
        Result := False;
        Break;
      end
    end;
  end else Result := False;
end;

function Explode(Separator: char; Data: string): TArrayOfString;
begin
  SetLength(Result, 0);
  while Pos(Separator, Data) > 0 do begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Copy(Data, 1, Pos(Separator, Data) - 1);
    Delete(Data, 1, Pos(Separator, Data));
  end;
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := Data;
end;

function GetUserName: string;
const
  MAX_USERNAME_LENGTH = 256;
var
  L: LongWord;
begin
  L := MAX_USERNAME_LENGTH + 2;
  SetLength(Result, L);
  if Windows.GetUserName(PChar(Result), L) and (L > 0) then
    SetLength(Result, StrLen(PChar(Result))) else
    Result := '';
end;

procedure GetUserNameEx(NameFormat: DWORD;
  lpNameBuffer: LPSTR; nSize: PULONG); stdcall;
  external 'secur32.dll' Name 'GetUserNameExA';


function LoggedOnUserNameEx(Format: TUserNameFormat): string;
var
  UserName: array[0..250] of Char;
  Size: DWORD;
begin
  Size := 250;
  GetUserNameEx(Integer(Format), @UserName, @Size);
  Result := UTF8Encode(UserName);
end;

function SplitString(var Text: string; Count: Word): string;
begin
  Result := Copy(Text, 1, Count);
  Delete(Text, 1, Count);
end;

function GetBit(Variable:QWord;Index:Byte):Boolean;
begin
  Result := ((Variable shr Index) and 1) = 1;
end;

procedure SetBit(var Variable:QWord;Index:Byte;State:Boolean); overload;
begin
  Variable := (Variable and ((1 shl Index) xor QWord($ffffffffffffffff))) or (QWord(State) shl Index);
end;

procedure SetBit(var Variable:Cardinal;Index:Byte;State:Boolean); overload;
begin
  Variable := (Variable and ((1 shl Index) xor Cardinal($ffffffff))) or (Cardinal(State) shl Index);
end;

procedure SetBit(var Variable:Word;Index:Byte;State:Boolean); overload;
begin
  Variable := (Variable and ((1 shl Index) xor Word($ffff))) or (Word(State) shl Index);
end;

function AddLeadingZeroes(const aNumber, Length : integer) : string;
begin
  Result := SysUtils.Format('%.*d', [Length, aNumber]) ;
end;

end.

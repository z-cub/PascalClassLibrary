unit UCommon;

{$mode delphi}

interface

uses
  {$ifdef Windows}Windows,{$endif}
  {$ifdef Linux}baseunix,{$endif}
  Classes, SysUtils, StrUtils, Dialogs, Process, LCLIntf,
  FileUtil; //, ShFolder, ShellAPI;

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

  TFilterMethod = function (FileName: string): Boolean of object;
  TFileNameMethod = procedure (FileName: string) of object;

var
  ExceptionHandler: TExceptionEvent;
  DLLHandle1: HModule;

{$IFDEF Windows}
  GetUserNameEx: procedure (NameFormat: DWORD;
    lpNameBuffer: LPSTR; nSize: PULONG); stdcall;
{$ENDIF}

function AddLeadingZeroes(const aNumber, Length : integer) : string;
function BinToInt(BinStr: string): Int64;
function BinToHexString(Source: AnsiString): string;
//function DelTree(DirName : string): Boolean;
//function GetSpecialFolderPath(Folder: Integer): string;
function BCDToInt(Value: Byte): Byte;
function CompareByteArray(Data1, Data2: TArrayOfByte): Boolean;
procedure CopyStringArray(Dest: TStringArray; Source: array of string);
function CombinePaths(Path1, Path2: string): string;
function ComputerName: string;
procedure DeleteFiles(APath, AFileSpec: string);
procedure ExecuteProgram(Executable: string; Parameters: array of string);
procedure FileDialogUpdateFilterFileType(FileDialog: TOpenDialog);
procedure FreeThenNil(var Obj);
function GetDirCount(Dir: string): Integer;
function GetUserName: string;
function GetBitCount(Variable: QWord; MaxIndex: Integer): Integer;
function GetBit(Variable: QWord; Index: Byte): Boolean;
function GetStringPart(var Text: string; Separator: string): string;
function GenerateNewName(OldName: string): string;
function GetFileFilterItemExt(Filter: string; Index: Integer): string;
function IntToBin(Data: Int64; Count: Byte): string;
function LastPos(const SubStr: String; const S: String): Integer;
function LoadFileToStr(const FileName: TFileName): AnsiString;
function LoggedOnUserNameEx(Format: TUserNameFormat): string;
function MergeArray(A, B: array of string): TArrayOfString;
function OccurenceOfChar(What: Char; Where: string): Integer;
procedure OpenWebPage(URL: string);
procedure OpenFileInShell(FileName: string);
function PosFromIndex(SubStr: string; Text: string;
  StartIndex: Integer): Integer;
function PosFromIndexReverse(SubStr: string; Text: string;
  StartIndex: Integer): Integer;
function RemoveQuotes(Text: string): string;
procedure SaveStringToFile(S, FileName: string);
procedure SetBit(var Variable: Int64; Index: Byte; State: Boolean); overload;
procedure SetBit(var Variable: QWord; Index: Byte; State: Boolean); overload;
procedure SetBit(var Variable: Cardinal; Index: Byte; State: Boolean); overload;
procedure SetBit(var Variable: Word; Index: Byte; State: Boolean); overload;
procedure SearchFiles(AList: TStrings; Dir: string;
  FilterMethod: TFilterMethod = nil; FileNameMethod: TFileNameMethod = nil);
function SplitString(var Text: string; Count: Word): string;
function StripTags(const S: string): string;
function TryHexToInt(Data: string; var Value: Integer): Boolean;
function TryBinToInt(Data: string; var Value: Integer): Boolean;
procedure SortStrings(Strings: TStrings);


implementation

function BinToInt(BinStr : string) : Int64;
var
  i : byte;
  RetVar : Int64;
begin
  BinStr := UpperCase(BinStr);
  if BinStr[length(BinStr)] = 'B' then Delete(BinStr,length(BinStr),1);
  RetVar := 0;
  for i := 1 to length(BinStr) do begin
    if not (BinStr[i] in ['0','1']) then begin
      RetVar := 0;
      Break;
    end;
    RetVar := (RetVar shl 1) + (byte(BinStr[i]) and 1) ;
  end;

  Result := RetVar;
end;

function BinToHexString(Source: AnsiString): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Source) do begin
    Result := Result + LowerCase(IntToHex(Ord(Source[I]), 2));
  end;
end;


procedure DeleteFiles(APath, AFileSpec: string);
var
  SearchRec: TSearchRec;
  Find: Integer;
  Path: string;
begin
  Path := IncludeTrailingPathDelimiter(APath);

  Find := FindFirst(Path + AFileSpec, faAnyFile xor faDirectory, SearchRec);
  while Find = 0 do begin
    DeleteFile(Path + SearchRec.Name);

    Find := SysUtils.FindNext(SearchRec);
  end;
  FindClose(SearchRec);
end;


function GetFileFilterItemExt(Filter: string; Index: Integer): string;
var
  List: TStringList;
begin
  try
    List := TStringList.Create;
    List.Text := StringReplace(Filter, '|', #10, [rfReplaceAll]);
    Result := List[Index * 2 + 1];
  finally
    List.Free;
  end;
end;

procedure FileDialogUpdateFilterFileType(FileDialog: TOpenDialog);
var
  FileExt: string;
begin
  FileExt := GetFileFilterItemExt(FileDialog.Filter, FileDialog.FilterIndex - 1);
  Delete(FileExt, 1, 1); // Remove symbol '*'
  if FileExt <> '.*' then
    FileDialog.FileName := ChangeFileExt(FileDialog.FileName, FileExt)
end;

function GenerateNewName(OldName: string): string;
var
  I: Integer;
  Number: Integer;
begin
  Number := 1;
  // Find number on end
  if Length(OldName) > 0 then begin
    I := Length(OldName);
    while (I > 1) and ((OldName[I] >= '0') and (OldName[I] <= '9')) do Dec(I);
    TryStrToInt(Copy(OldName, I + 1, Length(OldName) - I), Number);
    Inc(Number)
  end;
  Result := Copy(OldName, 1, I) + IntToStr(Number);
end;

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

function IntToBin(Data: Int64; Count: Byte): string;
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

{$IFDEF Windows}
function GetUserName: string;
const
  MAX_USERNAME_LENGTH = 256;
var
  L: LongWord;
begin
  L := MAX_USERNAME_LENGTH + 2;
  SetLength(Result, L);
  if Windows.GetUserName(PChar(Result), L) and (L > 0) then begin
    SetLength(Result, StrLen(PChar(Result)));
    Result := UTF8Encode(Result);
  end else Result := '';
end;

function GetVersionInfo: TOSVersionInfo;
begin
  Result.dwOSVersionInfoSize := SizeOf(Result);
  if GetVersionEx(Result) then begin
  end;
end;
{$endif}

function ComputerName: string;
{$ifdef mswindows}
const
 INFO_BUFFER_SIZE = 32767;
var
  Buffer : array[0..INFO_BUFFER_SIZE] of WideChar;
  Ret : DWORD;
begin
  Ret := INFO_BUFFER_SIZE;
  If (GetComputerNameW(@Buffer[0],Ret)) then begin
    Result := UTF8Encode(WideString(Buffer));
  end
  else begin
    Result := 'ERROR_NO_COMPUTERNAME_RETURNED';
  end;
end;
{$endif}
{$ifdef unix}
var
  Name: UtsName;
begin
  fpuname(Name);
  Result := Name.Nodename;
end;
{$endif}

{$ifdef windows}
function LoggedOnUserNameEx(Format: TUserNameFormat): string;
const
  MaxLength = 1000;
var
  UserName: array[0..MaxLength] of Char;
  VersionInfo: TOSVersionInfo;
  Size: DWORD;
begin
  VersionInfo := GetVersionInfo;
  if VersionInfo.dwPlatformId = VER_PLATFORM_WIN32_NT then begin
    Size := MaxLength;
    GetUserNameEx(Integer(Format), @UserName, @Size);
    //ShowMessage(SysErrorMessage(GetLastError));
    if GetLastError = 0 then Result := UTF8Encode(UserName)
      else Result := GetUserName;
  end else Result := GetUserName;
end;
{$ELSE}
function GetUserName: string;
begin
  Result := '';
end;

function LoggedOnUserNameEx(Format: TUserNameFormat): string;
begin
  Result := '';
end;

{$ENDIF}

function SplitString(var Text: string; Count: Word): string;
begin
  Result := Copy(Text, 1, Count);
  Delete(Text, 1, Count);
end;

function GetBitCount(Variable: QWord; MaxIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to MaxIndex - 1 do
    if ((Variable shr I) and 1) = 1 then Inc(Result);
end;

function GetBit(Variable:QWord;Index:Byte):Boolean;
begin
  Result := ((Variable shr Index) and 1) = 1;
end;

procedure SetBit(var Variable: Int64; Index: Byte; State: Boolean);
begin
  Variable := (Variable and ((1 shl Index) xor High(QWord))) or (Int64(State) shl Index);
end;

procedure SetBit(var Variable:QWord;Index:Byte;State:Boolean); overload;
begin
  Variable := (Variable and ((1 shl Index) xor High(QWord))) or (QWord(State) shl Index);
end;

procedure SetBit(var Variable:Cardinal;Index:Byte;State:Boolean); overload;
begin
  Variable := (Variable and ((1 shl Index) xor High(Cardinal))) or (Cardinal(State) shl Index);
end;

procedure SetBit(var Variable:Word;Index:Byte;State:Boolean); overload;
begin
  Variable := (Variable and ((1 shl Index) xor High(Word))) or (Word(State) shl Index);
end;

function AddLeadingZeroes(const aNumber, Length : integer) : string;
begin
  Result := SysUtils.Format('%.*d', [Length, aNumber]) ;
end;

procedure LoadLibraries;
begin
  {$IFDEF Windows}
  DLLHandle1 := LoadLibrary('secur32.dll');
  if DLLHandle1 <> 0 then
  begin
    @GetUserNameEx := GetProcAddress(DLLHandle1, 'GetUserNameExA');
  end;
  {$ENDIF}
end;

procedure FreeLibraries;
begin
  {$IFDEF Windows}
  if DLLHandle1 <> 0 then FreeLibrary(DLLHandle1);
  {$ENDIF}
end;

procedure ExecuteProgram(Executable: string; Parameters: array of string);
var
  Process: TProcess;
  I: Integer;
begin
  try
    Process := TProcess.Create(nil);
    Process.Executable := Executable;
    for I := 0 to Length(Parameters) - 1 do
      Process.Parameters.Add(Parameters[I]);
    Process.Options := [poNoConsole];
    Process.Execute;
  finally
    Process.Free;
  end;
end;

procedure FreeThenNil(var Obj);
begin
  TObject(Obj).Free;
  TObject(Obj) := nil;
end;

procedure OpenWebPage(URL: string);
begin
  OpenURL(URL);
end;

procedure OpenFileInShell(FileName: string);
begin
  ExecuteProgram('cmd.exe', ['/c', 'start', FileName]);
end;

function RemoveQuotes(Text: string): string;
begin
  Result := Text;
  if (Pos('"', Text) = 1) and (Text[Length(Text)] = '"') then
    Result := Copy(Text, 2, Length(Text) - 2);
end;

function OccurenceOfChar(What: Char; Where: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(Where) do
    if Where[I] = What then Inc(Result);
end;

function GetDirCount(Dir: string): Integer;
begin
  Result := OccurenceOfChar(DirectorySeparator, Dir);
  if Copy(Dir, Length(Dir), 1) = DirectorySeparator then
    Dec(Result);
end;

function MergeArray(A, B: array of string): TArrayOfString;
var
  I: Integer;
begin
  SetLength(Result, Length(A) + Length(B));
  for I := 0 to Length(A) - 1 do
    Result[I] := A[I];
  for I := 0 to Length(B) - 1 do
    Result[Length(A) + I] := B[I];
end;

function LoadFileToStr(const FileName: TFileName): AnsiString;
var
  FileStream: TFileStream;
  Read: Integer;
begin
  Result := '';
  FileStream := TFileStream.Create(FileName, fmOpenRead);
  try
    if FileStream.Size > 0 then begin
      SetLength(Result, FileStream.Size);
      Read := FileStream.Read(Pointer(Result)^, FileStream.Size);
      SetLength(Result, Read);
    end;
  finally
    FileStream.Free;
  end;
end;

function DefaultSearchFilter(const FileName: string): Boolean;
begin
  Result := True;
end;

procedure SaveStringToFile(S, FileName: string);
var
  F: TextFile;
begin
  AssignFile(F, FileName);
  try
    ReWrite(F);
    Write(F, S);
  finally
    CloseFile(F);
  end;
end;

procedure SearchFiles(AList: TStrings; Dir: string;
  FilterMethod: TFilterMethod = nil; FileNameMethod: TFileNameMethod = nil);
var
  SR: TSearchRec;
begin
  Dir := IncludeTrailingPathDelimiter(Dir);
  if FindFirst(Dir + '*', faAnyFile, SR) = 0 then
    try
      repeat
        if (SR.Name = '.') or (SR.Name = '..') or (Assigned(FilterMethod) and (not FilterMethod(SR.Name) or
          not FilterMethod(Copy(Dir, 3, Length(Dir)) + SR.Name))) then Continue;
        if Assigned(FileNameMethod) then
          FileNameMethod(Dir + SR.Name);
        AList.Add(Dir + SR.Name);
        if (SR.Attr and faDirectory) <> 0 then
          SearchFiles(AList, Dir + SR.Name, FilterMethod);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
end;

function GetStringPart(var Text: string; Separator: string): string;
var
  P: Integer;
begin
  P := Pos(Separator, Text);
  if P > 0 then begin
    Result := Copy(Text, 1, P - 1);
    Delete(Text, 1, P - 1 + Length(Separator));
  end else begin
    Result := Text;
    Text := '';
  end;
  Result := Trim(Result);
  Text := Trim(Text);
end;

function StripTags(const S: string): string;
var
  Len: Integer;

  function ReadUntil(const ReadFrom: Integer; const C: Char): Integer;
  var
    J: Integer;
  begin
    for J := ReadFrom to Len do
      if (S[j] = C) then
      begin
        Result := J;
        Exit;
      end;
    Result := Len + 1;
  end;

var
  I, APos: Integer;
begin
  Len := Length(S);
  I := 0;
  Result := '';
  while (I <= Len) do begin
    Inc(I);
    APos := ReadUntil(I, '<');
    Result := Result + Copy(S, I, APos - i);
    I := ReadUntil(APos + 1, '>');
  end;
end;

function PosFromIndex(SubStr: string; Text: string;
  StartIndex: Integer): Integer;
var
  I, MaxLen: SizeInt;
  Ptr: PAnsiChar;
begin
  Result := 0;
  if (StartIndex < 1) or (StartIndex > Length(Text) - Length(SubStr)) then Exit;
  if Length(SubStr) > 0 then begin
    MaxLen := Length(Text) - Length(SubStr) + 1;
    I := StartIndex;
    Ptr := @Text[StartIndex];
    while (I <= MaxLen) do begin
      if (SubStr[1] = Ptr^) and (CompareByte(Substr[1], Ptr^, Length(SubStr)) = 0) then begin
        Result := I;
        Exit;
      end;
      Inc(I);
      Inc(Ptr);
    end;
  end;
end;

function PosFromIndexReverse(SubStr: string; Text: string;
  StartIndex: Integer): Integer;
var
  I: SizeInt;
  Ptr: PAnsiChar;
begin
  Result := 0;
  if (StartIndex < 1) or (StartIndex > Length(Text)) then Exit;
  if Length(SubStr) > 0 then begin
    I := StartIndex;
    Ptr := @Text[StartIndex];
    while (I > 0) do begin
      if (SubStr[1] = Ptr^) and (CompareByte(Substr[1], Ptr^, Length(SubStr)) = 0) then begin
        Result := I;
        Exit;
      end;
      Dec(I);
      Dec(Ptr);
    end;
  end;
end;

procedure CopyStringArray(Dest: TStringArray; Source: array of string);
var
  I: Integer;
begin
  SetLength(Dest, Length(Source));
  for I := 0 to Length(Dest) - 1 do
    Dest[I] := Source[I];
end;

function CombinePaths(Path1, Path2: string): string;
begin
  Result := Path1;
  if Result <> '' then Result := Result + DirectorySeparator + Path2
    else Result := Path2;
end;

procedure SortStrings(Strings: TStrings);
var
  Tmp: TStringList;
begin
  Strings.BeginUpdate;
  try
    if Strings is TStringList then begin
      TStringList(Strings).Sort;
    end else begin
      Tmp := TStringList.Create;
      try
        Tmp.Assign(Strings);
        Tmp.Sort;
        Strings.Assign(Tmp);
      finally
        Tmp.Free;
      end;
    end;
  finally
    Strings.EndUpdate;
  end;
end;


initialization

LoadLibraries;


finalization

FreeLibraries;

end.

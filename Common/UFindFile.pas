{TFindFile

Article:
http://delphi.about.com/library/weekly/aa052300a.htm

Tired of using FindFirst, Next and Close?
Come see how to encapsulate all those functions
in a single "find-files-recursively" component.
It's easy to use, free and with code.


********************************************
Zarko Gajic
About.com Guide to Delphi Programming
http://delphi.about.com
email: delphi.guide@about.com
********************************************

}

unit UFindFile;

interface

uses
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  EDirNotFound = class(Exception);

  TFileAttrKind = (ffaReadOnly, ffaHidden, ffaSysFile, ffaVolumeID, ffaDirectory, ffaArchive, ffaAnyFile);
  TFileAttrib = set of TFileAttrKind;

  TFindFile = class(TComponent)
  private
    s : TStringList;

    fSubFolder : boolean;
    fAttr: TFileAttrib;
    fPath : string;
    fFileMask : string;

    procedure SetPath(Value: string);
    procedure FileSearch(const inPath : string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function SearchForFiles: TStringList;
  published
    property FileAttr: TFileAttrib read fAttr write fAttr;
    property InSubFolders : boolean read fSubFolder write fSubFolder;
    property Path : string read fPath write SetPath;
    property FileMask : string read fFileMask write fFileMask ;
  end;

const
{$IFDEF WINDOWS}
  FilterAll = '*.*';
{$ENDIF}
{$IFDEF UNIX}
  FilterAll = '*';
{$ENDIF}

procedure Register;

implementation

resourcestring
  SDirNotFound = 'Directory not found';

procedure Register;
begin
  RegisterComponents('Common', [TFindFile]);
end;

constructor TFindFile.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Path := IncludeTrailingBackslash(UTF8Encode(GetCurrentDir));
  FileMask := FilterAll;
  FileAttr := [ffaAnyFile];
  s := TStringList.Create;
end;

destructor TFindFile.Destroy;
begin
  s.Free;
  inherited Destroy;
end;

procedure TFindFile.SetPath(Value: string);
begin
  if fPath <> Value then
  begin
    if Value <> '' then
      if DirectoryExists(UTF8Decode(Value)) then
        fPath := IncludeTrailingBackslash(Value)
        else raise EDirNotFound.Create(SDirNotFound);
  end;
end;

function TFindFile.SearchForFiles: TStringList;
begin
  s.Clear;
  try
    FileSearch(Path);
  finally
    Result := s;
  end;
end;

procedure TFindFile.FileSearch(const InPath : string);
var Rec  : TSearchRec;
    Attr : integer;
begin
  Attr := 0;
  if ffaReadOnly in FileAttr then Attr := Attr + faReadOnly;
  if ffaHidden in FileAttr then Attr := Attr + 2; //faHidden; use constant to avoid platform warning
  if ffaSysFile in FileAttr then Attr := Attr + 4; //faSysFile; use constant to avoid platform warning
  // Deprecated: if ffaVolumeID in FileAttr then Attr := Attr + faVolumeID;
  if ffaDirectory in FileAttr then Attr := Attr + faDirectory;
  if ffaArchive in FileAttr then Attr := Attr + faArchive;
  if ffaAnyFile in FileAttr then Attr := Attr + faAnyFile;

  if SysUtils.FindFirst(inPath + FileMask, Attr, Rec) = 0 then
  try
    repeat
      s.Add(inPath + Rec.Name);
    until SysUtils.FindNext(Rec) <> 0;
  finally
    SysUtils.FindClose(Rec);
  end;

  If not InSubFolders then Exit;

  if SysUtils.FindFirst(inPath + FilterAll, faDirectory, Rec) = 0 then
  try
    repeat
      if ((Rec.Attr and faDirectory) > 0) and (Rec.Name <> '.')
      and (Rec.Name <> '..') then
        FileSearch(IncludeTrailingBackslash(inPath + Rec.Name));
    until SysUtils.FindNext(Rec) <> 0;
  finally
    SysUtils.FindClose(Rec);
  end;
end; 

end.


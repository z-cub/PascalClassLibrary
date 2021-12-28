unit UTranslator;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, ExtCtrls, Controls, fgl, LazFileUtils, LazUTF8,
  Translations, TypInfo, Dialogs, FileUtil, LCLProc, ULanguages, LCLType,
  LCLVersion;

type
  THandleStringEvent = function (AValue: string): string of object;

  TPoFiles = class(TFPGObjectList<TPOFile>)
  end;

  { TComponentExcludes }

  TComponentExcludes = class
    ExcludedClassType: TClass;
    PropertyExcludes: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

  { TComponentExcludesList }

  TComponentExcludesList = class(TFPGObjectList<TComponentExcludes>)
    function FindByClassType(AClassType: TClass): TComponentExcludes;
    procedure DumpToStrings(Strings: TStrings);
  end;

  { TTranslator }

  TTranslator = class(TComponent)
  private
    FLanguage: TLanguage;
    FOnAutomaticLanguage: THandleStringEvent;
    FOnTranslate: TNotifyEvent;
    FPoFilesFolder: string;
    FPoFiles: TPoFiles;
    function GetLocale: string;
    function GetLocaleShort: string;
    function FindLocaleFileName(LCExt: string): string;
    function GetLocaleFileName(const LangID, LCExt: string): string;
    procedure ReloadFiles;
    procedure SetPOFilesFolder(const AValue: string);
    procedure SetLanguage(const AValue: TLanguage);
    procedure TranslateProperty(Component: TPersistent; PropInfo: PPropInfo);
    function IsExcluded(Component: TPersistent; PropertyName: string): Boolean;
    function GetLangFileDir: string;
  public
    ComponentExcludes: TComponentExcludesList;
    Languages: TLanguages;
    procedure Translate;
    procedure LanguageListToStrings(Strings: TStrings; WithCode: Boolean = True);
    procedure TranslateResourceStrings(PoFileName: string);
    procedure TranslateUnitResourceStrings(UnitName: string; PoFileName: string);
    procedure TranslateComponent(Component: TPersistent);
    procedure TranslateComponentRecursive(Component: TComponent);
    function TranslateText(Identifier, Text: string): string;
    procedure AddExcludes(AClassType: TClass; PropertyName: string);
    procedure CheckLanguageFiles;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property POFilesFolder: string read FPoFilesFolder write SetPOFilesFolder;
    property Language: TLanguage read FLanguage write SetLanguage;
    property OnTranslate: TNotifyEvent read FOnTranslate write FOnTranslate;
    property OnAutomaticLanguage: THandleStringEvent read FOnAutomaticLanguage
      write FOnAutomaticLanguage;
  end;

procedure Register;


implementation

procedure Register;
begin
  RegisterComponents('Common', [TTranslator]);
end;

{ TComponentExcludesList }

function TComponentExcludesList.FindByClassType(AClassType: TClass
  ): TComponentExcludes;
var
  I: Integer;
begin
  I := 0;
  while (I < Count) and (TComponentExcludes(Items[I]).ExcludedClassType <> AClassType) do
    Inc(I);
  if I < Count then Result := TComponentExcludes(Items[I])
    else Result := nil;
end;

procedure TComponentExcludesList.DumpToStrings(Strings: TStrings);
var
  I, J: Integer;
  Text: string;
begin
  Strings.Clear;
  for I := 0 to Count - 1 do
  with TComponentExcludes(Items[I]) do begin
    Text := ExcludedClassType.ClassName + ': ';
    for J := 0 to PropertyExcludes.Count - 1 do
      Text := Text + PropertyExcludes[J] + ', ';
    Strings.Add(Text);
  end;
end;

{ TComponentExcludes }

constructor TComponentExcludes.Create;
begin
  PropertyExcludes := TStringList.Create;
end;

destructor TComponentExcludes.Destroy;
begin
  FreeAndNil(PropertyExcludes);
  inherited;
end;


{ TTranslator }

procedure TTranslator.Translate;
var
  I, J: Integer;
  Po: TPoFile;
  Item: TPoFileItem;
begin
  TranslateComponentRecursive(Application);

  // Merge files to single translation file
  try
    Po := TPoFile.Create;
    for I := 0 to FPoFiles.Count - 1 do
    with TPoFile(FPoFiles[I]) do
      for J := 0 to Items.Count - 1 do
      with TPoFileItem(Items[J]) do begin
        {$if (lcl_major<2)}
        Po.Add(IdentifierLow, Original, Translation, Comments, Context,
          Flags, PreviousID);
        {$else}
        Item := nil;
        Po.FillItem(Item, IdentifierLow, Original, Translation, Comments, Context,
          Flags, PreviousID);
        {$endif}
      end;
    Translations.TranslateResourceStrings(Po);
  finally
    Po.Free;
  end;
end;

procedure TTranslator.ReloadFiles;
var
  FileName: string;
  FileList: TStringList;
  I: Integer;
  LocaleShort: string;
  SearchMask: string;
begin
  FPoFiles.Clear;
  if Assigned(FLanguage) then
  try
    LocaleShort := GetLocaleShort;
    //ShowMessage(ExtractFileDir(Application.ExeName) +
    //  DirectorySeparator + 'Languages' + ' ' + '*.' + LocaleShort + '.po');
    SearchMask := '*';
    if LocaleShort <> '' then SearchMask := SearchMask + '.' + LocaleShort;
    SearchMask := SearchMask + '.po';
    FileList := FindAllFiles(GetLangFileDir, SearchMask);
    for I := 0 to FileList.Count - 1 do begin
      FileName := FileList[I];
      //FileName := FindLocaleFileName('.po');
      if FileExists(FileName) and (
      ((LocaleShort = '') and (Pos('.', FileName) = Pos('.po', FileName))) or
      (LocaleShort <> '')) then FPoFiles.Add(TPOFile.Create(FileName));
    end;
  finally
    FileList.Free;
  end;
end;

procedure TTranslator.SetPOFilesFolder(const AValue: string);
begin
  if FPoFilesFolder = AValue then Exit;
  FPoFilesFolder := AValue;
  ReloadFiles;
  CheckLanguageFiles;
end;

procedure TTranslator.SetLanguage(const AValue: TLanguage);
begin
  if FLanguage = AValue then Exit;
  FLanguage := AValue;
  ReloadFiles;
  Translate;
  if Assigned(FOnTranslate) then FOnTranslate(Self);
end;

procedure TTranslator.TranslateComponent(Component: TPersistent);
var
  I, Count: Integer;
  PropInfo: PPropInfo;
  PropList: PPropList;
begin
  Count := GetTypeData(Component.ClassInfo)^.PropCount;
  if Count > 0 then begin
    GetMem(PropList, Count * SizeOf(Pointer));
    try
      GetPropInfos(Component.ClassInfo, PropList);
      for I := 0 to Count - 1 do
      begin
        PropInfo := PropList^[I];
        if PropInfo = nil then
          Break;
        TranslateProperty(Component, PropInfo);
      end;
    finally
      FreeMem(PropList, Count * SizeOf(Pointer));
    end;
  end;
end;

procedure TTranslator.TranslateComponentRecursive(Component: TComponent);
var
  I: Integer;
begin
  TranslateComponent(Component);
  for I := 0 to Component.ComponentCount - 1 do
    TranslateComponentRecursive(Component.Components[I]);
end;

procedure TTranslator.TranslateProperty(Component: TPersistent;
  PropInfo: PPropInfo);
var
  PropType: PTypeInfo;
  Obj: TObject;
  I: Integer;
begin

//  PropInfo^.Name;
  // Using IsDefaultPropertyValue will tell us if we should write out
  // a given property because it was different from the default or
  // different from the Ancestor (if applicable).
  if (PropInfo^.GetProc <> nil) and
     ((PropInfo^.SetProc <> nil) or
     ((PropInfo^.PropType^.Kind = tkClass) and
      (TObject(GetOrdProp(Component, PropInfo)) is TComponent) and
      (csSubComponent in TComponent(GetOrdProp(Component, PropInfo)).ComponentStyle))) then
  begin
    begin
      PropType := PropInfo^.PropType;
      case PropType^.Kind of
        tkString, tkLString, tkWString, tkAString: begin
          if (UpperCase(PropType.Name) = 'TTRANSLATESTRING') then
          //if not IsExcluded(Component, PropInfo^.Name) then
              SetStrProp(Component, PropInfo, TranslateText(PropInfo^.Name, string(GetWideStrProp(Component, PropInfo))));
        end;
        tkClass: begin
          Obj := TObject(GetOrdProp(Component, PropInfo));
          if Obj is TCollection then
            for I := 0 to TCollection(Obj).Count - 1 do
              with TCollection(Obj).Items[I] do
                TranslateComponent(TCollection(Obj).Items[I]);
          (*if Obj is TStrings then
            for I := 0 to TStrings(Obj).Count - 1 do
              with TStrings(Obj) do
                Strings[I] := TranslateText(Strings[I], Strings[I]);
          *)
        end;
      end;
    end;
  end;
end;

function TTranslator.IsExcluded(Component: TPersistent; PropertyName: string
  ): Boolean;
var
  Item: TClass;
  Excludes: TComponentExcludes;
begin
  Result := False;
  Item := Component.ClassType;
  while Assigned(Item) do begin
    //ShowMessage(Component.Name + ', ' + Component.ClassName + ', ' + Item.ClassName + ', ' + PropertyName);
    Excludes := ComponentExcludes.FindByClassType(Item.ClassType);
    if Assigned(Excludes) then begin
      if Excludes.PropertyExcludes.IndexOf(PropertyName) <> -1 then begin
        Result := True;
        Exit;
      end;
    end;
    Item := Item.ClassParent;
  end;
end;

function TTranslator.GetLangFileDir: string;
begin
  Result := FPoFilesFolder;
  if Copy(Result, 1, 1) <> DirectorySeparator then
    Result := ExtractFileDir(Application.ExeName) +
      DirectorySeparator + Result;
end;

procedure TTranslator.LanguageListToStrings(Strings: TStrings; WithCode: Boolean = True);
var
  I: Integer;
  ItemName: string;
begin
  with Strings do begin
    BeginUpdate;
    try
      Clear;
      for I := 0 to Languages.Count - 1 do
      with Languages[I] do
        if Available then begin
          ItemName := Name;
          if WithCode and (Code <> '') then ItemName := ItemName + ' (' + Code + ')';
          AddObject(ItemName, Languages[I]);
        end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TTranslator.TranslateResourceStrings(PoFileName: string);
begin
  Translations.TranslateResourceStrings(PoFileName);
end;

procedure TTranslator.TranslateUnitResourceStrings(UnitName: string;
  PoFileName: string);
begin
  Translations.TranslateUnitResourceStrings(UnitName, PoFileName);
end;

function TTranslator.TranslateText(Identifier, Text: string): string;
var
  I: Integer;
begin
  Result := '';
  if Text <> '' then begin
    for I := 0 to FPoFiles.Count - 1 do begin
      Result := TPoFile(FPoFiles[I]).Translate(Identifier, Text);
      if Result <> Text then Break;
    end;
    if Result = '' then Result := Text;
  end else Result := '';
end;

procedure TTranslator.AddExcludes(AClassType: TClass; PropertyName: string
  );
var
  NewItem: TComponentExcludes;
begin
  NewItem := ComponentExcludes.FindByClassType(AClassType);
  if not Assigned(NewItem) then begin
    NewItem := TComponentExcludes.Create;
    NewItem.ExcludedClassType := AClassType;
    ComponentExcludes.Add(NewItem);
  end;
  NewItem.PropertyExcludes.Add(PropertyName);
end;

procedure TTranslator.CheckLanguageFiles;
var
  I: Integer;
  LangDir: string;
begin
  LangDir := GetLangFileDir;
  Languages.SearchByCode('').Available := True; // Automatic

  for I := 1 to Languages.Count - 1 do
  with Languages[I] do begin
    Available := FileExists(LangDir + DirectorySeparator + ExtractFileNameOnly(Application.ExeName) +
      '.' + Code + ExtensionSeparator + 'po') or (Code = 'en');
  end;
end;

constructor TTranslator.Create(AOwner: TComponent);
begin
  inherited;
  FPoFiles := TPoFiles.Create;
  ComponentExcludes := TComponentExcludesList.Create;
  Languages := TLanguages.Create;
  POFilesFolder := 'Languages';
  CheckLanguageFiles;

  // LCL
  AddExcludes(TComponent, 'Name');
  //AddExcludes(TAction, 'Category');
  AddExcludes(TControl, 'HelpKeyword');
end;

destructor TTranslator.Destroy;
begin
  FreeAndNil(FPoFiles);
  FreeAndNil(Languages);
  FreeAndNil(ComponentExcludes);
  inherited;
end;

function TTranslator.GetLocale: string;
var
  Lang: string;
  I: Integer;
  T: string;
begin
  // Win32 user may decide to override locale with LANG variable.
  Lang := GetEnvironmentVariable('LANG');

  // Use user selected language
  if Assigned(Language) and (Language.Code <> '') then
    Lang := Language.Code;

  if Lang = '' then begin
    for i := 1 to Paramcount - 1 do
      if (ParamStr(i) = '--LANG') or (ParamStr(i) = '-l') or
        (ParamStr(i) = '--lang') then
        Lang := ParamStr(i + 1);
  end;
  if Lang = '' then begin
    T := '';
    LazGetLanguageIDs(Lang, T);
  end;

  if Assigned(Language) and (Language.Code = '') and Assigned(FOnAutomaticLanguage) then begin
    Lang := FOnAutomaticLanguage(Lang);
  end;

  Result := Lang;
end;

function TTranslator.GetLocaleShort: string;
begin
  Result := Copy(GetLocale, 1, 2);
end;

function TTranslator.FindLocaleFileName(LCExt: string): string;
var
  Lang: string;
begin
  Result := '';
  Lang := GetLocale;

  Result := GetLocaleFileName(Lang, LCExt);
  if Result <> '' then
    Exit;

  Result := ChangeFileExt(ParamStr(0), LCExt);
  if FileExistsUTF8(Result) then
    Exit;

  Result := '';
end;

function TTranslator.GetLocaleFileName(const LangID, LCExt: string): string;
var
  LangShortID: string;
  FormatLang: string;
begin
  if LangID <> '' then FormatLang := '.%s' else FormatLang := '';

  begin

    // ParamStrUTF8(0) is said not to work properly in linux, but I've tested it
    Result := ExtractFilePath(ParamStrUTF8(0)) + LangID +
      DirectorySeparator + ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;

    Result := ExtractFilePath(ParamStrUTF8(0)) + 'languages' + DirectorySeparator + LangID +
      DirectorySeparator + ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;

    Result := ExtractFilePath(ParamStrUTF8(0)) + 'locale' + DirectorySeparator
      + LangID + DirectorySeparator + ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;

    Result := ExtractFilePath(ParamStrUTF8(0)) + 'locale' + DirectorySeparator
      + LangID + DirectorySeparator + 'LC_MESSAGES' + DirectorySeparator +
      ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;

    {$IFDEF UNIX}
    // In unix-like systems we can try to search for global locale
    Result := '/usr/share/locale/' + LangID + '/LC_MESSAGES/' +
      ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;
    {$ENDIF}
    // Let us search for reducted files
    LangShortID := copy(LangID, 1, 2);
    // At first, check all was checked
    Result := ExtractFilePath(ParamStrUTF8(0)) + LangShortID +
      DirectorySeparator + ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;

    Result := ExtractFilePath(ParamStrUTF8(0)) + 'languages' + DirectorySeparator +
      LangShortID + DirectorySeparator + ChangeFileExt(
      ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;

    Result := ExtractFilePath(ParamStrUTF8(0)) + 'locale' + DirectorySeparator
      + LangShortID + DirectorySeparator + ChangeFileExt(
      ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;

    Result := ExtractFilePath(ParamStrUTF8(0)) + 'locale' + DirectorySeparator
      + LangShortID + DirectorySeparator + 'LC_MESSAGES' + DirectorySeparator +
      ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;

    // Full language in file name - this will be default for the project
    // We need more careful handling, as it MAY result in incorrect filename
    try
      Result := ExtractFilePath(ParamStrUTF8(0)) + ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), Format(FormatLang, [LangID])) + LCExt;
      if FileExistsUTF8(Result) then
        exit;
      // Common location (like in Lazarus)
      Result := ExtractFilePath(ParamStrUTF8(0)) + 'locale' + DirectorySeparator +
        ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), Format(FormatLang, [LangID])) + LCExt;
      if FileExistsUTF8(Result) then
        exit;

      Result := ExtractFilePath(ParamStrUTF8(0)) + 'languages' +
        DirectorySeparator + ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), Format(FormatLang, [LangID])) + LCExt;
      if FileExistsUTF8(Result) then
        exit;
    except
      Result := ''; // Or do something else (useless)
    end;

    {$IFDEF UNIX}
    Result := '/usr/share/locale/' + LangShortID + '/LC_MESSAGES/' +
      ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), LCExt);
    if FileExistsUTF8(Result) then
      exit;
    {$ENDIF}
    Result := ExtractFilePath(ParamStrUTF8(0)) + ChangeFileExt(
      ExtractFileName(ParamStrUTF8(0)), Format(FormatLang, [LangShortID])) + LCExt;
    if FileExistsUTF8(Result) then
      exit;

    Result := ExtractFilePath(ParamStrUTF8(0)) + 'locale' + DirectorySeparator +
      ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), Format(FormatLang, [LangShortID])) + LCExt;
    if FileExistsUTF8(Result) then
      exit;

    Result := ExtractFilePath(ParamStrUTF8(0)) + 'languages' + DirectorySeparator +
      ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), Format(FormatLang, [LangShortID])) + LCExt;
    if FileExistsUTF8(Result) then
      exit;
  end;

  Result := '';
end;


end.


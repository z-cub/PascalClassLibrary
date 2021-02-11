unit UApplicationInfo;

{$mode delphi}

interface

uses
  SysUtils, Classes, Forms, URegistry, Controls, Graphics, LCLType;

type

  { TApplicationInfo }

  TApplicationInfo = class(TComponent)
  private
    FDescription: TTranslateString;
    FIcon: TBitmap;
    FIdentification: Byte;
    FLicense: string;
    FVersionMajor: Byte;
    FVersionMinor: Byte;
    FVersionBugFix: Byte;
    FVersionSuffix: string; // alfa, beta, RC1, RC2, ...
    FCompanyName: string;
    FCompanyHomePage: string;
    FHomePage: string;
    FAuthorsName: string;
    FEmailContact: string;
    FAppName: string;
    FReleaseDate: TDateTime;
    FRegistryKey: string;
    FRegistryRoot: TRegistryRoot;
    function GetVersion: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Version: string read GetVersion;
    function GetRegistryContext: TRegistryContext;
  published
    property Identification: Byte read FIdentification write FIdentification;
    property VersionMajor: Byte read FVersionMajor write FVersionMajor;
    property VersionMinor: Byte read FVersionMinor write FVersionMinor;
    property VersionBugFix: Byte read FVersionBugFix write FVersionBugFix;
    property VersionSuffix: string read FVersionSuffix write FVersionSuffix;
    property CompanyName: string read FCompanyName write FCompanyName;
    property CompanyHomePage: string read FCompanyHomePage write FCompanyHomePage;
    property HomePage: string read FHomePage write FHomePage;
    property AuthorsName: string read FAuthorsName write FAuthorsName;
    property EmailContact: string read FEmailContact write FEmailContact;
    property AppName: string read FAppName write FAppName;
    property Description: TTranslateString read FDescription write FDescription;
    property ReleaseDate: TDateTime read FReleaseDate write FReleaseDate;
    property RegistryKey: string read FRegistryKey write FRegistryKey;
    property RegistryRoot: TRegistryRoot read FRegistryRoot write FRegistryRoot;
    property License: string read FLicense write FLicense;
    property Icon: TBitmap read FIcon write FIcon;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Common', [TApplicationInfo]);
end;

{ TApplicationInfo }

function TApplicationInfo.GetVersion: string;
begin
  Result := IntToStr(FVersionMajor) + '.' + IntToStr(FVersionMinor);
  if FVersionSuffix <> '' then Result := Result + ' ' + FVersionSuffix
    else Result := Result + '.' + IntToStr(FVersionBugFix);
end;

constructor TApplicationInfo.Create(AOwner: TComponent);
begin
  inherited;
  FVersionMajor := 1;
  FIdentification := 1;
  FAppName := Application.Name;
  FRegistryKey := '\Software\' + FAppName;
  FRegistryRoot := rrKeyCurrentUser;
  FIcon := TBitmap.Create;
end;

destructor TApplicationInfo.Destroy;
begin
  FreeAndNil(FIcon);
  inherited;
end;

function TApplicationInfo.GetRegistryContext: TRegistryContext;
begin
  Result := TRegistryContext.Create(RegistryRoot, RegistryKey);
end;

end.

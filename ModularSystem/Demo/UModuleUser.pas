unit UModuleUser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, UModularSystem;

type

  { TModuleUser }

  TModuleUser = class(TModule)
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

{ TModuleUser }

constructor TModuleUser.Create;
begin
  inherited;
  Name := 'User';
  Title := 'User';
  Version := '1.0';
  License := 'GNU/LGPLv3';
  Dependencies.Add('Base');
end;

destructor TModuleUser.Destroy;
begin
  inherited Destroy;
end;

end.


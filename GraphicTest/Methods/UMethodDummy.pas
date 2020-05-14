unit UMethodDummy;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap;

type
  { TMethodDummy }

  TMethodDummy = class(TDrawMethod)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodDummy }

constructor TMethodDummy.Create;
begin
  inherited Create;
  Caption := 'Dummy';
  Description.Add('This method doesn''t draw anything. It''s purpose is to measure ' +
    'and compare speed of system and event handling.');
end;

procedure TMethodDummy.DrawFrame(FastBitmap: TFastBitmap);
begin
end;


end.


unit UMethodMove;

{$mode delphi}

interface

uses
  LCLIntf, LCLType, Classes, SysUtils, UDrawMethod, UFastBitmap, Controls, Graphics;

type
  { TMethodMove }

  TMethodMove = class(TDrawMethod)
    FastBitmap2: TFastBitmap;
    constructor Create; override;
    destructor Destroy; override;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    procedure UpdateSettings; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodMove }

constructor TMethodMove.Create;
begin
  inherited Create;
  FastBitmap2 := TFastBitmap.Create;
  Caption := 'Move';
  Description.Add('This method doesn''t draw anything. Measurement of memory copy' +
    ' of bitmap data using Move procedure.');
end;

destructor TMethodMove.Destroy;
begin
  FreeAndNil(FastBitmap2);
  inherited Destroy;
end;

procedure TMethodMove.Init(Parent: TWinControl; Size: TPoint;
  PixelFormat: TPixelFormat);
begin
  FastBitmap2.Size := Size;
  inherited;
end;

procedure TMethodMove.UpdateSettings;
begin
  inherited UpdateSettings;
end;

procedure TMethodMove.DrawFrame(FastBitmap: TFastBitmap);
var
  Size: Integer;
begin
  Size := FastBitmap.Size.X * FastBitmap.Size.Y * FastPixelSize;
  Move(FastBitmap.PixelsData^, FastBitmap2.PixelsData^, Size);
end;


end.


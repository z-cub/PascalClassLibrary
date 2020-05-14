unit UMethodBGRABitmap;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap, BGRABitmap, BGRABitmapTypes,
  Controls, Graphics;

type
  { TMethodBGRABitmap }

  TMethodBGRABitmap = class(TDrawMethodCanvas)
    BGRABitmap: TBGRABitmap;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodBGRABitmap }

procedure TMethodBGRABitmap.Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat);
begin
  inherited;
  BGRABitmap.SetSize(Size.X, Size.Y);
end;

constructor TMethodBGRABitmap.Create;
begin
  inherited;
  Caption := 'TBGRABitmap';
  BGRABitmap := TBGRABitmap.Create(0, 0);
  PaintObject := poPaintBox;
  Description.Add('This method uses graphic library BGRABitmap. ' +
    'PaintBox is used to display image data.');
end;

destructor TMethodBGRABitmap.Destroy;
begin
  BGRABitmap.Free;
  inherited Destroy;
end;

procedure TMethodBGRABitmap.DrawFrame(FastBitmap: TFastBitmap);
var
  X, Y: Integer;
  P: PCardinal;
begin
  with FastBitmap do
  for Y := 0 to Size.Y - 1 do begin
    P := PCardinal(BGRABitmap.ScanLine[Y]);
    for X := 0 to Size.X - 1 do begin
      P^ := SwapBRComponent(Pixels[X, Y]) or $ff000000;
      Inc(P);
    end;
  end;
  BGRABitmap.InvalidateBitmap; // changed by direct access
  BGRABitmap.Draw(Canvas, 0, 0, True);
end;


end.


unit UMethodBitmapScanline;

{$mode delphi}

interface

uses
  LCLIntf, LCLType, Classes, SysUtils, UDrawMethod, UFastBitmap, Controls, Graphics;

type
  { TMethodBitmapScanline }

  TMethodBitmapScanline = class(TDrawMethodCanvas)
    Bitmap: TBitmap;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodBitmapScanline }

procedure TMethodBitmapScanline.Init(Parent: TWinControl; Size: TPoint;
  PixelFormat: TPixelFormat);
begin
  inherited;
  Bitmap.SetSize(Size.X, Size.Y);
end;

constructor TMethodBitmapScanline.Create;
begin
  inherited;
  Caption := 'TBitmap Scanline PaintBox';
  Bitmap := TBitmap.Create;
  PaintObject := poCanvas;
  Description.Add('This method uses TBitmap.ScanLine. ' +
    'PaintBox is used to display image data.');
end;

destructor TMethodBitmapScanline.Destroy;
begin
  FreeAndNil(Bitmap);
  inherited;
end;

procedure TMethodBitmapScanline.DrawFrame(FastBitmap: TFastBitmap);
var
  X, Y: Integer;
  P: PCardinal;
begin
  Bitmap.BeginUpdate;
  with FastBitmap do
  for Y := 0 to Size.Y - 1 do begin
    P := Bitmap.ScanLine[Y];
    for X := 0 to Size.X - 1 do begin
      P^ := NoSwapBRComponent(Pixels[X, Y]);
      Inc(P);
    end;
  end;
  Bitmap.EndUpdate;
  BitBlt(Canvas.Handle, 0, 0, FastBitmap.Size.X, FastBitmap.Size.Y, Bitmap.Canvas.Handle, 0, 0, SRCCOPY);
end;

end.


unit UMethodCanvasPixels;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap, Graphics;

type
  { TMethodCanvasPixels }

  TMethodCanvasPixels = class(TDrawMethodCanvas)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodCanvasPixels }

constructor TMethodCanvasPixels.Create;
begin
  inherited;
  Caption := 'TBitmap.Canvas.Pixels';
  Description.Add('This is simple naive approach to copy image by accessing Pixels property. ' +
  'Method is slow because of much of overhead in access methods like multiple nested method calls, ' +
  'pixel format conversion, update notification, etc.');
end;

procedure TMethodCanvasPixels.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
begin
  with FastBitmap do begin
    for Y := 0 to Size.Y - 1 do
      for X := 0 to Size.X - 1 do
        Canvas.Pixels[X, Y] := TColor(SwapBRComponent(Pixels[X, Y]));
  end;
end;


end.


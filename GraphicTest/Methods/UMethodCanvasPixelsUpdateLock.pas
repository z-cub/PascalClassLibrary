unit UMethodCanvasPixelsUpdateLock;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap, Graphics;

type
  { TMethodCanvasPixelsUpdateLock }

  TMethodCanvasPixelsUpdateLock = class(TDrawMethodImage)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodCanvasPixelsUpdateLock }

constructor TMethodCanvasPixelsUpdateLock.Create;
begin
  inherited;
  Caption := 'TBitmap.Canvas.Pixels Update locking';
  Description.Add('This method improves basic canvas pixel access by eliminating ' +
    'updating of visible area during complete operation. Image data is ' +
    'painted only one at the end of complete operation');
end;

procedure TMethodCanvasPixelsUpdateLock.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
begin
  with FastBitmap do
  try
    Image.Picture.Bitmap.BeginUpdate(True);
    for Y := 0 to Size.Y - 1 do
      for X := 0 to Size.X - 1 do
        Image.Picture.Bitmap.Canvas.Pixels[X, Y] := TColor(SwapBRComponent(Pixels[X, Y]));
  finally
    Image.Picture.Bitmap.EndUpdate(False);
  end;
end;


end.


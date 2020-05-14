unit UMethodLazIntfImageColorsNoCopy;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap, IntfGraphics, Graphics, Controls;

type
  { TMethodLazIntfImageColorsNoCopy }

  TMethodLazIntfImageColorsNoCopy = class(TDrawMethodImage)
    TempIntfImage: TLazIntfImage;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodLazIntfImageColorsNoCopy }

procedure TMethodLazIntfImageColorsNoCopy.Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat);
begin
  inherited;
  TempIntfImage.Free;
  TempIntfImage := Image.Picture.Bitmap.CreateIntfImage;
end;

constructor TMethodLazIntfImageColorsNoCopy.Create;
begin
  inherited;
  Caption := 'TLazIntfImage.Colors no copy';
  Description.Add('Method use TLazIntfImage class for faster access to bitmap pixels compared to simple access using TBitmap.Pixels.');
  Description.Add('Bitmap is not copied from original bitmap.');
end;

destructor TMethodLazIntfImageColorsNoCopy.Destroy;
begin
  TempIntfImage.Free;
  inherited Destroy;
end;

procedure TMethodLazIntfImageColorsNoCopy.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
begin
  with FastBitmap do begin
    for X := 0 to Size.X - 1 do
      for Y := 0 to Size.Y - 1 do
        TempIntfImage.Colors[X, Y] := TColorToFPColor(SwapBRComponent(Pixels[X, Y]));
    Image.Picture.Bitmap.LoadFromIntfImage(TempIntfImage);
  end;
end;


end.


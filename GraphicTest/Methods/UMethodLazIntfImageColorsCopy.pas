unit UMethodLazIntfImageColorsCopy;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap, IntfGraphics, GraphType,
  fpImage, Graphics;

type
  { TMethodLazIntfImageColorsCopy }

  TMethodLazIntfImageColorsCopy = class(TDrawMethodImage)
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodLazIntfImageColorsCopy }

constructor TMethodLazIntfImageColorsCopy.Create;
begin
  inherited;
  Caption := 'TLazIntfImage.Colors copy';
  Description.Add('Method use TLazIntfImage class for faster access to bitmap pixels compared to simple access using TBitmap.Pixels.');
  Description.Add('TLazIntfImage is created from visible image.');
end;

destructor TMethodLazIntfImageColorsCopy.Destroy;
begin
  inherited Destroy;
end;

procedure TMethodLazIntfImageColorsCopy.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
  TempIntfImage: TLazIntfImage;
begin
  with FastBitmap do begin
    TempIntfImage := TLazIntfImage.Create(Image.Picture.Bitmap.Width, Image.Picture.Bitmap.Height);
    TempIntfImage.LoadFromBitmap(Image.Picture.Bitmap.Handle,
      Image.Picture.Bitmap.MaskHandle);
    for X := 0 to Size.X - 1 do
      for Y := 0 to Size.Y - 1 do
        TempIntfImage.Colors[X, Y] := TColorToFPColor(SwapBRComponent(Pixels[X, Y]));
    Image.Picture.Bitmap.LoadFromIntfImage(TempIntfImage);
    TempIntfImage.Free;
  end;
end;


end.


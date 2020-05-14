unit UMethodBitmapRawImageData;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap, Graphics, GraphType;

type
  { TMethodBitmapRawImageData }

  TMethodBitmapRawImageData = class(TDrawMethodImage)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodBitmapRawImageData }

constructor TMethodBitmapRawImageData.Create;
begin
  inherited;
  Caption := 'TBitmap.RawImage.Data';
  Description.Add('Custom TFastBitmap data are converted to visible image bitmap raw data. ' +
    'Then TImage is responsible for show loaded data.');
end;

procedure TMethodBitmapRawImageData.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
  PixelPtr: PCardinal;
  RowPtr: PCardinal;
  P: TPixelFormat;
  RawImage: TRawImage;
  BytePerPixel: Integer;
  BytePerRow: Integer;
begin
  P := Image.Picture.Bitmap.PixelFormat;
    with FastBitmap do
    try
      Image.Picture.Bitmap.BeginUpdate(False);
      RawImage := Image.Picture.Bitmap.RawImage;
      RowPtr := PCardinal(RawImage.Data);
      BytePerPixel := RawImage.Description.BitsPerPixel div 8;
      BytePerRow := RawImage.Description.BytesPerLine;
      for Y := 0 to Size.Y - 1 do begin
        PixelPtr := RowPtr;
        for X := 0 to Size.X - 1 do begin
          PixelPtr^ := Pixels[X, Y];
          Inc(PByte(PixelPtr), BytePerPixel);
        end;
        Inc(PByte(RowPtr), BytePerRow);
      end;
    finally
      Image.Picture.Bitmap.EndUpdate(False);
    end;
end;


end.


unit UMethodBitmapRawImageDataPaintBox;

{$mode delphi}

interface

uses
  {$IFDEF windows}Windows,{$ENDIF}Classes, SysUtils, Controls, UDrawMethod, UFastBitmap, Graphics, LCLType,
  FPimage, IntfGraphics, GraphType;

type
  { TMethodBitmapRawImageDataPaintBox }

  TMethodBitmapRawImageDataPaintBox = class(TDrawMethodPaintBox)
    TempBitmap: TBitmap;
    constructor Create; override;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    procedure Done; override;
    procedure Paint(Sender: TObject); override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodBitmapRawImageDataPaintBox }

constructor TMethodBitmapRawImageDataPaintBox.Create;
begin
  inherited;
  Caption := 'TBitmap.RawImage.Data PaintBox';
  PaintObject := poPaintBox;
  Description.Add('Custom TFastBitmap data are converted to bitmap data compatible with screen. ' +
    'Then data is sent to PaintBox by Draw method.');
end;

procedure TMethodBitmapRawImageDataPaintBox.Init(Parent: TWinControl; Size: TPoint;
  PixelFormat: TPixelFormat);
begin
  inherited;
  TempBitmap := TBitmap.Create;
  TempBitmap.PixelFormat := PixelFormat;
  TempBitmap.SetSize(Size.X, Size.Y);
end;

procedure TMethodBitmapRawImageDataPaintBox.Done;
begin
  FreeAndNil(TempBitmap);
  inherited Done;
end;

procedure TMethodBitmapRawImageDataPaintBox.Paint(Sender: TObject);
var
  hPaint, hBmp: HDC;
begin
  hBmp := TempBitmap.Canvas.Handle;
  hPaint := PaintBox.Canvas.Handle;
  //PaintBox.Canvas.CopyRect(Rect(0, 0, PaintBox.Width, PaintBox.Height), TempBitmap.Canvas,
  //  Rect(0, 0, TempBitmap.Width, TempBitmap.Height));
  PaintBox.Canvas.Draw(0, 0, TempBitmap);
  //BitBlt(hPaint, 0, 0, TempBitmap.Width, TempBitmap.Height, hBmp, 0, 0, srcCopy);
end;

procedure TMethodBitmapRawImageDataPaintBox.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
  PixelPtr: PCardinal;
  RowPtr: PCardinal;
  P: TPixelFormat;
  RawImage: TRawImage;
  BytePerPixel: Integer;
  BytePerRow: Integer;
begin
  P := TempBitmap.PixelFormat;
    with FastBitmap do
    try
      TempBitmap.BeginUpdate(False);
      RawImage := TempBitmap.RawImage;
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
      TempBitmap.EndUpdate(False);
    end;
  PaintBox.Repaint;
end;


end.


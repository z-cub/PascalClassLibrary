unit UPixelPointer;

interface

uses
  Classes, SysUtils, Graphics;

type
  TColor32 = type Cardinal;
  TColor32Component = (ccBlue, ccGreen, ccRed, ccAlpha);

  { TPixel32 }

  TPixel32 = packed record
  private
    procedure SetRGB(AValue: Cardinal);
    function GetRGB: Cardinal;    
  public
    property RGB: Cardinal read GetRGB write SetRGB;
    case Integer of
      0: (B, G, R, A: Byte);
      1: (ARGB: TColor32);
      2: (Planes: array[0..3] of Byte);
      3: (Components: array[TColor32Component] of Byte);
  end;
  PPixel32 = ^TPixel32;

  { TPixelPointer }

  TPixelPointer = record
    Base: PPixel32;
    Pixel: PPixel32;
    Line: PPixel32;
    RelLine: PPixel32;
    BytesPerPixel: Integer;
    BytesPerLine: Integer;
    procedure NextLine; inline; // Move pointer to start of next line
    procedure PreviousLine; inline; // Move pointer to start of previous line
    procedure NextPixel; inline; // Move pointer to next pixel
    procedure PreviousPixel; inline; // Move pointer to previous pixel
    procedure SetXY(X, Y: Integer); inline; // Set pixel position relative to base
    procedure SetX(X: Integer); inline; // Set horizontal pixel position relative to base
  end;
  PPixelPointer = ^TPixelPointer;

  function PixelPointer(Bitmap: TRasterImage; BaseX: Integer = 0; BaseY: Integer = 0): TPixelPointer; inline;
  function SwapRedBlue(Color: TColor32): TColor32;
  procedure BitmapCopyRect(DstBitmap: TRasterImage; DstRect: TRect; SrcBitmap: TRasterImage; SrcPos: TPoint);
  procedure BitmapStretchRect(DstBitmap: TRasterImage; DstRect: TRect;
    SrcBitmap: TRasterImage; SrcRect: TRect);
  procedure BitmapFill(Bitmap: TRasterImage; Color: TColor32);
  procedure BitmapFillRect(Bitmap: TRasterImage; Color: TColor32; Rect: TRect);
  procedure BitmapSwapRedBlue(Bitmap:TRasterImage);
  procedure BitmapInvert(Bitmap: TRasterImage);
  procedure BitmapBlendColor(Bitmap: TRasterImage; Color: TColor32);
  function Color32(A, R, G, B: Byte): TColor32;
  function Color32ToPixel32(Color: TColor32): TPixel32;
  function Pixel32ToColor32(Color: TPixel32): TColor32;
  function Color32ToColor(Color: TColor32): TColor;
  function ColorToColor32(Color: TColor): TColor32;

implementation

{ TPixel32 }

function TPixel32.GetRGB: Cardinal;
begin
  Result := ARGB and $ffffff;
end;

procedure TPixel32.SetRGB(AValue: Cardinal);
begin
  R := (AValue shr 16) and $ff;
  G := (AValue shr 8) and $ff;
  B := (AValue shr 0) and $ff;
end;

{ TPixelPointer }

procedure TPixelPointer.NextLine; inline;
begin
  Line := Pointer(Line) + BytesPerLine;
  Pixel := Line;
end;

procedure TPixelPointer.PreviousLine;
begin
  Line := Pointer(Line) - BytesPerLine;
  Pixel := Line;
end;

procedure TPixelPointer.NextPixel; inline;
begin
  Pixel := Pointer(Pixel) + BytesPerPixel;
end;

procedure TPixelPointer.PreviousPixel;
begin
  Pixel := Pointer(Pixel) - BytesPerPixel;
end;

procedure TPixelPointer.SetXY(X, Y: Integer); inline;
begin
  Line := Pointer(Base) + Y * BytesPerLine;
  SetX(X);
end;

procedure TPixelPointer.SetX(X: Integer); inline;
begin
  Pixel := Pointer(Line) + X * BytesPerPixel;
end;

procedure BitmapCopyRect(DstBitmap: TRasterImage; DstRect: TRect;
  SrcBitmap: TRasterImage; SrcPos: TPoint);
var
  SrcPtr, DstPtr: TPixelPointer;
  X, Y: Integer;
begin
  SrcBitmap.BeginUpdate(True);
  DstBitmap.BeginUpdate(True);
  SrcPtr := PixelPointer(SrcBitmap, SrcPos.X, SrcPos.Y);
  DstPtr := PixelPointer(DstBitmap, DstRect.Left, DstRect.Top);
  for Y := 0 to DstRect.Height - 1 do begin
    for X := 0 to DstRect.Width - 1 do begin
      DstPtr.Pixel^.ARGB := SrcPtr.Pixel^.ARGB;
      SrcPtr.NextPixel;
      DstPtr.NextPixel;
    end;
    SrcPtr.NextLine;
    DstPtr.NextLine;
  end;
  SrcBitmap.EndUpdate;
  DstBitmap.EndUpdate;
end;

procedure BitmapStretchRect(DstBitmap: TRasterImage; DstRect: TRect;
  SrcBitmap: TRasterImage; SrcRect: TRect);
var
  SrcPtr, DstPtr: TPixelPointer;
  X, Y: Integer;
  XX, YY: Integer;
  R: TRect;
  C: TColor32;
begin
  if (DstRect.Width = SrcRect.Width) and (DstRect.Height = SrcRect.Height) then begin
    BitmapCopyRect(DstBitmap, DstRect, SrcBitmap, Point(SrcRect.Left, SrcRect.Top));
    Exit;
  end;
  SrcBitmap.BeginUpdate(True);
  DstBitmap.BeginUpdate(True);
  SrcPtr := PixelPointer(SrcBitmap, SrcRect.Left, SrcRect.Top);
  DstPtr := PixelPointer(DstBitmap, DstRect.Left, DstRect.Top);
  for Y := 0 to DstRect.Height - 1 do begin
    for X := 0 to DstRect.Width - 1 do begin
      R := Rect(Trunc(X * SrcRect.Width / DstRect.Width),
        Trunc(Y * SrcRect.Height / DstRect.Height),
        Trunc((X + 1) * SrcRect.Width / DstRect.Width),
        Trunc((Y + 1) * SrcRect.Height / DstRect.Height));
      DstPtr.SetXY(X, Y);
      SrcPtr.SetXY(R.Left, R.Top);
      C := SrcPtr.Pixel^.ARGB;
      DstPtr.Pixel^.ARGB := C;
      for YY := 0 to R.Height - 1 do begin
        for XX := 0 to R.Width - 1 do begin
          DstPtr.Pixel^.ARGB := C;
          DstPtr.NextPixel;
        end;
        DstPtr.NextLine;
      end;
    end;
  end;
  SrcBitmap.EndUpdate;
  DstBitmap.EndUpdate;
end;

procedure BitmapFill(Bitmap: TRasterImage; Color: TColor32);
var
  X, Y: Integer;
  Ptr: TPixelPointer;
begin
  Bitmap.BeginUpdate(True);
  Ptr := PixelPointer(Bitmap);
  for Y := 0 to Bitmap.Height - 1 do begin
    for X := 0 to Bitmap.Width - 1 do begin
      Ptr.Pixel^.ARGB := Color;
      Ptr.NextPixel;
    end;
    Ptr.NextLine;
  end;
  Bitmap.EndUpdate;
end;

procedure BitmapFillRect(Bitmap: TRasterImage; Color: TColor32; Rect: TRect);
var
  X, Y: Integer;
  Ptr: TPixelPointer;
begin
  Bitmap.BeginUpdate(True);
  Ptr := PixelPointer(Bitmap, Rect.Left, Rect.Top);
  for Y := 0 to Rect.Height - 1 do begin
    for X := 0 to Rect.Width - 1 do begin
      Ptr.Pixel^.ARGB := Color;
      Ptr.NextPixel;
    end;
    Ptr.NextLine;
  end;
  Bitmap.EndUpdate;
end;

procedure BitmapSwapRedBlue(Bitmap: TRasterImage);
var
  X, Y: Integer;
  Ptr: TPixelPointer;
begin
  Bitmap.BeginUpdate(True);
  Ptr := PixelPointer(Bitmap);
  for Y := 0 to Bitmap.Height - 1 do begin
    for X := 0 to Bitmap.Width - 1 do begin
      Ptr.Pixel^.ARGB := SwapRedBlue(Ptr.Pixel^.ARGB);
      Ptr.NextPixel;
    end;
    Ptr.NextLine;
  end;
  Bitmap.EndUpdate;
end;

procedure BitmapInvert(Bitmap: TRasterImage);
var
  X, Y: Integer;
  Ptr: TPixelPointer;
begin
  Bitmap.BeginUpdate(True);
  Ptr := PixelPointer(Bitmap);
  for Y := 0 to Bitmap.Height - 1 do begin
    for X := 0 to Bitmap.Width - 1 do begin
      Ptr.Pixel^.ARGB := Ptr.Pixel^.ARGB xor $ffffff;
      Ptr.NextPixel;
    end;
    Ptr.NextLine;
  end;
  Bitmap.EndUpdate;
end;

procedure BitmapBlendColor(Bitmap: TRasterImage; Color: TColor32);
var
  X, Y: Integer;
  Ptr: TPixelPointer;
  A, R, G, B: Word;
  Pixel: TPixel32;
begin
  Pixel := Color32ToPixel32(Color);
  Bitmap.BeginUpdate(True);
  Ptr := PixelPointer(Bitmap);
  for Y := 0 to Bitmap.Height - 1 do begin
    for X := 0 to Bitmap.Width - 1 do begin
      A := Ptr.Pixel^.A; //(Ptr.Pixel^.A + Pixel.A) shr 1;
      R := (Ptr.Pixel^.R + Pixel.R) shr 1;
      G := (Ptr.Pixel^.G + Pixel.G) shr 1;
      B := (Ptr.Pixel^.B + Pixel.B) shr 1;
      Ptr.Pixel^.ARGB := Color32(A, R, G, B);
      Ptr.NextPixel;
    end;
    Ptr.NextLine;
  end;
  Bitmap.EndUpdate;
end;

function Color32(A, R, G, B: Byte): TColor32;
begin
  Result := ((A and $ff) shl 24) or ((R and $ff) shl 16) or
    ((G and $ff) shl 8) or ((B and $ff) shl 0);
end;

function Color32ToPixel32(Color: TColor32): TPixel32;
begin
  Result.ARGB := Color;
end;

function Pixel32ToColor32(Color: TPixel32): TColor32;
begin
  Result := Color.ARGB;
end;

function Color32ToColor(Color: TColor32): TColor;
begin
  Result := ((Color shr 16) and $ff) or (Color and $00ff00) or
    ((Color and $ff) shl 16);
end;

function ColorToColor32(Color: TColor): TColor32;
begin
  Result := $ff000000 or ((Color shr 16) and $ff) or (Color and $00ff00) or
    ((Color and $ff) shl 16);
end;

function PixelPointer(Bitmap: TRasterImage; BaseX: Integer;
  BaseY: Integer): TPixelPointer;
begin
  Result.BytesPerLine := Bitmap.RawImage.Description.BytesPerLine;
  Result.BytesPerPixel := Bitmap.RawImage.Description.BitsPerPixel shr 3;
  Result.Base := PPixel32(Bitmap.RawImage.Data + BaseX * Result.BytesPerPixel +
    BaseY * Result.BytesPerLine);
  Result.SetXY(0, 0);
end;

function SwapRedBlue(Color: TColor32): TColor32;
begin
  Result := (Color and $ff00ff00) or ((Color and $ff) shl 16) or ((Color shr 16) and $ff);
end;


end.


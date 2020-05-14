unit UMethodGraphics32;

{$mode delphi}

interface

uses
  Classes, SysUtils, UFastBitmap, UDrawMethod,
  {$IFDEF GRAPHICS32}GR32, GR32_Image,{$ENDIF}
  Controls, Graphics;

{$IFDEF GRAPHICS32}
type
  { TMethodGraphics32 }

  TMethodGraphics32 = class(TDrawMethod)
    Image: TImage32;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    procedure Done; override;
  end;
{$ENDIF}

implementation

{$IFDEF GRAPHICS32}
{ TMethodGraphics32 }

constructor TMethodGraphics32.Create;
begin
  inherited Create;
  Caption := 'TGR32Image';
  Description.Add('Graphics32 is well implemented highly optimized Delphi graphic ' +
    'library also ported to Lazarus/LCL. It uses static 32-bit wide pixel:');
  Description.Add('TColor32Entry = packed record');
  Description.Add('  case Integer of');
  Description.Add('    0: (B, G, R, A: Byte);');
  Description.Add('    1: (ARGB: TColor32);');
  Description.Add('    2: (Planes: array[0..3] of Byte);');
  Description.Add('    3: (Components: array[TColor32Component] of Byte);');
  Description.Add('end;');
end;

destructor TMethodGraphics32.Destroy;
begin
  inherited Destroy;
end;

procedure TMethodGraphics32.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
  PixelPtr: PColor32;
  RowPtr: PColor32;
  ImagePtr: PColor32;
  BytePerPixel: Integer;
  BytePerRow: Integer;
begin
    with FastBitmap do
    try
      Image.Bitmap.BeginUpdate;
      BytePerPixel := 4;
      BytePerRow := 4 * Image.Bitmap.Width;
      ImagePtr := Image.Bitmap.PixelPtr[0, 0];
      RowPtr := ImagePtr;
      for Y := 0 to Size.Y - 1 do begin
        PixelPtr := RowPtr;
        for X := 0 to Size.X - 1 do begin
          PixelPtr^ := Pixels[X, Y];
          Inc(PByte(PixelPtr), BytePerPixel);
        end;
        Inc(PByte(RowPtr), BytePerRow);
      end;
    finally
      Image.Bitmap.EndUpdate;
    end;
  Image.Repaint;
end;

procedure TMethodGraphics32.Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat);
begin
  inherited;
  Image := TImage32.Create(Parent);
  Image.Parent := Parent;
  Image.SetBounds(0, 0, Size.X, Size.Y);
  Image.Bitmap.SetSize(Size.X, Size.Y);
  Image.Show;
end;

procedure TMethodGraphics32.Done;
begin
  FreeAndNil(Image);
  inherited Done;
end;

{$ENDIF}

end.


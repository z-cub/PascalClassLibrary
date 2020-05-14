unit UMethodBitmapRawImageDataMove;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap, Graphics, GraphType;

type
  { TMethodBitmapRawImageDataMove }

  TMethodBitmapRawImageDataMove = class(TDrawMethodImage)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

{ TMethodBitmapRawImageDataMove }

constructor TMethodBitmapRawImageDataMove.Create;
begin
  inherited;
  Caption := 'TBitmap.RawImage.Data Move';
  Description.Add('This is same as BitmapRawImageData but data is not converted from different format. ' +
   'But only moved to TImage raw data. ' +
    'Then TImage is responsible for show loaded data.');
end;

procedure TMethodBitmapRawImageDataMove.DrawFrame(FastBitmap: TFastBitmap);
var
  RowPtr: PInteger;
  RawImage: TRawImage;
  BytePerRow: Integer;
begin
    with FastBitmap do
    try
      Image.Picture.Bitmap.BeginUpdate(False);
      RawImage := Image.Picture.Bitmap.RawImage;
      RowPtr := PInteger(RawImage.Data);
      BytePerRow := RawImage.Description.BytesPerLine;
      Move(FastBitmap.PixelsData^, RowPtr^, Size.Y * BytePerRow);
    finally
      Image.Picture.Bitmap.EndUpdate(False);
    end;
end;


end.


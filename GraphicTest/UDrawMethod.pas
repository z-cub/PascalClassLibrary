unit UDrawMethod;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, UPlatform, UFastBitmap, Graphics, Controls,
  LCLType, IntfGraphics, fpImage, GraphType, DateUtils, Forms,
  {$IFDEF OPENGL}GL, GLExt, OpenGLContext,{$ENDIF}
  LclIntf;

type
  TPaintObject = (poImage, poPaintBox, poOpenGL, poCanvas);


  { TDrawMethod }

  TDrawMethod = class
  private
    FControl: TControl;
    FFPS: Real;
    FParent: TWinControl;
  public
    Caption: string;
    Description: TStringList;
    Terminated: Boolean;
    FrameDuration: TDateTime;
    StepDuration: TDateTime;
    PaintObject: TPaintObject;
    FrameCounter: Integer;
    FrameCounterStart: TDateTime;
    FrameCounterStop: TDateTime;
    function GetFPS: Real;
    property FPS: Real read FFPS write FFPS;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); virtual;
    procedure Done; virtual;
    constructor Create; virtual;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); virtual;
    procedure DrawFrameTiming(FastBitmap: TFastBitmap);
    procedure UpdateSettings; virtual;
    property Control: TControl read FControl;
  end;

  TDrawMethodClass = class of TDrawMethod;

  { TDrawMethodImage }

  TDrawMethodImage = class(TDrawMethod)
    Image: TImage;
    procedure UpdateSettings; override;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    procedure Done; override;
  end;

  { TDrawMethodPaintBox }

  TDrawMethodPaintBox = class(TDrawMethod)
    PaintBox: TPaintBox;
    procedure Paint(Sender: TObject); virtual;
    procedure UpdateSettings; override;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    procedure Done; override;
  end;

  { TDrawMethodCanvas }

  TDrawMethodCanvas = class(TDrawMethod)
    Canvas: TCanvas;
    procedure UpdateSettings; override;
    procedure Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    procedure Done; override;
  end;

  {$IFDEF OPENGL}

  { TDrawMethodOpenGL }

  TDrawMethodOpenGL = class(TDrawMethod)
    OpenGLControl: TOpenGLControl;
    TextureId: GLuint;
    OpenGLBitmap: Pointer;
    procedure UpdateSettings; override;
    procedure InitGL;
    procedure OpenGLControlResize(Sender: TObject);
    procedure Init(AParent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    procedure Done; override;
  end;

  {$ENDIF}


implementation

{ TDrawMethodCanvas }

procedure TDrawMethodCanvas.UpdateSettings;
begin
  inherited UpdateSettings;
end;

procedure TDrawMethodCanvas.Init(Parent: TWinControl; Size: TPoint;
  PixelFormat: TPixelFormat);
begin
  Canvas := TForm(Parent).Canvas;
end;

procedure TDrawMethodCanvas.Done;
begin
  inherited Done;
end;


{ TDrawMethodPaintBox }

procedure TDrawMethodPaintBox.Paint(Sender: TObject);
begin

end;

procedure TDrawMethodPaintBox.UpdateSettings;
begin
  inherited UpdateSettings;
  PaintBox.ControlStyle := FParent.ControlStyle;
end;

procedure TDrawMethodPaintBox.Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat);
begin
  inherited;
  PaintBox := TPaintBox.Create(Parent);
  PaintBox.Parent := Parent;
  PaintBox.SetBounds(0, 0, Size.X, Size.Y);
  PaintBox.OnPaint := Paint;
  PaintBox.Show;
  UpdateSettings;
end;

procedure TDrawMethodPaintBox.Done;
begin
  FreeAndNil(PaintBox);
  inherited Done;
end;

{ TDrawMethodImage }

procedure TDrawMethodImage.UpdateSettings;
begin
  inherited;
  Image.ControlStyle := FParent.ControlStyle;
end;

procedure TDrawMethodImage.Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat);
begin
  inherited;
  Image := TImage.Create(Parent);
  Image.Parent := Parent;
  Image.SetBounds(0, 0, Size.X, Size.Y);
  Image.Picture.Bitmap.PixelFormat := PixelFormat;
  Image.Picture.Bitmap.SetSize(Size.X, Size.Y);
  Image.Show;
  UpdateSettings;
end;

procedure TDrawMethodImage.Done;
begin
  FreeAndNil(Image);
  inherited Done;
end;


{$IFDEF OPENGL}

{ TDrawMethodOpenGL }

procedure TDrawMethodOpenGL.Init(AParent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat);
begin
  inherited;
  OpenGLControl := TOpenGLControl.Create(AParent);
  with OpenGLControl do begin
    Name := 'OpenGLControl';
    Parent := AParent;
    SetBounds(0, 0, Size.X, Size.Y);
    InitGL;
    //OnPaint := OpenGLControl1Paint;
    OnResize := OpenGLControlResize;
  end;
  GetMem(OpenGLBitmap, OpenGLControl.Width * OpenGLControl.Height * SizeOf(Integer));
  UpdateSettings;
end;

procedure TDrawMethodOpenGL.Done;
begin
  FreeMem(OpenGLBitmap, OpenGLControl.Width * OpenGLControl.Height);
  FreeAndNil(OpenGLControl);
  inherited;
end;

procedure TDrawMethodOpenGL.OpenGLControlResize(Sender: TObject);
begin
  glViewport(0, 0, OpenGLControl.Width, OpenGLControl.Height);
end;

procedure TDrawMethodOpenGL.UpdateSettings;
begin
  inherited UpdateSettings;
  OpenGLControl.ControlStyle := FParent.ControlStyle;
end;

procedure TDrawMethodOpenGL.InitGL;
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, OpenGLControl.Width, OpenGLControl.Height, 0, 0, 1);
//  glOrtho(0, 1, 1, 0, 0, 1);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glDisable(GL_DEPTH_TEST);
  glViewport(0, 0, OpenGLControl.Width, OpenGLControl.Height);
  //gluPerspective( 45.0, (GLfloat)(OpenGLControl1.Width)/(GLfloat)(OpenGLControl1.Height), 0.1f, 500.0 );

    //glFrustum (-1.0, 1.0, -1.0, 1.0, 1.5, 20.0);
    //glTranslatef (0.0, 0.0,-3.0);
  //  glClearColor(0.0, 0.0, 0.0, 1.0);

  glGenTextures(1, @TextureId);
  glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
end;

{$ENDIF}


{ TDrawMethod }

function TDrawMethod.GetFPS: Real;
var
  StopTime: TDateTime;
begin
  if FrameCounterStop <> 0 then StopTime := FrameCounterStop
    else StopTime := NowPrecise;
  if FrameCounter > 0 then begin
    Result := FrameCounter / ((StopTime - FrameCounterStart) / OneSecond);
    //FrameCounter := 0;
    //FrameCounterStart := NowPrecise;
  end else Result := FFPS;
end;

procedure TDrawMethod.Init(Parent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat);
begin
  FParent := Parent;
end;

procedure TDrawMethod.Done;
begin

end;

constructor TDrawMethod.Create;
begin
  Description := TStringList.Create;
end;

destructor TDrawMethod.Destroy;
begin
  FreeAndNil(Description);
  inherited;
end;

procedure TDrawMethod.DrawFrame(FastBitmap: TFastBitmap);
begin

end;

procedure TDrawMethod.DrawFrameTiming(FastBitmap: TFastBitmap);
var
  StartTime: TDateTime;
begin
  StartTime := NowPrecise;
  DrawFrame(FastBitmap);
  FrameDuration := NowPrecise - StartTime;
end;

procedure TDrawMethod.UpdateSettings;
begin
end;

end.


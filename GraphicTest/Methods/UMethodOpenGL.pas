unit UMethodOpenGL;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap
  {$IFDEF OPENGL}, GL, GLExt, OpenGLContext{$ENDIF};

{$IFDEF OPENGL}
type
  { TMethodOpenGL }

  TMethodOpenGL = class(TDrawMethodOpenGL)
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;
  {$ENDIF}


implementation

{$IFDEF OPENGL}
{ TMethodOpenGL }

constructor TMethodOpenGL.Create;
begin
  inherited Create;
  Caption := 'OpenGL';
  PaintObject := poOpenGL;
  Description.Add('This method use OpenGL 3D acceleration with simple one 2D orthogonal plane covering all visible area.' +
    'Texture data is loaded from bitmap.');
end;

destructor TMethodOpenGL.Destroy;
begin
  inherited Destroy;
end;

procedure TMethodOpenGL.DrawFrame(FastBitmap: TFastBitmap);
var
  X, Y: Integer;
  P: PCardinal;
  R: PCardinal;
const
  GL_CLAMP_TO_EDGE = $812F;
begin
  glLoadIdentity;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  //glLoadIdentity;             { clear the matrix }
  //glTranslatef(0.0, 0.0, -3.0);  // -2.5); { viewing transformation }

  P := OpenGLBitmap;
  with FastBitmap do
  for Y := 0 to Size.Y - 1 do begin
    R := P;
    for X := 0 to Size.X - 1 do begin
      //R^ := Round($ff * (Y / Size.Y)) or $ff000000;
      R^  := NoSwapBRComponent(Pixels[X, Y]) or $ff000000;
      Inc(R);
    end;
    Inc(P, Size.X);
  end;

    //glRotatef(30.0, 0, 0, 1.0);
    glTranslatef(-OpenGLControl.Width div 2, -OpenGLControl.Height div 2, 0.0);

    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, TextureId);
      //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexImage2D(GL_TEXTURE_2D, 0, 4, OpenGLControl.Width, OpenGLControl.Height,
        0, GL_RGBA, GL_UNSIGNED_BYTE, OpenGLBitmap);
      //glTexImage2D(GL_TEXTURE_2D, 0, 4, 512, 256,
      //0, GL_RGBA, GL_UNSIGNED_BYTE, OpenGLBitmap);

    //Define how alpha blending will work and enable alpha blending.
    //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //glEnable(GL_BLEND);

    glBegin(GL_QUADS);
    //glBegin(GL_POLYGON);
      glColor3ub(255, 255, 255);
      glTexCoord2f(0, 0);
      glVertex3f(0, 0, 0);
      glTexCoord2f(OpenGLControl.Width div 2, 0);
      glVertex3f(OpenGLControl.Width, 0, 0);
      glTexCoord2f(OpenGLControl.Width div 2, OpenGLControl.Height div 2);
      glVertex3f(OpenGLControl.Width, OpenGLControl.Height, 0);
      glTexCoord2f(0, OpenGLControl.Height div 2);
      glVertex3f(0, OpenGLControl.Height, 0);
    glEnd();

  OpenGLControl.SwapBuffers;
end;

{$ENDIF}

end.


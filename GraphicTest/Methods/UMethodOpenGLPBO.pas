unit UMethodOpenGLPBO;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap, Controls, Graphics
  {$IFDEF OPENGL}, GL, GLExt, OpenGLContext{$ENDIF};

{$IFDEF OPENGL}
type
  { TMethodOpenGLPBO }

  TMethodOpenGLPBO = class(TDrawMethodOpenGL)
    pboIds: array[0..1] of GLuint;
    Index, NextIndex: Integer;
    procedure Init(AParent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat); override;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;
  {$ENDIF}


implementation

{$IFDEF OPENGL}
{ TMethodOpenGLPBO }

//procedure glGenBuffersARB2 : procedure(n : GLsizei; buffers : PGLuint); extdecl;

procedure TMethodOpenGLPBO.Init(AParent: TWinControl; Size: TPoint; PixelFormat: TPixelFormat);
var
  DataSize: Integer;
  glExtensions: string;
begin
  inherited;

  OpenGLControl.MakeCurrent;
  DataSize := OpenGLControl.Width * OpenGLControl.Height * SizeOf(Integer);
//  glGenBuffersARB(Length(pboIds), PGLuint(pboIds));
  //if glext_LoadExtension('GL_ARB_pixel_buffer_object') then
  if Load_GL_ARB_vertex_buffer_object then begin
    glGenBuffersARB(2, @pboIds);
    glBindBufferARB(GL_PIXEL_PACK_BUFFER_ARB, pboIds[0]);
    glBufferDataARB(GL_PIXEL_PACK_BUFFER_ARB, DataSize, Pointer(0), GL_STREAM_READ_ARB);
    glBindBufferARB(GL_PIXEL_PACK_BUFFER_ARB, pboIds[1]);
    glBufferDataARB(GL_PIXEL_PACK_BUFFER_ARB, DataSize, Pointer(0), GL_STREAM_READ_ARB);

  end else raise Exception.Create('GL_ARB_pixel_buffer_object not supported');

  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, TextureId);
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, 4, OpenGLControl.Width, OpenGLControl.Height,
      0, GL_RGBA, GL_UNSIGNED_BYTE, OpenGLBitmap);
end;

constructor TMethodOpenGLPBO.Create;
begin
  inherited Create;
  Caption := 'OpenGL PBO';
  PaintObject := poOpenGL;
//  SetLength(pboIds, 2);
  Index := 0;
  NextIndex := 1;
  Description.Add('This method use OpenGL acceleration same like other OpenGL method but ' +
    'use DMA(Direct Memory Access) for faster texture data transfer without use of CPU.');
end;

destructor TMethodOpenGLPBO.Destroy;
begin
  inherited Destroy;
end;

procedure TMethodOpenGLPBO.DrawFrame(FastBitmap: TFastBitmap);
var
  X, Y: Integer;
  P: PCardinal;
  R: PCardinal;
  Ptr: ^GLubyte;
  TextureShift: TPoint;
  TextureShift2: TPoint;
const
  GL_CLAMP_TO_EDGE = $812F;
begin
  // "index" is used to read pixels from framebuffer to a PBO
  // "nextIndex" is used to update pixels in the other PBO
  Index := (Index + 1) mod 2;
  NextIndex := (Index + 1) mod 2;

  glLoadIdentity;

  glBindTexture(GL_TEXTURE_2D, TextureId);
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //glTexImage2D(GL_TEXTURE_2D, 0, 4, OpenGLControl.Width, OpenGLControl.Height,
    //  0, GL_RGBA, GL_UNSIGNED_BYTE, OpenGLBitmap);
    //glTexImage2D(GL_TEXTURE_2D, 0, 4, 512, 256,
    //0, GL_RGBA, GL_UNSIGNED_BYTE, OpenGLBitmap);

  // bind the texture and PBO
  //glBindTexture(GL_TEXTURE_2D, textureId);
  glBindBufferARB(GL_PIXEL_UNPACK_BUFFER_ARB, pboIds[index]);

  // copy pixels from PBO to texture object
  // Use offset instead of ponter.
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, OpenGLControl.Width, OpenGLControl.Height,
    GL_BGRA, GL_UNSIGNED_BYTE, Pointer(0));


  // bind PBO to update texture source
  glBindBufferARB(GL_PIXEL_UNPACK_BUFFER_ARB, pboIds[nextIndex]);

  // Note that glMapBufferARB() causes sync issue.
  // If GPU is working with this buffer, glMapBufferARB() will wait(stall)
  // until GPU to finish its job. To avoid waiting (idle), you can call
  // first glBufferDataARB() with NULL pointer before glMapBufferARB().
  // If you do that, the previous data in PBO will be discarded and
  // glMapBufferARB() returns a new allocated pointer immediately
  // even if GPU is still working with the previous data.
  glBufferDataARB(GL_PIXEL_UNPACK_BUFFER_ARB, OpenGLControl.Width * OpenGLControl.Height * SizeOf(Integer), Pointer(0), GL_STREAM_DRAW_ARB);

  // map the buffer object into client's memory
  ptr := glMapBufferARB(GL_PIXEL_UNPACK_BUFFER_ARB, GL_WRITE_ONLY_ARB);
  if Assigned(ptr) then begin
    // update data directly on the mapped buffer
    P := PCardinal(Ptr);
    with FastBitmap do
    for Y := 0 to Size.Y - 2 do begin
      R := P;
      for X := 0 to Size.X - 1 do begin
        R^ := NoSwapBRComponent(Pixels[X, Y]) or $ff000000;
        Inc(R);
      end;
      Inc(P, Size.X);
    end;
    glUnmapBufferARB(GL_PIXEL_PACK_BUFFER_ARB);
  end;

  // it is good idea to release PBOs with ID 0 after use.
  // Once bound with 0, all pixel operations are back to normal ways.
  glBindBufferARB(GL_PIXEL_UNPACK_BUFFER_ARB, 0);

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  //glRotatef(30.0, 0, 0, 1.0);
  glTranslatef(-OpenGLControl.Width / 2, -OpenGLControl.Height / 2, 0.0);
  glBindTexture(GL_TEXTURE_2D, TextureId);

  TextureShift := Point(0, 0);
  TextureShift2 := Point(0, 0);
  glBegin(GL_QUADS);
    glColor3ub(255, 255, 255);
    glTexCoord2f(TextureShift.X, TextureShift.Y);
    glVertex3f(TextureShift2.X, TextureShift2.Y, 0);
    glTexCoord2f(TextureShift.X + OpenGLControl.Width div 2, TextureShift.Y);
    glVertex3f(TextureShift2.X + OpenGLControl.Width, TextureShift2.Y, 0);
    glTexCoord2f(TextureShift.X + OpenGLControl.Width div 2, TextureShift.Y + OpenGLControl.Height div 2);
    glVertex3f(TextureShift2.X + OpenGLControl.Width, TextureShift2.Y + OpenGLControl.Height, 0);
    glTexCoord2f(TextureShift.X, TextureShift.Y + OpenGLControl.Height div 2);
    glVertex3f(TextureShift2.X, TextureShift2.Y + OpenGLControl.Height, 0);
  glEnd();

  OpenGLControl.SwapBuffers;
end;

{$ENDIF}

end.


program GraphicTest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, SysUtils, openglcontext, UFormMain, UPlatform, UDrawMethod,
  UFastBitmap, UFormDraw, bgrabitmappack, UMethodCanvasPixels,
  UMethodCanvasPixelsUpdateLock, UMethodLazIntfImageColorsCopy, UMethodLazIntfImageColorsNoCopy,
  UMethodBGRABitmap, UMethodBitmapRawImageDataPaintBox, UMethodBitmapRawImageData,
  UMethodDummy, UMethodBitmapRawImageDataMove, UMethodOpenGL, UMethodOpenGLPBO,
  UMethodGraphics32, UMethodBitmapScanline;

{$R *.res}

{$if declared(UseHeapTrace)}
const
  HeapTraceLog = 'heaptrclog.trc';
{$ENDIF}

begin
  {$if declared(UseHeapTrace)}
  // Heap trace
  DeleteFile(ExtractFilePath(ParamStr(0)) + HeapTraceLog);
  SetHeapTraceOutput(ExtractFilePath(ParamStr(0)) + HeapTraceLog);
  {$ENDIF}

  RequireDerivedFormResource := True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormDraw, FormDraw);
  Application.Run;
end.


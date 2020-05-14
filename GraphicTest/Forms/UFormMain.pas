unit UFormMain;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, LazFileUtils, SynHighlighterPas, SynMemo, Forms, Controls,
  Graphics, Dialogs, ComCtrls, ExtCtrls, StdCtrls, DateUtils, UPlatform,
  LCLType, IntfGraphics, fpImage, Math, GraphType, Contnrs, LclIntf, Spin,
  ActnList, Menus, StdActns, UFastBitmap, UDrawMethod, typinfo;

const
  SceneFrameCount = 100;

type

  { TFormMain }

  TFormMain = class(TForm)
    AFormDrawShow: TAction;
    AShowFormDraw: TAction;
    ATestAllMethods: TAction;
    ATestOneMethod: TAction;
    ATestStop: TAction;
    AExportAsWikiText: TAction;
    ActionList1: TActionList;
    ButtonBenchmark: TButton;
    ButtonSingleTest: TButton;
    ButtonStop: TButton;
    CheckBoxOpaque: TCheckBox;
    CheckBoxDoubleBuffered: TCheckBox;
    CheckBoxEraseBackground: TCheckBox;
    ComboBoxPixelFormat: TComboBox;
    FileExit1: TFileExit;
    FloatSpinEdit1: TFloatSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    ListViewMethods: TListView;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    MenuItemTest: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    PopupMenuMethod: TPopupMenu;
    SaveDialog1: TSaveDialog;
    SpinEditHeight: TSpinEdit;
    SpinEditWidth: TSpinEdit;
    Splitter1: TSplitter;
    SynMemo1: TSynMemo;
    SynPasSyn1: TSynPasSyn;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TimerUpdateSettings: TTimer;
    TimerUpdateList: TTimer;
    procedure AExportAsWikiTextExecute(Sender: TObject);
    procedure AFormDrawShowExecute(Sender: TObject);
    procedure ATestAllMethodsExecute(Sender: TObject);
    procedure ATestOneMethodExecute(Sender: TObject);
    procedure ATestStopExecute(Sender: TObject);
    procedure CheckBoxOpaqueChange(Sender: TObject);
    procedure CheckBoxDoubleBufferedChange(Sender: TObject);
    procedure CheckBoxEraseBackgroundChange(Sender: TObject);
    procedure ComboBoxPixelFormatChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure ListViewMethodsData(Sender: TObject; Item: TListItem);
    procedure ListViewMethodsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure SpinEditHeightChange(Sender: TObject);
    procedure SpinEditWidthChange(Sender: TObject);
    procedure TimerUpdateListTimer(Sender: TObject);
    procedure TimerUpdateSettingsTimer(Sender: TObject);
  private
    FCurrentMethod: TDrawMethod;
    SingleTestActive: Boolean;
    AllTestActive: Boolean;
    TestTerminated: Boolean;
    TestTimeout: Real;
    DrawMethodClasses: array of TDrawMethodClass;
    procedure GenerateSceneFrames;
    procedure TestMethod(Method: TDrawMethod);
    procedure UpdateMethodList;
    procedure UpdateInterface;
    procedure RegisterDrawMethods;
    procedure RegisterDrawMethod(MethodClass: TDrawMethodClass);
  public
    FrameSize: TPoint;
    PixelFormat: TPixelFormat;
    DrawMethods: TObjectList; // TObjectList<TDrawMethod>
    Scenes: TObjectList; // TObjectList<TFastBitmap>
    SceneIndex: Integer;
    property CurrentMethod: TDrawMethod read FCurrentMethod;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

uses
  UFormDraw, UMethodLazIntfImageColorsCopy, UMethodLazIntfImageColorsNoCopy, UMethodCanvasPixels,
  UMethodCanvasPixelsUpdateLock, UMethodBGRABitmap, UMethodBitmapRawImageDataPaintBox,
  UMethodBitmapRawImageData, UMethodBitmapRawImageDataMove, UMethodDummy, UMethodOpenGL,
  UMethodOpenGLPBO{$IFDEF GRAPHICS32}, UGraphics32Method{$ENDIF},
  UMethodBitmapScanline, UMethodMove;

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
var
  NewDrawMethod: TDrawMethod;
  I: Integer;
  PF: TPixelFormat;
begin
  Scenes := TObjectList.Create;

  FrameSize := Point(320, 240);
  Randomize;

  RegisterDrawMethods;
  DrawMethods := TObjectList.Create;
  for I := 0 to High(DrawMethodClasses) do begin
    NewDrawMethod := DrawMethodClasses[I].Create;
    DrawMethods.Add(NewDrawMethod);
  end;

  for PF := Low(TPixelFormat) to High(TPixelFormat) do
    ComboBoxPixelFormat.Items.Add(GetEnumName(TypeInfo(TPixelFormat), Integer(PF)));

  PageControl1.TabIndex := 0;
end;

procedure TFormMain.TestMethod(Method: TDrawMethod);
var
  StepStartTime: TDateTime;
  StartTime: TDateTime;
begin
  FCurrentMethod := Method;
  with Method do begin
    Init(FormDraw, FrameSize, PixelFormat);
    //Application.ProcessMessages;
    StartTime := NowPrecise;
    FrameCounterStart := NowPrecise;
    FrameCounterStop := 0;
    FrameCounter := 0;
    repeat
      StepStartTime := NowPrecise;
      DrawFrameTiming(TFastBitmap(Scenes[SceneIndex]));
      Application.ProcessMessages;
      StepDuration := NowPrecise - StepStartTime;
      SceneIndex := (SceneIndex + 1) mod Scenes.Count;
      Inc(FrameCounter);
    until TestTerminated or
      ((TestTimeout > 0) and ((NowPrecise - StartTime) > OneSecond * TestTimeout));
    FrameCounterStop := NowPrecise;
    //FPS := GetFPS;
    Done;
  end;
  FCurrentMethod := nil;
end;

procedure TFormMain.AExportAsWikiTextExecute(Sender: TObject);
var
  Output: TStringList;
  I: Integer;
  Duration: Real;
begin
  SaveDialog1.FileName := 'GraphicsTest results.txt';
  if SaveDialog1.Execute then
  try
    Output := TStringList.Create;
    Output.Add('{| class="wikitable sortable"');
    Output.Add('|-');
    Output.Add('! Method !! FPS !! Frame duration [ms]');
    for I := 0 to DrawMethods.Count - 1 do
    with TDrawMethod(DrawMethods[I]) do begin
      Output.Add('|-');
      if FPS <> 0 then Duration := 1 / FPS * 1000
        else Duration := 0;
      Output.Add('|' + Caption + ' || ' + FloatToStr(RoundTo(FPS, -1)) +
        ' || ' + FloatToStr(RoundTo(Duration, -1)));
    end;
    Output.Add('|}');
    Output.SaveToFile(SaveDialog1.FileName);
  finally
    Output.Free;
  end;
end;

procedure TFormMain.AFormDrawShowExecute(Sender: TObject);
begin
  FormDraw.Show;
end;

procedure TFormMain.ATestAllMethodsExecute(Sender: TObject);
var
  I: Integer;
begin
  try
    AllTestActive := True;
    UpdateInterface;
    TimerUpdateList.Enabled := True;
    TestTerminated := False;
    TestTimeout := FloatSpinEdit1.Value;
    with ListViewMethods, Items do
    for I := 0 to DrawMethods.Count - 1 do
    with TDrawMethod(DrawMethods[I]) do begin
      TestMethod(TDrawMethod(DrawMethods[I]));
      if TestTerminated then Break;
    end;
  finally
    TimerUpdateList.Enabled := False;
    AllTestActive := False;
    UpdateInterface;
  end;
end;

procedure TFormMain.ATestOneMethodExecute(Sender: TObject);
begin
  if Assigned(ListViewMethods.Selected) then
  try
    SingleTestActive := True;
    UpdateInterface;
    TimerUpdateList.Enabled := True;
    TestTerminated := False;
    TestTimeout := -1;
    TestMethod(TDrawMethod(ListViewMethods.Selected.Data));
  finally
    //TimerUpdateList.Enabled := False;
    SingleTestActive := False;
    UpdateInterface;
  end;
end;

procedure TFormMain.ATestStopExecute(Sender: TObject);
begin
  TestTerminated := True;
  SingleTestActive := False;
  AllTestActive := False;
end;

procedure TFormMain.CheckBoxOpaqueChange(Sender: TObject);
begin
  if CheckBoxOpaque.Checked then
    FormDraw.ControlStyle := FormDraw.ControlStyle + [csOpaque]
    else FormDraw.ControlStyle := FormDraw.ControlStyle - [csOpaque];
  if Assigned(FCurrentMethod) then
    FCurrentMethod.UpdateSettings;
end;

procedure TFormMain.CheckBoxDoubleBufferedChange(Sender: TObject);
begin
  FormDraw.DoubleBuffered := CheckBoxDoubleBuffered.Checked;
end;

procedure TFormMain.CheckBoxEraseBackgroundChange(Sender: TObject);
begin
  FormDraw.EraseBackgroundEnabled := CheckBoxEraseBackground.Checked;
end;

procedure TFormMain.ComboBoxPixelFormatChange(Sender: TObject);
begin
  PixelFormat := TPixelFormat(ComboBoxPixelFormat.ItemIndex);
  UpdateInterface;
end;

procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ATestStop.Execute;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  ListViewMethods.Clear;
  FreeAndNil(DrawMethods);
  FreeAndNil(Scenes);
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  UpdateMethodList;
  UpdateInterface;
  FormDraw.Show;
  FormDraw.Left := Left + Width;
  FormDraw.Top := Top;
end;

procedure TFormMain.ListViewMethodsData(Sender: TObject; Item: TListItem);
begin
  if (Item.Index >= 0) and (Item.Index < DrawMethods.Count) then
  with TDrawMethod(DrawMethods[Item.Index]) do begin
    Item.Caption := Caption;
    Item.Data := TDrawMethod(DrawMethods[Item.Index]);
    FPS := GetFPS;
    Item.SubItems.Add(FloatToStr(RoundTo(FPS, -3)));
    if FPS > 0 then
      Item.SubItems.Add(FloatToStr(RoundTo(1 / FPS * 1000, -3)))
      else Item.SubItems.Add('0');
    if FrameDuration > 0 then
      Item.SubItems.Add(FloatToStr(RoundTo(1 / (FrameDuration / OneSecond), -3)))
      else Item.SubItems.Add('0');
    Item.SubItems.Add(FloatToStr(RoundTo(FrameDuration / OneMillisecond, -3)));
    if FrameDuration > 0 then
      Item.SubItems.Add(FloatToStr(RoundTo(1 / (StepDuration / OneSecond), -3)))
      else Item.SubItems.Add('0');
    Item.SubItems.Add(FloatToStr(RoundTo(StepDuration / OneMillisecond, -3)));
  end;
end;

procedure TFormMain.ListViewMethodsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  FileName: string;
begin
  UpdateInterface;
  if Assigned(ListViewMethods.Selected) then begin
    FileName := 'Methods' + DirectorySeparator + 'U' +
    Copy(TDrawMethod(DrawMethods[ListViewMethods.Selected.Index]).ClassName, 2, High(Integer)) + '.pas';

    if FileExists(FileName) then
      SynMemo1.Lines.LoadFromFile(FileName)
      else SynMemo1.Lines.Clear;
    Memo1.Lines.Assign(TDrawMethod(DrawMethods[ListViewMethods.Selected.Index]).Description);
  end;
end;

procedure TFormMain.SpinEditHeightChange(Sender: TObject);
begin
  FrameSize.Y := SpinEditHeight.Value;
end;

procedure TFormMain.SpinEditWidthChange(Sender: TObject);
begin
  FrameSize.X := SpinEditWidth.Value;
end;

procedure TFormMain.TimerUpdateListTimer(Sender: TObject);
begin
  UpdateMethodList;
end;

procedure TFormMain.TimerUpdateSettingsTimer(Sender: TObject);
begin
  if (FrameSize.X <> FormDraw.FrameSize.X) or
    (FrameSize.Y <> FormDraw.FrameSize.Y) then begin
      FormDraw.FrameSize := FrameSize;
      FormDraw.ClientWidth := FrameSize.X;
      FormDraw.ClientHeight := FrameSize.Y;
      GenerateSceneFrames;
    end;
end;

procedure TFormMain.GenerateSceneFrames;
var
  I: Integer;
  NewScene: TFastBitmap;
begin
  Scenes.Clear;
  for I := 0 to SceneFrameCount - 1 do begin
    NewScene := TFastBitmap.Create;
    NewScene.Size := FrameSize;
    NewScene.RandomImage(I, SceneFrameCount);
    Scenes.Add(NewScene);
  end;
end;

procedure TFormMain.UpdateMethodList;
begin
  ListViewMethods.Items.Count := DrawMethods.Count;
  ListViewMethods.Refresh;
end;

procedure TFormMain.UpdateInterface;
begin
  ATestOneMethod.Enabled := not SingleTestActive and not AllTestActive and Assigned(ListViewMethods.Selected);
  ATestAllMethods.Enabled := not AllTestActive and not SingleTestActive;
  ATestStop.Enabled := SingleTestActive or AllTestActive;
  SpinEditWidth.MaxValue := Screen.DesktopWidth;
  SpinEditHeight.MaxValue := Screen.DesktopHeight;
  CheckBoxDoubleBuffered.Checked := FormDraw.DoubleBuffered;
  CheckBoxEraseBackground.Checked := FormDraw.EraseBackgroundEnabled;
  CheckBoxOpaque.Checked := csOpaque in FormDraw.ControlStyle;
  ComboBoxPixelFormat.ItemIndex := Integer(PixelFormat);
end;

procedure TFormMain.RegisterDrawMethods;
begin
  RegisterDrawMethod(TMethodCanvasPixels);
  RegisterDrawMethod(TMethodCanvasPixelsUpdateLock);
  RegisterDrawMethod(TMethodLazIntfImageColorsCopy);
  RegisterDrawMethod(TMethodLazIntfImageColorsNoCopy);
  RegisterDrawMethod(TMethodBitmapRawImageData);
  RegisterDrawMethod(TMethodBitmapRawImageDataPaintBox);
  RegisterDrawMethod(TMethodBitmapRawImageDataMove);
  RegisterDrawMethod(TMethodBitmapScanline);
  RegisterDrawMethod(TMethodBGRABitmap);
  {$IFDEF GRAPHICS32}
  RegisterDrawMethod(TMethodGraphics32);
  {$ENDIF}
  {$IFDEF OPENGL}
  RegisterDrawMethod(TMethodOpenGL);
  RegisterDrawMethod(TMethodOpenGLPBO);
  {$ENDIF}
  RegisterDrawMethod(TMethodMove);
  RegisterDrawMethod(TMethodDummy);
end;

procedure TFormMain.RegisterDrawMethod(MethodClass: TDrawMethodClass);
begin
  SetLength(DrawMethodClasses, Length(DrawMethodClasses) + 1);
  DrawMethodClasses[High(DrawMethodClasses)] := MethodClass;
end;

end.


unit UMainForm;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, DateUtils, UPlatform, LCLType, IntfGraphics, fpImage,
  Math, GraphType, Contnrs, LclIntf, UFastBitmap, UDrawMethod;

const
  SceneFrameCount = 100;

type


  { TMainForm }

  TMainForm = class(TForm)
    ButtonBenchmark: TButton;
    ButtonStart: TButton;
    ButtonStop: TButton;
    ComboBox1: TComboBox;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    ListView1: TListView;
    PageControl1: TPageControl;
    PaintBox1: TPaintBox;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Timer1: TTimer;
    procedure ButtonBenchmarkClick(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
    procedure ButtonStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
  public
    DrawMethods: TObjectList; // TObjectList<TDrawMethod>
    Bitmap: TBitmap;
    Scenes: TObjectList; // TObjectList<TFastBitmap>
    SceneIndex: Integer;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
var
  NewScene: TFastBitmap;
  NewDrawMethod: TDrawMethod;
  I: Integer;
begin
  TabSheet1.DoubleBuffered := True;
  Randomize;
  Scenes := TObjectList.Create;
  for I := 0 to SceneFrameCount - 1 do begin
    NewScene := TFastBitmap.Create;
    NewScene.Size := Point(320, 240);
    NewScene.RandomImage;
    Scenes.Add(NewScene);
  end;
  Bitmap := TBitmap.Create;
  Bitmap.PixelFormat := pf24bit;
  Image1.Picture.Bitmap.SetSize(TFastBitmap(Scenes[0]).Size.X, TFastBitmap(Scenes[0]).Size.Y);
  Bitmap.SetSize(TFastBitmap(Scenes[0]).Size.X, TFastBitmap(Scenes[0]).Size.Y);

  DrawMethods := TObjectList.Create;
  ComboBox1.Clear;
  for I := 0 to High(DrawMethodClasses) do begin
    NewDrawMethod := DrawMethodClasses[I].Create;
    NewDrawMethod.Bitmap := Image1.Picture.Bitmap;
    NewDrawMethod.PaintBox := PaintBox1;
    DrawMethods.Add(NewDrawMethod);
    ComboBox1.Items.Add(NewDrawMethod.Caption);
  end;
  ComboBox1.ItemIndex := 0;
end;

procedure TMainForm.ButtonStartClick(Sender: TObject);
begin
  ButtonStop.Enabled := True;
  ButtonStart.Enabled := False;
  Timer1.Enabled := True;
  if ComboBox1.ItemIndex >= 0 then
  with TDrawMethod(DrawMethods[ComboBox1.ItemIndex]) do begin
    PageControl1.TabIndex := Integer(PaintObject);
    Application.ProcessMessages;
    repeat
      DrawFrameTiming(TFastBitmap(Scenes[SceneIndex]));
      SceneIndex := (SceneIndex + 1) mod Scenes.Count;
      Application.ProcessMessages;
    until not ButtonStop.Enabled;
  end;
  ButtonStopClick(Self);
end;

procedure TMainForm.ButtonBenchmarkClick(Sender: TObject);
var
  NewItem: TListItem;
  I: Integer;
begin
  with ListView1, Items do
  try
    BeginUpdate;
    Clear;
    for I := 0 to DrawMethods.Count - 1 do
    with TDrawMethod(DrawMethods[I]) do begin
      PageControl1.TabIndex := Integer(PaintObject);
      Application.ProcessMessages;
      DrawFrameTiming(TFastBitmap(Scenes[0]));
      Application.ProcessMessages;
      DrawFrameTiming(TFastBitmap(Scenes[0]));
      NewItem := Add;
      NewItem.Caption := Caption;
      NewItem.SubItems.Add(FloatToStr(RoundTo(FrameDuration / OneMillisecond, -3)));
      NewItem.SubItems.Add(FloatToStr(RoundTo(1 / (FrameDuration / OneSecond), -3)));
    end;
  finally
    EndUpdate;
  end;
end;

procedure TMainForm.ButtonStopClick(Sender: TObject);
begin
  ButtonStart.Enabled := True;
  ButtonStop.Enabled := False;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ButtonStopClick(Self);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  DrawMethods.Free;
  Scenes.Free;
  Bitmap.Free;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  if (ComboBox1.ItemIndex >= 0) then
  with TDrawMethod(DrawMethods[ComboBox1.ItemIndex]) do begin
    if (FrameDuration > 0) then
      Label2.Caption := FloatToStr(RoundTo(1 / (FrameDuration / OneSecond), -3))
      else Label2.Caption := '0';
    Label4.Caption := FloatToStr(RoundTo(FrameDuration / OneMillisecond, -3)) + ' ms';
  end;
end;

end.


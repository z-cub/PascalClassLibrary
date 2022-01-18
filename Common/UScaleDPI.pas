unit UScaleDPI;

{ See: http://wiki.lazarus.freepascal.org/High_DPI }

{$mode delphi}{$H+}

interface

uses
  Classes, Forms, Graphics, Controls, ComCtrls, LCLType, SysUtils, fgl;

type
  TControlDimensions = class;

  { TControlDimension }

  TControlDimension = class
    BoundsRect: TRect;
    FontHeight: Integer;
    Controls: TControlDimensions;
    // Class specifics
    ButtonSize: TPoint; // TToolBar
    CoolBandWidth: Integer;
    ConstraintsMin: TPoint; // TForm
    ConstraintsMax: TPoint; // TForm
    constructor Create;
    destructor Destroy; override;
  end;

  TControlDimensions = class(TFPGObjectList<TControlDimension>)
  end;

  { TScaleDPI }

  TScaleDPI = class(TComponent)
  private
    FAutoDetect: Boolean;
    FDesignDPI: TPoint;
    FDPI: TPoint;
    procedure SetAutoDetect(AValue: Boolean);
    procedure SetDesignDPI(AValue: TPoint);
    procedure SetDPI(AValue: TPoint);
  public
    procedure StoreDimensions(Control: TControl; Dimensions: TControlDimension);
    procedure RestoreDimensions(Control: TControl; Dimensions: TControlDimension);
    procedure ScaleDimensions(Control: TControl; Dimensions: TControlDimension);
    procedure ApplyToAll(FromDPI: TPoint);
    procedure ScaleControl(Control: TControl; FromDPI: TPoint);
    procedure ScaleImageList(ImgList: TImageList; FromDPI: TPoint);
    function ScalePoint(APoint: TPoint; FromDPI: TPoint): TPoint;
    function ScaleRect(ARect: TRect; FromDPI: TPoint): TRect;
    function ScaleX(Size: Integer; FromDPI: Integer): Integer;
    function ScaleY(Size: Integer; FromDPI: Integer): Integer;
    constructor Create(AOwner: TComponent); override;
    property DesignDPI: TPoint read FDesignDPI write SetDesignDPI;
    property DPI: TPoint read FDPI write SetDPI;
  published
    property AutoDetect: Boolean read FAutoDetect write SetAutoDetect;
  end;

procedure Register;


implementation

resourcestring
  SWrongDPI = 'Wrong DPI [%d,%d]';

procedure Register;
begin
  RegisterComponents('Common', [TScaleDPI]);
end;

{ TControlDimension }

constructor TControlDimension.Create;
begin
  Controls := TControlDimensions.Create;
end;

destructor TControlDimension.Destroy;
begin
  FreeAndNil(Controls);
  inherited;
end;

procedure TScaleDPI.SetAutoDetect(AValue: Boolean);
begin
  if FAutoDetect = AValue then Exit;
  FAutoDetect := AValue;
  if AValue then begin
    DPI := Point(ScreenInfo.PixelsPerInchX, ScreenInfo.PixelsPerInchY);
  end;
end;

procedure TScaleDPI.SetDesignDPI(AValue: TPoint);
begin
  if (FDesignDPI.X = AValue.X) and (FDesignDPI.Y = AValue.Y) then Exit;
  if (AValue.X <= 0) or (AValue.Y <= 0) then
    raise Exception.Create(Format(SWrongDPI, [AValue.X, AValue.Y]));
  FDesignDPI := AValue;
end;

procedure TScaleDPI.SetDPI(AValue: TPoint);
begin
  if (FDPI.X = AValue.X) and (FDPI.Y = AValue.Y) then Exit;
  if (AValue.X <= 0) or (AValue.Y <= 0) then
    raise Exception.Create(Format(SWrongDPI, [AValue.X, AValue.Y]));
  FDPI := AValue;
end;

procedure TScaleDPI.StoreDimensions(Control: TControl;
  Dimensions: TControlDimension);
var
  NewControl: TControlDimension;
  I: Integer;
begin
  Dimensions.BoundsRect := Control.BoundsRect;
  Dimensions.FontHeight := Control.Font.GetTextHeight('Hg');
  Dimensions.Controls.Clear;
  if Control is TToolBar then
    Dimensions.ButtonSize := Point(TToolBar(Control).ButtonWidth, TToolBar(Control).ButtonHeight);
  if Control is TForm then begin
    Dimensions.ConstraintsMin := Point(TForm(Control).Constraints.MinWidth,
      TForm(Control).Constraints.MinHeight);
    Dimensions.ConstraintsMax := Point(TForm(Control).Constraints.MaxWidth,
      TForm(Control).Constraints.MaxHeight);
  end;
  if Control is TWinControl then
  for I := 0 to TWinControl(Control).ControlCount - 1 do begin
    if TWinControl(Control).Controls[I] is TControl then
    // Do not scale docked forms twice
    if not (TWinControl(Control).Controls[I] is TForm) then begin
      NewControl := TControlDimension.Create;
      Dimensions.Controls.Add(NewControl);
      StoreDimensions(TWinControl(Control).Controls[I], NewControl);
    end;
  end;
end;

procedure TScaleDPI.RestoreDimensions(Control: TControl;
  Dimensions: TControlDimension);
var
  I: Integer;
begin
  Control.BoundsRect := Dimensions.BoundsRect;
  Control.Font.Height := Dimensions.FontHeight;
  if Control is TToolBar then begin
    TToolBar(Control).ButtonWidth := Dimensions.ButtonSize.X;
    TToolBar(Control).ButtonHeight := Dimensions.ButtonSize.Y;
  end;
  if Control is TForm then begin
    TForm(Control).Constraints.MinWidth := Dimensions.ConstraintsMin.X;
    TForm(Control).Constraints.MinHeight := Dimensions.ConstraintsMin.Y;
    TForm(Control).Constraints.MaxWidth := Dimensions.ConstraintsMax.X;
    TForm(Control).Constraints.MaxHeight := Dimensions.ConstraintsMax.Y;
  end;
  if Control is TWinControl then
  for I := 0 to TWinControl(Control).ControlCount - 1 do begin
    if TWinControl(Control).Controls[I] is TControl then
    // Do not scale docked forms twice
    if not (TWinControl(Control).Controls[I] is TForm) then begin
      RestoreDimensions(TWinControl(Control).Controls[I], TControlDimension(Dimensions.Controls[I]));
    end;
  end;
end;

procedure TScaleDPI.ScaleDimensions(Control: TControl;
  Dimensions: TControlDimension);
var
  I: Integer;
begin
  Control.BoundsRect := ScaleRect(Dimensions.BoundsRect, DesignDPI);
  Control.Font.Height := ScaleY(Dimensions.FontHeight, DesignDPI.Y);
  if Control is TToolBar then begin
    TToolBar(Control).ButtonWidth := ScaleX(Dimensions.ButtonSize.X, DesignDPI.X);
    TToolBar(Control).ButtonHeight := ScaleY(Dimensions.ButtonSize.Y, DesignDPI.Y);
  end;
  if Control is TCoolBar then begin
    with TCoolBar(Control) do
    for I := 0 to Bands.Count - 1 do
    with TCoolBand(Bands[I]) do begin
      MinWidth := ScaleX(Dimensions.ButtonSize.X, DesignDPI.X);
      MinHeight := ScaleY(Dimensions.ButtonSize.Y, DesignDPI.Y);
      //Width := ScaleX(Dimensions.BoundsRect.Left -
    end;
  end;
  if Control is TForm then begin
    TForm(Control).Constraints.MinWidth := ScaleX(Dimensions.ConstraintsMin.X, DesignDPI.X);
    TForm(Control).Constraints.MaxWidth := ScaleX(Dimensions.ConstraintsMax.X, DesignDPI.X);
    TForm(Control).Constraints.MinHeight := ScaleY(Dimensions.ConstraintsMin.Y, DesignDPI.Y);
    TForm(Control).Constraints.MaxHeight := ScaleY(Dimensions.ConstraintsMax.Y, DesignDPI.Y);
  end;
  if Control is TWinControl then
  for I := 0 to TWinControl(Control).ControlCount - 1 do begin
    if TWinControl(Control).Controls[I] is TControl then
    // Do not scale docked forms twice
    if not (TWinControl(Control).Controls[I] is TForm) then begin
      ScaleDimensions(TWinControl(Control).Controls[I], TControlDimension(Dimensions.Controls[I]));
    end;
  end;
end;

procedure TScaleDPI.ApplyToAll(FromDPI: TPoint);
var
  I: Integer;
begin
  for I := 0 to Screen.FormCount - 1 do begin
    ScaleControl(Screen.Forms[I], FromDPI);
  end;
end;

procedure TScaleDPI.ScaleImageList(ImgList: TImageList; FromDPI: TPoint);
var
  TempBmp: TBitmap;
  Temp: array of TBitmap;
  NewWidth: Integer;
  NewHeight: Integer;
  I: Integer;
begin
  ImgList.BeginUpdate;
  try
    NewWidth := ScaleX(ImgList.Width, FromDPI.X);
    NewHeight := ScaleY(ImgList.Height, FromDPI.Y);

    Temp := nil;
    SetLength(Temp, ImgList.Count);
    for I := 0 to ImgList.Count - 1 do
    begin
      TempBmp := TBitmap.Create;
      try
        TempBmp.PixelFormat := pf32bit;
        ImgList.GetBitmap(I, TempBmp);
        Temp[I] := TBitmap.Create;
        Temp[I].SetSize(NewWidth, NewHeight);
        {$IFDEF UNIX}
        Temp[I].PixelFormat := pf24bit;
        {$ELSE}
        Temp[I].PixelFormat := pf32bit;
        {$ENDIF}
        Temp[I].TransparentColor := TempBmp.TransparentColor;
        //Temp[I].TransparentMode := TempBmp.TransparentMode;
        Temp[I].Transparent := True;
        Temp[I].Canvas.Brush.Style := bsSolid;
        Temp[I].Canvas.Brush.Color := Temp[I].TransparentColor;
        Temp[I].Canvas.FillRect(0, 0, Temp[I].Width, Temp[I].Height);

        if (Temp[I].Width = 0) or (Temp[I].Height = 0) then Continue;
        Temp[I].Canvas.StretchDraw(Rect(0, 0, Temp[I].Width, Temp[I].Height), TempBmp);
      finally
        TempBmp.Free;
      end;
    end;

    ImgList.Clear;
    ImgList.Width := NewWidth;
    ImgList.Height := NewHeight;

    for I := 0 to High(Temp) do
    begin
      ImgList.Add(Temp[I], nil);
      Temp[i].Free;
    end;
  finally
    ImgList.EndUpdate;
  end;
end;

function TScaleDPI.ScaleX(Size: Integer; FromDPI: Integer): Integer;
begin
  Result := MulDiv(Size, DPI.X, FromDPI);
end;

function TScaleDPI.ScaleY(Size: Integer; FromDPI: Integer): Integer;
begin
  Result := MulDiv(Size, DPI.Y, FromDPI);
end;

function TScaleDPI.ScalePoint(APoint: TPoint; FromDPI: TPoint): TPoint;
begin
  Result.X := ScaleX(APoint.X, FromDPI.X);
  Result.Y := ScaleY(APoint.Y, FromDPI.Y);
end;

function TScaleDPI.ScaleRect(ARect: TRect; FromDPI: TPoint): TRect;
begin
  Result.TopLeft := ScalePoint(ARect.TopLeft, FromDPI);
  Result.BottomRight := ScalePoint(ARect.BottomRight, FromDPI);
end;

constructor TScaleDPI.Create(AOwner: TComponent);
begin
  inherited;
  DPI := Point(96, 96);
  DesignDPI := Point(96, 96);
end;

procedure TScaleDPI.ScaleControl(Control: TControl; FromDPI: TPoint);
var
  I: Integer;
  WinControl: TWinControl;
  ToolBarControl: TToolBar;
  //OldAnchors: TAnchors;
  //OldAutoSize: Boolean;
begin
  //if not (Control is TCustomPage) then
  // Resize childs first
  if Control is TWinControl then begin
    WinControl := TWinControl(Control);
    if WinControl.ControlCount > 0 then begin
      for I := 0 to WinControl.ControlCount - 1 do begin
        if WinControl.Controls[I] is TControl then begin
          ScaleControl(WinControl.Controls[I], FromDPI);
        end;
      end;
    end;
  end;

  //if Control is TMemo then Exit;
  //if Control is TForm then
  //  Control.DisableAutoSizing;
  with Control do begin
    //OldAutoSize := AutoSize;
    //AutoSize := False;
    //Anchors := [];
    Left := ScaleX(Left, FromDPI.X);
    Top := ScaleY(Top, FromDPI.Y);
    //if not (akRight in Anchors) then
    Width := ScaleX(Width, FromDPI.X);
    //if not (akBottom in Anchors) then
    Height := ScaleY(Height, FromDPI.Y);
    {$IFDEF LCL Qt}
      Font.Size := 0;
    {$ELSE}
      Font.Height := ScaleY(Font.GetTextHeight('Hg'), FromDPI.Y);
    {$ENDIF}
    //Anchors := OldAnchors;
    //AutoSize := OldAutoSize;
  end;

  if Control is TCoolBar then
  with TCoolBar(Control) do begin
    BeginUpdate;
    try
      for I := 0 to Bands.Count - 1 do
        with Bands[I] do begin
          MinWidth := ScaleX(MinWidth, FromDPI.X);
          MinHeight := ScaleY(MinHeight, FromDPI.Y);
          // Workaround to bad band width auto sizing
          //Width := ScaleX(Width, FromDPI.X);
          Width := ScaleX(Control.Width + 28, FromDPI.X);
          //Control.Invalidate;
        end;
      // Workaround for bad autosizing of coolbar
      if AutoSize then begin
        AutoSize := False;
        Height := ScaleY(Height, FromDPI.Y);
        AutoSize := True;
      end;
    finally
      EndUpdate;
    end;
  end;

  if Control is TToolBar then begin
    ToolBarControl := TToolBar(Control);
    with ToolBarControl do begin
      ButtonWidth := ScaleX(ButtonWidth, FromDPI.X);
      ButtonHeight := ScaleY(ButtonHeight, FromDPI.Y);
    end;
  end;

  //if Control is TForm then
  //  Control.EnableAutoSizing;
end;

end.

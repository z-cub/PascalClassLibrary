unit UMetaCanvas;

{$mode delphi}

interface

uses
  Classes, SysUtils, Graphics, Types, fgl;

type
  TArrayOfPoint = array of TPoint;

  { TCanvasObject }

  TCanvasObject = class
    procedure Paint(Canvas: TCanvas); virtual;
    procedure Zoom(Factor: Double); virtual;
    procedure Move(Delta: TPoint); virtual;
  end;

  TCanvasObjects = class(TFPGObjectList<TCanvasObject>)
  end;

  { TCanvasText }

  TCanvasText = class(TCanvasObject)
    Brush: TBrush;
    Font: TFont;
    Position: TPoint;
    Text: string;
    procedure Paint(Canvas: TCanvas); override;
    procedure Zoom(Factor: Double); override;
    procedure Move(Delta: TPoint); override;
    constructor Create;
    destructor Destroy; override;
  end;

  { TCanvasRectangle }

  TCanvasRectangle = class(TCanvasObject)
    Pen: TPen;
    Brush: TBrush;
    BoundingRect: TRect;
    Rounded: TPoint;
    procedure Paint(Canvas: TCanvas); override;
    procedure Zoom(Factor: Double); override;
    procedure Move(Delta: TPoint); override;
    constructor Create;
    destructor Destroy; override;
  end;

  { TCanvasLine }

  TCanvasLine = class(TCanvasObject)
    Pen: TPen;
    P1, P2: TPoint;
    procedure Paint(Canvas: TCanvas); override;
    procedure Zoom(Factor: Double); override;
    procedure Move(Delta: TPoint); override;
    constructor Create;
    destructor Destroy; override;
  end;

  { TCanvasPolygon }

  TCanvasPolygon = class(TCanvasObject)
    Pen: TPen;
    Brush: TBrush;
    Points: array of TPoint;
    procedure Paint(Canvas: TCanvas); override;
    procedure Zoom(Factor: Double); override;
    procedure Move(Delta: TPoint); override;
    constructor Create;
    destructor Destroy; override;
  end;

  { TCanvasEllipse }

  TCanvasEllipse = class(TCanvasObject)
    Pen: TPen;
    Brush: TBrush;
    BoundingRect: TRect;
    procedure Paint(Canvas: TCanvas); override;
    procedure Zoom(Factor: Double); override;
    procedure Move(Delta: TPoint); override;
    constructor Create;
    destructor Destroy; override;
  end;

  { TCanvasPie }

  TCanvasPie = class(TCanvasObject)
    Pen: TPen;
    Brush: TBrush;
    BoundingRect: TRect;
    StartPoint: TPoint;
    EndPoint: TPoint;
    procedure Paint(Canvas: TCanvas); override;
    procedure Zoom(Factor: Double); override;
    procedure Move(Delta: TPoint); override;
    constructor Create;
    destructor Destroy; override;
  end;

  { TCanvasStretchDraw }

  TCanvasStretchDraw = class(TCanvasObject)
    SrcGraphic: TGraphic;
    DestRect: TRect;
    procedure Paint(Canvas: TCanvas); override;
    procedure Zoom(Factor: Double); override;
    procedure Move(Delta: TPoint); override;
    constructor Create;
    destructor Destroy; override;
  end;

  { TMetaCanvas }

  TMetaCanvas = class(TCanvas)
  private
    FSize: TPoint;
    FPenPos: TPoint;
  protected
    procedure SetHeight(AValue: Integer); override;
    function GetHeight: Integer; override;
    procedure SetWidth(AValue: Integer); override;
    function GetWidth: Integer; override;
    procedure DoLine (x1,y1,x2,y2:integer); override;
    procedure DoTextOut(X, Y: Integer; Text: string); override;
    procedure DoRectangle(const Bounds: TRect); override;
    procedure DoRectangleFill(const Bounds: TRect); override;
    procedure DoPolygon(const Points: array of TPoint); override;
    procedure CreateHandle; override;
    procedure DoEllipse(const Bounds: TRect); override;
    procedure DoMoveTo(X, Y: Integer); override;
    procedure DoLineTo(X, Y: Integer); override;
  public
    Objects: TCanvasObjects;
    procedure FillRect(const ARect: TRect); overload; override;
    procedure FillRect(X1,Y1,X2,Y2: Integer); overload;
    procedure RoundRect(X1, Y1, X2, Y2: Integer; RX,RY: Integer); overload; override;
    procedure RoundRect(const Rect: TRect; RX,RY: Integer); overload;
    procedure TextOut(X,Y: Integer; const Text: String); override;
    procedure Polygon(Points: PPoint; NumPts: Integer; Winding: boolean = False); override;
    procedure Ellipse(x1, y1, x2, y2: Integer); override;
    procedure StretchDraw(const DestRect: TRect; SrcGraphic: TGraphic); override;
    function TextExtent(const Text: string): TSize; override;
    procedure Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2,
      StartX, StartY, EndX, EndY: Integer); override;
    procedure Reset;
    procedure DrawTo(Canvas: TCanvas);
    procedure Zoom(Factor: Double);
    procedure Move(Delta: TPoint);
    constructor Create;
    destructor Destroy; override;
    property Size: TPoint read FSize write FSize;
  end;


implementation

uses
  UGeometric, LCLIntf;

{ TCanvasPie }

procedure TCanvasPie.Paint(Canvas: TCanvas);
begin
  Canvas.Brush.Assign(Brush);
  Canvas.Pen.Assign(Pen);
  Canvas.Pie(BoundingRect.Left, BoundingRect.Top,
    BoundingRect.Right, BoundingRect.Bottom, StartPoint.X, StartPoint.Y,
    EndPoint.X, EndPoint.Y);
end;

procedure TCanvasPie.Zoom(Factor: Double);
begin
  BoundingRect := Rect(Trunc(BoundingRect.Left * Factor),
    Trunc(BoundingRect.Top * Factor),
    Trunc(BoundingRect.Right * Factor),
    Trunc(BoundingRect.Bottom * Factor));
  Pen.Width := Trunc(Pen.Width * Factor);
  StartPoint := Point(Trunc(StartPoint.X * Factor), Trunc(StartPoint.Y * Factor));
  EndPoint := Point(Trunc(EndPoint.X * Factor), Trunc(EndPoint.Y * Factor));
end;

procedure TCanvasPie.Move(Delta: TPoint);
begin
  BoundingRect := ShiftRect(BoundingRect, Delta);
  StartPoint := AddPoint(StartPoint, Delta);
  EndPoint := AddPoint(EndPoint, Delta);
end;

constructor TCanvasPie.Create;
begin
  Pen := TPen.Create;
  Brush := TBrush.Create;
end;

destructor TCanvasPie.Destroy;
begin
  Pen.Free;
  Brush.Free;
  inherited;
end;

{ TCanvasStretchDraw }

procedure TCanvasStretchDraw.Paint(Canvas: TCanvas);
begin
  Canvas.StretchDraw(DestRect, SrcGraphic);
end;

procedure TCanvasStretchDraw.Zoom(Factor: Double);
begin
  DestRect := Rect(Trunc(DestRect.Left * Factor),
    Trunc(DestRect.Top * Factor),
    Trunc(DestRect.Right * Factor),
    Trunc(DestRect.Bottom * Factor));
end;

procedure TCanvasStretchDraw.Move(Delta: TPoint);
begin
  DestRect := ShiftRect(DestRect, Delta);
end;

constructor TCanvasStretchDraw.Create;
begin
  SrcGraphic := nil;
end;

destructor TCanvasStretchDraw.Destroy;
begin
  inherited;
end;

{ TCanvasEllipse }

procedure TCanvasEllipse.Paint(Canvas: TCanvas);
begin
  Canvas.Pen.Assign(Pen);
  Canvas.Brush.Assign(Brush);
  Canvas.Ellipse(BoundingRect);
end;

procedure TCanvasEllipse.Zoom(Factor: Double);
begin
  BoundingRect := Rect(Trunc(BoundingRect.Left * Factor),
    Trunc(BoundingRect.Top * Factor),
    Trunc(BoundingRect.Right * Factor),
    Trunc(BoundingRect.Bottom * Factor));
  Pen.Width := Trunc(Pen.Width * Factor);
end;

procedure TCanvasEllipse.Move(Delta: TPoint);
begin
  BoundingRect := ShiftRect(BoundingRect, Delta);
end;

constructor TCanvasEllipse.Create;
begin
  Pen := TPen.Create;
  Brush := TBrush.Create;
end;

destructor TCanvasEllipse.Destroy;
begin
  Pen.Free;
  Brush.Free;
  inherited;
end;

{ TCanvasPolygon }

procedure TCanvasPolygon.Paint(Canvas: TCanvas);
begin
  Canvas.Pen.Assign(Pen);
  Canvas.Brush.Assign(Brush);
  Canvas.Polygon(Points);
end;

procedure TCanvasPolygon.Zoom(Factor: Double);
var
  I: Integer;
begin
  for I := 0 to High(Points) do
    Points[I] := Point(Trunc(Points[I].X * Factor),
      Trunc(Points[I].Y * Factor));
  Pen.Width := Trunc(Pen.Width * Factor);
end;

procedure TCanvasPolygon.Move(Delta: TPoint);
var
  I: Integer;
begin
  for I := 0 to High(Points) do
    Points[I] := AddPoint(Points[I], Delta);
end;

constructor TCanvasPolygon.Create;
begin
  Pen := TPen.Create;
  Brush := TBrush.Create;
end;

destructor TCanvasPolygon.Destroy;
begin
  Brush.Free;
  Pen.Free;
  inherited;
end;

{ TCanvasLine }

procedure TCanvasLine.Paint(Canvas: TCanvas);
begin
  Canvas.Pen.Assign(Pen);
  Canvas.Line(P1, P2);
end;

procedure TCanvasLine.Zoom(Factor: Double);
begin
  P1 := Point(Trunc(P1.X * Factor), Trunc(P1.Y * Factor));
  P2 := Point(Trunc(P2.X * Factor), Trunc(P2.Y * Factor));
  Pen.Width := Trunc(Pen.Width * Factor);
end;

procedure TCanvasLine.Move(Delta: TPoint);
begin
  P1 := AddPoint(P1, Delta);
  P2 := AddPoint(P2, Delta);
end;

constructor TCanvasLine.Create;
begin
  Pen := TPen.Create;
end;

destructor TCanvasLine.Destroy;
begin
  Pen.Free;
  inherited;
end;

{ TCanvasRectangle }

procedure TCanvasRectangle.Paint(Canvas: TCanvas);
begin
  Canvas.Pen.Assign(Pen);
  Canvas.Brush.Assign(Brush);

  if Rounded <> Point(0, 0) then Canvas.RoundRect(BoundingRect, Rounded.X, Rounded.Y)
    else Canvas.Rectangle(BoundingRect);
end;

procedure TCanvasRectangle.Zoom(Factor: Double);
begin
  BoundingRect := Rect(Trunc(BoundingRect.Left * Factor),
    Trunc(BoundingRect.Top * Factor),
    Trunc(BoundingRect.Right * Factor),
    Trunc(BoundingRect.Bottom * Factor));
  Pen.Width := Trunc(Pen.Width * Factor);
end;

procedure TCanvasRectangle.Move(Delta: TPoint);
begin
  BoundingRect := ShiftRect(BoundingRect, Delta);
end;

constructor TCanvasRectangle.Create;
begin
  Pen := TPen.Create;
  Brush := TBrush.Create;
  Rounded := Point(0, 0);
end;

destructor TCanvasRectangle.Destroy;
begin
  Pen.Free;
  Brush.Free;
  inherited;
end;

{ TCanvasText }

procedure TCanvasText.Paint(Canvas: TCanvas);
begin
  Canvas.Brush.Assign(Brush);
  Canvas.Font.Assign(Font);
  Canvas.TextOut(Position.X, Position.Y, Text);
end;

procedure TCanvasText.Zoom(Factor: Double);
begin
  Position := Point(Trunc(Position.X * Factor), Trunc(Position.Y * Factor));
  Font.Size := Trunc(Font.Size * Factor);
end;

procedure TCanvasText.Move(Delta: TPoint);
begin
  Position := AddPoint(Position, Delta);
end;

constructor TCanvasText.Create;
begin
  Font := TFont.Create;
  Brush := TBrush.Create;
end;

destructor TCanvasText.Destroy;
begin
  Brush.Free;
  Font.Free;
  inherited;
end;

{ TCanvasObject }

procedure TCanvasObject.Paint(Canvas: TCanvas);
begin

end;

procedure TCanvasObject.Zoom(Factor: Double);
begin

end;

procedure TCanvasObject.Move(Delta: TPoint);
begin
end;

{ TMetaCanvas }

procedure TMetaCanvas.SetHeight(AValue: Integer);
begin
  FSize.Y := AValue;
end;

function TMetaCanvas.GetHeight: Integer;
begin
  Result := FSize.Y;
end;

procedure TMetaCanvas.SetWidth(AValue: Integer);
begin
  FSize.X := AValue;
end;

function TMetaCanvas.GetWidth: Integer;
begin
  Result := FSize.X;
end;

procedure TMetaCanvas.DoLine(x1, y1, x2, y2: integer);
var
  NewObj: TCanvasLine;
begin
  NewObj := TCanvasLine.Create;
  NewObj.Pen.Assign(Pen);
  NewObj.P1 := Point(X1, Y1);
  NewObj.P2 := Point(X2, Y2);
  Objects.Add(NewObj);
end;

procedure TMetaCanvas.DoTextOut(X, Y: Integer; Text: string);
var
  NewObj: TCanvasText;
begin
  NewObj := TCanvasText.Create;
  NewObj.Font.Assign(Font);
  NewObj.Brush.Assign(Brush);
  NewObj.Position := Point(X, Y);
  NewObj.Text := Text;
  Objects.Add(NewObj);
end;

procedure TMetaCanvas.TextOut(X, Y: Integer; const Text: String);
begin
  DoTextOut(X, Y, Text);
end;

procedure TMetaCanvas.DoRectangle(const Bounds: TRect);
var
  NewObj: TCanvasRectangle;
begin
  NewObj := TCanvasRectangle.Create;
  NewObj.Pen.Assign(Pen);
  NewObj.BoundingRect := Bounds;
  Objects.Add(NewObj);
end;

procedure TMetaCanvas.DoRectangleFill(const Bounds: TRect);
var
  NewObj: TCanvasRectangle;
begin
  NewObj := TCanvasRectangle.Create;
  NewObj.Brush.Assign(Brush);
  NewObj.Pen.Assign(Pen);
  NewObj.BoundingRect := Bounds;
  Objects.Add(NewObj);
end;

procedure TMetaCanvas.Polygon(Points: PPoint; NumPts: Integer; Winding: boolean
  );
var
  APoints: array of TPoint;
  I: Integer;
begin
  SetLength(APoints, NumPts);
  for I := 0 to High(APoints) do
    APoints[I] := Points[I];
  DoPolygon(APoints);
end;

procedure TMetaCanvas.DoPolygon(const Points: array of TPoint);
var
  NewObj: TCanvasPolygon;
  I: Integer;
begin
  NewObj := TCanvasPolygon.Create;
  NewObj.Brush.Assign(Brush);
  NewObj.Pen.Assign(Pen);
  SetLength(NewObj.Points, Length(Points));
  for I := 0 to High(Points) do
    NewObj.Points[I] := Points[I];
  Objects.Add(NewObj);
end;

procedure TMetaCanvas.CreateHandle;
begin
end;

procedure TMetaCanvas.Ellipse(x1, y1, x2, y2: Integer);
begin
  DoEllipse(Rect(X1, Y1, X2, Y2));
end;

procedure TMetaCanvas.DoEllipse(const Bounds: TRect);
var
  NewObj: TCanvasEllipse;
begin
  NewObj := TCanvasEllipse.Create;
  NewObj.Brush.Assign(Brush);
  NewObj.Pen.Assign(Pen);
  NewObj.BoundingRect := Bounds;
  Objects.Add(NewObj);
end;

procedure TMetaCanvas.StretchDraw(const DestRect: TRect; SrcGraphic: TGraphic);
var
  NewObj: TCanvasStretchDraw;
begin
  NewObj := TCanvasStretchDraw.Create;
  NewObj.SrcGraphic := SrcGraphic;
  NewObj.DestRect := DestRect;
  Objects.Add(NewObj);
end;

function TMetaCanvas.TextExtent(const Text: string): TSize;
var
  Canvas: TCanvas;
begin
  Canvas := TCanvas.Create;
  Canvas.Handle := CreateCompatibleDC(0);
  Canvas.Font.Assign(Font);
  Result := Canvas.TextExtent(Text);
  DeleteDC(Canvas.Handle);
  Canvas.Free;
end;

procedure TMetaCanvas.DoMoveTo(X, Y: Integer);
begin
  FPenPos := Point(X, Y);
end;

procedure TMetaCanvas.DoLineTo(X, Y: Integer);
begin
  DoLine(FPenPos.X, FPenPos.Y, X, Y);
  DoMoveTo(X, Y);
end;

procedure TMetaCanvas.FillRect(const ARect: TRect);
begin
  DoRectangleFill(ARect);
end;

procedure TMetaCanvas.FillRect(X1, Y1, X2, Y2: Integer);
begin
  FillRect(Rect(X1, Y1, X2, Y2));
end;

procedure TMetaCanvas.RoundRect(X1, Y1, X2, Y2: Integer; RX, RY: Integer);
begin
  RoundRect(Rect(X1, Y1, X2, Y2), RX, RY);
end;

procedure TMetaCanvas.RoundRect(const Rect: TRect; RX, RY: Integer);
var
  NewObj: TCanvasRectangle;
begin
  NewObj := TCanvasRectangle.Create;
  NewObj.Brush.Assign(Brush);
  NewObj.Pen.Assign(Pen);
  NewObj.BoundingRect := Rect;
  NewObj.Rounded := Point(RX, RY);
  Objects.Add(NewObj);
end;

procedure TMetaCanvas.Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2, StartX,
  StartY, EndX, EndY: Integer);
var
  NewObj: TCanvasPie;
begin
  NewObj := TCanvasPie.Create;
  NewObj.Brush.Assign(Brush);
  NewObj.Pen.Assign(Pen);
  NewObj.BoundingRect := Rect(EllipseX1, EllipseY1, EllipseX2, EllipseY2);
  NewObj.StartPoint := Point(StartX, StartY);
  NewObj.EndPoint := Point(EndX, EndY);
  Objects.Add(NewObj);
end;

procedure TMetaCanvas.Reset;
begin
  Objects.Count := 0;
end;

procedure TMetaCanvas.DrawTo(Canvas: TCanvas);
var
  I: Integer;
begin
  for I := 0 to Objects.Count - 1 do
    Objects[I].Paint(Canvas);
end;

procedure TMetaCanvas.Zoom(Factor: Double);
var
  I: Integer;
begin
  for I := 0 to Objects.Count - 1 do
    Objects[I].Zoom(Factor);
end;

procedure TMetaCanvas.Move(Delta: TPoint);
var
  I: Integer;
begin
  for I := 0 to Objects.Count - 1 do
    Objects[I].Move(Delta);
end;

constructor TMetaCanvas.Create;
begin
  inherited;
  FPenPos := Point(0, 0);
  Objects := TCanvasObjects.Create;
end;

destructor TMetaCanvas.Destroy;
begin
  Objects.Free;
  inherited;
end;

end.


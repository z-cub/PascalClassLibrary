unit UGeometric;

{$mode delphi}

interface

uses
  Classes, SysUtils, Math;

type
  TPointArray = array of TPoint;

function Distance(P1, P2: TPoint): Integer;
function Dot(const P1, P2: TPoint): Double;
function AddPoint(const P1, P2: TPoint): TPoint;
function SubPoint(const P1, P2: TPoint): TPoint;
function PointToLineDistance(const P, V, W: TPoint): Integer;
function ComparePoint(P1, P2: TPoint): Boolean;
function RotatePoint(Center, P: TPoint; Angle: Double): TPoint;
function RotatePoints(Center: TPoint; P: TPointArray; Angle: Double): TPointArray;
function LineIntersect(LineAP1, LineAP2, LineBP1, LineBP2: TPoint;
  out Intersection: TPoint): Boolean;
function ArcTan2Point(Point: TPoint): Float;
function ArcTanPoint(Point: TPoint): Float;
function RectEquals(A, B: TRect): Boolean;
function RectEnlarge(Rect: TRect; Value: Integer): TRect;
function ShiftRect(ARect: TRect; Delta: TPoint): TRect;

implementation

function Distance(P1, P2: TPoint): Integer;
begin
  Result := Trunc(Sqrt(Sqr(P2.X - P1.X) + Sqr(P2.Y - P1.Y)));
end;

function Dot(const P1, P2: TPoint): Double;
begin
  Result := P1.X * P2.X + P1.Y * P2.Y;
end;

function AddPoint(const P1, P2: TPoint): TPoint;
begin
  Result.X := P1.X + P2.X;
  Result.Y := P1.Y + P2.Y;
end;

function SubPoint(const P1, P2: TPoint): TPoint;
begin
  Result.X := P1.X - P2.X;
  Result.Y := P1.Y - P2.Y;
end;

function PointToLineDistance(const P, V, W: TPoint): Integer;
var
  l2, t: Double;
  tt: TPoint;
begin
  // Return minimum distance between line segment vw and point p
  L2 := Distance(V, W); // i.e. |w-v|^2 -  avoid a sqrt
  L2 := Power(l2, 2);
  if L2 = 0 then begin
    Result := Distance(P, V);   // v == w case
    Exit;
  end;
  // Consider the line extending the segment, parameterized as v + t (w - v).
  // We find projection of point p onto the line.
  // It falls where t = [(p-v) . (w-v)] / |w-v|^2
  T := Dot(SubPoint(P, V), SubPoint(W, V)) / L2;
  if T < 0 then begin
    Result := Distance(P, V);       // Beyond the 'v' end of the segment
    exit;
  end
  else if T > 1 then begin
    Result := Distance(P, W);  // Beyond the 'w' end of the segment
    Exit;
  end;
  TT.X := Trunc(V.X + T * (W.X - V.X));
  TT.Y := Trunc(V.Y + T * (W.Y - V.Y));
  Result := Distance(P, TT);
end;

function ComparePoint(P1, P2: TPoint): Boolean;
begin
  Result := (P1.X = P2.X) and (P1.Y = P2.Y);
end;

function RotatePoint(Center, P: TPoint; Angle: Double): TPoint;
begin
  P := Point(P.X - Center.X, P.Y - Center.Y);
  Result := Point(Center.X + Round(P.X * Cos(Angle) - P.Y * Sin(Angle)),
    Center.Y + Round(P.X * Sin(Angle) + P.Y * Cos(Angle)));
end;

function RotatePoints(Center: TPoint; P: TPointArray; Angle: Double): TPointArray;
var
  I: Integer;
begin
  Result := Default(TPointArray);
  SetLength(Result, Length(P));
  for I := 0 to High(P) do
    Result[I] := RotatePoint(Center, P[I], Angle);
end;

function LineIntersect(LineAP1, LineAP2, LineBP1, LineBP2: TPoint;
  out Intersection: TPoint): Boolean;
Var
  LDetLineA, LDetLineB, LDetDivInv: Double;
  LDiffLA, LDiffLB: TPoint;
  D: Double;
begin
  if (LineAP1 = LineAP2) or (LineBP1 = LineBP2) then begin
    Result := False;
    Exit;
  end;
  LDetLineA := LineAP1.X * LineAP2.Y - LineAP1.Y * LineAP2.X;
  LDetLineB := LineBP1.X * LineBP2.Y - LineBP1.Y * LineBP2.X;

  LDiffLA := SubPoint(LineAP1, LineAP2);
  LDiffLB := SubPoint(LineBP1, LineBP2);

  D := ((LDiffLA.X * LDiffLB.Y) - (LDiffLA.Y * LDiffLB.X));
  if D = 0 then begin
    // Parallel lines without intersection
    Result := False;
    Exit;
  end;
  LDetDivInv := 1 / D;

  Intersection.X := Trunc(((LDetLineA * LDiffLB.X) - (LDiffLA.X * LDetLineB)) * LDetDivInv);
  Intersection.Y := Trunc(((LDetLineA * LDiffLB.Y) - (LDiffLA.Y * LDetLineB)) * LDetDivInv);
  Result := True;
end;

function ArcTan2Point(Point: TPoint): Float;
begin
  Result := ArcTan2(Point.Y, Point.X);
end;

function ArcTanPoint(Point: TPoint): Float;
begin
  if Point.Y = 0 then Result := Infinity
    else Result := ArcTan(Point.X / Point.Y);
end;

function RectEquals(A, B: TRect): Boolean;
begin
  Result := (A.Left = B.Left) and (A.Top = B.Top) and
    (A.Right = B.Right) and (A.Bottom = B.Bottom);
end;

function RectEnlarge(Rect: TRect; Value: Integer): TRect;
begin
  Result.Left := Rect.Left - Value;
  Result.Right := Rect.Right + Value;
  Result.Top := Rect.Top - Value;
  Result.Bottom := Rect.Bottom + Value;
end;

function ShiftRect(ARect: TRect; Delta: TPoint): TRect;
begin
  Result := Rect(ARect.Left + Delta.X, ARect.Top + Delta.Y,
    ARect.Right + Delta.X, ARect.Bottom + Delta.Y);
end;


end.


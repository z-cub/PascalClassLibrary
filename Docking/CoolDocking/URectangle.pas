unit URectangle;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 

type
  { TRectangle }

  TRectangle = class
  private
    function GetBottomLeft: TPoint;
    function GetBottomRight: TPoint;
    function GetHeight: Integer;
    function GetTopLeft: TPoint;
    function GetTopRight: TPoint;
    function GetWidth: Integer;
    procedure SetBottomLeft(const AValue: TPoint);
    procedure SetBottomRight(const AValue: TPoint);
    procedure SetHeight(const AValue: Integer);
    procedure SetTopLeft(const AValue: TPoint);
    procedure SetTopRight(const AValue: TPoint);
    procedure SetWidth(const AValue: Integer);
  public
    Left: Integer;
    Top: Integer;
    Right: Integer;
    Bottom: Integer;

    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;

    property TopLeft: TPoint read GetTopLeft write SetTopLeft;
    property TopRight: TPoint read GetTopRight write SetTopRight;
    property BottomLeft: TPoint read GetBottomLeft write SetBottomLeft;
    property BottomRight: TPoint read GetBottomRight write SetBottomRight;
  end;

implementation

{ TRectangle }

function TRectangle.GetBottomLeft: TPoint;
begin
  Result.X := Left;
  Result.Y := Bottom;
end;

function TRectangle.GetBottomRight: TPoint;
begin
  Result.X := Right;
  Result.Y := Bottom;
end;

function TRectangle.GetHeight: Integer;
begin
  Result := Bottom - Top;
end;

function TRectangle.GetTopLeft: TPoint;
begin
  Result.X := Left;
  Result.Y := Top;
end;

function TRectangle.GetTopRight: TPoint;
begin
  Result.X := Right;
  Result.Y := Top;
end;

function TRectangle.GetWidth: Integer;
begin
  Result := Right - Left;
end;

procedure TRectangle.SetBottomLeft(const AValue: TPoint);
begin
  Left := AValue.X;
  Bottom := AValue.Y;
end;

procedure TRectangle.SetBottomRight(const AValue: TPoint);
begin
  Right := AValue.X;
  Bottom := AValue.Y;
end;

procedure TRectangle.SetHeight(const AValue: Integer);
begin
  Bottom := Top + AValue;
end;

procedure TRectangle.SetTopLeft(const AValue: TPoint);
begin
  Left := AValue.X;
  Top := AValue.Y;
end;

procedure TRectangle.SetTopRight(const AValue: TPoint);
begin
  Right := AValue.X;
  Top := AValue.Y;
end;

procedure TRectangle.SetWidth(const AValue: Integer);
begin
  Right := Left + AValue;
end;

end.

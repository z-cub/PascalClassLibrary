unit UListViewSort;

// Date: 2019-05-17

{$mode delphi}

interface

uses
  {$IFDEF Windows}Windows, CommCtrl, LMessages, {$ENDIF}Classes, Graphics, ComCtrls, SysUtils,
  Controls, DateUtils, Dialogs, fgl, Forms, Grids, StdCtrls, ExtCtrls,
  LclIntf, LclType, LResources;

type
  TSortOrder = (soNone, soUp, soDown);

  TListViewSort = class;

  TCompareEvent = function (Item1, Item2: TObject): Integer of object;
  TListFilterEvent = procedure (ListViewSort: TListViewSort) of object;

  { TListViewSort }

  TListViewSort = class(TComponent)
  private
    FListView: TListView;
    FOnCompareItem: TCompareEvent;
    FOnFilter: TListFilterEvent;
    FOnCustomDraw: TLVCustomDrawItemEvent;
    {$IFDEF Windows}FHeaderHandle: HWND;{$ENDIF}
    FColumn: Integer;
    FOrder: TSortOrder;
    FOldListViewWindowProc: TWndMethod;
    FOnColumnWidthChanged: TNotifyEvent;
    procedure DoColumnBeginResize(const AColIndex: Integer);
    procedure DoColumnResized(const AColIndex: Integer);
    procedure DoColumnResizing(const AColIndex, AWidth: Integer);
    procedure SetListView(const Value: TListView);
    procedure ColumnClick(Sender: TObject; Column: TListColumn);
    procedure Sort(Compare: TCompareEvent);
    procedure DrawCheckMark(Item: TListItem; Checked: Boolean);
    procedure GetCheckBias(var XBias, YBias, BiasTop, BiasLeft: Integer;
      const ListView: TListView);
    procedure ListViewCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure ListViewClick(Sender: TObject);
    procedure UpdateColumns;
    procedure SetColumn(const Value: Integer);
    procedure SetOrder(const Value: TSortOrder);
    {$IFDEF WINDOWS}
    procedure NewListViewWindowProc(var AMsg: TMessage);
    {$ENDIF}
  public
    List: TFPGObjectList<TObject>;
    Source: TFPGObjectList<TObject>;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CompareTime(Time1, Time2: TDateTime): Integer;
    function CompareInteger(Value1, Value2: Integer): Integer;
    function CompareString(Value1, Value2: string): Integer;
    function CompareBoolean(Value1, Value2: Boolean): Integer;
    procedure Refresh;
  published
    property ListView: TListView read FListView write SetListView;
    property OnCompareItem: TCompareEvent read FOnCompareItem
      write FOnCompareItem;
    property OnFilter: TListFilterEvent read FOnFilter
      write FOnFilter;
    property OnCustomDraw: TLVCustomDrawItemEvent read FOnCustomDraw
      write FOnCustomDraw;
    property OnColumnWidthChanged: TNotifyEvent read FOnColumnWidthChanged
      write FOnColumnWidthChanged;
    property Column: Integer read FColumn write SetColumn;
    property Order: TSortOrder read FOrder write SetOrder;
  end;

  { TListViewFilter }

  TListViewFilter = class(TWinControl)
  private
    FOnChange: TNotifyEvent;
    FStringGrid1: TStringGrid;
    procedure DoOnChange;
    procedure GridDoOnKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GridDoOnResize(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure UpdateFromListView(ListView: TListView);
    function TextEntered: Boolean;
    function TextEnteredCount: Integer;
    function TextEnteredColumn(Index: Integer): Boolean;
    function GetColValue(Index: Integer): string;
    procedure Reset;
    property StringGrid: TStringGrid read FStringGrid1 write FStringGrid1;
  published
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Align;
    property Anchors;
    property BorderSpacing;
  end;

  { TListViewEx }

  TListViewEx = class(TWinControl)
  private
    FFilter: TListViewFilter;
    FListView: TListView;
    FListViewSort: TListViewSort;
    procedure ResizeHanlder;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ListView: TListView read FListView write FListView;
    property ListViewSort: TListViewSort read FListViewSort write FListViewSort;
    property Filter: TListViewFilter read FFilter write FFilter;
    property Visible;
  end;

procedure Register;


implementation

procedure Register;
begin
  RegisterComponents('Common', [TListViewSort, TListViewFilter, TListViewEx]);
end;

{ TListViewEx }

procedure TListViewEx.ResizeHanlder;
begin
end;

constructor TListViewEx.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Filter := TListViewFilter.Create(Self);
  Filter.Parent := Self;
  Filter.Align := alBottom;
  ListView := TListView.Create(Self);
  ListView.Parent := Self;
  ListView.Align := alClient;
  ListViewSort := TListViewSort.Create(Self);
  ListViewSort.ListView := ListView;
end;

destructor TListViewEx.Destroy;
begin
  inherited Destroy;
end;

{ TListViewFilter }

procedure TListViewFilter.DoOnChange;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TListViewFilter.GridDoOnKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  DoOnChange;
end;

procedure TListViewFilter.GridDoOnResize(Sender: TObject);
begin
  FStringGrid1.DefaultRowHeight := FStringGrid1.Height;
end;

constructor TListViewFilter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStringGrid1 := TStringGrid.Create(Self);
  FStringGrid1.Align := alClient;
  FStringGrid1.Parent := Self;
  FStringGrid1.Visible := True;
  FStringGrid1.ScrollBars := ssNone;
  FStringGrid1.FixedCols := 0;
  FStringGrid1.FixedRows := 0;
  FStringGrid1.RowCount := 1;
  FStringGrid1.Options := [goFixedHorzLine, goFixedVertLine, goVertLine,
    goHorzLine, goRangeSelect, goEditing, goAlwaysShowEditor, goSmoothScroll];
  FStringGrid1.OnKeyUp := GridDoOnKeyUp;
  FStringGrid1.OnResize := GridDoOnResize;
end;

procedure TListViewFilter.UpdateFromListView(ListView: TListView);
var
  I: Integer;
  R: TRect;
begin
  with FStringGrid1 do begin
    while Columns.Count > ListView.Columns.Count do Columns.Delete(Columns.Count - 1);
    while Columns.Count < ListView.Columns.Count do Columns.Add;
    for I := 0 to ListView.Columns.Count - 1 do begin
      Columns[I].Width := ListView.Columns[I].Width;
      if Selection.Left = I then begin
        R := CellRect(I, 0);
        Editor.Left := R.Left + 2;
        Editor.Width := R.Width - 4;
      end;
    end;
  end;
end;

function TListViewFilter.TextEntered: Boolean;
begin
  Result := TextEnteredCount > 0;
end;

function TListViewFilter.TextEnteredCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FStringGrid1.ColCount - 1 do begin
    if FStringGrid1.Cells[I, 0] <> '' then begin
      Inc(Result);
    end;
  end;
end;

function TListViewFilter.TextEnteredColumn(Index: Integer): Boolean;
begin
  Result := FStringGrid1.Cells[Index, 0] <> '';
end;

function TListViewFilter.GetColValue(Index: Integer): string;
begin
  if (Index >= 0) and (Index < StringGrid.Columns.Count) then
    Result := StringGrid.Cells[Index, 0]
    else Result := '';
end;

procedure TListViewFilter.Reset;
var
  I: Integer;
begin
  with StringGrid do
  for I := 0 to ColCount - 1 do
    Cells[I, 0] := '';
  DoOnChange;
end;

{ TListViewSort }

{$IFDEF WINDOWS}
procedure TListViewSort.NewListViewWindowProc(var AMsg: TMessage);
var
  vColWidth: Integer;
  vMsgNotify: TLMNotify absolute AMsg;
  Code: Integer;
begin
  // call the old WindowProc of ListView
  FOldListViewWindowProc(AMsg);

  // Currently we care only with WM_NOTIFY message
  if AMsg.Msg = WM_NOTIFY then
  begin
    Code := NMHDR(PHDNotify(vMsgNotify.NMHdr)^.Hdr).Code;
    case Code of
      HDN_ENDTRACKA, HDN_ENDTRACKW:
        DoColumnResized(PHDNotify(vMsgNotify.NMHdr)^.Item);

      HDN_BEGINTRACKA, HDN_BEGINTRACKW:
        DoColumnBeginResize(PHDNotify(vMsgNotify.NMHdr)^.Item);

      HDN_TRACKA, HDN_TRACKW:
        begin
          vColWidth := -1;
          if (PHDNotify(vMsgNotify.NMHdr)^.PItem<>nil)
             and (PHDNotify(vMsgNotify.NMHdr)^.PItem^.Mask and HDI_WIDTH <> 0)
          then
            vColWidth := PHDNotify(vMsgNotify.NMHdr)^.PItem^.cxy;

          DoColumnResizing(PHDNotify(vMsgNotify.NMHdr)^.Item, vColWidth);
        end;
    end;
  end;
end;
{$ENDIF}

procedure TListViewSort.DoColumnBeginResize(const AColIndex: Integer);
begin
end;

procedure TListViewSort.DoColumnResizing(const AColIndex, AWidth: Integer);
begin
end;

procedure TListViewSort.DoColumnResized(const AColIndex: Integer);
begin
  if Assigned(FOnColumnWidthChanged) then
    FOnColumnWidthChanged(Self);
end;

procedure TListViewSort.ColumnClick(Sender: TObject; Column: TListColumn);
begin
  if Column.Index = Self.Column then begin
    if FOrder = soUp then FOrder := soDown
    else if FOrder = soDown then FOrder := soUp
    else FOrder := soUp;
  end else Self.Column := Column.Index;
  Refresh;
  UpdateColumns;
end;

procedure TListViewSort.SetOrder(const Value: TSortOrder);
begin
  FOrder := Value;
  UpdateColumns;
end;

procedure TListViewSort.SetColumn(const Value: Integer);
begin
  FColumn := Value;
  UpdateColumns;
end;

procedure TListViewSort.SetListView(const Value: TListView);
begin
  if FListView = Value then Exit;
  if Assigned(FListView) then
    ListView.WindowProc := FOldListViewWindowProc;
  FListView := Value;
  FListView.OnColumnClick := ColumnClick;
  FListView.OnCustomDrawItem := ListViewCustomDrawItem;
  FListView.OnClick := ListViewClick;
  FOldListViewWindowProc := FListView.WindowProc;
  {$IFDEF WINDOWS}
  FListView.WindowProc := NewListViewWindowProc;
  {$ENDIF}
end;

var
  ListViewSortCompare: TCompareEvent;

function ListViewCompare(const Item1, Item2: TObject): Integer;
begin
  Result := ListViewSortCompare(Item1, Item2);
end;

procedure TListViewSort.Sort(Compare: TCompareEvent);
begin
  // TODO: Because TFLGObjectList compare handler is not class method,
  // it is necessary to use simple function compare handler with local variable
  ListViewSortCompare := Compare;
  if (List.Count > 0) then
    List.Sort(ListViewCompare);
end;

procedure TListViewSort.Refresh;
begin
  if Assigned(FOnFilter) then FOnFilter(Self)
  else if Assigned(Source) then
    List.Assign(Source) else
    List.Clear;
  if ListView.Items.Count <> List.Count then
    ListView.Items.Count := List.Count;
  if Assigned(FOnCompareItem) and (Order <> soNone) then Sort(FOnCompareItem);
  //ListView.Items[-1]; // Workaround for not show first row if selected
  ListView.Refresh;
  // Workaround for not working item selection on first row
  //if not Assigned(ListView.Selected) then begin
  //  ListView.Items.Count := 0;
  //  ListView.Items.Count := List.Count;
  //end;
  //if ListView.Items.Count > 0 then
  //  ListView.Items[0].Selected := True;
  //ListView.Selected := nil;
  UpdateColumns;
end;

const
  //W_64: Integer = 64; {Width of thumbnail in ICON view mode}
  H_64: Integer = 64; {Height of thumbnail size}
  CheckWidth: Integer = 14; {Width of check mark box}
  CheckHeight: Integer = 14; {Height of checkmark}
  CheckBiasTop: Integer = 2; {This aligns the checkbox to be in centered}
  CheckBiasLeft: Integer = 3; {In the row of the list item display}

function TListViewSort.CompareBoolean(Value1, Value2: Boolean): Integer;
begin
  if Value1 > Value2 then Result := 1
  else if Value1 < Value2 then Result := -1
  else Result := 0;
end;

function TListViewSort.CompareInteger(Value1, Value2: Integer): Integer;
begin
  if Value1 > Value2 then Result := 1
  else if Value1 < Value2 then Result := -1
  else Result := 0;
end;

function TListViewSort.CompareString(Value1, Value2: string): Integer;
begin
  Result := AnsiCompareStr(Value1, Value2);
//  if Value1 > Value2 then Result := -1
//  else if Value1 < Value2 then Result := 1
//  else Result := 0;
end;

function TListViewSort.CompareTime(Time1, Time2: TDateTime): Integer;
begin
  Result := DateUtils.CompareDateTime(Time1, Time2);
end;

constructor TListViewSort.Create(AOwner: TComponent);
begin
  inherited;
  List := TFPGObjectList<TObject>.Create;
  List.FreeObjects := False;
end;

destructor TListViewSort.Destroy;
begin
  List.Free;
  inherited;
end;

procedure TListViewSort.DrawCheckMark(Item: TListItem; Checked:
  Boolean);
var
  TP1: TPoint;
  XBias, YBias: Integer;
  PenColor: TColor;
  BrushColor: TColor;
  BiasTop, BiasLeft: Integer;
  Rect1: TRect;
  lRect: TRect;
  ItemLeft: Integer;
begin
  XBias := 0;
  YBias := 0;
  BiasTop := 0;
  BiasLeft := 0;
  Item.Left := 0;
  GetCheckBias(XBias, YBias, BiasTop, BiasLeft, ListView);
  PenColor := ListView.Canvas.Pen.Color;
  BrushColor := ListView.Canvas.Brush.Color;
  //TP1 := Item.GetPosition;
  lRect := Item.DisplayRect(drBounds); // Windows 7 workaround
  TP1.X := lRect.Left;
  TP1.Y := lRect.Top;
  //ShowMessage(IntToStr(Item.Index) + ', ' + IntToStr(GetScrollPos(Item.ListView.Handle, SB_VERT)) + '  ' +
  //  IntToHex(Integer(Item), 8) + ', ' + IntToStr(TP1.X) + ', ' + IntToStr(TP1.Y));

//  if Checked then
    ListView.Canvas.Brush.Color := clWhite;
  ItemLeft := Item.Left;
  ItemLeft := 23; // Windows 7 workaround

  Rect1.Left := ItemLeft - CheckWidth - BiasLeft + 1 + XBias;
  //ShowMessage(IntToStr(Tp1.Y) + ', ' + IntToStr(BiasTop) + ', ' + IntToStr(XBias));
  Rect1.Top := Tp1.Y + BiasTop + 1 + YBias;
  Rect1.Right := ItemLeft - BiasLeft - 1 + XBias;
  Rect1.Bottom := Tp1.Y + BiasTop + CheckHeight - 1 + YBias;
  //ShowMessage(IntToStr(Rect1.Left) + ', ' + IntToStr(Rect1.Top) + ', ' + IntToStr(Rect1.Right) + ', ' + IntToStr(Rect1.Bottom));

  ListView.Canvas.FillRect(Rect1);
  //if Checked then ListView.Canvas.Brush.Color := clBlack
  ListView.Canvas.Brush.Color := clBlack;
  ListView.Canvas.FrameRect(Rect1);
  ListView.Canvas.FrameRect(Rect(Rect1.Left - 1, Rect1.Top - 1,
    Rect1.Right + 1, Rect1.Bottom + 1));
  if Checked then begin
    ListView.Canvas.Pen.Color := clBlack;
    ListView.Canvas.MoveTo(ItemLeft - BiasLeft - 2 + XBias - 2,
      Tp1.Y + BiasTop + 3 + YBias);
    ListView.Canvas.LineTo(ItemLeft - BiasLeft - (CheckWidth div 2) + XBias,
      Tp1.Y + BiasTop + (CheckHeight - 4) + YBias);
    ListView.Canvas.LineTo(ItemLeft - BiasLeft - (CheckWidth - 3) + XBias,
      Tp1.Y + BiasTop + (CheckHeight div 2) + YBias - 1);

    ListView.Canvas.MoveTo(ItemLeft - BiasLeft - 2 - 1 + XBias - 2,
      Tp1.Y + BiasTop + 3 + YBias);
    ListView.Canvas.LineTo(ItemLeft - BiasLeft - (CheckWidth div 2) - 1 + XBias,
      Tp1.Y + BiasTop + (CheckHeight - 4) + YBias);
    ListView.Canvas.LineTo(ItemLeft - BiasLeft - (CheckWidth - 3) - 1 + XBias,
      Tp1.Y + BiasTop + (CheckHeight div 2) + YBias - 1);
  end;
  //ListView.Canvas.Brush.Color := ListView.Color;
  ListView.Canvas.Brush.Color := BrushColor;
  ListView.Canvas.Pen.Color := PenColor;
end;

procedure TListViewSort.GetCheckBias(var XBias, YBias, BiasTop, BiasLeft: Integer;
  const ListView: TListView);
begin
  XBias := 0;
  YBias := 0;
  if ListView.ViewStyle = vsICON then
  begin
    YBias := H_64 - CheckHeight;
    XBias := 0;
  end;
  BiasTop := CheckBiasTop;
  BiasLeft := CheckBiasLeft;
  if ListView.ViewStyle <> vsReport then
  begin
    BiasTop := 0;
    BiasLeft := 0;
  end;
end;

procedure TListViewSort.ListViewCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if Assigned(Item) then begin
    if ListView.Checkboxes then
      DrawCheckMark(Item, Item.Checked);
    if Assigned(FOnCustomDraw) then
      FOnCustomDraw(Sender, Item, State, DefaultDraw);
  end;
end;

procedure TListViewSort.ListViewClick(Sender: TObject);
var
  Item: TListItem;
  Pos: TPoint;
  DefaultDraw: Boolean;
begin
  Pos := ListView.ScreenToClient(Mouse.CursorPos);
  Item := ListView.GetItemAt(Pos.X, Pos.Y);
  //ShowMessage(IntToStr(Item.Index) + ', ' + IntToStr(Pos.X) + ', ' + IntToStr(Pos.Y));
  if Assigned(Item) and (Pos.X < 20) then begin

    Item.Checked := not Item.Checked;
    //ShowMessage(IntToStr(Item.Index) + ', ' +BoolToStr(Item.Checked));
    if Assigned(ListView.OnChange) then
      ListView.OnChange(Self, Item, ctState);
    DefaultDraw := False;
    ListViewCustomDrawItem(ListView, Item, [], DefaultDraw);
      //ListView.UpdateItems(Item.Index, Item.Index);
  end;
end;

procedure TListViewSort.UpdateColumns;
{$IFDEF Windows}
const
  HDF_SORTUP = $0400;
  HDF_SORTDOWN = $0200;
  SortOrder: array[TSortOrder] of Word = (0, HDF_SORTUP, HDF_SORTDOWN);
var
  Item: THDItem;
  I: Integer;
begin
  if Assigned(FListView) then begin
    FHeaderHandle := ListView_GetHeader(FListView.Handle);
    for I := 0 to FListView.Columns.Count - 1 do begin
      {$push}{$warn 5057 off}
      FillChar(Item, SizeOf(THDItem), 0);
      {$pop}
      Item.Mask := HDI_FORMAT;
      Header_GetItem(FHeaderHandle, I, Item);
      Item.fmt := Item.fmt and not (HDF_SORTDOWN or HDF_SORTUP);
      if (Column <> -1) and (I = Column) then
        Item.fmt := Item.fmt or SortOrder[FOrder];
      Header_SetItem(FHeaderHandle, I, Item);
    end;
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

end.

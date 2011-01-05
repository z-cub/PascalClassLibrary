unit UCoolDockStyleTabs;

{$mode Delphi}{$H+}

interface

uses
  Classes, Controls, ExtCtrls, ComCtrls, SysUtils, Dialogs,
  Menus, UCoolDockStyle, Forms, UCoolDockClientPanel;

type

  { TCoolDockStyleTabs }

  TCoolDockStyleTabs = class(TCoolDockStyle)
    MouseDown: Boolean;
    MouseButton: TMouseButton;
    MouseDownSkip: Boolean;
    TabControl: TTabControl;
    TabImageList: TImageList;
    procedure TabControlMouseLeave(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure TabControlMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TabControlMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure InsertControl(NewPanel: TCoolDockClientPanel;
      AControl: TControl; InsertAt: TAlign); override;
    procedure UpdateClientSize; override;
  private
    FTabsPos: THeaderPos;
  public
    constructor Create(AManager: TObject);
    procedure SetVisible(const AValue: Boolean); override;
    destructor Destroy; override;
    procedure ChangeVisible(Control: TWinControl; Visible: Boolean); override;
    procedure Switch(Index: Integer); override;
    procedure SetTabsPos(const AValue: THeaderPos);
    procedure PopupMenuTabCloseClick(Sender: TObject);
    property TabsPos: THeaderPos read FTabsPos write SetTabsPos;
  end;

implementation

uses
  UCoolDocking;

{ TCoolDockStyleTabs }

procedure TCoolDockStyleTabs.PopupMenuTabCloseClick(Sender: TObject);
begin
  if TabControl.TabIndex <> -1 then
    TCoolDockClientPanel(TCoolDockManager(Manager).DockPanels[TabControl.TabIndex]).Control.Hide;
end;

procedure TCoolDockStyleTabs.TabControlMouseLeave(Sender: TObject);
begin
  if MouseDown then
  with TCoolDockManager(Manager) do
  if (TabControl.TabIndex <> -1) then begin
    TCoolDockClientPanel(DockPanels[TabControl.TabIndex]).ClientAreaPanel.DockSite := False;
    DragManager.DragStart(TCoolDockClientPanel(DockPanels[TabControl.TabIndex]).Control, False, 1);
  end;
  MouseDown := False;
end;

procedure TCoolDockStyleTabs.TabControlChange(Sender: TObject);
var
  I: Integer;
begin
  // Hide all clients
  with TCoolDockManager(Manager) do
  for I := 0 to DockPanels.Count - 1 do begin
    TCoolDockClientPanel(DockPanels[I]).Control.Hide;
    TCoolDockClientPanel(DockPanels[I]).ClientAreaPanel.Hide;
    TCoolDockClientPanel(DockPanels[I]).ClientAreaPanel.Parent := DockSite;
    TCoolDockClientPanel(DockPanels[I]).Control.Align := alClient;
    //ShowMessage(TCoolDockClientPanel(DockPanels[I]).Control.ClassName);
    Application.ProcessMessages;

    // Workaround for "Cannot focus" error
    TForm(TCoolDockClientPanel(DockPanels[I]).Control).ActiveControl := nil;
  end;

  // Show selected
  with TCoolDockManager(Manager) do
  if (TabControl.TabIndex <> -1) and (DockPanels.Count > TabControl.TabIndex) then begin
    with TCoolDockClientPanel(DockPanels[TabControl.TabIndex]), ClientAreaPanel do begin
      Control.Show;
      (*AutoHide.Enable := True;
      if AutoHide.Enable then begin
        //Parent := nil;
        Visible := True;
        if AutoHide.ControlVisible then begin
          AutoHide.Hide;
        end;
        AutoHide.Control := Control;
        AutoHide.Show;
      end else begin
      *)
        //Parent := DockSite;
        //Show;
        Visible := True;
        UpdateClientSize;
//      end;
    end;
  //TCoolDockClientPanel(FDockPanels[TabControl.TabIndex]).Visible := True;
  end;
  MouseDownSkip := True;
end;

procedure TCoolDockStyleTabs.TabControlMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not MouseDownSkip then begin
    MouseDown := True;
    MouseButton := Button;
  end;
  MouseDownSkip := False;
end;

procedure TCoolDockStyleTabs.TabControlMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  MouseDown := False;
end;

constructor TCoolDockStyleTabs.Create(AManager: TObject);
var
  NewMenuItem: TMenuItem;
  NewMenuItem2: TMenuItem;
  I: Integer;
begin
  inherited;

  TabImageList := TImageList.Create(TCoolDockManager(AManager).DockSite); //FDockSite);
  with TabImageList do begin
    Name := TCoolDockManager(Manager).DockSite.Name + '_' + 'ImageList';
  end;
  TabControl := TTabControl.Create(TCoolDockManager(AManager).DockSite); //FDockSite);
  with TabControl do begin
    Parent := TCoolDockManager(Manager).DockSite;
    Name := TCoolDockManager(Manager).DockSite.Name + '_' + 'TabControl';
    Visible := False;
    Align := alTop;
    Height := 24;
    OnChange := TabControlChange;
    PopupMenu := TCoolDockManager(Manager).PopupMenu;
    TTabControlNoteBookStrings(Tabs).NoteBook.OnMouseLeave := TabControlMouseLeave;
    TTabControlNoteBookStrings(Tabs).NoteBook.OnMouseDown := TabControlMouseDown;
    TTabControlNoteBookStrings(Tabs).NoteBook.OnMouseUp := TabControlMouseUp;
    OnMouseUp := TabControlMouseUp;
    Images := TabImageList;
  end;
  //TabsPos := hpTop;
  //MoveDuration := 1000; // ms

  TabControl.Visible := True;
  TabControl.Tabs.Clear;
  TabImageList.Clear;
  with TCoolDockManager(Manager) do
  for I := 0 to DockPanels.Count - 1 do begin
    TabControl.Tabs.Add(TCoolDockClientPanel(DockPanels[I]).Control.Caption);
    TabImageList.Add(TCoolDockClientPanel(DockPanels[I]).Header.Icon.Picture.Bitmap, nil);
    if Assigned(TCoolDockClientPanel(DockPanels[I]).Splitter) then
      TCoolDockClientPanel(DockPanels[I]).Splitter.Visible := False;
    TCoolDockClientPanel(DockPanels[I]).ClientAreaPanel.Visible := False;
    TCoolDockClientPanel(DockPanels[I]).Visible := False;
  end;
end;

destructor TCoolDockStyleTabs.Destroy;
begin
  TabControl.Free;
  TabImageList.Free;
  inherited Destroy;
end;

procedure TCoolDockStyleTabs.Switch(Index: Integer);
begin
  inherited Switch(Index);
  TabControl.TabIndex := Index;
end;

procedure TCoolDockStyleTabs.InsertControl(NewPanel: TCoolDockClientPanel;
  AControl: TControl; InsertAt: TAlign);
begin
  inherited;
  TabControl.Tabs.Add(AControl.Caption);
  TabImageList.Add(NewPanel.Header.Icon.Picture.Bitmap, nil);
  if Assigned(NewPanel.Splitter) then
    NewPanel.Splitter.Visible := False;
  NewPanel.ClientAreaPanel.Visible := False;
  NewPanel.Visible := False;
  TabControlChange(Self);
end;

procedure TCoolDockStyleTabs.UpdateClientSize;
var
  I: Integer;
begin
  inherited UpdateClientSize;
  with TCoolDockManager(Manager) do
  for I := 0 to DockPanels.Count - 1 do begin
    TCoolDockClientPanel(DockPanels[I]).ClientAreaPanel.Width := DockSite.Width;
    TCoolDockClientPanel(DockPanels[I]).ClientAreaPanel.Height := DockSite.Height - TabControl.Height;
    //TCoolDockClientPanel(FDockPanels[I]).DockPanelPaint(Self);
  end;
end;

procedure TCoolDockStyleTabs.SetVisible(const AValue: Boolean);
begin
  inherited SetVisible(AValue);
  with TCoolDockManager(Manager) do
    if (TabControl.TabIndex >= 0) and (TabControl.TabIndex < DockPanels.Count) then
      with TCoolDockClientPanel(DockPanels[TabControl.TabIndex]) do begin
        //Show;
        if AValue then Control.Show;
        //TabControl.Show;
        //ClientAreaPanel.Show;
      end;
end;

procedure TCoolDockStyleTabs.ChangeVisible(Control: TWinControl; Visible: Boolean);
var
  I: Integer;
begin
  inherited;
  if not Visible then
  if Assigned(TWinControl(Control).DockManager) then
  with TCoolDockManager(TWinControl(Control).DockManager) do begin
//    ShowMessage(IntToStr(TabControl.TabIndex) + ' ' + IntToStr(DockPanels.Count));
//    TabControl.Tabs[0].;
//    if (TabControl.TabIndex >= 0) and (TabControl.TabIndex < DockPanels.Count) then begin
//      TCoolDockClientPanel(DockPanels[TabControl.TabIndex]).Show;
//      TCoolDockClientPanel(DockPanels[TabControl.TabIndex]).Control.Show;
//    end;
    //    ShowMessage(IntToStr(DockPanels.Count));
  end;
end;

procedure TCoolDockStyleTabs.SetTabsPos(const AValue: THeaderPos);
begin
  (*if FTabsPos = AValue then Exit;
  FTabsPos := AValue;
  with TabControl do
  case AValue of
    hpAuto, hpTop: begin
      Align := alTop;
      TabPosition := tpTop;
      Height := GrabberSize;
    end;
    hpLeft: begin
      Align := alLeft;
      TabPosition := tpLeft;
      Width := GrabberSize;
    end;
    hpRight: begin
      Align := alRight;
      TabPosition := tpRight;
      Width := GrabberSize;
    end;
    hpBottom: begin
      Align := alBottom;
      TabPosition := tpBottom;
      Height := GrabberSize;
    end;
  end;       *)
end;


end.


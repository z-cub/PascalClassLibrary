unit UCDPopupMenu;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Menus, Forms, Controls, Dialogs,
  ExtCtrls, ComCtrls, UCDCommon;

type

  { TCDPopupMenu }

  TCDPopupMenu = class(TPopupMenu)
  private
    procedure PopupExecute(Sender: TObject);
  public
    Manager: TCDManagerBase;
    PositionMenu: TMenuItem;
    StyleMenu: TMenuItem;
    LockedMenu: TMenuItem;
    constructor Create(AManager: TCDManagerBase);
    procedure UncheckMenuGroup(Item: TMenuItem);
    procedure PopupMenuListClick(Sender: TObject);
    procedure PopupMenuTabsClick(Sender: TObject);
    procedure PopupMenuPopupListClick(Sender: TObject);
    procedure PopupMenuPopupTabsClick(Sender: TObject);
    procedure PopupMenuCloseClick(Sender: TObject);
    procedure PopupMenuRenameClick(Sender: TObject);
    procedure PopupMenuPositionAutoClick(Sender: TObject);
    procedure PopupMenuPositionLeftClick(Sender: TObject);
    procedure PopupMenuPositionRightClick(Sender: TObject);
    procedure PopupMenuPositionTopClick(Sender: TObject);
    procedure PopupMenuPositionBottomClick(Sender: TObject);
    procedure PopupMenuUndockClick(Sender: TObject);
    procedure PopupMenuCustomizeClick(Sender: TObject);
    procedure PopupMenuLockedClick(Sender: TObject);
  end;

implementation

uses
  UCDClient, UCDManagerTabs, UCDCustomize, UCDManager;

resourcestring
  SDockStyle = 'Style';
  SDockList = 'List';
  SDockTabs = 'Tabs';
  SDockPopupList = 'Popup list';
  SDockPopupTabs = 'Popup tabs';
  SCloseForm = 'Close';
  SRenameForm = 'Rename';
  SPosition = 'Position';
  SPositionAuto = 'Auto';
  SPositionTop = 'Top';
  SPositionLeft = 'Left';
  SPositionRight = 'Right';
  SPositionBottom = 'Bottom';
  SUndock = 'Undock';
  SCustomize = 'Customize...';
  SEnterNewWindowName = 'Enter new window name';
  SRenameWindow = 'Rename window';
  SLocked = 'Locked';


{ TCDPopupMenu }

procedure TCDPopupMenu.UncheckMenuGroup(Item: TMenuItem);
var
  I: Integer;
begin
  for I := 0 to Item.Count - 1 do
    Item.Items[I].Checked := False;
end;

procedure TCDPopupMenu.PopupExecute(Sender: TObject);
begin
  UncheckMenuGroup(StyleMenu);
  StyleMenu.Items[Integer(TCDManager(Manager).DockStyle)].Checked := True;
  UncheckMenuGroup(PositionMenu);
  PositionMenu.Items[Integer(TCDManager(Manager).HeaderPos)].Checked := True;;
  LockedMenu.Checked := TCDManager(Manager).Locked;
end;

constructor TCDPopupMenu.Create(AManager: TCDManagerBase);
var
  NewMenuItem: TMenuItem;
  NewMenuItem2: TMenuItem;
  I: Integer;
begin
  inherited Create(nil);
  Manager := AManager;

  Name := GetUniqueName(TCDManager(AManager).DockSite.Name + 'PopupMenu');
  OnPopup := PopupExecute;

  StyleMenu := TMenuItem.Create(Self);
  StyleMenu.Caption := SDockStyle;
  Items.Add(StyleMenu);

  NewMenuItem2 := TMenuItem.Create(StyleMenu);
  NewMenuItem2.Caption := SDockList;
  NewMenuItem2.OnClick := PopupMenuListClick;
  StyleMenu.Add(NewMenuItem2);

  NewMenuItem2 := TMenuItem.Create(StyleMenu);
  NewMenuItem2.Caption := SDockTabs;
  NewMenuItem2.OnClick := PopupMenuTabsClick;
  StyleMenu.Add(NewMenuItem2);

  NewMenuItem2 := TMenuItem.Create(StyleMenu);
  NewMenuItem2.Caption := SDockPopupTabs;
  NewMenuItem2.OnClick := PopupMenuPopupTabsClick;
  StyleMenu.Add(NewMenuItem2);

  NewMenuItem2 := TMenuItem.Create(StyleMenu);
  NewMenuItem2.Caption := SDockPopupList;
  NewMenuItem2.OnClick := PopupMenuPopupListClick;
  StyleMenu.Add(NewMenuItem2);

  PositionMenu := TMenuItem.Create(Self);
  PositionMenu.Caption := SPosition;
  Items.Add(PositionMenu);

  NewMenuItem2 := TMenuItem.Create(PositionMenu);
  NewMenuItem2.Caption := SPositionAuto;
  NewMenuItem2.OnClick := PopupMenuPositionAutoClick;
  PositionMenu.Add(NewMenuItem2);

  NewMenuItem2 := TMenuItem.Create(PositionMenu);
  NewMenuItem2.Caption := SPositionLeft;
  NewMenuItem2.OnClick := PopupMenuPositionLeftClick;
  PositionMenu.Add(NewMenuItem2);

  NewMenuItem2 := TMenuItem.Create(PositionMenu);
  NewMenuItem2.Caption := SPositionTop;
  NewMenuItem2.OnClick := PopupMenuPositionTopClick;
  PositionMenu.Add(NewMenuItem2);

  NewMenuItem2 := TMenuItem.Create(PositionMenu);
  NewMenuItem2.Caption := SPositionRight;
  NewMenuItem2.OnClick := PopupMenuPositionRightClick;
  PositionMenu.Add(NewMenuItem2);

  NewMenuItem2 := TMenuItem.Create(PositionMenu);
  NewMenuItem2.Caption := SPositionBottom;
  NewMenuItem2.OnClick := PopupMenuPositionBottomClick;
  PositionMenu.Add(NewMenuItem2);

  NewMenuItem := TMenuItem.Create(Self);
  NewMenuItem.Caption := SCloseForm;
  NewMenuItem.OnClick := PopupMenuCloseClick;
  Items.Add(NewMenuItem);

  NewMenuItem := TMenuItem.Create(Self);
  NewMenuItem.Caption := SRenameForm;
  NewMenuItem.OnClick := PopupMenuRenameClick;
  Items.Add(NewMenuItem);

  NewMenuItem := TMenuItem.Create(Self);
  NewMenuItem.Caption := SUndock;
  NewMenuItem.OnClick := PopupMenuUndockClick;
  Items.Add(NewMenuItem);

  NewMenuItem := TMenuItem.Create(Self);
  NewMenuItem.Caption := SCustomize;
  NewMenuItem.OnClick := PopupMenuCustomizeClick;
  Items.Add(NewMenuItem);

  LockedMenu := TMenuItem.Create(Self);
  LockedMenu.Caption := SLocked;
  LockedMenu.OnClick := PopupMenuLockedClick;
  Items.Add(LockedMenu);
end;

procedure TCDPopupMenu.PopupMenuTabsClick(Sender: TObject);
begin
  TCDManager(Manager).DockStyle := dsTabs;
end;

procedure TCDPopupMenu.PopupMenuPopupListClick(Sender: TObject);
begin
  TCDManager(Manager).DockStyle := dsPopupList;
end;

procedure TCDPopupMenu.PopupMenuPopupTabsClick(Sender: TObject);
begin
  TCDManager(Manager).DockStyle := dsPopupTabs;
end;

procedure TCDPopupMenu.PopupMenuCloseClick(Sender: TObject);
var
  Control: TControl;
begin
  if PopupComponent is TPageControl then
  with TPageControl(PopupComponent) do begin
    TForm(TCDManagerTabsItem(TCDManagerTabs(Manager).DockItems[TabIndex]).Control).Close;
  end;
  if PopupComponent is TCDHeader then
  with TCDHeader(PopupComponent) do begin
    TForm(ManagerItem.Control).Close;
  end;
end;

procedure TCDPopupMenu.PopupMenuRenameClick(Sender: TObject);
var
  Value: string;
begin
  //ShowMessage(PopupComponent.ClassName);
  if PopupComponent is TPageControl then
  with TPageControl(PopupComponent) do begin
    Value := TCDManagerTabsItem(TCDManagerTabs(Manager).DockItems[TabIndex]).Control.Caption;
    if InputQuery(SRenameWindow, SEnterNewWindowName, False, Value) then begin
      TCDManagerTabsItem(TCDManagerTabs(Manager).DockItems[TabIndex]).Control.Caption := Value;
      Pages[TabIndex].Caption := Value;
    end;
  end;
  if PopupComponent is TCDHeader then
  with TCDHeader(PopupComponent) do begin
    Value := ManagerItem.Control.Caption;
    if InputQuery(SRenameWindow, SEnterNewWindowName, False, Value) then begin
      ManagerItem.Control.Caption := Value;
      Title.Caption := Value;
    end;
  end;
end;

procedure TCDPopupMenu.PopupMenuPositionAutoClick(Sender: TObject);
begin
  if PopupComponent is TPageControl then
  with TPageControl(PopupComponent) do begin
    TCDManagerTabs(Manager).HeaderPos := hpAuto;
  end else
  if PopupComponent is TCDHeader then
  with TCDHeader(PopupComponent) do begin
    TCDManager(Manager).HeaderPos := hpAuto;
  end;
end;

procedure TCDPopupMenu.PopupMenuPositionLeftClick(Sender: TObject);
begin
  if PopupComponent is TPageControl then
  with TPageControl(PopupComponent) do begin
    TCDManagerTabs(Manager).HeaderPos := hpLeft;
  end else
  if PopupComponent is TCDHeader then
  with TCDHeader(PopupComponent) do begin
    TCDManager(Manager).HeaderPos := hpLeft;
  end;
end;

procedure TCDPopupMenu.PopupMenuPositionRightClick(Sender: TObject);
begin
  if PopupComponent is TPageControl then
  with TPageControl(PopupComponent) do begin
    TCDManagerTabs(Manager).HeaderPos := hpRight;
  end else
  if PopupComponent is TCDHeader then
  with TCDHeader(PopupComponent) do begin
    TCDManager(Manager).HeaderPos := hpRight;
  end;
end;

procedure TCDPopupMenu.PopupMenuPositionTopClick(Sender: TObject);
begin
  if PopupComponent is TPageControl then
  with TPageControl(PopupComponent) do begin
    TCDManagerTabs(Manager).HeaderPos := hpTop;
  end else
  if PopupComponent is TCDHeader then
  with TCDHeader(PopupComponent) do begin
    TCDManager(Manager).HeaderPos := hpTop;
  end;
end;

procedure TCDPopupMenu.PopupMenuPositionBottomClick(Sender: TObject);
begin
  if PopupComponent is TPageControl then
  with TPageControl(PopupComponent) do begin
    TCDManagerTabs(Manager).HeaderPos := hpBottom;
  end else
  if PopupComponent is TCDHeader then
  with TCDHeader(PopupComponent) do begin
    TCDManager(Manager).HeaderPos := hpBottom;
  end;
end;

procedure TCDPopupMenu.PopupMenuUndockClick(Sender: TObject);
var
  Control: TControl;
begin
  if PopupComponent is TPageControl then
  with TPageControl(PopupComponent) do begin
    Control := TCDManagerTabsItem(TCDManagerTabs(Manager).DockItems[TabIndex]).Control;
  end else
  if PopupComponent is TCDHeader then
  with TCDHeader(PopupComponent) do begin
    Control := ManagerItem.Control;
  end else Control := nil;
  if Assigned(Control) then
    Control.ManualFloat(Control.BoundsRect);
end;

procedure TCDPopupMenu.PopupMenuCustomizeClick(Sender: TObject);
begin
  with TCDManager(Manager) do
  if Assigned(Master) and
    Assigned(Master.Customize) then
    TCDCustomize(Master.Customize).Execute;
end;

procedure TCDPopupMenu.PopupMenuLockedClick(Sender: TObject);
begin
  if PopupComponent is TPageControl then
  with TPageControl(PopupComponent) do begin
    TCDManagerTabs(Manager).Locked := not TCDManagerTabs(Manager).Locked;
  end else
  if PopupComponent is TCDHeader then
  with TCDHeader(PopupComponent) do begin
    TCDManagerTabs(Manager).Locked := not TCDManagerTabs(Manager).Locked;
  end;
end;

procedure TCDPopupMenu.PopupMenuListClick(Sender: TObject);
begin
  TCDManager(Manager).DockStyle := dsList;
end;


end.


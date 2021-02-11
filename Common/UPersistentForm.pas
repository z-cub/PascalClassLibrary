unit UPersistentForm;

{$mode delphi}

// Date: 2020-11-26

interface

uses
  Classes, SysUtils, Forms, URegistry, LCLIntf, Registry, Controls, ComCtrls,
  ExtCtrls, LCLType;

type

  { TPersistentForm }

  TPersistentForm = class(TComponent)
  private
    FEntireVisible: Boolean;
    FMinVisiblePart: Integer;
    FRegistryContext: TRegistryContext;
    procedure LoadControl(Control: TControl);
    procedure SaveControl(Control: TControl);
  public
    FormNormalSize: TRect;
    FormRestoredSize: TRect;
    FormWindowState: TWindowState;
    FormFullScreen: Boolean;
    Form: TForm;
    procedure LoadFromRegistry(RegistryContext: TRegistryContext);
    procedure SaveToRegistry(RegistryContext: TRegistryContext);
    function CheckEntireVisible(Rect: TRect): TRect;
    function CheckPartVisible(Rect: TRect; Part: Integer): TRect;
    procedure Load(Form: TForm; DefaultMaximized: Boolean = False;
      DefaultFullScreen: Boolean = False);
    procedure Save(Form: TForm);
    constructor Create(AOwner: TComponent); override;
    procedure SetFullScreen(State: Boolean);
    property RegistryContext: TRegistryContext read FRegistryContext
      write FRegistryContext;
  published
    property MinVisiblePart: Integer read FMinVisiblePart write FMinVisiblePart;
    property EntireVisible: Boolean read FEntireVisible write FEntireVisible;
  end;

procedure Register;


implementation

procedure Register;
begin
  RegisterComponents('Common', [TPersistentForm]);
end;

{ TPersistentForm }

procedure TPersistentForm.LoadControl(Control: TControl);
var
  I: Integer;
  WinControl: TWinControl;
begin
  if Control is TListView then begin
    with Form, TRegistryEx.Create do
    try
      RootKey := RegistryContext.RootKey;
      OpenKey(RegistryContext.Key + '\Forms\' + Form.Name + '\' + Control.Name, True);
      for I := 0 to TListView(Control).Columns.Count - 1 do begin
        if ValueExists('ColWidth' + IntToStr(I)) then
          TListView(Control).Columns[I].Width := ReadInteger('ColWidth' + IntToStr(I));
      end;
    finally
      Free;
    end;
  end;

  if (Control is TPanel) then begin
    with Form, TRegistryEx.Create do
    try
      RootKey := RegistryContext.RootKey;
      OpenKey(RegistryContext.Key + '\Forms\' + Form.Name + '\' + Control.Name, True);
      if (TPanel(Control).Align = alRight) or (TPanel(Control).Align = alLeft) then begin
        if ValueExists('Width') then
          TPanel(Control).Width := ReadInteger('Width');
      end;
      if (TPanel(Control).Align = alTop) or (TPanel(Control).Align = alBottom) then begin
        if ValueExists('Height') then
          TPanel(Control).Height := ReadInteger('Height');
      end;
    finally
      Free;
    end;
  end;

  if Control is TWinControl then begin
    WinControl := TWinControl(Control);
    if WinControl.ControlCount > 0 then begin
      for I := 0 to WinControl.ControlCount - 1 do begin
        if WinControl.Controls[I] is TControl then begin
          LoadControl(WinControl.Controls[I]);
        end;
      end;
    end;
  end;
end;

procedure TPersistentForm.SaveControl(Control: TControl);
var
  I: Integer;
  WinControl: TWinControl;
begin
  if Control is TListView then begin
    with Form, TRegistryEx.Create do
    try
      RootKey := RegistryContext.RootKey;
      OpenKey(RegistryContext.Key + '\Forms\' + Form.Name + '\' + Control.Name, True);
      for I := 0 to TListView(Control).Columns.Count - 1 do begin
        WriteInteger('ColWidth' + IntToStr(I), TListView(Control).Columns[I].Width);
      end;
    finally
      Free;
    end;
  end;

  if (Control is TPanel) then begin
    with Form, TRegistryEx.Create do
    try
      RootKey := RegistryContext.RootKey;
      OpenKey(RegistryContext.Key + '\Forms\' + Form.Name + '\' + Control.Name, True);
      if (TPanel(Control).Align = alRight) or (TPanel(Control).Align = alLeft) then begin
        WriteInteger('Width', TPanel(Control).Width);
      end;
      if (TPanel(Control).Align = alTop) or (TPanel(Control).Align = alBottom) then begin
        WriteInteger('Height', TPanel(Control).Height);
      end;
    finally
      Free;
    end;
  end;

  if Control is TWinControl then begin
      WinControl := TWinControl(Control);
      if WinControl.ControlCount > 0 then begin
        for I := 0 to WinControl.ControlCount - 1 do begin
          if WinControl.Controls[I] is TControl then begin
            SaveControl(WinControl.Controls[I]);
          end;
        end;
      end;
    end;
end;

procedure TPersistentForm.LoadFromRegistry(RegistryContext: TRegistryContext);
begin
  with TRegistryEx.Create do
  try
    RootKey := RegistryContext.RootKey;
    OpenKey(RegistryContext.Key + '\Forms\' + Form.Name, True);
    // Normal size
    FormNormalSize.Left := ReadIntegerWithDefault('NormalLeft', FormNormalSize.Left);
    FormNormalSize.Top := ReadIntegerWithDefault('NormalTop', FormNormalSize.Top);
    FormNormalSize.Right := ReadIntegerWithDefault('NormalWidth', FormNormalSize.Right - FormNormalSize.Left)
      + FormNormalSize.Left;
    FormNormalSize.Bottom := ReadIntegerWithDefault('NormalHeight', FormNormalSize.Bottom - FormNormalSize.Top)
      + FormNormalSize.Top;
    // Restored size
    FormRestoredSize.Left := ReadIntegerWithDefault('RestoredLeft', FormRestoredSize.Left);
    FormRestoredSize.Top := ReadIntegerWithDefault('RestoredTop', FormRestoredSize.Top);
    FormRestoredSize.Right := ReadIntegerWithDefault('RestoredWidth', FormRestoredSize.Right - FormRestoredSize.Left)
      + FormRestoredSize.Left;
    FormRestoredSize.Bottom := ReadIntegerWithDefault('RestoredHeight', FormRestoredSize.Bottom - FormRestoredSize.Top)
      + FormRestoredSize.Top;
    // Other state
    FormWindowState := TWindowState(ReadIntegerWithDefault('WindowState', Integer(FormWindowState)));
    FormFullScreen := ReadBoolWithDefault('FullScreen', FormFullScreen);
  finally
    Free;
  end;
end;

procedure TPersistentForm.SaveToRegistry(RegistryContext: TRegistryContext);
begin
  with Form, TRegistryEx.Create do
  try
    RootKey := RegistryContext.RootKey;
    OpenKey(RegistryContext.Key + '\Forms\' + Form.Name, True);
    // Normal state
    WriteInteger('NormalWidth', FormNormalSize.Right - FormNormalSize.Left);
    WriteInteger('NormalHeight', FormNormalSize.Bottom - FormNormalSize.Top);
    WriteInteger('NormalTop', FormNormalSize.Top);
    WriteInteger('NormalLeft', FormNormalSize.Left);
    // Restored state
    WriteInteger('RestoredWidth', FormRestoredSize.Right - FormRestoredSize.Left);
    WriteInteger('RestoredHeight', FormRestoredSize.Bottom - FormRestoredSize.Top);
    WriteInteger('RestoredTop', FormRestoredSize.Top);
    WriteInteger('RestoredLeft', FormRestoredSize.Left);
    // Other state
    WriteInteger('WindowState', Integer(FormWindowState));
    WriteBool('FullScreen', FormFullScreen);
  finally
    Free;
  end;
end;

function TPersistentForm.CheckEntireVisible(Rect: TRect): TRect;
var
  Width: Integer;
  Height: Integer;
begin
  Result := Rect;
  Width := Rect.Right - Rect.Left;
  Height := Rect.Bottom - Rect.Top;
  if Result.Left < (Screen.DesktopLeft) then begin
    Result.Left := Screen.DesktopLeft;
    Result.Right := Screen.DesktopLeft + Width;
  end;
  if Result.Right > (Screen.DesktopLeft + Screen.DesktopWidth) then begin
    Result.Left := Screen.DesktopLeft + Screen.DesktopWidth - Width;
    Result.Right := Screen.DesktopLeft + Screen.DesktopWidth;
  end;
  if Result.Top < Screen.DesktopTop then begin
    Result.Top := Screen.DesktopTop;
    Result.Bottom := Screen.DesktopTop + Height;
  end;
  if Result.Bottom > (Screen.DesktopTop + Screen.DesktopHeight) then begin
    Result.Top := Screen.DesktopTop + Screen.DesktopHeight - Height;
    Result.Bottom := Screen.DesktopTop + Screen.DesktopHeight;
  end;
end;

function TPersistentForm.CheckPartVisible(Rect: TRect; Part: Integer): TRect;
var
  Width: Integer;
  Height: Integer;
begin
  Result := Rect;
  Width := Rect.Right - Rect.Left;
  Height := Rect.Bottom - Rect.Top;
  if Result.Right < (Screen.DesktopLeft + Part) then begin
    Result.Left := Screen.DesktopLeft + Part - Width;
    Result.Right := Screen.DesktopLeft + Part;
  end;
  if Result.Left > (Screen.DesktopLeft + Screen.DesktopWidth - Part) then begin
    Result.Left := Screen.DesktopLeft + Screen.DesktopWidth - Part;
    Result.Right := Screen.DesktopLeft + Screen.DesktopWidth - Part + Width;
  end;
  if Result.Bottom < (Screen.DesktopTop + Part) then begin
    Result.Top := Screen.DesktopTop + Part - Height;
    Result.Bottom := Screen.DesktopTop + Part;
  end;
  if Result.Top > (Screen.DesktopTop + Screen.DesktopHeight - Part) then begin
    Result.Top := Screen.DesktopTop + Screen.DesktopHeight - Part;
    Result.Bottom := Screen.DesktopTop + Screen.DesktopHeight - Part + Height;
  end;
end;

procedure TPersistentForm.Load(Form: TForm; DefaultMaximized: Boolean = False;
  DefaultFullScreen: Boolean = False);
begin
  Self.Form := Form;
  // Set default
  FormNormalSize := Bounds((Screen.Width - Form.Width) div 2,
    (Screen.Height - Form.Height) div 2, Form.Width, Form.Height);
  FormRestoredSize := Bounds((Screen.Width - Form.Width) div 2,
    (Screen.Height - Form.Height) div 2, Form.Width, Form.Height);
  FormWindowState := Form.WindowState;
  FormFullScreen := DefaultFullScreen;

  LoadFromRegistry(RegistryContext);

  if not EqualRect(FormNormalSize, FormRestoredSize) or
    DefaultMaximized then begin
    // Restore to maximized state
    Form.WindowState := wsNormal;
    if not EqualRect(FormRestoredSize, Form.BoundsRect) then
      Form.BoundsRect := FormRestoredSize;
    Form.WindowState := wsMaximized;
  end else begin
    // Restore to normal state
    Form.WindowState := wsNormal;
    if FEntireVisible then FormNormalSize := CheckEntireVisible(FormNormalSize)
      else if FMinVisiblePart > 0 then
    FormNormalSize := CheckPartVisible(FormNormalSize, FMinVisiblePart);
    if not EqualRect(FormNormalSize, Form.BoundsRect) then
      Form.BoundsRect := FormNormalSize;
  end;
  if FormFullScreen then SetFullScreen(True);
  LoadControl(Form);
end;

procedure TPersistentForm.Save(Form: TForm);
begin
  Self.Form := Form;
  FormNormalSize := Bounds(Form.Left, Form.Top, Form.Width, Form.Height);
  if not FormFullScreen then
    FormRestoredSize := Bounds(Form.RestoredLeft, Form.RestoredTop, Form.RestoredWidth,
      Form.RestoredHeight);
  FormWindowState := Form.WindowState;
  SaveToRegistry(RegistryContext);
  SaveControl(Form);
end;

constructor TPersistentForm.Create(AOwner: TComponent);
begin
  inherited;
  if AOwner is TForm then Form := TForm(AOwner)
    else Form := nil;
  FMinVisiblePart := 50;
  FRegistryContext.RootKey := HKEY_CURRENT_USER;
end;

procedure TPersistentForm.SetFullScreen(State: Boolean);
begin
  if State then begin
    FormFullScreen := True;
    FormNormalSize := Form.BoundsRect;
    FormRestoredSize := Bounds(Form.RestoredLeft, Form.RestoredTop, Form.RestoredWidth,
      Form.RestoredHeight);
    FormWindowState := Form.WindowState;
    ShowWindow(Form.Handle, SW_SHOWFULLSCREEN);
    {$IFDEF WINDOWS}
    Form.BorderStyle := bsNone;
    {$ENDIF}
  end else begin
    FormFullScreen := False;
    {$IFDEF WINDOWS}
    Form.BorderStyle := bsSizeable;
    {$ENDIF}
    ShowWindow(Form.Handle, SW_SHOWNORMAL);
    if FormWindowState = wsNormal then begin
      Form.BoundsRect := FormNormalSize;
    end else
    if FormWindowState = wsMaximized then begin
      Form.BoundsRect := FormRestoredSize;
      Form.WindowState := wsMaximized;
    end;
  end;
end;

end.


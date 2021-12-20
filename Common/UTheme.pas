unit UTheme;

interface

uses
  Classes, SysUtils, Graphics, ComCtrls, Controls, ExtCtrls, Menus, StdCtrls,
  Spin, Forms, fgl, Grids;

type
  TTheme = class
    Name: string;
    ColorWindow: TColor;
    ColorWindowText: TColor;
    ColorControl: TColor;
    ColorControlText: TColor;
    ColorControlSelected: TColor;
  end;

  { TThemes }

  TThemes = class(TFPGObjectList<TTheme>)
    function AddNew(Name: string): TTheme;
    function FindByName(Name: string): TTheme;
    procedure LoadToStrings(Strings: TStrings);
  end;

  { TThemeManager }

  TThemeManager = class(TComponent)
  private
    FTheme: TTheme;
    procedure SetTheme(AValue: TTheme);
    procedure SetThemeName(AValue: TTheme);
  public
    Used: Boolean;
    Themes: TThemes;
    procedure ApplyTheme(Component: TComponent);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure UseTheme(Form: TForm);
    property Theme: TTheme read FTheme write SetTheme;
  end;

procedure Register;

implementation

{ TThemes }

procedure Register;
begin
  RegisterComponents('Common', [TThemeManager]);
end;

function TThemes.AddNew(Name: string): TTheme;
begin
  Result := TTheme.Create;
  Result.Name := Name;
  Add(Result);
end;

function TThemes.FindByName(Name: string): TTheme;
var
  Theme: TTheme;
begin
  Result := nil;
  for Theme in Self do
    if Theme.Name = Name then begin
      Result := Theme;
      Exit;
    end;
end;

procedure TThemes.LoadToStrings(Strings: TStrings);
var
  I: Integer;
begin
  Strings.BeginUpdate;
  try
    while Strings.Count < Count do Strings.Add('');
    while Strings.Count > Count do Strings.Delete(Strings.Count - 1);
    for I := 0 to Count - 1 do begin
      Strings[I] := Items[I].Name;
      Strings.Objects[I] := Items[I];
    end;
  finally
    Strings.EndUpdate;
  end;
end;

procedure TThemeManager.SetThemeName(AValue: TTheme);
begin
  if FTheme = AValue then Exit;
  FTheme := AValue;
end;

procedure TThemeManager.SetTheme(AValue: TTheme);
begin
  if FTheme = AValue then Exit;
  FTheme := AValue;
end;

constructor TThemeManager.Create(AOwner: TComponent);
begin
  inherited;
  Themes := TThemes.Create;
  with Themes.AddNew('System') do begin
    ColorWindow := clWindow;
    ColorWindowText := clWindowText;
    ColorControl := clMenu;
    ColorControlText := clWindowText;
    ColorControlSelected := clWindow;
  end;
  Theme := TTheme(Themes.First);
  with Themes.AddNew('Dark') do begin
    ColorWindow := RGBToColor($20, $20, $20);
    ColorWindowText := clWhite;
    ColorControl := RGBToColor($40, $40, $40);
    ColorControlText := clWhite;
    ColorControlSelected := RGBToColor(96, 125, 155);
  end;
  with Themes.AddNew('Light') do begin
    ColorWindow := clWhite;
    ColorWindowText := clBlack;
    ColorControl := RGBToColor($e0, $e0, $e0);
    ColorControlText := clBlack;
    ColorControlSelected := RGBToColor(196, 225, 255);
  end;
end;

destructor TThemeManager.Destroy;
begin
  FreeAndNil(Themes);
  inherited;
end;

procedure TThemeManager.ApplyTheme(Component: TComponent);
var
  Control: TControl;
  I: Integer;
begin
  if Component is TWinControl then begin
    for I := 0 to TWinControl(Component).ControlCount - 1 do
      ApplyTheme(TWinControl(Component).Controls[I]);
  end;

  if Component is TControl then begin
    Control := (Component as TControl);
    if (Control is TEdit) or (Control is TSpinEdit) or (Control is TComboBox) and
    (Control is TMemo) or (Control is TListView) or (Control is TCustomDrawGrid) or
    (Control is TCheckBox) or (Control is TPageControl) or (Control is TRadioButton) then begin
      Control.Color := FTheme.ColorWindow;
      Control.Font.Color := FTheme.ColorWindowText;
    end else begin
      Control.Color := FTheme.ColorControl;
      Control.Font.Color := FTheme.ColorControlText;
    end;

    if Control is TCustomDrawGrid then begin
      (Control as TCustomDrawGrid).Editor.Color := FTheme.ColorWindow;
      (Control as TCustomDrawGrid).Editor.Font.Color := FTheme.ColorWindowText;
    end;

    if Control is TPageControl then begin
      for I := 0 to TPageControl(Component).PageCount - 1 do
        ApplyTheme(TPageControl(Component).Pages[I]);
    end;

    if Control is TCoolBar then begin
      (Control as TCoolBar).Themed := False;
    end;
  end;
end;

procedure TThemeManager.UseTheme(Form: TForm);
begin
  if not Used and (FTheme.Name = 'System') then Exit;
  ApplyTheme(Form);
  Used := True;
end;


end.

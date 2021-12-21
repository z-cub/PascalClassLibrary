unit UAboutDialog;

{$mode delphi}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  StdCtrls, ExtCtrls, UApplicationInfo, UCommon, UTranslator, UTheme, UFormAbout;

type

  { TAboutDialog }

  TAboutDialog = class(TComponent)
  private
    FApplicationInfo: TApplicationInfo;
    FTranslator: TTranslator;
    FThemeManager: TThemeManager;
  public
    FormAbout: TFormAbout;
    procedure Show;
  published
    property Translator: TTranslator read FTranslator write FTranslator;
    property ThemeManager: TThemeManager read FThemeManager write FThemeManager;
    property ApplicationInfo: TApplicationInfo read FApplicationInfo write
      FApplicationInfo;
  end;

procedure Register;


implementation

procedure Register;
begin
  RegisterComponents('Common', [TAboutDialog]);
end;

{ TAboutDialog }

procedure TAboutDialog.Show;
begin
  FormAbout := TFormAbout.Create(nil);
  try
    FormAbout.AboutDialog := Self;
    FormAbout.ShowModal;
  finally
    FreeAndNil(FormAbout);
  end;
end;

end.


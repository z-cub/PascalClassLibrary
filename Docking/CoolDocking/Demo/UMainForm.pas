unit UMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Buttons, Menus, UCoolDocking, UDockForm;

type

  { TMainForm }

  TMainForm = class(TForm)
    Button1: TButton;
    CoolDockMaster1: TCoolDockMaster;
    Panel1: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    FormIndex: Integer;
    DockForms: TList;
    function NewDockForm: TDockForm;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  DockForms := TList.Create;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  DockForms.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  ConjoinedDockForm1: TCoolDockConjoinForm;
  ConjoinedDockForm2: TCoolDockConjoinForm;
begin
  NewDockForm.ManualDock(Panel1);
//  NewDockForm.ManualDock(Panel1, nil, a);
  ConjoinedDockForm1 := TCoolDockManager(Panel1.DockManager).CreateContainer(alRight);
  ConjoinedDockForm1.Name := 'Model';;
  TCoolDockManager(ConjoinedDockForm1.Panel.DockManager).TabsPos := hpLeft;
  //ConjoinedDockForm1.ManualDock(Panel1);
  TCoolDockManager(ConjoinedDockForm1.Panel.DockManager).DockStyle := dsTabs;
  NewDockForm.ManualDock(ConjoinedDockForm1.Panel);
  NewDockForm.ManualDock(ConjoinedDockForm1.Panel);
  NewDockForm.ManualDock(TForm(DockForms[0]));
  NewDockForm.ManualDock(TForm(DockForms[0]));
  NewDockForm.ManualDock(TForm(DockForms[0]));
//  TCustomDockManager(TDockForm(DockForms[0]).DockManager).DockStyle := dsTabs;
end;

function TMainForm.NewDockForm: TDockForm;
begin
  Result := TDockForm.Create(Self);
  Result.Name := 'Form' + IntToStr(FormIndex);
  Result.Memo1.Text := Result.Name;
  Result.DragKind := dkDock;
  Result.DragMode := dmAutomatic;
  Result.DockSite := True;
  Result.UseDockManager := True;
  Inc(FormIndex);
  Result.Show;
  DockForms.Add(Result);
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  NewDockForm;
end;

end.


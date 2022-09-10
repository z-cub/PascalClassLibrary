unit UFormMain;

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ActnList, UPDClient;

type

  { TFormMain }

  TFormMain = class(TForm)
    AClientActive: TAction;
    ActionList1: TActionList;
    Button1: TButton;
    ComboBox1: TComboBox;
    Label1: TLabel;
    procedure AClientActiveExecute(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
  public
    Client: TPDClient;
  end;

var
  FormMain: TFormMain;


implementation

{$R *.lfm}

uses
  UPersistentData;

{ TFormMain }

procedure TFormMain.FormShow(Sender: TObject);
begin
  DefaultManager.LoadToStrings(ComboBox1.Items);
  if ComboBox1.Items.Count > 0 then ComboBox1.ItemIndex := 0;
end;

procedure TFormMain.AClientActiveExecute(Sender: TObject);
begin
  AClientActive.Checked := not AClientActive.Checked;
  Client.Connected := AClientActive.Checked;
end;

procedure TFormMain.ComboBox1Change(Sender: TObject);
begin
  FreeAndNil(Client);
  Client := TPDClientClass(ComboBox1.Items.Objects[ComboBox1.ItemIndex]).Create(Self);
end;

end.


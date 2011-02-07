unit UMicroThreadList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, DateUtils;

type

  { TMicroThreadListForm }

  TMicroThreadListForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    ListView1: TListView;
    ListView2: TListView;
    Panel1: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    TimerRedraw: TTimer;
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListView1Data(Sender: TObject; Item: TListItem);
    procedure ListView2Data(Sender: TObject; Item: TListItem);
    procedure TimerRedrawTimer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

implementation

{$R *.lfm}

uses
  UMicroThreading;

{ TMicroThreadListForm }

procedure TMicroThreadListForm.TimerRedrawTimer(Sender: TObject);
var
  ThreadCount: Integer;
begin
  if ListView1.Items.Count <> MainScheduler.MicroThreadCount then
    ListView1.Items.Count := MainScheduler.MicroThreadCount;
  ListView1.Items[-1];
  ListView1.Refresh;

  ThreadCount := MainScheduler.ThreadPoolCount;
  if MainScheduler.UseMainThread then Inc(ThreadCount);
  if ListView2.Items.Count <> ThreadCount then
    ListView2.Items.Count := ThreadCount;
  ListView2.Items[-1];
  ListView2.Refresh;
end;

procedure TMicroThreadListForm.ListView1Data(Sender: TObject; Item: TListItem
  );
begin
  try
    MainScheduler.MicroThreadsLock.Acquire;
    if Item.Index < MainScheduler.MicroThreads.Count then
    with TMicroThread(MainScheduler.MicroThreads[Item.Index]) do begin
      Item.Caption := IntToStr(Id);
      Item.SubItems.Add('');
      Item.SubItems.Add(IntToStr(Priority));
      Item.SubItems.Add(MicroThreadStateText[State]);
      Item.SubItems.Add(MicroThreadBlockStateText[BlockState]);
      Item.SubItems.Add(FloatToStr(ExecutionTime));
      Item.SubItems.Add(IntToStr(ExecutionCount));
      Item.SubItems.Add(IntToStr(Trunc(Completion * 100)) + '%');
      Item.SubItems.Add(IntToStr(StackUsed));
      Item.SubItems.Add(Name);
    end;
  finally
    MainScheduler.MicroThreadsLock.Release;
  end;
end;

procedure TMicroThreadListForm.ListView2Data(Sender: TObject; Item: TListItem);
var
  Increment: Integer;
begin
  if MainScheduler.UseMainThread then Increment := 1
    else Increment := 0;

  if Item.Index < (MainScheduler.ThreadPoolCount + Increment) then begin
    if MainScheduler.UseMainThread and (Item.Index = 0) then begin
      Item.Caption := IntToStr(MainThreadID);
      Item.SubItems.Add('');
      Item.SubItems.Add(IntToStr(MainScheduler.MainThreadManager.GetCurrentMicroThreadId));
      Item.SubItems.Add(FloatToStr(MainScheduler.MainThreadManager.LoopDuration / OneMillisecond) + ' ms');
    end else
    try
      MainScheduler.ThreadPoolLock.Acquire;
      with TMicroThreadThread(MainScheduler.ThreadPool[Item.Index - Increment]) do begin
        Item.Caption := IntToStr(ThreadID);
        Item.SubItems.Add(MicroThreadThreadStateText[State]);
        Item.SubItems.Add(IntToStr(Manager.GetCurrentMicroThreadId));
        Item.SubItems.Add(FloatToStr(Manager.LoopDuration / OneMillisecond) + ' ms');
      end;
    finally
      MainScheduler.ThreadPoolLock.Release;
    end;
  end;
end;

procedure TMicroThreadListForm.FormShow(Sender: TObject);
begin
  TimerRedraw.Enabled := True;
end;

procedure TMicroThreadListForm.FormHide(Sender: TObject);
begin
  TimerRedraw.Enabled := False;
end;


end.


unit UJobProgressView;

{$MODE Delphi}

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Syncobjs,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, fgl, UThreading, Math,
  DateUtils;

const
  EstimatedTimeShowTreshold = 4;
  EstimatedTimeShowTresholdTotal = 1;
  UpdateInterval = 100; // ms

type

  { TProgress }

  TProgress = class
  private
    FLock: TCriticalSection;
    FOnChange: TNotifyEvent;
    FText: string;
    FValue: Integer;
    FMax: Integer;
    procedure SetMax(const AValue: Integer);
    procedure SetText(AValue: string);
    procedure SetValue(const AValue: Integer);
  public
    procedure Increment;
    procedure Reset;
    constructor Create;
    destructor Destroy; override;
    property Value: Integer read FValue write SetValue;
    property Max: Integer read FMax write SetMax;
    property Text: string read FText write SetText;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TFormJobProgressView = class;
  TJobProgressView = class;
  TJobThread = class;
  TJob = class;

  TJobProgressViewMethod = procedure(Job: TJob) of object;

  { TJob }

  TJob = class
  private
    FTerminate: Boolean;
    procedure SetTerminate(const AValue: Boolean);
  public
    StartTime: TDateTime;
    EndTime: TDateTime;
    ProgressView: TJobProgressView;
    Title: string;
    Method: TJobProgressViewMethod;
    NoThreaded: Boolean;
    WaitFor: Boolean;
    Progress: TProgress;
    Thread: TJobThread;
    ResultString: string;
    Finished: Boolean;
    procedure AddLogItem(Value: string);
    constructor Create;
    destructor Destroy; override;
    property Terminate: Boolean read FTerminate write SetTerminate;
  end;

  TJobs = class(TFPGObjectList<TJob>)
  end;

  TJobThread = class(TListedThread)
    procedure Execute; override;
  public
    ProgressView: TJobProgressView;
    Job: TJob;
  end;

  { TFormJobProgressView }

  TFormJobProgressView = class(TForm)
    ImageList1: TImageList;
    LabelText: TLabel;
    Label2: TLabel;
    LabelOperation: TLabel;
    LabelEstimatedTimePart: TLabel;
    LabelEstimatedTimeTotal: TLabel;
    ListViewJobs: TListView;
    MemoLog: TMemo;
    PanelText: TPanel;
    PanelProgressTotal: TPanel;
    PanelOperationsTitle: TPanel;
    PanelLog: TPanel;
    PanelOperations: TPanel;
    PanelProgress: TPanel;
    ProgressBarPart: TProgressBar;
    ProgressBarTotal: TProgressBar;
    TimerUpdate: TTimer;
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ReloadJobList;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure ListViewJobsData(Sender: TObject; Item: TListItem);
    procedure TimerUpdateTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure UpdateHeight;
  public
    JobProgressView: TJobProgressView;
  end;

  { TJobProgressView }

  TJobProgressView = class(TComponent)
  private
    FAutoClose: Boolean;
    Finished: Boolean;
    FOnJobFinish: TJobProgressViewMethod;
    FOnOwnerDraw: TNotifyEvent;
    FOwnerDraw: Boolean;
    FShowDelay: Integer;
    FTerminate: Boolean;
    FormList: TList;
    TotalStartTime: TDateTime;
    Log: TStringList;
    FForm: TFormJobProgressView;
    procedure SetTerminate(const AValue: Boolean);
    procedure UpdateProgress;
    procedure JobProgressChange(Sender: TObject);
  public
    Jobs: TJobs;
    CurrentJob: TJob;
    CurrentJobIndex: Integer;
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    function AddJob(Title: string; Method: TJobProgressViewMethod;
      NoThreaded: Boolean = False; WaitFor: Boolean = False): TJob;
    procedure Start;
    procedure Stop;
    procedure TermSleep(Delay: Integer);
    property Form: TFormJobProgressView read FForm;
    property Terminate: Boolean read FTerminate write SetTerminate;
  published
    property OwnerDraw: Boolean read FOwnerDraw write FOwnerDraw;
    property ShowDelay: Integer read FShowDelay write FShowDelay;
    property AutoClose: Boolean read FAutoClose write FAutoClose;
    property OnJobFinish: TJobProgressViewMethod read FOnJobFinish
      write FOnJobFinish;
    property OnOwnerDraw: TNotifyEvent read FOnOwnerDraw
      write FOnOwnerDraw;
  end;

  //var
  //  FormJobProgressView: TFormJobProgressView;

procedure Register;

resourcestring
  SExecuted = 'Executed';

implementation

{$R *.lfm}

resourcestring
  SPleaseWait = 'Please wait...';
  STerminate = 'Termination';
  SEstimatedTime = 'Estimated time: %s';
  STotalEstimatedTime = 'Total estimated time: %s';
  SFinished = 'Finished';

procedure Register;
begin
  RegisterComponents('Common', [TJobProgressView]);
end;

{ TJobThread }

procedure TJobThread.Execute;
begin
  try
    try
      //raise Exception.Create('Exception in job');
      ProgressView.CurrentJob.Method(Job);
    except
      on E: Exception do begin
        ProgressView.Terminate := True;
        raise;
      end;
    end;
  finally
    Terminate;
  end;
end;

{ TFormJobProgressView }

procedure TFormJobProgressView.UpdateHeight;
var
  H: Integer;
  PanelOperationsVisible: Boolean;
  PanelOperationsHeight: Integer;
  PanelProgressVisible: Boolean;
  PanelProgressTotalVisible: Boolean;
  PanelLogVisible: Boolean;
  MemoLogHeight: Integer = 200;
  I: Integer;
  ItemRect: TRect;
  MaxH: Integer;
begin
    H := PanelOperationsTitle.Height;
    PanelOperationsVisible := JobProgressView.Jobs.Count > 0;
    if PanelOperationsVisible <> PanelOperations.Visible then
      PanelOperations.Visible := PanelOperationsVisible;
    if ListViewJobs.Items.Count > 0 then begin
      Maxh := 0;
      for I := 0 to ListViewJobs.Items.Count - 1 do
      begin
        ItemRect := ListViewJobs.Items[i].DisplayRect(drBounds);
        Maxh := Max(Maxh, ItemRect.Top + (ItemRect.Bottom - ItemRect.Top));
      end;
      PanelOperationsHeight := Scale96ToScreen(12) + Maxh;
    end else PanelOperationsHeight := Scale96ToScreen(8);
    if PanelOperationsHeight <> PanelOperations.Height then
      PanelOperations.Height := PanelOperationsHeight;
    if PanelOperationsVisible then
      H := H + PanelOperations.Height;

    PanelProgressVisible := (JobProgressView.Jobs.Count > 0) and not JobProgressView.Finished;
    if PanelProgressVisible <> PanelProgress.Visible then
      PanelProgress.Visible := PanelProgressVisible;
    if PanelProgressVisible then
      H := H + PanelProgress.Height;
    PanelProgressTotalVisible := (JobProgressView.Jobs.Count > 1) and not JobProgressView.Finished;
    if PanelProgressTotalVisible <> PanelProgressTotal.Visible then
      PanelProgressTotal.Visible := PanelProgressTotalVisible;
    if PanelProgressTotalVisible then
      H := H + PanelProgressTotal.Height;
    Constraints.MinHeight := H;
    PanelLogVisible := MemoLog.Lines.Count > 0;
    if PanelLogVisible <> PanelLog.Visible then
      PanelLog.Visible := PanelLogVisible;
    if PanelLogVisible then
      H := H + Scale96ToScreen(MemoLogHeight);
    if PanelText.Visible then
      H := H + PanelText.Height;
    if Height <> H then begin
      Height := H;
      Top := (Screen.Height - H) div 2;
    end;
end;

procedure TFormJobProgressView.TimerUpdateTimer(Sender: TObject);
var
  ProgressBarPartVisible: Boolean;
  ProgressBarTotalVisible: Boolean;
begin
  JobProgressView.UpdateProgress;
  if Visible and (not ProgressBarPart.Visible) and
  Assigned(JobProgressView.CurrentJob) and
  (JobProgressView.CurrentJob.Progress.Value > 0) then begin
    ProgressBarPartVisible := True;
    if ProgressBarPartVisible <> ProgressBarPart.Visible then
      ProgressBarPart.Visible := ProgressBarPartVisible;
    ProgressBarTotalVisible := True;
    if ProgressBarTotalVisible <> ProgressBarTotal.Visible then
      ProgressBarTotal.Visible := ProgressBarTotalVisible;
  end;
  if not Visible then begin
    TimerUpdate.Interval := UpdateInterval;
    if not JobProgressView.OwnerDraw then Show;
  end;
  if Assigned(JobProgressView.CurrentJob) then begin
    LabelText.Caption := JobProgressView.CurrentJob.Progress.Text;
    if LabelText.Caption <> '' then begin
      PanelText.Visible := True;
      UpdateHeight;
    end;
  end;
end;

procedure TFormJobProgressView.ListViewJobsData(Sender: TObject; Item: TListItem);
begin
  if (Item.Index >= 0) and (Item.Index < JobProgressView.Jobs.Count) then
  with JobProgressView.Jobs[Item.Index] do begin
    Item.Caption := Title;
    if Item.Index = JobProgressView.CurrentJobIndex then Item.ImageIndex := 1
      else if Finished then Item.ImageIndex := 0
      else Item.ImageIndex := 2;
    Item.Data := JobProgressView.Jobs[Item.Index];
  end;
end;

procedure TFormJobProgressView.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
end;

procedure TFormJobProgressView.FormCreate(Sender: TObject);
begin
  Caption := SPleaseWait;
  try
    //Animate1.FileName := ExtractFileDir(UTF8Encode(Application.ExeName)) +
    //  DirectorySeparator + 'horse.avi';
    //Animate1.Active := True;
  except

  end;
end;

procedure TFormJobProgressView.ReloadJobList;
begin
  // Workaround for not showing first line
  //Form.ListViewJobs.Items.Count := Jobs.Count + 1;
  //Form.ListViewJobs.Refresh;

  if ListViewJobs.Items.Count <> JobProgressView.Jobs.Count then
    ListViewJobs.Items.Count := JobProgressView.Jobs.Count;
  ListViewJobs.Refresh;
  Application.ProcessMessages;
  UpdateHeight;
end;

procedure TFormJobProgressView.FormShow(Sender: TObject);
begin
  ReloadJobList;
end;

procedure TFormJobProgressView.FormHide(Sender: TObject);
begin
  JobProgressView.Jobs.Clear;
  ReloadJobList;
end;

procedure TFormJobProgressView.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := JobProgressView.Finished;
  JobProgressView.Terminate := True;
  Caption := SPleaseWait + STerminate;
end;


{ TJobProgressView }

function TJobProgressView.AddJob(Title: string; Method: TJobProgressViewMethod;
  NoThreaded: Boolean = False; WaitFor: Boolean = False): TJob;
begin
  Result := TJob.Create;
  Result.ProgressView := Self;
  Result.Title := Title;
  Result.Method := Method;
  Result.NoThreaded := NoThreaded;
  Result.WaitFor := WaitFor;
  Result.Progress.Max := 100;
  Result.Progress.Reset;
  Result.Progress.OnChange := JobProgressChange;
  Jobs.Add(Result);
  //ReloadJobList;
end;

procedure TJobProgressView.Start;
var
  I: Integer;
begin
  Terminate := False;

  if not OwnerDraw then Form.BringToFront;

  Finished := False;
  Form.Caption := SPleaseWait;
  try
    FormList := Screen.DisableForms(Form);
    Log.Clear;
    Form.MemoLog.Clear;

    Form.PanelText.Visible := False;
    Form.LabelEstimatedTimePart.Visible := False;
    Form.LabelEstimatedTimeTotal.Visible := False;

    CurrentJob := nil;
    if ShowDelay = 0 then begin
      Form.TimerUpdate.Interval := UpdateInterval;
      Form.TimerUpdate.Enabled := True;
      Form.TimerUpdateTimer(Self);
    end else begin
      Form.TimerUpdate.Interval := ShowDelay;
      Form.TimerUpdate.Enabled := True;
    end;

    TotalStartTime := Now;
    Form.ProgressBarTotal.Position := 0;
    Form.ProgressBarTotal.Visible := False;
    //UpdateHeight;

    I := 0;
    while I < Jobs.Count do
    with Jobs[I] do begin
      CurrentJobIndex := I;
      CurrentJob := Jobs[I];
      JobProgressChange(Self);
      StartTime := Now;
      Form.LabelEstimatedTimePart.Caption := Format(SEstimatedTime, ['']);
      Form.ProgressBarPart.Position := 0;
      Form.ProgressBarPart.Visible := False;
      //Show;
      Form.ReloadJobList;
      Application.ProcessMessages;
      if NoThreaded then begin
        Thread := nil;
        Method(CurrentJob);
      end else begin
        Thread := TJobThread.Create(True);
        try
          with Thread do begin
            FreeOnTerminate := False;
            Job := CurrentJob;
            Name := 'Job: ' + Job.Title;
            ProgressView := Self;
            Start;
            while not Terminated do begin
              Application.ProcessMessages;
              Sleep(1);
            end;
            WaitFor;
          end;
        finally
          FreeAndNil(Thread);
        end;
      end;
      Form.ProgressBarPart.Hide;
      if Assigned(FOnJobFinish) then
        FOnJobFinish(CurrentJob);
      if Terminate then Break;
      EndTime := Now;
      Finished := True;
      Inc(I);
    end;
  finally
    CurrentJob := nil;
    Form.TimerUpdate.Enabled := False;
    Screen.EnableForms(FormList);
    //if Visible then Hide;
    Form.MemoLog.Lines.Assign(Log);
    if (Form.MemoLog.Lines.Count = 0) and FAutoClose then begin
      Form.Hide;
    end;
    if not Form.Visible then Clear;
    Form.Caption := SFinished;
    //LabelEstimatedTimePart.Visible := False;
    Finished := True;
    CurrentJobIndex := -1;
    Form.ReloadJobList;
  end;
end;

procedure TJobProgressView.JobProgressChange(Sender: TObject);
begin
  if Assigned(FOnOwnerDraw) then
    FOnOwnerDraw(Self);
end;

procedure TJobProgressView.Stop;
begin
  Terminate := True;
end;

procedure TJobProgressView.TermSleep(Delay: Integer);
const
  Quantum = 100;
var
  I: Integer;
begin
  Sleep(Delay mod Quantum);
  for I := 1 to (Delay div Quantum) do begin
    if Terminate then Break;
    Sleep(Quantum);
  end;
end;

procedure TJobProgressView.SetTerminate(const AValue: Boolean);
var
  I: Integer;
begin
  if AValue = FTerminate then Exit;
  for I := 0 to Jobs.Count - 1 do
    Jobs[I].Terminate := AValue;
  FTerminate := AValue;
end;

procedure TJobProgressView.UpdateProgress;
const
  OneJobValue: Integer = 100;
var
  TotalMax: Integer;
  TotalValue: Integer;
  EstimatedTimePart: TDateTime;
  RemainingTime: TDateTime;
begin
  if Assigned(CurrentJob) then
  with CurrentJob, Form do begin
    // Part progress
    ProgressBarPart.Max := Progress.Max;
    ProgressBarPart.Position := Progress.Value;
    if (Progress.Value >= EstimatedTimeShowTreshold) then begin
      EstimatedTimePart := (Now - StartTime) / Progress.Value * (Progress.Max - Progress.Value);
      LabelEstimatedTimePart.Caption := Format(SEstimatedTime, [
        TimeToStr(EstimatedTimePart)]);
      LabelEstimatedTimePart.Visible := True;
    end;

    // Total progress
    TotalMax := Jobs.Count * OneJobValue;
    TotalValue := Int64(CurrentJobIndex) * OneJobValue +
      Round(Progress.Value / Progress.Max * OneJobValue);
    ProgressBarTotal.Max := TotalMax;
    ProgressBarTotal.Position := TotalValue;
    if (TotalValue >= EstimatedTimeShowTresholdTotal) then begin
      // Project estimated time according part estimated time plus
      // estimated time by elapsed time divided by elapsed ticks mutiplied by rest ticks
      RemainingTime := EstimatedTimePart +
        (Now - TotalStartTime + EstimatedTimePart) /
        ((CurrentJobIndex + 1) * OneJobValue) *
        ((Jobs.Count - 1 - CurrentJobIndex) * OneJobValue);
      if (RemainingTime > 0) and (RemainingTime < EncodeDate(2100, 1, 1)) then begin
        LabelEstimatedTimeTotal.Caption := Format(STotalEstimatedTime, [
          TimeToStr(RemainingTime)]);
        LabelEstimatedTimeTotal.Visible := True;
      end else begin
        LabelEstimatedTimeTotal.Visible := False;
      end;
    end;
  end;
end;

constructor TJobProgressView.Create(TheOwner: TComponent);
begin
  inherited;
  if not (csDesigning in ComponentState) then begin
    FForm := TFormJobProgressView.Create(Self);
    FForm.JobProgressView := Self;
  end;
  Jobs := TJobs.Create;
  Log := TStringList.Create;
  //PanelOperationsTitle.Height := 80;
  AutoClose := True;
  ShowDelay := 0;
end;

procedure TJobProgressView.Clear;
begin
  Jobs.Clear;
  Log.Clear;
  //ReloadJobList;
end;

destructor TJobProgressView.Destroy;
begin
  FreeAndNil(Log);
  FreeAndNil(Jobs);
  inherited;
end;

{ TProgress }

procedure TProgress.SetMax(const AValue: Integer);
begin
  try
    FLock.Acquire;
    FMax := AValue;
    if FMax < 1 then FMax := 1;
    if FValue >= FMax then FValue := FMax;
  finally
    FLock.Release;
  end;
end;

procedure TProgress.SetText(AValue: string);
begin
  try
    FLock.Acquire;
    if FText = AValue then Exit;
    FText := AValue;
  finally
    FLock.Release;
  end;
end;

procedure TProgress.SetValue(const AValue: Integer);
var
  Change: Boolean;
begin
  try
    FLock.Acquire;
    if AValue < Max then begin
      Change := AValue <> FValue;
      FValue := AValue;
      if Change and Assigned(FOnChange) then
      try
        FLock.Release;
        FOnChange(Self);
      finally
        FLock.Acquire;
      end;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TProgress.Increment;
begin
  FLock.Acquire;
  try
    Value := Value + 1;
  finally
    FLock.Release;
  end;
end;

procedure TProgress.Reset;
begin
  FLock.Acquire;
  try
    FValue := 0;
  finally
    FLock.Release;
  end;
end;

constructor TProgress.Create;
begin
  FMax := 100;
  FLock := TCriticalSection.Create;
end;

destructor TProgress.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

{ TJob }

procedure TJob.SetTerminate(const AValue: Boolean);
begin
  if FTerminate = AValue then Exit;
  FTerminate := AValue;
  if AValue then begin
    ProgressView.Terminate := AValue;
    if Assigned(Thread) then Thread.Terminate;
  end;
end;

procedure TJob.AddLogItem(Value: string);
begin
  with ProgressView do begin
    Log.Add(Value);
  end;
end;

constructor TJob.Create;
begin
  Progress := TProgress.Create;
  Terminate := False;
  Finished := False;
end;

destructor TJob.Destroy;
begin
  FreeAndNil(Progress);
  inherited;
end;

end.

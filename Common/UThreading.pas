unit UThreading;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, fgl, SyncObjs;

type
  TExceptionEvent = procedure (Sender: TObject; E: Exception) of object;
  TMethodCall = procedure of object;


  { TVirtualThread }

  TVirtualThread = class
  private
    function GetFinished: Boolean; virtual; abstract;
    function GetFreeOnTerminate: Boolean; virtual; abstract;
    function GetPriority: TThreadPriority; virtual; abstract;
    function GetSuspended: Boolean; virtual; abstract;
    function GetTerminated: Boolean; virtual; abstract;
    function GetThreadId: TThreadID; virtual; abstract;
    procedure SetFreeOnTerminate(const AValue: Boolean); virtual; abstract;
    procedure SetPriority(const AValue: TThreadPriority); virtual; abstract;
    procedure SetSuspended(const AValue: Boolean); virtual; abstract;
    procedure SetTerminated(const AValue: Boolean); virtual; abstract;
  public
    Name: string;
    procedure Execute; virtual; abstract;
    procedure Start; virtual; abstract;
    procedure Terminate; virtual; abstract;
    procedure Synchronize(AMethod: TThreadMethod); virtual; abstract;
    procedure WaitFor; virtual; abstract;
    procedure Sleep(Delay: Integer); virtual; abstract;
    property FreeOnTerminate: Boolean read GetFreeOnTerminate
      write SetFreeOnTerminate;
    property Suspended: Boolean read GetSuspended
      write SetSuspended;
    property Priority: TThreadPriority read GetPriority write SetPriority;
    property Terminated: Boolean read GetTerminated write SetTerminated;
    property Finished: Boolean read GetFinished;
    property ThreadId: TThreadID read GetThreadId;
  end;

  TVirtualThreadClass = class of TVirtualThread;

  TListedThread = class;

  { TListedThreadExecute }

  TListedThreadExecute = class(TThread)
    Parent: TListedThread;
    procedure Execute; override;
  end;

  { TListedThread }

  TListedThread = class(TVirtualThread)
  private
    FTerminated: Boolean;
    FFinished: Boolean;
    FThread: TListedThreadExecute;
    function GetFinished: Boolean; override;
    function GetFreeOnTerminate: Boolean; override;
    function GetPriority: TThreadPriority; override;
    function GetSuspended: Boolean; override;
    function GetTerminated: Boolean; override;
    function GetThreadId: TThreadID; override;
    procedure SetFreeOnTerminate(const AValue: Boolean); override;
    procedure SetPriority(const AValue: TThreadPriority); override;
    procedure SetSuspended(const AValue: Boolean); override;
    procedure SetTerminated(const AValue: Boolean); override;
  public
    constructor Create(CreateSuspended: Boolean;
                       const StackSize: SizeUInt = DefaultStackSize);
    destructor Destroy; override;
    procedure Sleep(Delay: Integer); override;
    procedure Execute; override;
    procedure Start; override;
    procedure Terminate; override;
    procedure Synchronize(AMethod: TThreadMethod); override;
    procedure WaitFor; override;
  end;

  TTermThreadState = (ttsReady, ttsRunning, ttsFinished, ttsExceptionOccured);

  { TTermThread }

  TTermThread = class(TListedThread)
  private
    FOnFinished: TNotifyEvent;
  public
    State: TTermThreadState;
    ExceptionMessage: string;
    Method: TMethodCall;
    procedure Execute; override;
    property OnFinished: TNotifyEvent read FOnFinished write FOnFinished;
  end;

  { TThreadList }

  TThreadList = class(TFPGObjectList<TVirtualThread>)
    function FindById(Id: TThreadID): TVirtualThread;
    constructor Create; virtual;
  end;

var
  ThreadList: TThreadList;
  ThreadListLock: TCriticalSection;
  OnException: TExceptionEvent;

procedure RunInThread(Method: TMethodCall);
procedure RunInThreadAsync(Method: TMethodCall; Callback: TNotifyEvent = nil);
procedure Synchronize(Method: TMethodCall);

resourcestring
  SCurrentThreadNotFound = 'Current thread ID %d not found in virtual thread list.';


implementation

procedure RunInThread(Method: TMethodCall);
var
  Thread: TTermThread;
begin
  try
    Thread := TTermThread.Create(True);
    Thread.FreeOnTerminate := False;
    Thread.Method := Method;
    Thread.Start;
    while (Thread.State = ttsRunning) or (Thread.State = ttsReady) do begin
      if MainThreadID = ThreadID then Application.ProcessMessages;
      Sleep(1);
    end;
    if Thread.State = ttsExceptionOccured then
      raise Exception.Create(Thread.ExceptionMessage);
  finally
    Thread.Free;
  end;
end;

procedure RunInThreadAsync(Method: TMethodCall; Callback: TNotifyEvent = nil);
var
  Thread: TTermThread;
begin
  try
    Thread := TTermThread.Create(True);
    Thread.FreeOnTerminate := True;
    Thread.Method := Method;
    Thread.OnFinished := CallBack;
    Thread.Start;
    //if Thread.State = ttsExceptionOccured then
    //  raise Exception.Create(Thread.ExceptionMessage);
  finally
  end;
end;

procedure Synchronize(Method: TMethodCall);
var
  Thread: TVirtualThread;
begin
  if MainThreadID = ThreadID then Method
  else begin
    try
      ThreadListLock.Acquire;
      Thread := ThreadList.FindById(ThreadID);
    finally
      ThreadListLock.Release;
    end;
    if Assigned(Thread) then begin
      Thread.Synchronize(Method);
    end else raise Exception.Create(Format(SCurrentThreadNotFound, [ThreadID]));
  end;
end;

{ TThreadList }

function TThreadList.FindById(Id: TThreadID): TVirtualThread;
var
  I: Integer;
begin
  I := 0;
  while (I < ThreadList.Count) and (ThreadList[I].ThreadID <> Id) do
    Inc(I);
  if I < ThreadList.Count then Result := ThreadList[I]
    else Result := nil;
end;

constructor TThreadList.Create;
begin
  inherited Create;
end;

{ TListedThreadExecute }

procedure TListedThreadExecute.Execute;
begin
  try
    try
      Parent.Execute;
    except
      on E: Exception do
        if Assigned(OnException) then
          OnException(Parent.FThread, E);
    end;
  finally
    Parent.FFinished := True;
  end;
end;

{ TListedThread }

function TListedThread.GetFinished: Boolean;
begin
  Result := FFinished;
end;

function TListedThread.GetFreeOnTerminate: Boolean;
begin
  Result := FThread.FreeOnTerminate;
end;

function TListedThread.GetPriority: TThreadPriority;
begin
  Result := FThread.Priority;
end;

function TListedThread.GetSuspended: Boolean;
begin
  Result := FThread.Suspended;
end;

function TListedThread.GetTerminated: Boolean;
begin
  Result := FTerminated;
end;

function TListedThread.GetThreadId: TThreadID;
begin
  Result := FThread.ThreadID;
end;

procedure TListedThread.SetFreeOnTerminate(const AValue: Boolean);
begin
  FThread.FreeOnTerminate := AValue;
end;

procedure TListedThread.SetPriority(const AValue: TThreadPriority);
begin
  FThread.Priority := AValue;
end;

procedure TListedThread.SetSuspended(const AValue: Boolean);
begin
  FThread.Suspended := AValue;
end;

procedure TListedThread.SetTerminated(const AValue: Boolean);
begin
  FTerminated := AValue;
  if AValue then FThread.Terminate;
end;

constructor TListedThread.Create(CreateSuspended: Boolean;
  const StackSize: SizeUInt);
begin
  FFinished := False;
  FTerminated := False;

  FThread := TListedThreadExecute.Create(True, StackSize);
  FThread.Parent := Self;
  try
    ThreadListLock.Acquire;
    ThreadList.Add(Self);
  finally
    ThreadListLock.Release;
  end;
  if CreateSuspended = False then FThread.Start;
end;

destructor TListedThread.Destroy;
begin
  if not Suspended then
  begin
    Terminate;
    WaitFor;
  end;
  try
    ThreadListLock.Acquire;
    ThreadList.Delete(ThreadList.IndexOf(Self));
  finally
    ThreadListLock.Release;
  end;
  FThread.Free;
  inherited Destroy;
end;

procedure TListedThread.Sleep(Delay: Integer);
const
  Quantum = 20;
var
  I: Integer;
begin
  if Terminated then Exit;
  SysUtils.Sleep(Delay mod Quantum);
  for I := 1 to (Delay div Quantum) do begin
    if Terminated then Break;
    SysUtils.Sleep(Quantum);
  end;
end;

procedure TListedThread.Execute;
begin
end;

procedure TListedThread.Start;
begin
  FThread.Start;
end;

procedure TListedThread.Terminate;
begin
  FTerminated := True;
  FThread.Terminate;
end;

procedure TListedThread.Synchronize(AMethod: TThreadMethod);
begin
  FThread.Synchronize(FThread, AMethod);
end;

procedure TListedThread.WaitFor;
begin
  FThread.WaitFor;
end;

{ TTermThread }

procedure TTermThread.Execute;
begin
  try
    State := ttsRunning;
    Method;
    State := ttsFinished;
    if Assigned(FOnFinished) then
      FOnFinished(Self);
  except
    on E: Exception do begin
      ExceptionMessage := E.Message;
      State := ttsExceptionOccured;
      if Assigned(OnException) then
        OnException(FThread, E);
    end;
  end;
end;

initialization

ThreadListLock := TCriticalSection.Create;
ThreadList := TThreadList.Create;
ThreadList.FreeObjects := False;

finalization

ThreadList.Free;
ThreadListLock.Free;

end.


unit UResetableThread;

interface

uses
  Classes, SysUtils, syncobjs, UThreading, UPool;

type
  TResetableThread = class;

  { TResetableThreadExecute }

  TResetableThreadExecute = class(TTermThread)
    Parent: TResetableThread;
    procedure Execute; override;
  end;

  { TResetableThread }

  TResetableThread = class
  private
    FLock: TCriticalSection;
    FOnException: TExceptionEvent;
    FOnFinished: TNotifyEvent;
    FStartEvent: TEvent;
    FStopEvent: TEvent;
    FThread: TResetableThreadExecute;
    FStopPending: Boolean;
    FRunning: Boolean;
    FRunningPending: Boolean;
    function GetRunning: Boolean;
    procedure WaitForStart;
    procedure WaitForStop;
  public
    Method: TMethodCall;
    procedure Stop;
    procedure Start;
    constructor Create;
    destructor Destroy; override;
    property OnFinished: TNotifyEvent read FOnFinished write FOnFinished;
    property StopPending: Boolean read FStopPending;
    property Running: Boolean read GetRunning;
    property OnException: TExceptionEvent read FOnException
      write FOnException;
  end;

  { TThreadPool }

  TThreadPool = class(TThreadedPool)
  private
    FOnException: TExceptionEvent;
    procedure MethodFinish(Sender: TObject);
  protected
    function NewItemObject: TObject; override;
  public
    LastExceptionClass: TClass;
    LastExceptionMessage: string;
    procedure ThreadException(Sender: TObject; E: Exception);
    procedure CheckException;
    procedure WaitForEmpty;
    procedure Clear;
    procedure RunInThread(AMethod: TMethodCall);
    constructor Create; override;
    destructor Destroy; override;
    property OnException: TExceptionEvent read FOnException
      write FOnException;
  end;

resourcestring
  SWaitError = 'WaitFor error';


implementation

{ TResetableThread }

function TResetableThread.GetRunning: Boolean;
begin
  Result := FRunning;
end;

procedure TResetableThread.Stop;
begin
  try
    FLock.Acquire;
    if FRunning then FStopPending := True;
  finally
    FLock.Release;
  end;
end;

procedure TResetableThread.Start;
begin
  try
    FLock.Acquire;
    //FRunningPending := True;
    FStartEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TResetableThread.WaitForStart;
//var
//  WaitResult: TWaitResult;
begin
  //try
  //  FLock.Acquire;
//  while (not FThread.Terminate) and (not FRunning) and (not FRunningPending) do
//    Sleep(1);
  //repeat
    //try
    //  FLock.Release;
      //WaitResult := FStartEvent.WaitFor(1);
    //finally
    //  FLock.Acquire;
    //end;
  //until (WaitResult <> wrTimeout) or FRunning or FThread.Terminated;
  //if WaitResult = wrError then
  //  raise Exception.Create(SWaitError);
  //finally
  //  FLock.Release;
  //end;
end;

procedure TResetableThread.WaitForStop;
//var
//  WaitState: TWaitResult;
begin
  try
    FLock.Acquire;
    repeat
      try
        FLock.Release;
        //WaitState := FStopEvent.WaitFor(1);
        Sleep(1);
      finally
        FLock.Acquire;
      end;
    until (not FRunning); // or (WaitState <> wrTimeout);
  finally
    FLock.Release;
  end;
end;

constructor TResetableThread.Create;
begin
  FLock := TCriticalSection.Create;
  FRunning := False;
  FStopPending := False;
  FStartEvent := TEvent.Create(nil, False, False, '');
  FStopEvent := TEvent.Create(nil, False, False, '');
  FThread := TResetableThreadExecute.Create(True);
  FThread.Name := 'ResetableThread';
  FThread.Parent := Self;
  FThread.Start;
end;

destructor TResetableThread.Destroy;
begin
  Stop;
  WaitForStop;
  FThread.Free; // Do not use FreeAndNil
  FreeAndNil(FStartEvent);
  FreeAndNil(FStopEvent);
  FreeAndNil(FLock);
  inherited;
end;

{ TResetableThreadExecute }

procedure TResetableThreadExecute.Execute;
var
  WaitResult: TWaitResult;
begin
  while not Terminated do
  with Parent do begin
    try
      FLock.Acquire;
      //WaitForStart;
      (*while (not Terminated) and (not FRunning) and (not FRunningPending) do
      try
        FLock.Release;
        Sleep(1);
      finally
        FLock.Acquire;
      end;*)
      repeat
        try
          FLock.Release;
          WaitResult := FStartEvent.WaitFor(1);
        finally
          FLock.Acquire;
        end;
      until (WaitResult <> wrTimeout) or Terminated;

      if not Terminated then begin
        //try
          //FLock.Acquire;
          FRunning := True;
          FRunningPending := False;
          try
            FLock.Release;
            try
              try
                Method;
              finally
                if Assigned(FOnFinished) then
                  FOnFinished(Parent);
              end;
            except
              on E: Exception do
                if Assigned(FOnException) then
                  FOnException(Self, E);
            end;
          finally
            FLock.Acquire;
          end;
          FRunning := False;
          FStopPending := False;
          FStopEvent.SetEvent;
        //finally
          //FLock.Release;
        //end;
      end;
    finally
      FLock.Release;
    end;
  end;
end;

{ TThreadPool }

procedure TThreadPool.MethodFinish(Sender: TObject);
begin
  Release(Sender);
end;

procedure TThreadPool.ThreadException(Sender: TObject; E: Exception);
begin
  LastExceptionClass := E.ClassType;
  LastExceptionMessage := E.Message;
end;

procedure TThreadPool.CheckException;
begin
  if Assigned(LastExceptionClass) then
    raise Exception.Create(LastExceptionMessage);
end;

function TThreadPool.NewItemObject: TObject;
begin
  Result := TResetableThread.Create;
  TResetableThread(Result).OnException := ThreadException;
end;

procedure TThreadPool.WaitForEmpty;
begin
  while UsedCount > 0 do begin
    Sleep(1);
  end;
end;

procedure TThreadPool.Clear;
begin
  TotalCount := 0;
  LastExceptionClass := nil;
  LastExceptionMessage := '';
end;

procedure TThreadPool.RunInThread(AMethod: TMethodCall);
begin
  try
    with TResetableThread(Acquire) do begin
      Method := AMethod;
      OnFinished := MethodFinish;
      Start;
    end;
  finally
    CheckException;
  end;
end;

constructor TThreadPool.Create;
begin
  inherited;
end;

destructor TThreadPool.Destroy;
begin
  TotalCount := 0;
  WaitForEmpty;
  inherited;
end;

end.


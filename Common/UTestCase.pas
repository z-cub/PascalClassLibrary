unit UTestCase;

interface

uses
  Classes, SysUtils, FileUtil, Generics.Collections;

type
  TTestResult = (trNone, trPassed, trFailed);

  { TTestCase }

  TTestCase = class
  public
    Name: string;
    TestResult: TTestResult;
    Log: string;
    procedure Initialize; virtual;
    procedure Run; virtual;
    procedure Finalize; virtual;
    procedure Evaluate(Passed: Boolean);
    procedure Pass;
    procedure Fail;
    constructor Create; virtual;
  end;

  TTestCaseClass = class of TTestCase;

  { TTestCases }

  TTestCases = class(TObjectList<TTestCase>)
    function AddNew(Name: string; TestClass: TTestCaseClass): TTestCase;
    procedure Run;
  end;


resourcestring
  SNone = 'None';
  SPassed = 'Passed';
  SFailed = 'Failed';

const
  ResultText: array[TTestResult] of string = (SNone, SPassed, SFailed);

procedure Translate;


implementation

procedure Translate;
begin
  ResultText[trNone] := SNone;
  ResultText[trPassed] := SPassed;
  ResultText[trFailed] := SFailed;
end;


{ TTestCase }

procedure TTestCase.Initialize;
begin
  TestResult := trNone;
end;

procedure TTestCase.Run;
begin
end;

procedure TTestCase.Finalize;
begin
end;

procedure TTestCase.Evaluate(Passed: Boolean);
begin
  if Passed then TestResult := trPassed
    else TestResult := trFailed;
end;

procedure TTestCase.Pass;
begin
  TestResult := trPassed;
end;

procedure TTestCase.Fail;
begin
  TestResult := trFailed;
end;

constructor TTestCase.Create;
begin
end;

{ TTestCases }

function TTestCases.AddNew(Name: string; TestClass: TTestCaseClass): TTestCase;
begin
  Result := TestClass.Create;
  Result.Name := Name;
  Add(Result);
end;

procedure TTestCases.Run;
var
  I: Integer;
  Passed: Integer;
  Failed: Integer;
begin
  Passed := 0;
  Failed := 0;
  for I := 0 to Count - 1 do
  with Items[I] do begin
    WriteLn('== ' + Name + ' ======= ');
    Initialize;
    Run;
    Finalize;
    if TestResult = trPassed then Inc(Passed);
    if TestResult = trFailed then Inc(Failed);
  end;

  for I := 0 to Count - 1 do
  with Items[I] do begin
    WriteLn(Name + ': ' + ResultText[TestResult]);
  end;
  WriteLn('Total: ' + IntToStr(Count) + ', Passed: ' + IntToStr(Passed) +
    ', Failed: ' + IntToStr(Failed));
end;

end.


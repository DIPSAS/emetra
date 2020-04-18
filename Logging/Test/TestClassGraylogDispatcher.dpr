program TestClassGraylogDispatcher;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  TestCaseGrayLogDispatcher in 'TestCaseGrayLogDispatcher.pas',
  Emetra.Logging.Target.GrayLog in '..\Emetra.Logging.Target.GrayLog.pas',
  Emetra.Logging.PlainText.LogItem in '..\Emetra.Logging.PlainText.LogItem.pas',
  Emetra.Logging.PlainText in '..\Emetra.Logging.PlainText.pas';

{$R *.RES}

begin
  DUnitTestRunner.RunRegisteredTests;
end.


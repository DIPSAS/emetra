program TestClassPlainTextLog;
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
  Emetra.Logging.PlainText in '..\Emetra.Logging.PlainText.pas', {Keep logging first}
  TestCasePlainTextLog in 'TestCasePlainTextLog.pas',
  DUnitTestRunner,
  Emetra.Logging.Base in '..\Emetra.Logging.Base.pas',
  Emetra.Logging.PlainText.LogItem in '..\Emetra.Logging.PlainText.LogItem.pas',
  Emetra.Logging.PlainText.ItemList in '..\Emetra.Logging.PlainText.ItemList.pas',
  Emetra.Logging.Target.TextFile in '..\Emetra.Logging.Target.TextFile.pas',
  Emetra.Logging.Target.Interfaces in '..\Emetra.Logging.Target.Interfaces.pas',
  Emetra.Logging.Target.GrayLog in '..\Emetra.Logging.Target.GrayLog.pas',
  Emetra.Logging.Target.Mock in '..\Emetra.Logging.Target.Mock.pas',
  Emetra.Logging.Target.SmartInspect in '..\Emetra.Logging.Target.SmartInspect.pas',
  Emetra.Logging.Target.GrayLog.Interfaces in '..\Emetra.Logging.Target.GrayLog.Interfaces.pas',
  Emetra.Hash.CRC32 in '..\..\Utils\Emetra.Hash.CRC32.pas',
  Emetra.Win.User in '..\..\Utils\Emetra.Win.User.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := true;
  DUnitTestRunner.RunRegisteredTests;

end.

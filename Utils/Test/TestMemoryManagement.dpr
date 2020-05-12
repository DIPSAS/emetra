program TestMemoryManagement;
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

{ Logging should be the first entry }

uses
  Emetra.Logging.SmartInspect in '..\..\Logging\Emetra.Logging.SmartInspect.pas',
  DUnitTestRunner,
  TestCaseMemoryManagement in 'TestCaseMemoryManagement.pas',
  TestClassesMemoryManagement in 'TestClassesMemoryManagement.pas',
  Emetra.Logging.Interfaces in '..\..\Logging\Emetra.Logging.Interfaces.pas',
  Emetra.Logging.LogItem.Interfaces in '..\..\Logging\Emetra.Logging.LogItem.Interfaces.pas',
  Emetra.Logging.Base in '..\..\Logging\Emetra.Logging.Base.pas',
  Emetra.Logging.Utilities in '..\..\Logging\Emetra.Logging.Utilities.pas',
  Emetra.Logging.Colors in '..\..\Logging\Emetra.Logging.Colors.pas',
  Emetra.Logging.FileNames in '..\..\Logging\Emetra.Logging.FileNames.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := true;
  DUnitTestRunner.RunRegisteredTests;
end.


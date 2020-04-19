program TestClassMathParser;
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
  Emetra.Logging.SmartInspect,
  DUnitTestRunner,
  TestCaseMathParser in 'TestCaseMathParser.pas',
  Bitsoft.MathParser.StdFunctions in '..\Bitsoft.MathParser.StdFunctions.pas',
  BitSoft.MathParser in '..\BitSoft.MathParser.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := true;
  DUnitTestRunner.RunRegisteredTests;
end.


program TestClassConsoleLogger;
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
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  TestCaseConsoleLogger in 'TestCaseConsoleLogger.pas',
  Emetra.Logging.Console in '..\Emetra.Logging.Console.pas',
  Emetra.Logging.Interfaces in '..\Emetra.Logging.Interfaces.pas',
  Emetra.Logging.Utilities in '..\Emetra.Logging.Utilities.pas';

{$R *.RES}

begin
  Application.Initialize;
  if IsConsole then
    TextTestRunner.RunRegisteredTests
  else
    GUITestRunner.RunRegisteredTests;
end.


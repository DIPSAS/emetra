program TestClassPlainTextFireMonkey;

uses
  Emetra.Logging.PlainText,
  System.StartUpCopy,
  FMX.Forms,
  IPPeerClient,
  MainTestClassPlainTextLogInFireMonkey in 'MainTestClassPlainTextLogInFireMonkey.pas' {frmMain},
  Emetra.Logging.Colors in '..\Emetra.Logging.Colors.pas',
  Emetra.Logging.PlainText.LogItem in '..\Emetra.Logging.PlainText.LogItem.pas' {/ Emetra.Logging.SmartInspect;},
  Emetra.Logging.Target.GrayLog in '..\Emetra.Logging.Target.GrayLog.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

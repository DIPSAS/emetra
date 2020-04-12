program TestFormBrowserLinks;

uses
  Emetra.Logging.SmartInspect,
  Vcl.Forms,
  MainTestBrowserLinks in 'MainTestBrowserLinks.pas' {frmMainTestBrowserLinks},
  Emetra.Command.LinkClassifier in '..\Emetra.Command.LinkClassifier.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMainTestBrowserLinks, frmMainTestBrowserLinks);
  Application.Run;
end.

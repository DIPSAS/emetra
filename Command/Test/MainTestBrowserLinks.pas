unit MainTestBrowserLinks;

interface

uses
  Emetra.Command.LinkClassifier,
  Emetra.Logging.Interfaces,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.OleCtrls, SHDocVw, System.Actions, Vcl.ActnList, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls,
  System.ImageList, Vcl.ImgList, IDETheme.ActnCtrls, Vcl.StdStyleActnCtrls, Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TfrmMainTestBrowserLinks = class(TForm)
    brwDocumentViewer: TWebBrowser;
    ListBox1: TListBox;
    ImageList1: TImageList;
    ActionManager1: TActionManager;
    ActionToolBar1: TActionToolBar;
    actLoadFile: TAction;
    actLoadNewspaper: TAction;
    actClearLog: TAction;
    Splitter1: TSplitter;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    actLoadUsaToday: TAction;
    procedure brwDocumentViewerBeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
    procedure actLoadFileExecute(Sender: TObject);
    procedure actLoadNewspaperExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure actClearLogExecute(Sender: TObject);
    procedure actLoadUsaTodayExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    fClassifier: TLinkParser;
    fParams: TStringList;
    function TestFileName: string;
  public
    { Public declarations }
  end;

var
  frmMainTestBrowserLinks: TfrmMainTestBrowserLinks;

implementation

{$R *.dfm}

procedure TfrmMainTestBrowserLinks.FormCreate(Sender: TObject);
begin
  brwDocumentViewer.Silent := true;
  fClassifier := TLinkParser.Create;
  fParams := TStringList.Create;
end;

procedure TfrmMainTestBrowserLinks.FormDestroy(Sender: TObject);
begin
  fParams.Free;
  fClassifier.Free;
end;

{$REGION 'Action handlers'}

procedure TfrmMainTestBrowserLinks.actClearLogExecute(Sender: TObject);
begin
  ListBox1.Clear;
end;

procedure TfrmMainTestBrowserLinks.actLoadFileExecute(Sender: TObject);
begin
  brwDocumentViewer.Navigate2(TestFileName);
end;

procedure TfrmMainTestBrowserLinks.actLoadNewspaperExecute(Sender: TObject);
begin
  brwDocumentViewer.Navigate2('https://vg.no');
end;

procedure TfrmMainTestBrowserLinks.actLoadUsaTodayExecute(Sender: TObject);
begin
  brwDocumentViewer.Navigate2('https://usatoday.com');
end;

{$ENDREGION}

function TfrmMainTestBrowserLinks.TestFileName: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'MainTestBrowserLinks.htm';
end;

procedure TfrmMainTestBrowserLinks.brwDocumentViewerBeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
var
  commandName: string;
  urlClass: TUrlClass;
  fileName: string;
begin
  if fClassifier.TryParseCommand(URL, commandName, fParams) then
  begin
    GlobalLog.Event('URL "%s" is a valid command: %s Params=%s', [URL, commandName, fParams.CommaText], ltMessage);
    Cancel := true;
  end
  else
  begin
    GlobalLog.Event('URL "%s" was not a valid command, try to classify it.', [URL]);
    urlClass := fClassifier.ClassifyUrl(URL, fileName);
    ListBox1.Items.Add(FOrmat('%d: %s', [ord(urlClass), URL]));
    case urlClass of
      urlReportTemplateFile, urlApplicationCommand, urlReportOutput:
        Cancel := true;
      urlPDF:
        GlobalLog.Event('you clicked on a PDF file %s', [fileName]);
      urlFastReport:
        GlobalLog.Event('you clicked on a FastReport file %s', [fileName]);
    end;
  end;
end;

end.

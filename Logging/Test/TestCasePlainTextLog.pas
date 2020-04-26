unit TestCasePlainTextLog;

interface

uses
  Winapi.Windows,
  System.Win.Registry,
  System.Generics.Collections,
  System.StrUtils,
  System.SyncObjs,
  System.Classes,
  System.SysUtils,
  System.IniFiles,
  System.Diagnostics,
  System.RegularExpressions,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Emetra.Logging.PlainText,
  Emetra.Logging.LogItem.Interfaces,
  Emetra.Logging.PlainText.LogItem,
  Emetra.Logging.Interfaces,
  TestFramework,
  IdUDPClient;

type
  // Test methods for class TPlainTextLog

  TestTPlainTextLog = class( TTestCase )
  strict private
    fIniFile: TIniFile;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestClearTargets;
    procedure TestDecisionNo;
    procedure TestDecisionYes;
    procedure TestGrayLogEvent;
    procedure TestIgnoreButton;
    procedure TestShowMessage;
  end;

implementation

uses
  Emetra.Logging.Target.Interfaces,
  Emetra.Logging.Target.Mock,
  Emetra.Logging.Target.SmartInspect,
  Emetra.Logging.Target.GrayLog;

const
  ASK_CLICK_YES_FOR_INFOLEVEL    = 'Click Yes if you see a yes/no question here with level Information (blue).';
  ASK_CLICK_NO_FOR_WARNING_LEVEL = 'Click No if you see a yes/no question here with level Warning (yellow).';
  ASK_CONFIRM_SINGLE_MESSAGE     = 'Did you see the message "%s" exactly once?';
  MSG_IGNORABLE_MESSAGE          = 'Now, listen very carefully, I shall say zis only whence.';
  MSG_VERIFY_GRAYLOG_REACHED     = '%s.%s: Verify that an entry with number %d has appeared on your GrayLog server at %s.';

const
  TXT_CLICK_IGNORE = 'Click Ignore button here!';
  TXT_CLICK_OK     = 'Click OK button here!';

const
  GRAYLOG_SERVER = '40.69.207.41';

var
  multiTarget: ILogMultitarget;

{$REGION 'Initialization'}

procedure TestTPlainTextLog.SetUp;
begin
  ForceDirectories( ExtractFilePath( TPlainTextLog.GetFileNameSettings ) );
  fIniFile := TIniFile.Create( TPlainTextLog.GetFileNameSettings );
  fIniFile.WriteString( SECTION_GRAYLOG, KEY_LOG_SERVER, EmptyStr );
end;

procedure TestTPlainTextLog.TearDown;
begin
  fIniFile.Free;
end;

{$ENDREGION}

procedure TestTPlainTextLog.TestClearTargets;
begin
  { Make sure we have a multitarget log }
  if Supports( GlobalLog, ILogMultitarget, multiTarget ) then
  begin
    multiTarget.AddTarget( TMockTarget.Create );
    multiTarget.AddTarget( TMockTarget.Create );
    multiTarget.ClearAllTargets;
    CheckEquals( 0, multiTarget.TargetCount );
  end;
end;

procedure TestTPlainTextLog.TestDecisionNo;
begin
  CheckFalse( GlobalLog.LogYesNo( ASK_CLICK_NO_FOR_WARNING_LEVEL, ltWarning ) );
end;

procedure TestTPlainTextLog.TestDecisionYes;
begin
  CheckTrue( GlobalLog.LogYesNo( ASK_CLICK_YES_FOR_INFOLEVEL, ltMessage ) );
end;

procedure TestTPlainTextLog.TestGrayLogEvent;
const
  PROC_NAME = 'TestGrayLogEvent';
begin
  Randomize( );
  Assert( Supports( GlobalLog, ILogMultitarget, multiTarget ) );
  multiTarget.ClearAllTargets;
  multiTarget.AddTarget( TGrayLogDispatcher.Create( GRAYLOG_SERVER, DEFAULT_GRAYLOG_PORT ) );
  GlobalLog.LogYesNo( Format( MSG_VERIFY_GRAYLOG_REACHED, [ClassName, PROC_NAME, Random( 10000 ), GRAYLOG_SERVER] ), ltMessage );
end;

procedure TestTPlainTextLog.TestIgnoreButton;
begin
  GlobalLog.ShowMessage( TXT_CLICK_IGNORE, ltMessage, 2 );
  CheckEquals( mrIgnore, GlobalLog.ModalResult );
  GlobalLog.ShowMessage( TXT_CLICK_OK, ltMessage, 2 );
  CheckEquals( mrOk, GlobalLog.ModalResult );
end;

procedure TestTPlainTextLog.TestShowMessage;
begin
  GlobalLog.ResetCounter( MSG_IGNORABLE_MESSAGE );
  GlobalLog.ShowMessage( MSG_IGNORABLE_MESSAGE, ltMessage, 1 );
  GlobalLog.ShowMessage( MSG_IGNORABLE_MESSAGE, ltMessage, 1 );
  GlobalLog.ShowMessage( MSG_IGNORABLE_MESSAGE, ltMessage, 2 );
  GlobalLog.ShowMessage( MSG_IGNORABLE_MESSAGE, ltMessage, 3 );
  GlobalLog.ShowMessage( MSG_IGNORABLE_MESSAGE, ltMessage, 1 );
  CheckTrue( GlobalLog.LogYesNo( Format( ASK_CONFIRM_SINGLE_MESSAGE, [MSG_IGNORABLE_MESSAGE] ) ) );
end;

initialization

if Supports( GlobalLog, ILogMultitarget, multiTarget ) then
begin
  multiTarget.ClearAllTargets;
  multiTarget.AddTarget( TGrayLogDispatcher.Create( GRAYLOG_SERVER, DEFAULT_GRAYLOG_PORT ) );
  multiTarget.AddTarget( TSmartInspectTarget.Create );
end;

// Register any test cases with the test runner
RegisterTest( TestTPlainTextLog.Suite );

end.

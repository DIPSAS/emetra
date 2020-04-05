unit Emetra.Logging.SmartInspect;

{$DEBUGINFO OFF}

interface

uses
  {Third Party}
  SmartInspect,
  {Emetra Interfaces}
  Emetra.Logging.LogItem.Interfaces,
  Emetra.Logging.Interfaces,
  Emetra.Logging.Base,
  Emetra.Logging.Colors,
  Emetra.Win.User,
  {Standard}
  System.Classes, System.UITypes;

type
  TSmartInspectAdapter = class( TLogAdapter, ILog, ILogXmlData )
  strict private
    FCalls: integer;
  public
    { Property accessors }
    function Get_Enabled: boolean;
    function Get_Count: integer;
    procedure Set_Enabled( const AValue: boolean );
  protected
    procedure LogToSi( const ALevel: TSiLevel; const AColor: TColor; const s: string );
    procedure LogSqlCommand( const ASQL: string );
    procedure LogSqlQuery( const ASQL: string );
  public
    { Initialization }
    constructor Create; override;
    destructor Destroy; override;
    { Other methods }
    function GetStandardFileName: string;
    procedure EventColor( const AColor: TColor; const s: string ); overload;
    procedure EventColor( const AColor: TColor; const s: string; const AParams: array of const ); overload;
    procedure EnterMethod( AInstance: TObject; const AMethodName: string );
    procedure LeaveMethod( AInstance: TObject; const AMethodName: string );
    procedure LogXmlData( const ALevel: TLogLevel; const ATitle, AXmlData: string );
    procedure AddStrings( const ATitle: string; AStrings: TStrings );
    procedure Event( s: string; const ALogLevel: TLogLevel = ltInfo ); overload; override;
    procedure SilentError( const s: string; const AParams: array of const ); overload;
    procedure SilentWarning( const s: string; const AParams: array of const ); overload;
    procedure SilentSuccess( const s: string; const AParams: array of const ); overload;
    procedure SilentError( const s: string ); overload;
    procedure SilentWarning( const s: string ); overload;
    procedure SilentSuccess( const s: string ); overload;
    { Properties }
    property Count: integer read Get_Count;
    property Enabled: boolean read Get_Enabled write Set_Enabled;
    property LogCallStack: boolean read Get_LogCallStack write Set_LogCallStack;
  end;

implementation

uses
  {Third party}
  SiAuto,
  {General}
  Emetra.Logging.FileNames,
  Emetra.Logging.Utilities,
  {Standard}
  Inifiles, DateUtils, SysUtils, StrUtils;

var
  DefaultInstance: TSmartInspectAdapter = nil;
  Errors: integer = 0;
  SilentErrors: integer = 0;
  InstanceCounter: integer = 0;

resourcestring
  GODS_FINAL_MESSAGE = 'WE APOLOGIZE FOR THE INCONVENIENCE';
  SO_LONG_AND_THANKS = 'So long, and thanks for all the fish!';

  { TSmartInspectAdapter }

{$REGION 'Initialization'}

constructor TSmartInspectAdapter.Create;
begin
  inc( InstanceCounter );
  Assert( InstanceCounter = 1 );
  inherited Create;
  // fItems := TLogItemList.Create;
  LogCallStack := true;
{$IFDEF Debug}
  SiAuto.SiMain.ClearLog;
{$ENDIF}
  SiAuto.SiMain.LogSeparator;
  SiAuto.SiMain.LogColored( mcFirstAndLastEntry, ClassName );
  SiAuto.SiMain.LogSystem;
end;

destructor TSmartInspectAdapter.Destroy;
begin
  // fItems.Free;
  Dec( InstanceCounter );
  SiAuto.SiMain.LogColored( mcFirstAndLastEntry, Format( '%s.Destroy. Should precede final message in log.', [ClassName] ) );
  inherited;
end;

{$ENDREGION}
{$REGION 'LogCallStack'}

procedure TSmartInspectAdapter.EnterMethod( AInstance: TObject; const AMethodName: string );
begin
  if LogCallStack and Assigned( SiAuto.SiMain ) then
    SiAuto.SiMain.EnterMethod( AInstance, AMethodName );
end;

procedure TSmartInspectAdapter.LeaveMethod( AInstance: TObject; const AMethodName: string );
begin
  if LogCallStack and Assigned( SiAuto.SiMain ) then
    SiAuto.SiMain.LeaveMethod( AInstance, AMethodName );
end;

{$ENDREGION}
{$REGION 'Others that need SiMain'}

procedure TSmartInspectAdapter.AddStrings( const ATitle: string; AStrings: TStrings );
begin
  if Assigned( SiMain ) then
    SiAuto.SiMain.LogStringList( ATitle, AStrings );
end;

procedure TSmartInspectAdapter.LogToSi( const ALevel: TSiLevel; const AColor: TColor; const s: string );
begin
  if Assigned( SiMain ) then
    SiAuto.SiMain.LogColored( ALevel, AColor, AnonymizeLogMessage( s ) );
end;

procedure TSmartInspectAdapter.LogXmlData( const ALevel: TLogLevel; const ATitle, AXmlData: string );
begin
  if Assigned( SiMain ) then
    SiAuto.SiMain.LogText( lvVerbose, ATitle, AXmlData );
end;

{$ENDREGION}
{$REGION 'No need for SiMain'}

procedure TSmartInspectAdapter.EventColor( const AColor: TColor; const s: string );
begin
  LogToSi( lvVerbose, AColor, s );
end;

procedure TSmartInspectAdapter.EventColor( const AColor: TColor; const s: string; const AParams: array of const );
begin
  LogToSi( lvVerbose, AColor, Format( s, AParams ) );
end;

procedure TSmartInspectAdapter.Event( s: string; const ALogLevel: TLogLevel );
begin
  inc( FCalls );
  if ALogLevel >= Threshold then
  begin
    if ALogLevel > ltWarning then
      inc( Errors );
    case ALogLevel of
      Emetra.Logging.Interfaces.ltDebug: LogToSi( lvDebug, mcTransparent, s );
      Emetra.Logging.Interfaces.ltInfo: LogToSi( lvVerbose, mcTransparent, s );
      Emetra.Logging.Interfaces.ltMessage: LogToSi( lvMessage, mcInfoMessage, s );
      Emetra.Logging.Interfaces.ltWarning: LogToSi( lvWarning, mcWarningMessage, s );
      Emetra.Logging.Interfaces.ltError: LogToSi( lvError, mcErrorMessage, s );
      Emetra.Logging.Interfaces.ltCritical: LogToSi( lvFatal, mcCriticalMessage, s );
    end;
    if ALogLevel >= ThresholdForDialog then
      ShowCrossPlatformDialog( s, ButtonSet, DefaultButton, 0, ALogLevel );
  end;
end;

function TSmartInspectAdapter.Get_Enabled: boolean;
begin
  Result := Si.Enabled;
end;

function TSmartInspectAdapter.Get_Count: integer;
begin
  Result := FCalls;
end;

procedure TSmartInspectAdapter.LogSqlCommand( const ASQL: string );
begin
  LogToSi( lvVerbose, mcSqlCommand, ASQL );
end;

procedure TSmartInspectAdapter.LogSqlQuery( const ASQL: string );
begin
  LogToSi( lvVerbose, mcSqlQuery, ASQL );
end;

procedure TSmartInspectAdapter.Set_Enabled( const AValue: boolean );
begin
  Si.Enabled := AValue;
end;

procedure TSmartInspectAdapter.SilentError( const s: string );
begin
  SilentError( s, [] );
end;

procedure TSmartInspectAdapter.SilentError( const s: string; const AParams: array of const );
begin
  inc( SilentErrors );
  LogToSi( lvError, mcSilentError, Format( s, AParams ) );
end;

procedure TSmartInspectAdapter.SilentWarning( const s: string );
begin
  SilentWarning( s, [] );
end;

procedure TSmartInspectAdapter.SilentWarning( const s: string; const AParams: array of const );
begin
  LogToSi( lvWarning, mcSilentWarning, Format( s, AParams ) );
end;

function TSmartInspectAdapter.GetStandardFileName: string;
begin
  Result := TLogFileNaming.GetStdFileName( '.sil' );
end;

procedure TSmartInspectAdapter.SilentSuccess( const s: string );
begin
  SilentSuccess( s, [] );
end;

procedure TSmartInspectAdapter.SilentSuccess( const s: string; const AParams: array of const );
begin
  LogToSi( lvVerbose, mcSilentSuccess, Format( s, AParams ) );
end;

{$ENDREGION}
{$IFNDEF Debug}

procedure DumpToFile;
var
  fileStream: TFileStream;
begin
  try
    fileStream := TFileStream.Create( TLogFileNaming.GetStdFileName( '.sil' ), fmCreate );
    try
      Si.Dispatch( 'mem', 0, fileStream );
    finally
      fileStream.Free;
    end;
  except
    on Exception do
  end;
end;

{$ENDIF}

var
  smartInspectConfigFile: string;

initialization

Si.SetVariable( 'User', GetWindowsUsername );
Si.SetVariable( 'Root', ExtractFilePath( ParamStr( 0 ) ) );

smartInspectConfigFile := ExtractFilePath( ParamStr( 0 ) ) + 'Settings\' + ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '.sic' );
{ Find connections }
if FileExists( smartInspectConfigFile ) then
  Si.LoadConfiguration( smartInspectConfigFile )
else
begin
  Si.Connections := 'tcp()';
  Si.Enabled := true;
end;
DefaultInstance := TSmartInspectAdapter.Create;
GlobalLog := DefaultInstance;

finalization

GlobalLog := nil;
if Errors > 0 then
  SiAuto.SiMain.LogColored( mcFinalizeWithExceptions, GODS_FINAL_MESSAGE )
else
  SiAuto.SiMain.LogColored( mcFinalizeNoExceptions, SO_LONG_AND_THANKS );
SiAuto.SiMain.LogSeparator;
if Assigned( Si ) then
  Si.Enabled := false;

end.

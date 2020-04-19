unit Emetra.Logging.PlainText;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Emetra.Logging.PlainText.ItemList,
  Emetra.Logging.Base,
  {General interfaces}
  Emetra.Logging.LogItem.Interfaces,
  Emetra.Logging.Target.Interfaces,
  Emetra.Logging.Interfaces,
  {Standard services}
  System.UITypes,
  System.Generics.Collections, System.SyncObjs, System.Diagnostics, System.Classes, System.StrUtils, System.SysUtils, System.Inifiles,
  System.RegularExpressions,
  IdUDPClient;

const
  MAX_NESTING = 255;

type
  { Summary:
    The TLogObject class provides useful logging facilities for any application. }

  TPlainTextLog = class( TLogAdapter, ILog, ILogItemList, ILogMultitarget )
  strict private
    fCallCounter: Integer;
    fCriticalSection: TCriticalSection;
    fIndentLevel: Integer;
    fItems: TLogItemList;
    fLogCallStack: boolean;
    fLogFileNumber: Integer;
    fLogFolderPresent: boolean;
    fSaveToFileOnDestroy: boolean;
    fStopWatch: array [0 .. MAX_NESTING] of TStopWatch;
    fUserIniFile: TIniFile;
  private
    class var InstanceCounter: Integer;
    function GetFileNameLog: string;
    function GetStandardFileName: string;
    function StripNewlines( const AMsg: string ): string;
    function MainThread: boolean;
    procedure ReadLogSettings;
    procedure SetDefaultFileName;
  private
    { Other members }
    procedure AddStrings( const ATitle: string; AStrings: TStrings );
    function LogYesNo( const AMessage: string; const ALevel: TLogLevel = ltMessage; const ACancel: boolean = false ): boolean;
    procedure Event( const AMessage: string; const Args: array of const; const ALogType: TLogLevel = ltInfo ); overload; {
      Add a formatted message to the log }
    { Call stack logging }
    procedure EnterMethod( AInstance: TObject; const AMethodName: string );
    procedure LeaveMethod( AInstance: TObject; const AMethodName: string );
    { Outcomes logging }
    procedure SilentError( const AMessage: string; const Args: array of const ); overload;
    procedure SilentError( const AMessage: string ); overload;
    procedure SilentWarning( const AMessage: string ); overload;
    procedure SilentWarning( const AMessage: string; const Args: array of const ); overload;
    procedure SilentSuccess( const AMessage: string ); overload;
    procedure SilentSuccess( const AMessage: string; const Args: array of const ); overload;
    { SQL Logging }
    procedure LogSqlQuery( const ASQL: string );
    procedure LogSqlCommand( const ASQL: string );
  protected
    { Property accessors }
    function Get_Count: Integer;
    function Get_Text: string;
    { Other methods }
    function ShowCounter( const AKey: cardinal ): cardinal; override;
    procedure Event( AMessage: string; const ALogType: TLogLevel = ltInfo ); overload; override;
    procedure IncrementShowCounter( const AKey: cardinal ); override;
    procedure ResetCounter( const AMessage: string );
  public
    { Initialization }
    constructor Create; override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    { Class members }
    class function GetFileNameSettings: string;
    { ILogMultiTarget }
    function TargetCount: Integer;
    procedure AddTarget( const ATarget: ILogItemTarget );
    procedure ClearAllTargets;
    { Other members }
    function TryGetItem( const AIndex: Integer; out AItem: IBasicLogItem ): boolean;
    procedure Clear;
    procedure SaveToFile( const AFileName: string );
    procedure SetUserFile( AIniFile: TIniFile );
    { Properties }
    property Count: Integer read Get_Count;
    property LogFolderPresent: boolean read fLogFolderPresent;
    property SaveToFileOnDestroy: boolean read fSaveToFileOnDestroy write fSaveToFileOnDestroy;
    property Text: string read Get_Text;
  end;

function GetLogFileName( const AExtraFileId: string = '' ): string;

const
  { IniFile settings }
  SECTION_GLOBAL = 'Global';
  KEY_MAXFILE    = 'MaxFile';
  KEY_FILENO     = 'FileNo';

implementation

uses
{$IFDEF MSWINDOWS}
  WinApi.Windows,
{$ENDIF}
  Emetra.CrossPlatform.User,
  Emetra.Logging.Target.TextFile,
  Emetra.Logging.Colors,
  Emetra.Logging.PlainText.LogItem,
  Emetra.Logging.Utilities,
  {Standard}
  System.IOUtils;

function GetLogFileName( const AExtraFileId: string = '' ): string;
const
  LOG_EXT = '.LOG';
var
  logDirectory: string;
  defaultDirectory: string;
  parentDirectory: string;
  fileName: string;
begin
  fileName := ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '-' + GetUserName + LOG_EXT );
  if AExtraFileId <> EmptyStr then
    fileName := StringReplace( fileName, LOG_EXT, '-' + AExtraFileId + LOG_EXT, [] );
  defaultDirectory := ExtractFilePath( ParamStr( 0 ) ) + 'LOGS\';
  parentDirectory := ExtractFilePath( ParamStr( 0 ) ) + '..\LOGS\';
  if not DirectoryExists( defaultDirectory ) and DirectoryExists( parentDirectory ) then
    logDirectory := parentDirectory
  else
    logDirectory := defaultDirectory;
  Result := TPath.GetFullPath( logDirectory ) + fileName;
end;

{$REGION 'Initialization'}

constructor TPlainTextLog.Create;
begin
  inherited;
  // Assert( InstanceCounter = 0 );
  inc( InstanceCounter );
  fCriticalSection := TCriticalSection.Create;
  fItems := TLogItemList.Create;
  Enabled := true;
end;

procedure TPlainTextLog.AfterConstruction;
begin
  inherited;
  { Default settings }
  fUserIniFile := nil; { Should already be nil }
  { Add first log entry before settings are read }
  fItems.Add( TLogItem.Create( 0, Format( 'Initializing Emetra.Logging.PlainText.pas: %s', [ParamStr( 0 )] ), ltInfo, mcFirstAndLastEntry ) );
  { Read settings and connect to log server }
  ReadLogSettings;
  SetDefaultFileName;
end;

procedure TPlainTextLog.BeforeDestruction;
begin
  fItems.Add( TLogItem.Create( fIndentLevel, 'Finalizing Emetra.Logging.PlainText.pas', ltInfo, mcFirstAndLastEntry ) );
  if fSaveToFileOnDestroy then
    try
      SaveToFile( GetStandardFileName );
    except
      on Exception do
        { Ignore exception at this point }
    end;
  inherited;
end;

destructor TPlainTextLog.Destroy;
begin
  dec( InstanceCounter );
  fCriticalSection.Free;
  fItems.Free;
  inherited;
end;

procedure TPlainTextLog.Clear;
begin
  fItems.Clear;
end;

procedure TPlainTextLog.ReadLogSettings;
const
  PROC_NAME       = 'ReadLogSettings';
  DEFAULT_MAXFILE = 10;
var
  logSettings: TIniFile;
  userIniSection: string;
  globalMaxFileCount: Integer;
  userMaxFileCount: Integer;
begin
  fLogFileNumber := 0;
  fLogFolderPresent := DirectoryExists( ExtractFilePath( GetFileNameSettings ) );
  if not fLogFolderPresent then
    SilentWarning( '%s.%s: Log folder missing, expected location: "%s"', [ClassName, PROC_NAME, ExtractFilePath( GetFileNameSettings )] )
  else
    try
      logSettings := TIniFile.Create( GetFileNameSettings );
      try
        userIniSection := GetUserName;
        globalMaxFileCount := logSettings.ReadInteger( SECTION_GLOBAL, KEY_MAXFILE, DEFAULT_MAXFILE );
        fLogFileNumber := logSettings.ReadInteger( userIniSection, KEY_FILENO, 0 );
        userMaxFileCount := logSettings.ReadInteger( userIniSection, KEY_MAXFILE, globalMaxFileCount );
        if fLogFileNumber >= userMaxFileCount then
          fLogFileNumber := 1
        else
          inc( fLogFileNumber );
        logSettings.WriteInteger( userIniSection, KEY_FILENO, fLogFileNumber );
      finally
        logSettings.Free;
      end;
    except
      on E: Exception do
        SilentWarning( '%s.%s: %s - %s', [ClassName, PROC_NAME, E.ClassName, E.Message] );
    end;
end;

{$ENDREGION}
{$REGION 'Property accessors'}

function TPlainTextLog.Get_Count;
begin
  Result := fItems.Count;
end;

function TPlainTextLog.Get_Text: string;
var
  n: Integer;
  textLines: TStringList;
begin
  fCriticalSection.Enter;
  try
    textLines := TStringList.Create;
    try
      n := 0;
      while n < fItems.Count do
      begin
        textLines.Add( DupeString( '  ', fItems[n].Indent ) + fItems[n].Text );
        inc( n );
      end;
      Result := textLines.Text;
    finally
      textLines.Free;
    end;
  finally
    fCriticalSection.Leave;
  end;
end;

{$ENDREGION}
{$REGION 'CallStack logging'}

procedure TPlainTextLog.EnterMethod( AInstance: TObject; const AMethodName: string );
begin
  fCriticalSection.Enter;
  try
    if MainThread and fLogCallStack then
    begin
      fItems.Add( TLogItem.Create( fIndentLevel, Format( '%s.%s: Enter', [AInstance.ClassName, AMethodName] ), ltInfo, mcCallStack, clCallStack ) );
      inc( fIndentLevel );
      if ( fIndentLevel <= MAX_NESTING ) and ( fIndentLevel >= 0 ) then
        fStopWatch[fIndentLevel] := TStopWatch.StartNew;
    end;
  finally
    fCriticalSection.Leave;
  end;
end;

procedure TPlainTextLog.LeaveMethod( AInstance: TObject; const AMethodName: string );
var
  msElapsed: Int64;
begin
  fCriticalSection.Enter;
  try
    if MainThread and fLogCallStack then
    begin
      if ( fIndentLevel <= MAX_NESTING ) and ( fIndentLevel >= 0 ) then
        msElapsed := fStopWatch[fIndentLevel].ElapsedMilliseconds
      else
        msElapsed := 0;
      dec( fIndentLevel );
      fItems.Add( TLogItem.Create( fIndentLevel, Format( '%s.%s: Leave ( %d ms )', [AInstance.ClassName, AMethodName, msElapsed] ), ltInfo, mcCallStack, clCallStack ) );
    end;
  finally
    fCriticalSection.Leave;
  end;
end;

{$ENDREGION}
{$REGION 'SQL Logging'}

procedure TPlainTextLog.LogSqlQuery( const ASQL: string );
begin
  fItems.Add( TLogItem.Create( fIndentLevel, ASQL, ltInfo, mcSqlQuery, clLogDefaultText ) );
end;

procedure TPlainTextLog.LogSqlCommand( const ASQL: string );
begin
  fItems.Add( TLogItem.Create( fIndentLevel, ASQL, ltInfo, mcSqlCommand, clLogDefaultText ) );
end;
{$ENDREGION}
{$REGION 'Outcomes logging'}

procedure TPlainTextLog.SilentSuccess( const AMessage: string );
begin
  fItems.Add( TLogItem.Create( fIndentLevel, AMessage, ltInfo, mcSilentSuccess ) );
end;

procedure TPlainTextLog.SilentSuccess( const AMessage: string; const Args: array of const );
begin
  fItems.Add( TLogItem.Create( fIndentLevel, Format( AMessage, Args ), ltInfo, mcSilentSuccess ) );
end;

procedure TPlainTextLog.SilentError( const AMessage: string );
begin
  fItems.Add( TLogItem.Create( fIndentLevel, AMessage, ltInfo, mcSilentError ) );
end;

procedure TPlainTextLog.SilentError( const AMessage: string; const Args: array of const );
begin
  fItems.Add( TLogItem.Create( fIndentLevel, Format( AMessage, Args ), ltInfo, mcSilentError ) );
end;

procedure TPlainTextLog.SilentWarning( const AMessage: string );
begin
  fItems.Add( TLogItem.Create( fIndentLevel, AMessage, ltInfo, mcSilentWarning ) );
end;

procedure TPlainTextLog.SilentWarning( const AMessage: string; const Args: array of const );
begin
  fItems.Add( TLogItem.Create( fIndentLevel, Format( AMessage, Args ), ltInfo, mcSilentWarning ) );
end;

{$ENDREGION}
{$REGION 'File names'}

class function TPlainTextLog.GetFileNameSettings: string;
begin
  Result := ExtractFilePath( ParamStr( 0 ) ) + 'LOGS\logging.ini'
end;

function TPlainTextLog.GetFileNameLog: string;
begin
  Result := GetLogFileName( Format( '%.3d', [fLogFileNumber] ) );
end;

function TPlainTextLog.GetStandardFileName: string;
begin
  Result := GetLogFileName;
end;

procedure TPlainTextLog.SetDefaultFileName;
var
  item: TLogItem;
  newTarget: ILogItemTarget;
begin
  newTarget := TLogWriter.Create( GetFileNameLog );
  { Save existing items }
  for item in fItems do
    newTarget.Send( item );
  { Add target to list }
  fItems.AddTarget( newTarget );
end;

{$ENDREGION}
{$REGION 'Newline handling'}

function TPlainTextLog.StripNewlines( const AMsg: string ): string;
begin
  Result := StringReplace( AMsg, #13#10, ' ', [rfReplaceAll] );
  Result := StringReplace( Result, '\n', ' ', [rfReplaceAll] );
end;

{$ENDREGION}
{$REGION 'Events without user interaction (except simple notifications).'}

procedure TPlainTextLog.Event( AMessage: string; const ALogType: TLogLevel );
var
  responseCode: Integer;
  dialogText: string;
begin
  fCriticalSection.Enter;
  try
    inc( fCallCounter );
    if ( ALogType >= Threshold ) then
    begin
      if Enabled then
        fItems.Add( TLogItem.Create( fIndentLevel, StripNewlines( AMessage ), ALogType ) );
      { Dialog box if needed }
      if not( ALogType >= ThresholdForDialog ) then
        SetDefaultResult
      else
      begin
        dialogText := PrepareForDialog( AMessage );
        if TMsgDlgBtn.mbNo in ButtonSet then
        begin
          responseCode := ShowCrossPlatformDialog( dialogText, ButtonSet, TMsgDlgBtn.mbYes, 0, ALogType );
          if ModalResult = mrCancel then
            raise EAbort.Create( 'CanceledByUser' );
        end
        else if TMsgDlgBtn.mbIgnore in ButtonSet then
          responseCode := ShowCrossPlatformDialog( dialogText, [TMsgDlgBtn.mbOk, TMsgDlgBtn.mbIgnore], TMsgDlgBtn.mbOk, 0, ALogType )
        else
          responseCode := ShowCrossPlatformDialog( dialogText, [TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk, 0, ALogType );
        Event( LOG_STUB + 'ResponseCode: %d', [ClassName, 'Event', responseCode] );
      end;
    end;
  finally
    fCriticalSection.Leave;
  end;
end;

procedure TPlainTextLog.Event( const AMessage: string; const Args: array of const; const ALogType: TLogLevel );
begin
  if ( ALogType < Threshold ) then
    exit
  else
    Event( Format( AMessage, Args ), ALogType );
end;
{$ENDREGION}
{$REGION 'Events with user interaction that involves choices'}

function TPlainTextLog.LogYesNo( const AMessage: string; const ALevel: TLogLevel = ltMessage; const ACancel: boolean = false ): boolean;
begin
  fCriticalSection.Enter;
  try
    Result := inherited LogYesNo( AMessage, ALevel, ACancel );
  finally
    fCriticalSection.Leave;
  end;
end;

function TPlainTextLog.MainThread: boolean;
begin
{$IFDEF MSWINDOWS}
  Result := ( WinApi.Windows.GetCurrentThreadId( ) = System.MainThreadID );
{$ELSE}
  Result := true;
{$ENDIF}
end;

{$ENDREGION}
{$REGION 'ILogMultiTarget'}

procedure TPlainTextLog.ClearAllTargets;
begin
  fItems.ClearAllTargets;
end;

procedure TPlainTextLog.AddTarget( const ATarget: ILogItemTarget );
begin
  fItems.AddTarget( ATarget );
  Event( '%s.AddTarget( %s )', [ClassName, TObject( ATarget ).ClassName] );
end;

function TPlainTextLog.TargetCount: Integer;
begin
  Result := fItems.TargetCount;
end;

{$ENDREGION}
{$REGION 'Counter for messages with Ignore button'}

const
  SECTION_MESSAGE = 'Message';

procedure TPlainTextLog.ResetCounter( const AMessage: string );
var
  key: cardinal;
  strKey: string;
begin
  key := HashMessage( AMessage );
  if Assigned( fUserIniFile ) then
  begin
    strKey := Format( 'MSG_%.8x', [key] );
    fUserIniFile.WriteInteger( SECTION_MESSAGE, strKey, 0 )
  end
  else
    inherited ResetCounter( AMessage );
end;

function TPlainTextLog.ShowCounter( const AKey: cardinal ): cardinal;
var
  strKey: string;
begin
  if Assigned( fUserIniFile ) then
  begin
    strKey := Format( 'MSG_%.8x', [AKey] );
    Result := fUserIniFile.ReadInteger( SECTION_MESSAGE, strKey, 0 )
  end
  else
    Result := inherited ShowCounter( AKey );
end;

procedure TPlainTextLog.IncrementShowCounter( const AKey: cardinal );
var
  numberOfTimesShownBefore: Integer;
  strKey: string;
begin
  numberOfTimesShownBefore := ShowCounter( AKey );
  if Assigned( fUserIniFile ) then
  begin
    strKey := Format( 'MSG_%.8x', [AKey] );
    fUserIniFile.WriteInteger( SECTION_MESSAGE, strKey, numberOfTimesShownBefore + 1 )
  end
  else
    inherited IncrementShowCounter( AKey );
end;

{$ENDREGION}

procedure TPlainTextLog.AddStrings( const ATitle: string; AStrings: TStrings );
var
  n: Integer;
begin
  fCriticalSection.Enter;
  try
    fItems.Add( TLogItem.Create( 0, ATitle, ltInfo ) );
    n := 0;
    while n < AStrings.Count do
    begin
      fItems.Add( TLogItem.Create( 0, AStrings[n], ltInfo ) );
      inc( n );
    end;
  finally
    fCriticalSection.Leave;
  end;
end;

procedure TPlainTextLog.SaveToFile( const AFileName: string );
var
  currItem: TLogItem;
  plainTextLines: TStringList;
begin
  fCriticalSection.Enter;
  try
    plainTextLines := TStringList.Create;
    try
      for currItem in fItems do
        plainTextLines.Add( currItem.PlainText );
      plainTextLines.SaveToFile( AFileName );
    finally
      plainTextLines.Free;
    end;
  finally
    fCriticalSection.Leave;
  end;
end;

procedure TPlainTextLog.SetUserFile( AIniFile: TIniFile );
begin
  fUserIniFile := AIniFile;
end;

function TPlainTextLog.TryGetItem( const AIndex: Integer; out AItem: IBasicLogItem ): boolean;
begin
  Result := ( AIndex > -1 ) and ( AIndex < fItems.Count );
  if Result then
    AItem := fItems[AIndex];
end;

initialization

GlobalLog := TPlainTextLog.Create;

finalization

GlobalLog := nil;

end.

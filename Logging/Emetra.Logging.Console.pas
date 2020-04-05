unit Emetra.Logging.Console;

interface

uses
  System.UITypes,
  Emetra.Logging.Interfaces,
  {Standard}
  Classes;

type

  TConsoleLogger = class( TInterfacedPersistent, ILog, ILogXmlData )
  private
    FLogCallStack: boolean;
    FThreshold: TLogLevel;
    FThresholdForDialog: TLogLevel;
    FIndent: integer;
    FEnabled: boolean;
    FCounter: integer;
    fModalResult: integer;
  protected
    { Accessors }
    function Get_Count: integer;
    function Get_Enabled: boolean;
    function Get_ModalResult: integer;
    function Get_Threshold: TLogLevel;
    function Get_ThresholdForDialog: TLogLevel;
    function Get_LogCallStack: boolean;
    procedure Set_Threshold( ALevel: TLogLevel );
    procedure Set_ThresholdForDialog( ALevel: TLogLevel );
    procedure Set_LogCallStack( const AValue: boolean );
    procedure Set_Enabled( const AValue: boolean );
    procedure ResetCounter( const AMessage: string );
  public
    function GetStandardFileName: string;
    function LogYesNo( const s: string; const ALevel: TLogLevel = ltMessage; const ACancel: boolean = false ): boolean;
    procedure AddStrings( const ATitle: string; AStrings: TStrings );
    procedure Event( const s: string; const AParams: array of const; const ALogLevel: TLogLevel = ltInfo ); overload;
    procedure Event( s: string; const ALogLevel: TLogLevel = ltInfo ); overload;
    procedure EventColor( const AColor: TColor; const s: string ); overload;
    procedure EventColor( const AColor: TColor; const s: string; const AParams: array of const ); overload;
    procedure EnterMethod( AInstance: TObject; const AMethodName: string );
    procedure LeaveMethod( AInstance: TObject; const AMethodName: string );
    procedure LogSqlCommand( const ASQL: string );
    procedure LogSqlQuery( const ASQL: string );
    procedure LogXmlData( const ALogLevel: TLogLevel; const ATitle: UnicodeString; const AXmlData: UnicodeString );
    procedure SilentError( const AErrorMessage: string ); overload;
    procedure SilentWarning( const AWarningMessage: string ); overload;
    procedure SilentSuccess( const ASuccessMessage: string ); overload;
    procedure SilentError( const AErrorMessage: string; const AParams: array of const ); overload;
    procedure SilentWarning( const AWarningMessage: string; const AParams: array of const ); overload;
    procedure SilentSuccess( const ASuccessMessage: string; const AParams: array of const ); overload;
    procedure SetFilename( const AFileName: string; const AAppend: boolean = false );
    procedure SetItems( AItem: TStrings );
    procedure ShowMessage( const AMessage: string; const ALevel: TLogLevel = ltMessage; const AMaxTimes: cardinal = maxint );
    procedure Reset;
    { Properties }
    property Enabled: boolean read Get_Enabled write Set_Enabled;
    property ModalResult: integer read Get_ModalResult;
    property Threshold: TLogLevel read Get_Threshold write Set_Threshold;
    property ThresholdForDialog: TLogLevel read Get_ThresholdForDialog write Set_ThresholdForDialog;
    property LogCallStack: boolean read Get_LogCallStack write Set_LogCallStack;
  end;

implementation

uses
  Emetra.Logging.Utilities,
  System.SysUtils, System.StrUtils;

var
  ConsoleLogger: TConsoleLogger;

  { TConsoleLogger }

procedure TConsoleLogger.AddStrings( const ATitle: string; AStrings: TStrings );
begin
  WriteLn( ATitle );
  WriteLn( AStrings.Text );
end;

procedure TConsoleLogger.EnterMethod( AInstance: TObject; const AMethodName: string );
begin
  if FLogCallStack then
  begin
    Event( '>>' + AInstance.ClassName + '.' + AMethodName );
    inc( FIndent );
  end;
end;

procedure TConsoleLogger.Event( s: string; const ALogLevel: TLogLevel );
begin
  inc( FCounter );
  if FEnabled and ( ALogLevel >= FThreshold ) then
  begin
    if FLogCallStack then
      write( DupeString( ' ', FIndent ) );
    WriteLn( s );
  end;
end;

procedure TConsoleLogger.EventColor( const AColor: TColor; const s: string );
begin
  Event( s );
end;

procedure TConsoleLogger.EventColor( const AColor: TColor; const s: string; const AParams: array of const );
begin
  Event( s, AParams );
end;

procedure TConsoleLogger.Event( const s: string; const AParams: array of const; const ALogLevel: TLogLevel );
begin
  Event( Format( s, AParams ), ALogLevel );
end;

function TConsoleLogger.Get_Count: integer;
begin
  Result := FCounter;
end;

function TConsoleLogger.Get_Enabled: boolean;
begin
  Result := FEnabled;
end;

function TConsoleLogger.Get_LogCallStack: boolean;
begin
  Result := FLogCallStack;
end;

function TConsoleLogger.Get_ModalResult: integer;
begin
  Result := fModalResult;
end;

function TConsoleLogger.Get_Threshold: TLogLevel;
begin
  Result := FThreshold;
end;

function TConsoleLogger.Get_ThresholdForDialog: TLogLevel;
begin
  Result := FThresholdForDialog;
end;

procedure TConsoleLogger.LeaveMethod( AInstance: TObject; const AMethodName: string );
begin
  if FLogCallStack then
  begin
    Event( '<<' + AInstance.ClassName + '.' + AMethodName );
    if FIndent > 0 then
      dec( FIndent );
  end;
end;

procedure TConsoleLogger.LogSqlCommand( const ASQL: string );
begin
  WriteLn( 'SQLCMD: ', ASQL );
end;

procedure TConsoleLogger.LogSqlQuery( const ASQL: string );
begin
  WriteLn( 'SQLQRY: ', ASQL );
end;

procedure TConsoleLogger.LogXmlData( const ALogLevel: TLogLevel; const ATitle, AXmlData: UnicodeString );
begin
  if ALogLevel >= FThreshold then
  begin
    WriteLn( ATitle );
    WriteLn( AXmlData );
  end;
end;

function TConsoleLogger.LogYesNo( const s: string; const ALevel: TLogLevel; const ACancel: boolean ): boolean;
var
  answer: string;
  hint: string;
begin
  hint := ' (Yes/No';
  if ACancel then
    hint := hint + '/Abort';
  hint := hint + '):';
  write( PrepareForDialog( s ), hint );
  ReadLn( answer );
  answer := Copy( answer, 1, 1 );
  if ACancel and SameText( answer, 'A' ) then
    raise EAbort.Create( 'Aborted by user' );
  Result := SameText( answer, 'y' );
  if SameText( answer, 'y' ) then
    fModalResult := mrYes
  else if SameText( answer, 'n' ) then
    fModalResult := mrNo;
end;

procedure TConsoleLogger.Reset;
begin
  { Does nothing }
end;

procedure TConsoleLogger.ResetCounter( const AMessage: string );
begin
  { Does nothing here, resets counter for number of times a message has been shown }
end;

procedure TConsoleLogger.SetFilename( const AFileName: string; const AAppend: boolean );
begin
  { Does nothing }
end;

procedure TConsoleLogger.SetItems( AItem: TStrings );
begin
  { Not implemented }
end;

procedure TConsoleLogger.Set_Enabled( const AValue: boolean );
begin
  FEnabled := AValue;
end;

procedure TConsoleLogger.Set_LogCallStack( const AValue: boolean );
begin
  FLogCallStack := AValue;
end;

procedure TConsoleLogger.Set_Threshold( ALevel: TLogLevel );
begin
  FThreshold := ALevel;
end;

procedure TConsoleLogger.Set_ThresholdForDialog( ALevel: TLogLevel );
begin
  FThresholdForDialog := ALevel;
end;

procedure TConsoleLogger.ShowMessage( const AMessage: string; const ALevel: TLogLevel; const AMaxTimes: cardinal );
begin
  Write( PrepareForDialog( AMessage ), ' (Press any key to continue): ' );
  ReadLn;
end;

procedure TConsoleLogger.SilentError( const AErrorMessage: string );
begin
  Event( 'ERROR: %s', [AErrorMessage] );
end;

procedure TConsoleLogger.SilentWarning( const AWarningMessage: string );
begin
  Event( 'WARNING: %s', [AWarningMessage] );
end;

function TConsoleLogger.GetStandardFileName: string;
begin
  Result := 'CON';
end;

procedure TConsoleLogger.SilentSuccess( const ASuccessMessage: string );
begin
  Event( 'SUCCESS: %s', [ASuccessMessage] );
end;

procedure TConsoleLogger.SilentError( const AErrorMessage: string; const AParams: array of const );
begin
  SilentError( Format( AErrorMessage, AParams ) );
end;

procedure TConsoleLogger.SilentSuccess( const ASuccessMessage: string; const AParams: array of const );
begin
  SilentSuccess( Format( ASuccessMessage, AParams ) );
end;

procedure TConsoleLogger.SilentWarning( const AWarningMessage: string; const AParams: array of const );
begin
  SilentWarning( Format( AWarningMessage, AParams ) );
end;

initialization

ConsoleLogger := TConsoleLogger.Create;
ConsoleLogger.Enabled := true;
GlobalLog := ConsoleLogger;

finalization

GlobalLog := nil;
FreeAndNil( ConsoleLogger );

end.

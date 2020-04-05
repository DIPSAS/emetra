/// <summary>
///   This unit defines an interface that allows applications to log to several
///   loggers, internal (Console, Text files, Log windows) or external
///   (SmartInspect, GrayLog) through a common interface, allowing different
///   loggers to be used for logger-agnostic clients. Usually the same logger
///   is used throughout an application, and the GlobalLogger variable can be
///   set and and used by the clients.
/// </summary>
/// <seealso cref="GlobalLogger">
///   GlobalLogger
/// </seealso>
unit Emetra.Logging.Interfaces;

interface

uses
  System.UITypes,
  System.Classes;

const
  /// <summary>
  ///   When logging, it is a good practice to include the class and the method
  ///   where the log was produced. Include these constants at the start of the
  ///   log message to use a common template to support this practice.
  /// </summary>
  LOG_STUB = '%s.%s: ';
  LOG_STUB_INTEGER = '%s.%s(%d): ';
  LOG_STUB_STRING  = '%s.%s(%s): ';

{$REGION 'Documentation'}
  /// <summary>
  /// Use color ring with base value FFD5D5.  Variation "More Saturated",
  /// Segments 6, Rings 3.
  /// </summary>
{$ENDREGION}

type
  /// <remarks>
  ///   By using the LogYesNo method, the user is allowed to select two
  ///   different paths of execution based on a log event, and the single OK
  ///   button mentioned above is replaced by 2-3 buttons.
  /// </remarks>
  /// <seealso cref="LogYesNo">
  ///   LogYesNo
  /// </seealso>
  TLogLevel = (
    /// <summary>
    ///   The lowest severity, normally not logged in production.
    /// </summary>
    ltDebug,
    /// <summary>
    ///   Informational log entry that should be logged during normal
    ///   executions in production.
    /// </summary>
    ltInfo,
    /// <summary>
    ///   Informational, but with an alert to the user that typicall has single
    ///   OK button to click.
    /// </summary>
    ltMessage,
    /// <summary>
    ///   Will typically alert the user with a dialog with a yellow warning
    ///   icon and a single OK button to click,
    /// </summary>
    ltWarning,
    /// <summary>
    ///   Typical response is to make a users aware of the problem through an
    ///   error dialog with a red text or "stop" icon.
    /// </summary>
    ltError,
    /// <summary>
    ///   The highest severity, a typical response is to show a message to the
    ///   user and terminate the application.
    /// </summary>
    ltCritical );

  ILog = interface( IInterface )
    [ '{C006C5A5-3041-408C-8225-5E852931EDC1}' ]
    { Accessors }
    function Get_Count: integer;
    function Get_Enabled: boolean;
    function Get_LogCallStack: boolean;
    function Get_ModalResult: integer;
    function Get_Threshold: TLogLevel;
    function Get_ThresholdForDialog: TLogLevel;
    procedure Set_LogCallStack( const AValue: boolean );
    procedure Set_Threshold( ALevel: TLogLevel );
    procedure Set_ThresholdForDialog( ALevel: TLogLevel );
    procedure Set_Enabled( const AValue: boolean );
    { Other members }
    function LogYesNo( const s: string; const ALevel: TLogLevel = ltMessage; const ACancel: boolean = false ): boolean;
    function GetStandardFileName: string;
    procedure ResetCounter( const AMessage: string );
    procedure LogSqlQuery( const ASQL: string );
    procedure LogSqlCommand( const ASQL: string );
    procedure EnterMethod( AInstance: TObject; const AMethodName: string );
    procedure LeaveMethod( AInstance: TObject; const AMethodName: string );
    procedure AddStrings( const ATitle: string; AStrings: TStrings );
    procedure Event( const s: string; const AParams: array of const; const ALogLevel: TLogLevel = ltInfo ); overload;
    procedure Event( s: string; const ALogLevel: TLogLevel = ltInfo ); overload;
    procedure SilentError( const s: string ); overload;
    procedure SilentError( const s: string; const AParams: array of const ); overload;
    procedure SilentWarning( const s: string ); overload;
    procedure SilentWarning( const s: string; const AParams: array of const ); overload;
    procedure SilentSuccess( const s: string ); overload;
    procedure SilentSuccess( const s: string; const AParams: array of const ); overload;
    procedure ShowMessage( const AMessage: string; const ALevel: TLogLevel = ltMessage;
      const AMaxTimes: cardinal = maxint );
    { Properties }
    /// <summary>
    ///   The number of messages that has been sent to the log.
    /// </summary>
    property Count: integer read Get_Count;
    /// <summary>
    ///   Can be set to false to stop messages from appearing in the log.
    ///   Messages may still be sent, but they are simply ignored by the
    ///   logger.
    /// </summary>
    property Enabled: boolean read Get_Enabled write Set_Enabled;
    property LogCallStack: boolean read Get_LogCallStack write Set_LogCallStack;
    property ModalResult: integer read Get_ModalResult;
    property Threshold: TLogLevel read Get_Threshold write Set_Threshold;
    property ThresholdForDialog: TLogLevel read Get_ThresholdForDialog write Set_ThresholdForDialog;
  end;

  ILogXmlData = interface
    [ '{F3904ABE-673E-4405-AC79-506F518BE8C4}' ]
    procedure LogXmlData( const ALevel: TLogLevel; const ATitle, AXmlData: string );
  end;

const
  ltTrivialInfo           = ltDebug;
  ltException             = ltError;
  PROC_DESTROY            = 'Destroy';
  PROC_FORM_DESTROY       = 'FormDestroy';
  PROC_FORM_CREATE        = 'FormCreate';
  PROC_BEFORE_DESTRUCTION = 'BeforeDestruction';

resourcestring

  MSG_SUFFIX_CONTACT_SUPPORT  = '\nTa et skjermbilde og send til fasttrak@dips.no.';
  MSG_SUFFIX_CONTACT_SUPPORT_LOCAL = '\nNoter meldingen og kontakt systemansvarlig.';

CONST
  EXC_INTERFACE_UNASSIGNED = 'The interface %s is not assigned.';

var
  GlobalLog: ILog = nil;

procedure NilCheck( const AName: string; AInterface: IInterface );

implementation

uses
  SysUtils;

procedure NilCheck( const AName: string; AInterface: IInterface );
begin
  if not Assigned( AInterface ) then
    raise EArgumentNilException.CreateFmt( EXC_INTERFACE_UNASSIGNED, [ AName ] );
end;

end.

/// <summary>
///   This unit defines an interface that allows applications to log to several
///   loggers, internal (Console, Text files, Log windows) or external ( <see href="https://www.gurock.com/smartinspect">
///   SmartInspect</see>, <see href="https://www.graylog.org/">GrayLog</see>)
///   through a common interface, allowing different loggers to be used for
///   logger-agnostic clients. Usually the same logger is used throughout an
///   application, and the GlobalLogger variable can be set and and used by the
///   clients.
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
  /// When logging, it is a good practice to include the class and the method
  /// where the log was produced. Include these constants at the start of the
  /// log message to use a common template to support this practice.
  /// </summary>
  LOG_STUB         = '%s.%s: ';
  LOG_STUB_INTEGER = '%s.%s(%d): ';
  LOG_STUB_STRING  = '%s.%s(%s): ';

  { Some commonly used procedure names }

  PROC_DESTROY            = 'Destroy';
  PROC_FORM_DESTROY       = 'FormDestroy';
  PROC_FORM_CREATE        = 'FormCreate';
  PROC_AFTER_CONSTRUCTION = 'AfterConstruction';
  PROC_BEFORE_DESTRUCTION = 'BeforeDestruction';
  LOG_STUB_INTx2 = '%s.%s(%d,%d): ';

{$REGION 'Documentation'}
  /// <summary>
  /// Use color ring with base value FFD5D5.  Variation "More Saturated",
  /// Segments 6, Rings 3.
  /// </summary>
{$ENDREGION}

type
  /// <remarks>
  /// By using the LogYesNo method, the user is allowed to select two
  /// different paths of execution based on a log event, and the single OK
  /// button mentioned above is replaced by 2-3 buttons.
  /// </remarks>
  /// <seealso cref="LogYesNo">
  /// LogYesNo
  /// </seealso>
  TLogLevel = (
    /// <summary>
    /// The lowest severity, normally not logged in production.
    /// </summary>
    ltDebug,
    /// <summary>
    /// Informational log entry that should be logged during normal
    /// executions in production.
    /// </summary>
    ltInfo,
    /// <summary>
    /// Informational, but with an alert to the user that typicall has single
    /// OK button to click.
    /// </summary>
    ltMessage,
    /// <summary>
    /// Will typically alert the user with a dialog with a yellow warning
    /// icon and a single OK button to click,
    /// </summary>
    ltWarning,
    /// <summary>
    /// Typical response is to make a users aware of the problem through an
    /// error dialog with a red text or "stop" icon.
    /// </summary>
    ltError,
    /// <summary>
    /// The highest severity, a typical response is to show a message to the
    /// user and terminate the application.
    /// </summary>
    ltCritical );

  ILog = interface( IInterface )
    ['{C006C5A5-3041-408C-8225-5E852931EDC1}']
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
    /// <summary>
    /// Allows a logger implementation to suggest a filename to be used when
    /// saving the log to file, based on that logger's preferences and
    /// conventions.
    /// </summary>
    function GetStandardFileName: string;
    /// <summary>
    /// Resets the log counter. Depending on the implementation, this may
    /// also reset the actual log. Some logs can not be reset, as the log
    /// messages may already be in some faraway place like Splunk og Graylog.
    /// </summary>
    /// <param name="AMessage">
    /// A message to include as the first after the reset, typically
    /// information that the log has been reset.
    /// </param>
    procedure ResetCounter( const AMessage: string );
    procedure LogSqlQuery( const ASQL: string );
    /// <summary>
    /// Allows a call the the database to be handled in a custom way in the
    /// logg, e.g. by highlighting it with a certain color or sending it to a
    /// separate stream.
    /// </summary>
    procedure LogSqlCommand( const ASQL: string );
    /// <summary>
    /// Can be used as on easy way to log the call stack. Start your method
    /// with EnterMethod and call LeaveMethod at the end.
    /// </summary>
    /// <param name="AInstance">
    /// The object thas has the method in AMethodName.
    /// </param>
    /// <param name="AMethodName">
    /// The name of the method that you are entering.
    /// </param>
    /// <remarks>
    /// Make sure to use a try/finally block when using these methods, and
    /// also make sure that there are no exit statments between them. This
    /// would bypass the LeaveMethod call, and could case the indentation to
    /// fail in a viewer.
    /// </remarks>
    procedure EnterMethod( AInstance: TObject; const AMethodName: string );
    /// <summary>
    /// To be used together with EnterMethod.
    /// </summary>
    procedure LeaveMethod( AInstance: TObject; const AMethodName: string );
    /// <summary>
    /// Lets the client write a TStrings object to the log in a way that
    /// separarates the as a single object, instead of just writing them as
    /// individual messages to the log.
    /// </summary>
    /// <param name="ATitle">
    /// A caption describing AStrings
    /// </param>
    /// <param name="AStrings">
    /// The data you want to save to the log.
    /// </param>
    procedure AddStrings( const ATitle: string; AStrings: TStrings );
    /// <summary>
    ///   The most generic log events. Most other log events actually call this
    ///   method with a predefined set of parameters.
    /// </summary>
    /// <param name="s">
    ///   The log message in a format that is identical to that of FormatStr i
    ///   Delphi.
    /// </param>
    /// <param name="AParams">
    ///   Arguments to the format string in s.
    /// </param>
    /// <param name="ALogLevel">
    ///   The level for this log event.
    /// </param>
    procedure Event( const s: string; const AParams: array of const; const ALogLevel: TLogLevel = ltInfo ); overload;
    procedure Event( s: string; const ALogLevel: TLogLevel = ltInfo ); overload;
    /// <summary>
    /// Overloaded version of SilentError.
    /// </summary>
    /// <param name="s">
    /// The log message.
    /// </param>
    procedure SilentError( const s: string ); overload;
    /// <summary>
    /// Custom version of Event that allows the implementation to highlight
    /// the event in a way that makes it easy to find (e.g. pink background).
    /// The log level is always ltInformation.
    /// </summary>
    procedure SilentError( const s: string; const AParams: array of const ); overload;
    /// <summary>
    /// Overloaded version of SilentWarning.
    /// </summary>
    procedure SilentWarning( const s: string ); overload;
    /// <summary>
    /// Custom version of Event that allows the implementation to highlight
    /// the event in a way that makes it easy to find. The log level is
    /// always ltInformation.
    /// </summary>
    procedure SilentWarning( const s: string; const AParams: array of const ); overload;
    /// <summary>
    /// Overloaded version of SilentSuccess that doesn't take any parameters.
    /// </summary>
    procedure SilentSuccess( const s: string ); overload;
    /// <summary>
    /// Custom version of Event that allows the implementation to highlight
    /// the event in a way that makes it easy to find. The log level is
    /// always ltInformation.
    /// </summary>
    procedure SilentSuccess( const s: string; const AParams: array of const ); overload;
    /// <summary>
    ///   Prompts the user by displaying a dialog with important information.
    /// </summary>
    /// <param name="AMessage">
    ///   THe message itself.
    /// </param>
    /// <param name="ALevel">
    ///   The level to use in the log.
    /// </param>
    /// <param name="AMaxTimes">
    ///   Maximum number of times to show this message.
    /// </param>
    /// <remarks>
    ///   The implementation decides how to handle the AMaxTimes parameter. It
    ///   can be counted per application run og as a global counter for the
    ///   user across runs.
    /// </remarks>
    procedure ShowMessage( const AMessage: string; const ALevel: TLogLevel = ltMessage; const AMaxTimes: cardinal = maxint );
    { Properties }
    /// <summary>
    /// The number of messages that has been sent to the log.
    /// </summary>
    property Count: integer read Get_Count;
    /// <summary>
    /// Can be set to false to stop messages from appearing in the log.
    /// Messages may still be sent, but they are simply ignored by the
    /// logger.
    /// </summary>
    property Enabled: boolean read Get_Enabled write Set_Enabled;
    /// <summary>
    /// If set to true, <b>EnterMethod</b> and <b>LeaveMethod</b> will write
    /// entries to the log. When set to false, messages of this type will be
    /// ignored by the logger. In production, this is usually set to <b>False</b>
    /// . When debugging, set to true.
    /// </summary>
    property LogCallStack: boolean read Get_LogCallStack write Set_LogCallStack;
    property ModalResult: integer read Get_ModalResult;
    /// <summary>
    /// Sets a threshold for logging, where events below this level will
    /// actually not be written to the log. Default will usually be
    /// ltInformation, but that could depend on the implementation.
    /// </summary>
    property Threshold: TLogLevel read Get_Threshold write Set_Threshold;
    /// <summary>
    /// Allows the client to change the treshold before the uses is alerted.
    /// The default will usually be ltMessage, but for command line utilities
    /// it can be useful to raise it to ltError.
    /// </summary>
    property ThresholdForDialog: TLogLevel read Get_ThresholdForDialog write Set_ThresholdForDialog;
  end;

  ILogXmlData = interface
    ['{F3904ABE-673E-4405-AC79-506F518BE8C4}']
    procedure LogXmlData( const ALevel: TLogLevel; const ATitle, AXmlData: string );
  end;

const
  ltTrivialInfo = ltDebug;
  ltException   = ltError;

resourcestring

  MSG_SUFFIX_CONTACT_SUPPORT = '\nTa et skjermbilde og send til fasttrak@dips.no.';
  MSG_SUFFIX_CONTACT_SUPPORT_LOCAL = '\nNoter meldingen og kontakt lokal systemansvarlig.';

const
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
    raise EArgumentNilException.CreateFmt( EXC_INTERFACE_UNASSIGNED, [AName] );
end;

end.

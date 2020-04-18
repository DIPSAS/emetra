/// <summary>
/// The <see href="https://en.wikipedia.org/wiki/Mediator_pattern">Mediator
/// pattern</see> is a way to let objects interact without any direct
/// coupling. Inside FastTrak it is used for a number of purposes. The <see href="https://en.wikipedia.org/wiki/Command_pattern">
/// Command pattern</see> is a way to encapsulate the information needed to
/// perform an action. In this class, that includes the Receiver (or in this
/// case, a pseudonym for the object) upon with the command will be
/// performed.
/// </summary>
/// <remarks>
/// Some key concepts are
/// <list type="bullet">
/// <item>
/// CommandName - Key element, define what the action is and who
/// receives it.
/// </item>
/// <item>
/// Command - An instruction to perform some action. It contains
/// parameters that define the action, as well as the name of the
/// action itself. The command name
/// </item>
/// <item>
/// Receiver - Can accept one or more commands, in technical terms
/// implementing the ICommandReceiver interface.
/// </item>
/// <item>
/// Mediator - Accepts registration from Receivers for specific
/// commands that they want to handle.
/// </item>
/// </list>
/// <br /><br /><br />
/// </remarks>
/// <seealso cref="TCommand" />
unit Emetra.Command.Mediator;

interface

uses
  {Third party}
  Spring.Collections,
  {General classes}
  Emetra.Business.BaseClass,
  {General interfaces}
  Emetra.Command.Interfaces,
  {Standard}
  System.Classes, System.SysUtils;

type
{$REGION 'Readability types'}
  /// <summary>
  /// The type is declared to improve the readability of the code.
  /// </summary>
  TCommandName = string;
  /// <summary>
  /// The type is declared to improve the readability of the code.
  /// </summary>
  TReceiver = TObject;
  /// <summary>
  /// The type is declared to improve the readability of the code.
  /// </summary>
  TReceiverDictionary = IDictionary<string, TReceiver>;
{$ENDREGION}
  /// <remarks>
  /// The TCommandMediator derives from TCustomBusiness. This s a
  /// TInterfacedPersistent derived class that includes logging. It can be accessed through an
  /// interface or as an instance. It should not be freed until its clients are
  /// freed.
  /// </remarks>
  /// <example>
  /// When a user clicks a link inside a web view, they are not immediately
  /// taken to the link. Instead, the process is interrupted, and the URL
  /// that was clicked is inspected by an event handler. Based on the format
  /// of the link, the control flow can be redirected. This is done by
  /// converting the link into a command. This command is then passed to a
  /// command mediator, which decides where to send it. This will typically
  /// be to some object that has RegisterAsCommandReceiver with the command mediator.
  /// </example>

  TCommandMediator = class( TCustomBusiness, ICommandMediator, ICommandReceiver )
  strict private
    fRegisteredCommandHandlers: TReceiverDictionary;
    fRaiseExceptionIfTargetNotFound: boolean;
  private
    /// <param name="ATargetObject">
    /// The object upon which the method will be invoked.
    /// </param>
    /// <param name="AMethodParameters">
    /// This an ICommand with Invokable property is set to true. The number,
    /// order and type of parameters must match that of the method.
    /// </param>
    /// <remarks>
    /// This object doesn't have to implement ICommandReceiver. By using RTTI,
    /// all objects can be receievers as long has they have published methods.
    /// </remarks>
    function InvokePublishedMethod( const AReceiver: TReceiver; const AInvokableCommand: ICommand ): boolean;
    /// <summary>
    /// Used internally to find a receiver for a command.
    /// </summary>
    /// <param name="AName">
    /// The command name or receiver name.
    /// </param>
    /// <param name="AObject">
    /// The receiver object.
    /// </param>
    /// <returns>
    /// Returns true if the receiver was found.
    /// </returns>
    function FindReceiver( const AName: TCommandName; out AObject: TReceiver ): boolean;
  public
    { Initialization }
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    { Other methods }
    /// <param name="ACommand">
    /// The command to pass on to a RegisterAsCommandReceiver handler.
    /// </param>
    /// <returns>
    /// The return value indicates whether this command was successfully
    /// executed. The definition of success is the responsibility of the
    /// RegisterAsCommandReceiver handler.
    /// </returns>
    /// <remarks>
    /// Exceptions thrown in the handler may or may not be handled there. If
    /// an error occurs and the method returns false, it is normally the
    /// handler's responsibility to take necessary steps to log the failed
    /// attempt. The client that issued the command may also do so.
    /// </remarks>
    function ExecuteCmd( const ACommand: ICommand ): boolean; overload;
    /// <param name="ACommand">
    /// Containts all information about the method, including the target
    /// object.
    /// </param>
    function InvokeMethod( const ACommand: ICommand ): boolean;
    /// <param name="AName">
    /// The name to use in the dictionary, allows other
    /// </param>
    /// <param name="AHandledByThisObject">
    /// The object that will handle commands of this type, or the
    /// </param>
    /// <remarks>
    /// The same object can RegisterAsCommandReceiverAsReceiver under any number of names. However, more
    /// than one object can not RegisterAsCommandReceiverAsReceiver under the same name. This will give
    /// an exception and a runtime error.
    /// </remarks>
    procedure RegisterReceiver( const ACommandName: TCommandName; AReceiver: TReceiver );
    { Properties }
    /// <summary>
    /// When a Invokable command (one that applies directly to the object
    /// itself) is unable to find a matching object to operate upon, it can
    /// either fail silently or raise an exception based on this property.
    /// </summary>
    /// <example>
    /// If you send a command to a database connection, say a stored
    /// procedure, the object than created this message may not only want to
    /// know that it failed, but also make sure that further processing
    /// stops. However, in a situation where it matters less (say logging to
    /// multiple log providers), you may not care that much.
    /// </example>
    /// <seealso cref="Emetra.Command.Mediator|ETargetObjectNotFound" />
    property RaiseExceptionIfTargetNotFound: boolean read fRaiseExceptionIfTargetNotFound write fRaiseExceptionIfTargetNotFound;
  end;

implementation

uses
  {General interfaces}
  Emetra.Logging.Interfaces,
  {Standard units}
  System.Rtti, System.TypInfo;

const
  EXC_METHOD_VISIBILITY_TOO_LOW  = 'The method "%s" exists on the receiver (%s), but is not published and cannot be invoked (by design).';
  EXC_COMMAND_RECEIVER_NOT_FOUND = '%s.%s(%s): Failed to locate receiver for "%s"';

const
  LOG_CLASS_METHOD = '%s.%s: ';
  LOG_STUB_COMMAND = '%s.%s(%s): Command "%s" ';

{$REGION 'Initialization'}

procedure TCommandMediator.AfterConstruction;
begin
  inherited;
  fRegisteredCommandHandlers := Spring.Collections.TCollections.CreateDictionary<string, TReceiver>;
end;

procedure TCommandMediator.BeforeDestruction;
begin
  fRegisteredCommandHandlers := nil;
  inherited;
end;

procedure TCommandMediator.RegisterReceiver( const ACommandName: TCommandName; AReceiver: TReceiver );
const
  PROC_NAME = 'RegisterReceiver';
const
  LOG_REGISTERED_NOW        = LOG_STUB_COMMAND + 'handled by %s.';
  LOG_REGISTERED_BEFORE     = LOG_STUB_COMMAND + 'registered by %s before.';
  LOG_REGISTRATION_CONFLICT = LOG_STUB_COMMAND + 'already handled by %s.';
var
  upperCasedCommand: string;
  existingReceiver: TReceiver;
begin
  upperCasedCommand := AnsiUppercase( ACommandName );
  if fRegisteredCommandHandlers.TryGetValue( upperCasedCommand, existingReceiver ) then
  begin
    if existingReceiver = AReceiver then
      Log.Event( LOG_REGISTERED_BEFORE, [ClassName, PROC_NAME, AReceiver.ClassName, ACommandName, existingReceiver.ClassName], ltDebug )
    else
      Log.Event( LOG_REGISTRATION_CONFLICT, [ClassName, PROC_NAME, AReceiver.ClassName, ACommandName, existingReceiver.ClassName], ltError )
  end
  else
  begin
    fRegisteredCommandHandlers.Add( upperCasedCommand, AReceiver );
    Log.Event( LOG_REGISTERED_NOW, [ClassName, PROC_NAME, AReceiver.ClassName, ACommandName, AReceiver.ClassName] );
  end;
end;

{$ENDREGION}

function TCommandMediator.FindReceiver( const AName: string; out AObject: TReceiver ): boolean;
begin
  Result := fRegisteredCommandHandlers.TryGetValue( AnsiUppercase( AName ), AObject );
end;

function TCommandMediator.ExecuteCmd( const ACommand: ICommand ): boolean;
const
  PROC_NAME              = 'ExecuteCmd';
  WARN_UNHANDLED_COMMAND = LOG_CLASS_METHOD + 'No modules in the system responded to this command: "%s"';
var
  receiverObject: TObject;
  receiverInterface: ICommandReceiver;
begin
  Result := false;
  Log.EnterMethod( Self, Format( '%s("%s"): %s', [PROC_NAME, ACommand.Name, ACommand.CommaText] ) );
  try
    if ACommand.Invokable and FindReceiver( ACommand.Receiver, receiverObject ) then
      Result := InvokePublishedMethod( receiverObject, ACommand )
    else if not FindReceiver( ACommand.Name, receiverObject ) then
      Log.SilentError( WARN_UNHANDLED_COMMAND, [ClassName, PROC_NAME, ACommand.Name] )
    else if Supports( receiverObject, ICommandReceiver, receiverInterface ) then
      try
        Result := receiverInterface.ExecuteCmd( ACommand );
      except
        on E: Exception do
          Log.SilentError( E.Message )
      end;
  finally
    Log.LeaveMethod( Self, PROC_NAME );
  end;
end;

function TCommandMediator.InvokePublishedMethod( const AReceiver: TReceiver; const AInvokableCommand: ICommand ): boolean;
const
  PROC_NAME = 'ExecutePublishedMethod';
var
  n: integer;
  contextMethod: TRttiMethod;
  contextType: TRttiType;
  context: TRttiContext;
  methodParameters: array of TValue;
begin
  Result := false;
  Log.EnterMethod( Self, Format( '%s(%s,%s)', [PROC_NAME, AReceiver.ClassName, AInvokableCommand.Name] ) );
  try
    context := TRttiContext.Create;
    contextType := context.GetType( AReceiver.ClassType );
    if Assigned( contextType ) then
    begin
      contextMethod := contextType.GetMethod( AInvokableCommand.Name );
      if Assigned( contextMethod ) then
        if ( contextMethod.Visibility < mvPublished ) then
        begin
          if fRaiseExceptionIfTargetNotFound then
            raise EMethodExistsButIsNotPublished.CreateFmt( EXC_METHOD_VISIBILITY_TOO_LOW, [contextMethod.Name, AReceiver.ClassName] )
        end
        else
        begin
          SetLength( methodParameters, AInvokableCommand.ParameterCount );
          n := 0;
          while n < AInvokableCommand.ParameterCount do
          begin
            methodParameters[n] := TValue.FromVariant( AInvokableCommand[n] );
            inc( n );
          end;
          contextMethod.Invoke( AReceiver, methodParameters );
          Result := true;
        end;
    end;
  finally
    Log.LeaveMethod( Self, PROC_NAME );
  end;
end;

function TCommandMediator.InvokeMethod( const ACommand: ICommand ): boolean;
const
  PROC_NAME = 'InvokeMethod';
var
  commandTarget: TObject;
begin
  Assert( ACommand.Invokable );
  if FindReceiver( ACommand.Receiver, commandTarget ) then
    Result := InvokePublishedMethod( commandTarget, ACommand )
  else if fRaiseExceptionIfTargetNotFound then
    raise ETargetObjectNotFound.CreateFmt( EXC_COMMAND_RECEIVER_NOT_FOUND, [ClassName, PROC_NAME, ACommand.Receiver, ACommand.Name] )
  else
    Result := false;
end;

end.

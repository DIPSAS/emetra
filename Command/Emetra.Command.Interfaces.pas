unit Emetra.Command.Interfaces;

interface

uses
  Emetra.Settings.Interfaces,
  System.Classes, System.SysUtils;

type

  ECommandException = class( Exception );
  ETargetObjectNotFound = class( ECommandException );
  EMethodExistsButIsNotPublished = class( ECommandException );

{$REGION 'Documentation'}
  /// <summary>
  /// Allows all command handlers and command targets to register themselves in a central location, allowing the
  /// manager to ensure that the same command is not handled by more than one ICommandReceiver, and to dispatch
  /// commands to the right handler.
  /// </summary>
{$ENDREGION}

  ICommand = interface( ISettingsRead )
    ['{EF6DD3AA-D81C-41DE-9502-77ED77FE1D00}']
    function Get_Invokable: boolean;
    function Get_Name: string;
    function Get_ParameterCount: integer;
    function Get_ParameterValue( AIndex: integer ): Variant;
    function Get_Receiver: string;
    { Methods }
    function Matches( const ACommandName: string ): boolean;
    function CommaText: string;
    function TryGetValue( const AKey: string; out AValue: Variant ): boolean;
    function TryGetString( const AKey: string; out AValue: string ): boolean;
    procedure AddParameter( const AKey: string; const AValue: Variant ); overload;
    procedure AddParameterForInvokable( const AValue: Variant ); overload;
    { Properties }
    property Invokable: boolean read Get_Invokable;
    property name: string read Get_Name;
    property ParameterCount: integer read Get_ParameterCount;
    property ParameterValues[AIndex: integer]: Variant read Get_ParameterValue; default;
    property Receiver: string read Get_Receiver;
  end;

{$REGION 'Documentation'}
  /// <summary>
  /// A command handler will usually perform the task described in a command.
  /// It may also delegate internally to some contained object, so a GUI element may
  /// be the command handler or command target, but the actual execution may be left to a business object.
  /// </summary>
{$ENDREGION}

  ICommandReceiver = interface
    ['{8B3D08BC-16CE-4A2A-B6D9-CBA1DBB59125}']
    function ExecuteCmd( const ACommand: ICommand ): boolean;
  end;

{$REGION 'Documentation'}
  /// <summary>
  /// A command mediator will accept command handlers to register as handlers for specific commands.
  /// It is also a command handler itself, usually because it needs to accept commands in able to pass them on.
  /// Usually, however, the actual execution of the command is left to some other business object.
  /// </summary>
{$ENDREGION}

  ICommandMediator = interface
    ['{D393D15D-56F7-4832-B863-3BAB76057FAD}']
    procedure RegisterReceiver( const ACommandName: string; AReceiver: TObject );
  end;

{$REGION 'Documentation'}
  /// <summary>
  /// Command targets can register themselves with a ICommandMediator.  They are also responsible for
  /// carrying out the command when called upon to do so.
  /// A command target is usually a command handler, but doesn't have to be. Published methods
  /// without parameters can also be called by the command mediator, by leveraging RTTI at run-time.
  /// </summary>
{$ENDREGION}

  ISelfRegisterCommandReceiver = interface
    ['{E31B449F-D560-4E57-A6B5-1487681106BB}']
    procedure RegisterCommands( ACommandMediator: ICommandMediator );
  end;

implementation

end.

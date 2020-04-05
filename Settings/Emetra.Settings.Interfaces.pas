/// <summary>
///   Settings are typically dictionaries of primitive types, where an
///   application can store its configuration. A hierachy of settings can be
///   achieved by using a dot notation, but this is not supported explicitly
///   and needs to be a convention that the implementor of the interface
///   understands.
/// </summary>
unit Emetra.Settings.Interfaces;

interface

type
  /// <remarks>
  ///   The need to differentiate between ssUser and ssMachine user comes form
  ///   issues like the use of VPN, number of monitors and their
  ///   sizes/resolutions etc.
  /// </remarks>
  TSettingScope = (
    /// <summary>
    ///   The setting store is unavailable, it may not be possible to store
    ///   anything there.
    /// </summary>
    ssUndefined,
    /// <summary>
    ///   The setting is global for all users of an application or even a group
    ///   of applications.
    /// </summary>
    ssGlobal,
    /// <summary>
    ///   The setting is for this user, regardless of the machine they are
    ///   working on.
    /// </summary>
    ssUser,
    /// <summary>
    ///   The setting is specific for a user on this machine.
    /// </summary>
    ssMachineUser );

  /// <summary>
  ///   Readable settings where there is no scope, or where the scope is
  ///   implied from the context. An example can be a command line utitilty
  ///   that needs to read settings from the command it was invoked with. In
  ///   this context, the setting is applied per execution and not saved.
  /// </summary>
  ISettingsRead = interface
    ['{039D4FEB-5832-46E0-A42A-15C36C1663A9}']
    /// <summary>
    ///   Returns true if there is a setting of this type present in the
    ///   configuration.
    /// </summary>
    /// <param name="AKey">
    ///   The name of the setting in the setting dictionary.
    /// </param>
    /// <remarks>
    ///   The function can return false even if it AKey represents a valid
    ///   setting key. It only returns true if this setting has actually been
    ///   set to something. <br />
    /// </remarks>
    function Exists( const AKey: string ): boolean;
    function ReadBool( const AKey: string; const ADefault: boolean = false ): boolean;
    function ReadDate( const AKey: string; const ADefault: TDateTime ): TDateTime;
    function ReadInteger( const AKey: string; const ADefault: Integer = 0 ): Integer;
    function ReadFloat( const AKey: string; const ADefault: double = 0 ): double;
    function ReadString( const AKey: string; const ADefault: string = '' ): string;
  end;

  /// <summary>
  ///   A more general way to get the settings, where the scope of the setting
  ///   needs to be specified.
  /// </summary>
  IScopedSettingsRead = interface
    ['{13F163EA-6965-4581-BF49-FF9E7FDAA3CE}']
    { Accessors }
    function Get_Scope: TSettingScope;
    procedure Set_Scope( const ASettingScope: TSettingScope );
    { Other members }
    function Exists( const AScope: TSettingScope; const AContext, AKey: string ): boolean;
    function ReadBool( const AScope: TSettingScope; const AContext, AKey: string; const ADefault: boolean = false ): boolean;
    function ReadDate( const AScope: TSettingScope; const AContext, AKey: string; const ADefault: TDateTime ): TDateTime;
    function ReadFloat( const AScope: TSettingScope; const AContext, AKey: string; const ADefault: double = 0 ): double;
    function ReadInteger( const AScope: TSettingScope; const AContext, AKey: string; const ADefault: Integer = 0 ): Integer;
    function ReadString( const AScope: TSettingScope; const AContext, AKey: string; const ADefault: string = '' ): string;
    { Properties }
    property Scope: TSettingScope read Get_Scope write Set_Scope;
  end;

  IScopedSettingsReadWrite = interface( IScopedSettingsRead )
    ['{F94E287C-2EF7-4C20-94B8-7B39AC98EAAB}']
    { Other properties }
    procedure WriteBool( const AScope: TSettingScope; const AContext, AKey: string; const AValue: boolean );
    procedure WriteDateTime( const AScope: TSettingScope; const AContext, AKey: string; const AValue: TDateTime );
    procedure WriteFloat( const AScope: TSettingScope; const AContext, AKey: string; const AValue: double );
    procedure WriteInteger( const AScope: TSettingScope; const AContext, AKey: string; const AValue: Integer );
    procedure WriteString( const AScope: TSettingScope; const AContext, AKey, AValue: string );
  end;

  IParametersRead = interface( ISettingsRead )
    ['{2D269D74-2DD5-4923-95E6-52D629258AB3}']
    function Flag( const AFlag: string ): boolean; { Flags are just plain text parameters, e.g. run.exe "ReadOnly" }
    function Switch( const ASwitch: string ): boolean; { Switches are just plain text parameters with forward slash, e.g. /DoIt }
  end;

implementation

end.


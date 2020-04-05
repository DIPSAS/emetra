unit Emetra.Command;

interface

uses
  Emetra.Command.Interfaces,
  Emetra.Settings.Interfaces,
  Spring.Collections,
  Generics.Collections,
  Generics.Defaults,
  System.Classes;

type
  /// <remarks>
  /// All the methods of TCommand are private, and it has no properties, only
  /// property accessors. The reason for this is that you should always use a
  /// command as an ICommand interface, and not as an object. Commands are
  /// meant to be passed around in the application, and the factory has no
  /// way of knowing when a command has outlived it's purpose and can be
  /// freed.
  /// </remarks>
  TCommand = class( TInterfacedObject, ICommand, ISettingsRead )
  strict private
    fCommandName: string;
    fReceiver: string;
    fParameterValues: Spring.Collections.IOrderedDictionary<string, Variant>;
    { Basic retrieval from dictionary }
    function TryGetValue( const AKey: string; out AValue: Variant ): boolean;
    function TryGetString( const AKey: string; out AValue: string ): boolean;
  private
    function Exists( const AKey: string ): boolean; { Checks for existence of Key=Value on parameter list }
    { Property accessors }
    function Get_Name: string;
    function Get_Invokable: boolean;
    function Get_ParameterCount: integer;
    function Get_ParameterValue( AIndex: integer ): Variant;
    function Get_Receiver: string;
    { ISettingsRead implementation }
    function CommaText: string;
    function Matches( const ACommandName: string ): boolean;
    function ReadDate( const AKey: string; const ADefault: TDateTime = 0 ): TDateTime;
    function ReadBool( const AKey: string; const ADefault: boolean = false ): boolean; overload;
    function ReadInteger( const AKey: string; const ADefaultValue: integer = 0 ): integer; overload;
    function ReadFloat( const AKey: string; const ADefault: double = 0 ): double;
    function ReadString( const AKey: string; const ADefaultValue: string = '' ): string;
    // ICommand implementation
    /// <summary>
    ///   Standard command parameter need to have a name to be retrieved via
    ///   the Read methods.
    /// </summary>
    /// <param name="AKey">
    ///   The name of the parameter, not case sensitive.
    /// </param>
    /// <param name="AValue">
    ///   The value of the parameter. Note that not all variant types can be
    ///   retrieved with Read* methods.
    /// </param>
    procedure AddParameter( const AKey: string; const AValue: Variant ); overload;
    /// <summary>
    /// Parameters for invokable methods don't need a name, because when the
    /// command is invoked on an object, the parameters are applied in the
    /// order they are added. The number and type of the parameters are both
    /// essential, so this method must be called in the correct sequence to
    /// match the signature of the receiver.
    /// </summary>
    procedure AddParameterForInvokable( const AValue: Variant ); overload;
  public
    /// <summary>
    /// An invokable command is a special type of command than can be invoked
    /// on any object, even one that isn't a command target.
    /// </summary>
    /// <param name="ATargetObject">
    /// The name of a RegisterAsCommandReceiver object upon which this command is to be
    /// applied.
    /// </param>
    /// <param name="AMethodName">
    /// The method to invoke on this object.
    /// </param>
    /// <remarks>
    /// Check the
    /// </remarks>
    /// <seealso cref="TCommandMediator" />
    constructor CreateInvokable( const ATargetObject, AMethodName: string );
    constructor Create( const AName: string ); reintroduce; overload;
    procedure BeforeDestruction; override;
  end;

const
  PRM_DEFAULT_INTEGER = -1;
  PRM_DEFAULT_BOOLEAN = false;

implementation

uses
  System.SysUtils,
  System.Variants;

{ TCommand }

{$REGION 'Initialization'}

constructor TCommand.Create( const AName: string );
begin
  inherited Create;
  fCommandName := AName;
  fParameterValues := TCollections.CreateOrderedDictionary<string, Variant>;
end;

constructor TCommand.CreateInvokable( const ATargetObject, AMethodName: string );
begin
  Create( AMethodName );
  fReceiver := ATargetObject;
end;

procedure TCommand.BeforeDestruction;
begin
  fParameterValues := nil;
  inherited;
end;

{$ENDREGION}
{$REGION 'Property accessors'}

function TCommand.Get_Invokable: boolean;
begin
  Result := fReceiver <> EmptyStr;
end;

function TCommand.Get_Name: string;
begin
  Result := fCommandName;
end;

function TCommand.Get_ParameterCount: integer;
begin
  Result := fParameterValues.Count;
end;

function TCommand.Get_Receiver: string;
begin
  Result := fReceiver;
end;

{$ENDREGION}
{$REGION 'ISettingsRead interface'}

function TCommand.Exists( const AKey: string ): boolean;
begin
  Result := fParameterValues.ContainsKey( AnsiUppercase( AKey ) );
end;

function TCommand.ReadBool( const AKey: string; const ADefault: boolean ): boolean;
var
  parameterValue: Variant;
begin
  Result := ADefault;
  if fParameterValues.TryGetValue( AnsiUppercase( AKey ), parameterValue ) then
    case VarType( parameterValue ) of
      vtBoolean: Result := parameterValue;
      vtInteger: Result := parameterValue > 0;
      vtExtended: Result := parameterValue > 0;
    else Result := StrToBool( VarToStr( parameterValue ) )
    end;
end;

function TCommand.ReadDate( const AKey: string; const ADefault: TDateTime ): TDateTime;
var
  parameterValue: Variant;
begin
  Result := ADefault;
  if fParameterValues.TryGetValue( AnsiUppercase( AKey ), parameterValue ) then
    case VarType( parameterValue ) of
      vtInt64: Result := parameterValue;
      vtInteger: Result := parameterValue;
      vtExtended: Result := parameterValue;
    else Result := StrToDateDef( VarToStr( parameterValue ), ADefault )
    end;
end;

function TCommand.ReadFloat( const AKey: string; const ADefault: double ): double;
var
  parameterValue: Variant;
begin
  Result := ADefault;
  if fParameterValues.TryGetValue( AKey, parameterValue ) then
    if VarIsNumeric( parameterValue ) then
      Result := parameterValue
    else
      Result := StrToFloatDef( VarToStr( parameterValue ), ADefault );
end;

function TCommand.ReadInteger( const AKey: string; const ADefaultValue: integer ): integer;
begin
  Result := StrToIntDef( ReadString( AKey ), ADefaultValue );
end;

function TCommand.ReadString( const AKey: string; const ADefaultValue: string = '' ): string;
var
  parameterValue: Variant;
begin
  if fParameterValues.TryGetValue( AnsiUppercase( AKey ), parameterValue ) then
    Result := VarToStr( parameterValue )
  else
    Result := EmptyStr;
end;

{$ENDREGION}
{$REGION 'Adding parameters'}

procedure TCommand.AddParameterForInvokable( const AValue: Variant );
begin
  fParameterValues.AddOrSetValue( Format( 'P%d', [fParameterValues.Count] ), AValue );
end;

procedure TCommand.AddParameter( const AKey: string; const AValue: Variant );
begin
  fParameterValues.AddOrSetValue( AnsiUppercase( AKey ), AValue );
end;

{$ENDREGION}

function TCommand.Matches( const ACommandName: string ): boolean;
begin
  Result := SameText( fCommandName, ACommandName );
end;

function TCommand.CommaText: string;
var
  pair: TPair<string, Variant>;
begin
  Result := EmptyStr;
  for pair in fParameterValues do
    Result := Result + Format( '%s=%s', [pair.Key, QuotedStr( VarToStr( pair.Value ) )] );
end;

function TCommand.Get_ParameterValue( AIndex: integer ): Variant;
begin
  Result := fParameterValues.ElementAt( AIndex ).Value;
end;

function TCommand.TryGetString( const AKey: string; out AValue: string ): boolean;
var
  parameterValue: Variant;
begin
  Result := false;
  if fParameterValues.TryGetValue( AnsiUppercase( AKey ), parameterValue ) then
  begin
    AValue := VarToStr( parameterValue );
    Result := true;
  end;
end;

function TCommand.TryGetValue( const AKey: string; out AValue: Variant ): boolean;
begin
  Result := fParameterValues.TryGetValue( AnsiUppercase( AKey ), AValue );
end;

end.

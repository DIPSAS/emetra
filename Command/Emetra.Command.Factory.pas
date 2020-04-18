/// <summary>
///   Use a command factory is the preferred method of creating new commands.
/// </summary>
unit Emetra.Command.Factory;

interface

uses
  System.Classes,
  Generics.Collections,
  Emetra.Command.Interfaces;

type
{$REGION 'Documentation'}
  /// <summary>
  /// The command factory makces it easy to create commands of various types and with up to 6 parameters.
  /// </summary>
{$ENDREGION}
  TCommandFactory = class
  public
    { public }
{$REGION 'Overloaded methods for easy creation of invokable commands' }
    class function CreateInvokable( const ARegisteredObjectName, AMethodName: string ): ICommand; overload;
    class function CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0: Variant ): ICommand; overload;
    class function CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1: Variant ): ICommand; overload;
    class function CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1, P2: Variant ): ICommand; overload;
    class function CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1, P2, P3: Variant ): ICommand; overload;
    class function CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1, P2, P3, P4: Variant ): ICommand; overload;
    class function CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1, P2, P3, P4, P5: Variant ): ICommand; overload;
{$ENDREGION}
{$REGION 'Overloaded methods for easy creation of commands' }
    class function Create( const AName: string ): ICommand; overload;
    class function Create( const AName: string; const AParamName: string; const AValue: Variant ): ICommand; overload;
    class function Create( const AName: string; const P0: string; const V0: Variant; const P1: string; const V1: Variant ): ICommand; overload;
    class function Create( const AName: string; const P0: string; const V0: Variant; const P1: string; const V1: Variant;
      { } const P2: string; const V2: Variant ): ICommand; overload;
    class function Create( const AName: string; const P0: string; const V0: Variant; const P1: string; const V1: Variant;
      { } const P2: string; const V2: Variant; const P3: string; const V3: Variant ): ICommand; overload;
    class function Create( const AName: string; const P0: string; const V0: Variant; const P1: string; const V1: Variant;
      { } const P2: string; const V2: Variant; const P3: string; const V3: Variant; const P4: string; const V4: Variant ): ICommand; overload;
    class function Create( const AName: string; const P0: string; const V0: Variant; const P1: string; const V1: Variant;
      { } const P2: string; const V2: Variant; const P3: string; const V3: Variant; const P4: string; const V4: Variant;
      { } const P5: string; const V5: Variant ): ICommand; overload;
{$ENDREGION}
{$REGION 'Methods that take collections as parameters'}
    class function Create( const AName: string; const AParamList: TStrings ): ICommand; overload;
    class function Create( const AName: string; const AParamList: TDictionary<string, Variant> ): ICommand; overload;
    class function Create( const AName: string; const AParamList: array of Variant ): ICommand; overload;
{$ENDREGION}
  end;

implementation

uses
  System.SysUtils,
  Emetra.Command;

{ TCommandFactory }

class function TCommandFactory.Create( const AName: string ): ICommand;
begin
  Result := TCommand.Create( AName );
end;

class function TCommandFactory.Create( const AName, AParamName: string; const AValue: Variant ): ICommand;
begin
  Result := TCommand.Create( AName );
  Result.AddParameter( AParamName, AValue );
end;

class function TCommandFactory.Create( const AName: string;
  { } const P0: string;
  { } const V0: Variant;
  { } const P1: string; const V1: Variant ): ICommand;
begin
  Result := TCommand.Create( AName );
  Result.AddParameter( P0, V0 );
  Result.AddParameter( P1, V1 );
end;

class function TCommandFactory.Create( const AName: string;
  { } const P0: string; const V0: Variant;
  { } const P1: string; const V1: Variant;
  { } const P2: string; const V2: Variant ): ICommand;
begin
  Result := TCommand.Create( AName );
  Result.AddParameter( P0, V0 );
  Result.AddParameter( P1, V1 );
  Result.AddParameter( P2, V2 );
end;

class function TCommandFactory.Create( const AName: string;
  { } const P0: string; const V0: Variant;
  { } const P1: string; const V1: Variant;
  { } const P2: string; const V2: Variant;
  { } const P3: string; const V3: Variant ): ICommand;
begin
  Result := TCommand.Create( AName );
  Result.AddParameter( P0, V0 );
  Result.AddParameter( P1, V1 );
  Result.AddParameter( P2, V2 );
  Result.AddParameter( P3, V3 );
end;

class function TCommandFactory.Create( const AName: string;
  { } const P0: string; const V0: Variant; const P1: string; const V1: Variant;
  { } const P2: string; const V2: Variant; const P3: string; const V3: Variant;
  { } const P4: string; const V4: Variant ): ICommand;
begin
  Result := TCommand.Create( AName );
  Result.AddParameter( P0, V0 );
  Result.AddParameter( P1, V1 );
  Result.AddParameter( P2, V2 );
  Result.AddParameter( P3, V3 );
  Result.AddParameter( P4, V4 );
end;

class function TCommandFactory.Create( const AName: string;
  { } const P0: string; const V0: Variant; const P1: string; const V1: Variant;
  { } const P2: string; const V2: Variant; const P3: string; const V3: Variant;
  { } const P4: string; const V4: Variant; const P5: string; const V5: Variant ): ICommand;
begin
  Result := TCommand.Create( AName );
  Result.AddParameter( P0, V0 );
  Result.AddParameter( P1, V1 );
  Result.AddParameter( P2, V2 );
  Result.AddParameter( P3, V3 );
  Result.AddParameter( P4, V4 );
  Result.AddParameter( P5, V5 );
end;

class function TCommandFactory.Create( const AName: string; const AParamList: TStrings ): ICommand;
var
  i: integer;
begin
  Result := TCommand.Create( AName );
  i := 0;
  while i < AParamList.Count do
  begin
    Result.AddParameter( AParamList.Names[i], AParamList.ValueFromIndex[i] );
    inc( i );
  end;
end;

class function TCommandFactory.CreateInvokable( const ARegisteredObjectName, AMethodName: string ): ICommand;
begin
  Result := TCommand.CreateInvokable( ARegisteredObjectName, AMethodName );
end;

class function TCommandFactory.Create( const AName: string; const AParamList: TDictionary<string, Variant> ): ICommand;
var
  pair: TPair<string, Variant>;
begin
  Result := TCommand.Create( AName );
  for pair in AParamList do
    Result.AddParameter( pair.Key, pair.Value );
end;

class function TCommandFactory.Create( const AName: string; const AParamList: array of Variant ): ICommand;
var
  n: integer;
  varParam: Variant;
begin
  Result := TCommand.Create( AName );
  n := 0;
  for varParam in AParamList do
  begin
    Result.AddParameter( Format( 'P%d', [n] ), varParam );
    inc( n );
  end;
end;

class function TCommandFactory.CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0: Variant ): ICommand;
begin
  Result := TCommand.CreateInvokable( ARegisteredObjectName, AMethodName );
  Result.AddParameterForInvokable( P0 );
end;

class function TCommandFactory.CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1: Variant ): ICommand;
begin
  Result := TCommand.CreateInvokable( ARegisteredObjectName, AMethodName );
  Result.AddParameterForInvokable( P0 );
  Result.AddParameterForInvokable( P1 );
end;

class function TCommandFactory.CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1, P2: Variant ): ICommand;
begin
  Result := TCommand.CreateInvokable( ARegisteredObjectName, AMethodName );
  Result.AddParameterForInvokable( P0 );
  Result.AddParameterForInvokable( P1 );
  Result.AddParameterForInvokable( P2 );
end;

class function TCommandFactory.CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1, P2, P3: Variant ): ICommand;
begin
  Result := TCommand.CreateInvokable( ARegisteredObjectName, AMethodName );
  Result.AddParameterForInvokable( P0 );
  Result.AddParameterForInvokable( P1 );
  Result.AddParameterForInvokable( P2 );
  Result.AddParameterForInvokable( P3 );
end;

class function TCommandFactory.CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1, P2, P3, P4: Variant ): ICommand;
begin
  Result := TCommand.CreateInvokable( ARegisteredObjectName, AMethodName );
  Result.AddParameterForInvokable( P0 );
  Result.AddParameterForInvokable( P1 );
  Result.AddParameterForInvokable( P2 );
  Result.AddParameterForInvokable( P3 );
  Result.AddParameterForInvokable( P4 );
end;

class function TCommandFactory.CreateInvokable( const ARegisteredObjectName, AMethodName: string; const P0, P1, P2, P3, P4, P5: Variant ): ICommand;
begin
  Result := TCommand.CreateInvokable( ARegisteredObjectName, AMethodName );
  Result.AddParameterForInvokable( P0 );
  Result.AddParameterForInvokable( P1 );
  Result.AddParameterForInvokable( P2 );
  Result.AddParameterForInvokable( P3 );
  Result.AddParameterForInvokable( P4 );
  Result.AddParameterForInvokable( P5 );
end;

end.

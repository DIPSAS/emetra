unit Emetra.Database.Command;

interface

uses
  Emetra.Database.Interfaces,
  {Standard}
  Data.Db,
  Generics.Collections, System.SysUtils;

type
  EUnsupportedParameterType = class( EArgumentException );

  TSqlCommand = class( TObject )
  strict private
    fCommand: string;
    fParamsFromSql: TParams;
    fFormatSettings: TFormatSettings;
  private
    function GetParam( const AName: string ): TParam;
    { Property Accessors }
    function Get_ParamCount: integer;
  public
    { Initialization }
    constructor Create( const ASqlCommandText: string );
    destructor Destroy; override;
    { Other methods }
    function AsString: string;
    procedure SetDateTime( const AName: string; const AValue: TDateTime );
    procedure SetFloat( const AName: string; const AValue: double );
    procedure SetInteger( const AName: string; const AValue: integer );
    procedure SetParam( const AIndex: integer; const AValue: Variant );
    procedure SetString( const AName: string; const AValue: string );
    { Properties }
    property ParamCount: integer read Get_ParamCount;
  end;

implementation

uses
  System.DateUtils,
  System.Classes, System.Variants;

{ TSqlCommand }

{$REGION 'Initialization'}

constructor TSqlCommand.Create( const ASqlCommandText: string );
begin
  inherited Create;
  fCommand := ASqlCommandText;
  fParamsFromSql := TParams.Create( nil );
  fParamsFromSql.ParseSQL( fCommand, true );
  { Use en-US format settings for compatibility with database engines }
  fFormatSettings := TFormatSettings.Create( 'en-US' );
end;

destructor TSqlCommand.Destroy;
begin
  fParamsFromSql.DisposeOf;
  inherited;
end;

{$ENDREGION}
{$REGION 'Property accessors'}

function TSqlCommand.Get_ParamCount: integer;
begin
  Result := fParamsFromSql.Count;
end;

{$ENDREGION}
{$REGION 'Parameter setters'}

procedure TSqlCommand.SetParam( const AIndex: integer; const AValue: Variant );
var
  paramObject: TParam;
begin
  paramObject := fParamsFromSql[AIndex];
  case VarType( AValue ) of
    varString: paramObject.DataType := ftString;
    varDate: paramObject.DataType := ftDateTime;
    varInteger, varSmallInt: paramObject.DataType := ftInteger;
    varDouble, varSingle: paramObject.DataType := ftFloat;
  else raise EUnsupportedParameterType.CreateFmt( 'Unsupported parameter type: %d', [VarType( AValue )] );
  end;
  paramObject.Value := AValue;
end;

procedure TSqlCommand.SetDateTime( const AName: string; const AValue: TDateTime );
begin
  with GetParam( AName ) do
  begin
    ParamType := ptInput;
    DataType := ftDateTime;
  end;
end;

procedure TSqlCommand.SetFloat( const AName: string; const AValue: double );
begin
  with GetParam( AName ) do
  begin
    ParamType := ptInput;
    DataType := ftFloat;
  end;
end;

procedure TSqlCommand.SetInteger( const AName: string; const AValue: integer );
begin
  with GetParam( AName ) do
  begin
    ParamType := ptInput;
    DataType := ftInteger;
  end;
end;

procedure TSqlCommand.SetString( const AName: string; const AValue: string );
begin
  with GetParam( AName ) do
  begin
    ParamType := ptInput;
    DataType := ftString;
  end;
end;

{$ENDREGION}

function TSqlCommand.AsString: string;
var
  i: integer;
  parameterObject: TParam;
  stringRepresentation: string;
begin
  Result := fCommand;
  i := 0;
  while i < fParamsFromSql.Count do
  begin
    parameterObject := fParamsFromSql[i];
    if parameterObject.IsNull then
      stringRepresentation := 'NULL'
    else
      case parameterObject.DataType of
        ftInteger, ftByte: stringRepresentation := parameterObject.AsString;
        ftFloat, ftCurrency, ftBCD: stringRepresentation := Format( '%g', [parameterObject.AsFloat], fFormatSettings );
        ftDateTime: stringRepresentation := QuotedStr( DateToISO8601( parameterObject.AsDateTime ) );
        ftString, ftWideString: stringRepresentation := QuotedStr( parameterObject.AsString );
      else raise EDatabaseParameterError.CreateFmt( 'Unsupported data type %d for %s', [ord( parameterObject.DataType ), parameterObject.Name] );
      end;
    Result := StringReplace( Result, ':' + parameterObject.Name, stringRepresentation, [] );
    inc( i );
  end;
end;

function TSqlCommand.GetParam( const AName: string ): TParam;
begin
  Result := fParamsFromSql.FindParam( AName );
  Assert( Assigned( Result ), Format( 'Parameter name %s not found in SQL Command: %s', [AName, fCommand] ) );
end;

end.

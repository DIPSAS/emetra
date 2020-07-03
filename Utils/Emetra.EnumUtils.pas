unit Emetra.EnumUtils;

interface

uses
  System.TypInfo, System.SysUtils, System.Rtti;

type
  EEnumConversionError = class( Exception );

  TEnumMapper = class
    class function GetPrefix<T>( const ASampleValue: T ): string;
    class function GetValue<T>( const AInput: string; const AEnumPrefix: string = '' ): integer; overload;
    class function GetValue<T>( const AInput: string; const ASampleValue: T ): integer; overload;
    class function GetName<T>( const AValue: T ): string;
  end;

implementation

const
  UNASSIGNED_ENUM = -1;

class function TEnumMapper.GetPrefix<T>( const ASampleValue: T ): string;
var
  s: string;
  c: char;
  i: integer;
begin
  i := 1;
  s := GetName<T>( ASampleValue );
  for c in s do
    if not CharInSet( c, ['a' .. 'z'] ) then
      break
    else
      inc( i );
  Result := Copy( s, 1, i - 1 );
end;

class function TEnumMapper.GetName<T>( const AValue: T ): string;
begin
  Result := TRttiEnumerationType.GetName( AValue );
end;

class function TEnumMapper.GetValue<T>( const AInput: string; const AEnumPrefix: string ): integer;
var
  currentChar: char;
  extractedString: string;
  s: string;
  enumTypeInfo: PTypeInfo;
begin
  enumTypeInfo := TypeInfo( T );
  if not Assigned( enumTypeInfo ) then
    raise EEnumConversionError.CreateFmt( 'Failed to retrieve TypeInfo (%s)', [AInput] );
  Result := UNASSIGNED_ENUM;
  { Avoid reallocation of string as it grows, set to max size first }
  SetLength( extractedString, Length( AInput ) );
  extractedString := EmptyStr;
  { Add characters except whitespace and underscores }
  for currentChar in AInput do
    if not CharInSet( currentChar, [#9, #10, #13, #32, '_'] ) then
      extractedString := extractedString + currentChar;
  { Try to get value }
  Result := GetEnumValue( enumTypeInfo, AEnumPrefix + extractedString );
  if Result = UNASSIGNED_ENUM then
    raise EEnumConversionError.CreateFmt( 'String "%s" could not be converted to "%s" enumeration', [AInput, enumTypeInfo.Name] );
end;

class function TEnumMapper.GetValue<T>( const AInput: string; const ASampleValue: T ): integer;
begin
  Result := GetValue<T>( AInput, GetPrefix<T>( ASampleValue ) );
end;

end.

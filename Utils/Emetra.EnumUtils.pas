unit Emetra.EnumUtils;

interface

uses
  System.TypInfo, System.SysUtils, System.Rtti;

type
  /// <summary>
  ///   Exception is thrown when a string can not be converted to the requested
  ///   enumeration type.
  /// </summary>
  /// <remarks>
  ///   <para>
  ///     More on enumerated types here:
  ///   </para>
  ///   <para>
  ///     <see href="http://docwiki.embarcadero.com/RADStudio/Tokyo/en/Simple_Types_(Delphi)#Enumerated_Types_with_Explicitly_Assigned_Ordinality">
  ///     Enumerated Types</see>
  ///   </para>
  ///   <para>
  ///     For some reason, Enumerated types with expilcitly assigned
  ///     ordinalities have no RTTI, and using them with TEnumMapper will
  ///     also throw this exception. <br /><br />
  ///   </para>
  /// </remarks>
  EEnumMapperError = class( Exception );

  /// <summary>
  ///   This class improves a little bit on the standard RTTI functions by
  ///   automatically stripping underscores from enum values (typically when
  ///   read from JSON data). It can also add a prefix to the string before
  ///   trying to convert it. Otherwise, just use value := TRttiEnumerationType.GetValue<T>(string);
  /// </summary>
  /// <example>
  ///   A string like "first_value" can be automatically converted to
  ///   enFirstValue representing a member in a Delphi enumeration class that
  ///   follows standard Delphi naming conventions.
  /// </example>
  TEnumMapper = class
  public
    /// <summary>
    ///   Simple wrapper for similar functionality in RTTI.
    /// </summary>
    class function GetName<T>( const AValue: T ): string;
    /// <summary>
    /// Extracts the first sequence of lowercase characters (a..z) that by
    /// convention is part of an enumeration value in Delphi.
    /// </summary>
    /// <typeparam name="T">
    /// The enumeration type.
    /// </typeparam>
    /// <param name="ASampleValue">
    /// A sample value from the enumeration.
    /// </param>
    /// <remarks>
    /// The assumption is made that all members of an enumeration type share
    /// the same prefix.
    /// </remarks>
    class function GetPrefix<T { : enum } >( const ASampleValue: T ): string;
    /// <typeparam name="T">
    /// Any enumeration type
    /// </typeparam>
    /// <param name="AInput">
    /// The string that you want to convert to a member of the enumerated
    /// type T.
    /// </param>
    /// <param name="AEnumPrefix">
    /// The prefix used across all members of T.
    /// </param>
    /// <remarks>
    /// The asu
    /// </remarks>
    class function GetValue<T { : enum } >( const AInput: string; const AEnumPrefix: string = '' ): integer; overload;
    /// <typeparam name="T">
    /// The enumeration type.
    /// </typeparam>
    /// <param name="AInput">
    /// The string that you want to convert to a member of the enumerated
    /// type T.
    /// </param>
    /// <param name="ASampleValue">
    /// Any value from the enumeration T.
    /// </param>
    /// <remarks>
    /// The assumption is made that all members of an enumeration type share
    /// the prefix if ASampleValue.
    /// </remarks>
    class function GetValue<T { : enum } >( const AInput: string; const ASampleValue: T ): integer; overload;

    class function GetValueNullable<T { : enum }>( const AInput: string; const AEnumPrefix: string = '' ): integer;
  end;

implementation

const
  UNASSIGNED_ENUM = -1;

class function TEnumMapper.GetName<T>( const AValue: T ): string;
begin
  Result := TRttiEnumerationType.GetName( AValue );
end;

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

class function TEnumMapper.GetValue<T>( const AInput: string; const AEnumPrefix: string ): integer;
var
  currentChar: char;
  extractedString: string;
  s: string;
  enumTypeInfo: PTypeInfo;
begin
  enumTypeInfo := TypeInfo( T );
  if not Assigned( enumTypeInfo ) then
    raise EEnumMapperError.CreateFmt( 'Failed to retrieve TypeInfo for Enum (%s)', [AInput] );
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
    raise EEnumMapperError.CreateFmt( 'String "%s" could not be converted to "%s" enumeration', [AInput, enumTypeInfo.Name] );
end;

class function TEnumMapper.GetValue<T>( const AInput: string; const ASampleValue: T ): integer;
begin
  Result := GetValue<T>( AInput, GetPrefix<T>( ASampleValue ) );
end;

class function TEnumMapper.GetValueNullable<T>( const AInput: string; const AEnumPrefix: string ): integer;
begin
  // check if AInput == null then AInput = 'Null' then run GetValue
  Result := GetValue<T>( AInput, AEnumPrefix );
  if Result = -1 then
  begin
      if Length( AInput.Trim ) = 0 then
      begin
        //value was null
        Result := GetValue<T>( 'null' , AEnumPrefix );
      end;
  end;
end;


end.

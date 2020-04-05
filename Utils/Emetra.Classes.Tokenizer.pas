unit Emetra.Classes.Tokenizer;

interface

uses
  System.Classes;

type
  /// <summary>
  /// This class extends TStringList with the capability to split a string
  /// based on a sequence of characters and not just a single character. It
  /// will also not create an exception if you try to access something
  /// outside the range of lines that it actually contains, it will just
  /// return an empty string in this case.
  /// </summary>
  TTokenizer = class( TStringList )
  private
    function Get_Item( AIndex: Integer ): string;
  public
    { Initialization }
    constructor Create; reintroduce;
    { Methods }
    function Extract( const AInput: string; const AZeroBasedIndex: Integer; const ADelimiter: Char ): string;
    /// <summary>
    /// Deprecated method, that does the same as Prepare, but with a
    /// one-based index.
    /// </summary>
    function GetAt( const AInput: string; const AOneBasedIndex: Integer; const ADelimiter: Char ): string; deprecated;
    /// <param name="AInput">
    /// The string to split.
    /// </param>
    /// <param name="ADelimiter">
    /// Single character delimiter
    /// </param>
    procedure Prepare( const AInput: string; const ADelimiter: Char ); overload;
    /// <summary>
    /// Split a string into parts where the the separator is sequence of
    /// characters, like a <b>CrLf</b> pair, or the " <b>://"</b> in a URI.
    /// </summary>
    /// <param name="AInput">
    /// The string to split.
    /// </param>
    /// <param name="ADelimiterString">
    /// A string that separates the tokens in AInput.
    /// </param>
    procedure Prepare( const AInput: string; const ADelimiterString: string ); overload;
    /// <summary>
    /// After a call to Prepare, the items can be retrieved with this
    /// property. Attempts to go outside the bounds of from 0 to Count-1 will
    /// not fail, merely return an empty string.
    /// </summary>
    /// <param name="AIndex">
    /// Zero based index of tokens (strings).
    /// </param>
    { Properties }
    property Items[AIndex: Integer]: string read Get_Item; default;
  end;

implementation

uses
  System.SysUtils;

const
  EXC_NO_SUITABLE_DELIMITER = 'Failed to find an appropriate delimiter, because the string contained every character from #0 to #1023.';

constructor TTokenizer.Create;
begin
  inherited;
  StrictDelimiter := true;
end;

function TTokenizer.Get_Item( AIndex: Integer ): string;
begin
  if ( AIndex > -1 ) and ( AIndex < Count ) then
    Result := Trim( Get( AIndex ) )
  else
    Result := EmptyStr;
end;

function TTokenizer.Extract( const AInput: string; const AZeroBasedIndex: Integer; const ADelimiter: Char ): string;
begin
  Result := EmptyStr;
  Delimiter := ADelimiter;
  DelimitedText := AInput;
  if ( AZeroBasedIndex > -1 ) and ( AZeroBasedIndex < Count ) then
    Result := Self[AZeroBasedIndex];
end;

function TTokenizer.GetAt( const AInput: string; const AOneBasedIndex: Integer; const ADelimiter: Char ): string;
begin
  Result := EmptyStr;
  Delimiter := ADelimiter;
  DelimitedText := AInput;
  if ( AOneBasedIndex > 0 ) and ( AOneBasedIndex < Count + 1 ) then
    Result := Self[AOneBasedIndex - 1];
end;

procedure TTokenizer.Prepare( const AInput: string; const ADelimiter: Char );
begin
  Delimiter := ADelimiter;
  DelimitedText := AInput;
end;

procedure TTokenizer.Prepare( const AInput, ADelimiterString: string );
var
  delimiterChar: Char;
begin
  delimiterChar := #1023;
  while Pos( delimiterChar, AInput ) > 0 do
    Dec( delimiterChar );
  Assert( delimiterChar > #0, EXC_NO_SUITABLE_DELIMITER );
  { Call the standard prepare with this character }
  Prepare( StringReplace( AInput, ADelimiterString, delimiterChar, [rfReplaceAll, rfIgnoreCase] ), delimiterChar );
end;

end.

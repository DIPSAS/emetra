unit Emetra.Classes.Tokenizer;

interface

uses
  Classes;

type
  TTokenizer = class( TStringList )
  private
    function Get_Item( AIndex: Integer ): string;
  public
    constructor Create; reintroduce;
    { Methods }
    function Extract( const AInput: string; const AZeroBasedIndex: Integer; const ADelimiter: Char ): string;
    function GetAt( const AInput: string; const AOneBasedIndex: Integer; const ADelimiter: Char ): string; deprecated;
    procedure Prepare( const AInput: string; const ADelimiter: Char ); overload;
    procedure Prepare( const AInput: string; const AStringOfDelimiterChars: string ); overload;
    { Properties }
    property Items[AIndex: Integer]: string read Get_Item; default;
  end;

implementation

uses
  System.SysUtils;

{$REGION 'Tokenizer'}

constructor TTokenizer.Create;
begin
  inherited;
  StrictDelimiter := true;
end;

function TTokenizer.Extract( const AInput: string; const AZeroBasedIndex: Integer; const ADelimiter: Char ): string;
begin
  Result := EmptyStr;
  Self.Delimiter := ADelimiter;
  Self.DelimitedText := AInput;
  if ( AZeroBasedIndex > -1 ) and ( AZeroBasedIndex < Count ) then
    Result := Self[AZeroBasedIndex];
end;

function TTokenizer.GetAt( const AInput: string; const AOneBasedIndex: Integer; const ADelimiter: Char ): string;
begin
  Delimiter := ADelimiter;
  DelimitedText := AInput;
  if ( AOneBasedIndex > 0 ) and ( AOneBasedIndex < Count + 1 ) then
    Result := Self[AOneBasedIndex - 1]
  else
    Result := EmptyStr;
end;

function TTokenizer.Get_Item( AIndex: Integer ): string;
begin
  if ( AIndex > -1 ) and ( AIndex < Count ) then
    Result := Trim( Get( AIndex ) )
  else
    Result := EmptyStr;
end;

procedure TTokenizer.Prepare( const AInput: string; const ADelimiter: Char );
begin
  Delimiter := ADelimiter;
  DelimitedText := AInput;
end;

procedure TTokenizer.Prepare( const AInput, AStringOfDelimiterChars: string );
var
  delimChar: Char;
begin
  { Find a single char delimiter instead of the separator string.
    The character can not be in the string already, so we look for one.
    The rare case where all characters between 0 and 255 exists is not handled. }
  delimChar := #255;
  while Pos( delimChar, AInput ) > 0 do
    Dec( delimChar );
  Assert( delimChar > #0 );
  { Call the standard prepare with this character }
  Prepare( StringReplace( AInput, AStringOfDelimiterChars, delimChar, [rfReplaceAll, rfIgnoreCase] ), delimChar );
end;

{$ENDREGION}

end.

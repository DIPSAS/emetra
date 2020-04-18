unit Emetra.Logging.Utilities;

interface

function AnonymizeLogMessage( const s: string ): string;
function PrepareForDialog( const s: string ): string;
function RemoveHandlebars( const s: string ): string;

resourcestring
  TXT_REPLACEMENT = '(Anonymisert)';

implementation

uses
  System.SysUtils,
  System.RegularExpressions;

const
  TEST_MESSAGE             = 'Hello  {{Napoleon Æ. Bonaparte}}'#10#13'  test.';
  TEST_ANONYMIZED_TEMPLATE = 'Hello %s test.'; { Extra whitespace is removed }
  EXC_ANONYMIZE_FAILED     = 'Anonymization did not work properly.';

function AnonymizeLogMessage( const s: string ): string;
begin
  Result := TRegEx.Replace( s, '{{(.*)}}', TXT_REPLACEMENT );
  Result := TRegEx.Replace( Result, '\s+', ' ' );
end;

function RemoveHandlebars( const s: string ): string;
begin
  Result := TRegEx.Replace( s, '{{(.*)}}', '\1' );
end;

function PrepareForDialog( const s: string ): string;
begin
  Result := StringReplace( RemoveHandlebars( s ), '\n', #10, [rfReplaceAll] );
end;

procedure SelfTest;
begin
  Assert( SameText( AnonymizeLogMessage( TEST_MESSAGE ), Format( TEST_ANONYMIZED_TEMPLATE, [TXT_REPLACEMENT] ) ), EXC_ANONYMIZE_FAILED );
  Assert( SameText( PrepareForDialog( 'a\nb' ), 'a'#10'b' ) );
  Assert( SameText( RemoveHandlebars( 'a{{b}}c' ), 'abc' ) );
  Assert( SameText( RemoveHandlebars( '{{b}}c' ), 'bc' ) );
  Assert( SameText( RemoveHandlebars( 'a{{b}}' ), 'ab' ) );
end;

begin
  { Do a simple self-test here to avoid leaking deidentified log strings }
  SelfTest;

end.

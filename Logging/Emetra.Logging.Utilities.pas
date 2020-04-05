unit Emetra.Logging.Utilities;

interface

function RemoveHandlebars( const s: string ): string;
function PrepareForDialog( const s: string ): string;
function AnonymizeLogMessage( const s: string ): string;

implementation

uses
  System.SysUtils,
  System.RegularExpressions;

resourcestring
  StrAnonymized = '(Anonymisert)';

function RemoveHandlebars( const s: string ): string;
begin
  Result := TRegEx.Replace( s, '{{(.*)}}', '\1' );
end;

function PrepareForDialog( const s: string ): string;
begin
  Result := StringReplace( RemoveHandlebars( s ), '\n', #10, [rfReplaceAll] );
end;

function AnonymizeLogMessage( const s: string ): string;
begin
  Result := TRegEx.Replace( s, '{{(.*)}}', StrAnonymized );
  Result := TRegEx.Replace( Result, '\s+', ' ' );
end;

begin
  Assert( AnonymizeLogMessage( 'Hei {{navn}}'#10#13' test.' ) = 'Hei ' + StrAnonymized + ' test.', 'Anonymisering virket ikke.' );
end.

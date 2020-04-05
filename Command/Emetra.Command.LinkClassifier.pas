unit Emetra.Command.LinkClassifier;

interface

uses
  Emetra.Classes.Tokenizer,
  Classes, RegularExpressions;

type
  TUrlClass = ( urlPassThrough, urlReportTemplateFile, urlApplicationCommand, urlReportOutput, urlPDF, urlFastReport, urlOther );

  TLinkParser = class( TObject )
  private
    fTokenizer: TTokenizer;
    fOldStyleCommandFinder: TRegEx;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function ClassifyUrl( const AURL: string; out AFileName: string ): TUrlClass; overload;
    function ClassifyUrl( const AURL: string ): TUrlClass; overload;
    function TryParseCommand( const AURL: string; out ACommandName: string; AParams: TStrings ): boolean;
  end;

implementation

uses
  SysUtils;

procedure TLinkParser.AfterConstruction;
begin
  inherited;
  fOldStyleCommandFinder := TRegEx.Create( '(AddForm|AddDx|Print)=', [roIgnoreCase] );
  fTokenizer := TTokenizer.Create;
end;

procedure TLinkParser.BeforeDestruction;
begin
  fTokenizer.Free;
  inherited;
end;

function TLinkParser.ClassifyUrl( const AURL: string ): TUrlClass;
var
  fileName: string;
begin
  Result := ClassifyUrl( AURL, fileName );
end;

function TLinkParser.ClassifyUrl( const AURL: string; out AFileName: string ): TUrlClass;
var
  fileExt: string;
begin
  { A link to html-file is prefixed with report:// and has a '/' at the end }
  AFileName := StringReplace( AURL, 'report://', '', [] ).TrimRight( ['/'] );
  fileExt := ExtractFileExt( AFileName );
  Result := urlPassThrough;
  if Pos( 'TfrmDocViewer', AFileName ) > 1 then
    Result := urlReportOutput
  else if ( AURL[1] = '/' ) or fOldStyleCommandFinder.IsMatch( AURL ) then
    Result := urlApplicationCommand
  else if FileExists( AFileName ) then
  begin
    if SameText( fileExt, '.html' ) then
      Result := urlReportTemplateFile
    else if SameText( fileExt, '.fr3' ) then
      Result := urlFastReport
    else if SameText( fileExt, '.pdf' ) then
      Result := urlPDF
    else
      Result := urlOther;
  end;
end;

function TLinkParser.TryParseCommand( const AURL: string; out ACommandName: string; AParams: TStrings ): boolean;
var
  match: TMatch;
begin
  Result := false;
  if Pos( '//', AURL ) = 1 then
  begin
    { New style command, like URL: "about://AlertSnooze?AlertId=n&Delay=14" }
    ACommandName := Copy( AURL, 3, maxint );
    fTokenizer.Prepare( ACommandName, '?' );
    ACommandName := fTokenizer[0];
    AParams.Delimiter := '&';
    AParams.StrictDelimiter := true;
    AParams.DelimitedText := fTokenizer[1];
    Result := true;
  end
  else
  begin
    { Old style command handling }
    match := fOldStyleCommandFinder.match( AURL );
    if match.Success then
    begin
      fTokenizer.Prepare( Copy( AURL, match.Index, maxint ), '=' );
      ACommandName := fTokenizer[0];
      if SameText( ACommandName, 'AddForm' ) then
        AParams.Values['FormName'] := fTokenizer[1]
      else if SameText( ACommandName, 'Print' ) then
        AParams.Values['FileName'] := fTokenizer[1]
      else if SameText( ACommandName, 'AddDx' ) then
      begin
        fTokenizer.Prepare( fTokenizer[1], ':' );
        AParams.Values['ListId'] := fTokenizer[0];
        AParams.Values['DxCode'] := fTokenizer[1];
      end;
      Result := true;
    end;
  end;
end;

end.

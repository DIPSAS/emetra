unit Emetra.Logging.Colors;

interface

uses
  System.UITypes;

const
  { Start and end of log }
  mcFirstAndLastEntry: TColor      = $00DEC4B0; // Apricot
  mcFinalizeWithExceptions: TColor = $003C14DC; // Crimson - a clear red color
  mcFinalizeNoExceptions: TColor   = $0000FF7F; // Chartreuse - a bright green color

  { Warning level colors }
  mcWarningMessage: TColor  = $002BF0FF; // Broom - a yellow color
  mcInfoMessage: TColor     = $0029F667; // Bright green
  mcErrorMessage: TColor    = $005D2BFF; // Radical red
  mcCriticalMessage: TColor = $000000FF; // Solid red

  { Call stack colors }
  mcCallStack: TColor = TColorRec.Aliceblue;
  clCallStack: TColor = TColorRec.Gray;

  { From outer ring of color circle }
  mcSilentSuccess:TColor = $00CEF6DA; // Light tint of yellowish-green
  mcSilentWarning:TColor = $00D5FCFF; // Light tint of yellow
  mcSilentError:TColor   = $00DFD5FF; // Light tint of pinkish read

  { From middle ring, unused in outer ring }
  mcBlue     = $00F7CF89; // Tint of bluish cyan
  mcLavender = $00F387AD; // Tint of indigo
  mcOrange   = $008EC6FF; // Tint of orange

  mcSqlQuery        = $00F3CBD9; // Light tint of indigo
  mcSqlCommand      = $00D5EAFF; // Light tint of orange

  mcNone = $1FFFFFFF;
  mcLogDefaultBackground = TColorRec.White;
  clLogDefaultText = TColorRec.Black;

function ColorToAlphaColor(AValue: TColor): TAlphaColor;

implementation

uses
  System.UIConsts;

function ColorToAlphaColor(AValue: TColor): TAlphaColor;
begin
  {$WARNINGS OFF }
  Result := RGBToBGR( $FF000000 + AValue );
end;

end.

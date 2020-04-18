unit Emetra.Logging.PlainText.LogItem;

interface

uses
  Emetra.Logging.LogItem.Interfaces,
  Emetra.Logging.Interfaces,
  Emetra.Logging.Colors,
  {Standard}
  System.UITypes, System.SyncObjs, System.Classes, Generics.Collections, System.DateUtils, System.RegularExpressions;

type
  TLogItem = class( TInterfacedPersistent, IBasicLogItem, IColoredLogItem )
  strict private
    fBrushColor: TColor;
    fFontColor: TColor;
    fIndent: Integer;
    fLevel: TLogLevel;
    fLogText: string;
    fTimestamp: TDateTime;
  protected
    function Get_BrushColor: TColor;
    function Get_FontColor: TColor;
    function Get_Indent: Integer;
    function Get_LogLevel: TLogLevel;
    function Get_LogText: string;
    function Get_Timestamp: TDateTime;
    function Get_UnixTimestamp: double;
  public
    { Initialization }
    constructor Create( const AIndent: Integer; const ALogText: string; const ALevel: TLogLevel; const ABrushColor: TColor = mcNone; const AFontColor: TColor = mcNone ); reintroduce;
    { Other methods }
    function LevelText: string;
    function PlainText: string;
    { Properties }
    property BrushColor: TColor read Get_BrushColor write fBrushColor;
    property FontColor: TColor read Get_FontColor write fFontColor;
    property Indent: Integer read Get_Indent;
    property Level: TLogLevel read Get_LogLevel;
    property Text: string read fLogText write fLogText;
    property Timestamp: TDateTime read Get_Timestamp;
  end;

implementation

uses
  System.SysUtils, System.StrUtils;

  { TLogItem }

constructor TLogItem.Create( const AIndent: Integer; const ALogText: string; const ALevel: TLogLevel; const ABrushColor: TColor; const AFontColor: TColor );
begin
  inherited Create;
  fIndent := AIndent;
  fTimestamp := Now;
  fLogText := ALogText;
  fLevel := ALevel;
  fBrushColor := ABrushColor;
  fFontColor := AFontColor;
  if fBrushColor = mcNone then
    case ALevel of
      ltWarning: fBrushColor := mcWarningMessage;
      ltMessage: fBrushColor := mcInfoMessage;
      ltError: fBrushColor := mcErrorMessage;
      ltCritical: fBrushColor := mcCriticalMessage;
    else fBrushColor := mcLogDefaultBackground;
    end;
  if fFontColor = mcNone then
    case ALevel of
      { Light colors }
      ltError: fFontColor := mcLogDefaultBackground;
      ltCritical: fFontColor := mcLogDefaultBackground;
      { Dark colors }
    else fFontColor := clLogDefaultText;
    end;
end;

function TLogItem.Get_BrushColor: TColor;
begin
  Result := fBrushColor;
end;

function TLogItem.Get_FontColor: TColor;
begin
  Result := fFontColor;
end;

function TLogItem.Get_Indent: Integer;
begin
  Result := fIndent;
end;

function TLogItem.Get_LogLevel: TLogLevel;
begin
  Result := fLevel;
end;

function TLogItem.Get_LogText: string;
begin
  Result := fLogText;
end;

function TLogItem.Get_Timestamp: TDateTime;
begin
  Result := fTimestamp;
end;

function TLogItem.Get_UnixTimestamp: double;
begin
  Result :=  DateTimeToUnix( fTimeStamp, false ) + MillisecondOf( fTimestamp )/1000;
end;

function TLogItem.LevelText: string;
begin
  Result := LOG_LEVEL_NAMES[fLevel];
end;

function TLogItem.PlainText: string;
begin
  Result := FormatDateTime( 'hh:mm:ss.zzz', fTimestamp ) + #9 + LOG_LEVEL_NAMES[fLevel] + #9 + DupeString( #9, fIndent ) + fLogText;
end;

end.

unit Emetra.Logging.Target.SmartInspect;

interface

uses
  SmartInspect,
  Vcl.Graphics,
  Emetra.Logging.Interfaces,
  Emetra.Logging.LogItem.Interfaces,
  Emetra.Logging.Target.Interfaces;

type
  TSmartInspectTarget = class( TInterfacedObject, ILogItemTarget )
  private
    procedure LogToSi( ALevel: TSiLevel; AColor: TColor; const AText: string );
    procedure Send( const ALogItem: IBasicLogItem );
    function URI: string;
  public
    procedure AfterConstruction; override;
  end;

implementation

uses
  SiAuto,
  System.SysUtils,
  Emetra.WIn.User,
  Emetra.Logging.Colors;

{ TSmartInspectTarget }

procedure TSmartInspectTarget.AfterConstruction;
var
  smartInspectConfigFile: string;
begin
  inherited;
  Si.SetVariable( 'User', GetWindowsUsername );
  Si.SetVariable( 'Root', ExtractFilePath( ParamStr( 0 ) ) );
  smartInspectConfigFile := ExtractFilePath( ParamStr( 0 ) ) + 'Settings\' + ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '.sic' );
  if FileExists( smartInspectConfigFile ) then
    Si.LoadConfiguration( smartInspectConfigFile )
  else
  begin
    Si.Connections := 'tcp()';
    Si.Enabled := true;
  end;
end;

procedure TSmartInspectTarget.LogToSi( ALevel: TSiLevel; AColor: TColor; const AText: string );
begin
  if Assigned( SiMain ) then
    SiAuto.SiMain.LogColored( ALevel, AColor, AText );
end;

procedure TSmartInspectTarget.Send( const ALogItem: IBasicLogItem );
begin
  case ALogItem.LogLevel of
    ltDebug: LogToSi( lvDebug, mcTransparent, ALogItem.PlainText );
    ltInfo: LogToSi( lvVerbose, mcTransparent, ALogItem.PlainText );
    ltMessage: LogToSi( lvMessage, mcInfoMessage, ALogItem.PlainText );
    ltWarning: LogToSi( lvWarning, mcWarningMessage, ALogItem.PlainText );
    ltError: LogToSi( lvError, mcErrorMessage, ALogItem.PlainText );
    ltCritical: LogToSi( lvFatal, mcCriticalMessage, ALogItem.PlainText );
  end;
end;

function TSmartInspectTarget.URI: string;
begin
  Result := 'SmartInspect';
end;

end.

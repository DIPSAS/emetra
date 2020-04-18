unit Emetra.Logging.Target.GrayLog;

interface

uses
  {Logging}
  Emetra.Logging.LogItem.Interfaces,
  Emetra.Logging.Target.Interfaces,
  Emetra.Logging.Target.GrayLog.Interfaces,
  {Standard}
  IdUdpClient,
  System.Classes,
  System.Generics.Collections,
  System.RegularExpressions;

type
  TGrayLogDispatcher = class( TInterfacedObject, ILogItemTarget, IGrayLogDispatcher )
  strict private
    fUseCustomExtractors: boolean;
    fErrCount: integer;
    fGrayLogUdpClients: TObjectList<TIdUDPClient>;
    fHandlebarsMatcher: TRegEx;
    fKeyValueMatcher: TRegEx;
    fDbObjectNameMatcher: TRegEx;
    fDbSelectMatcher: TRegEx;
    fDbExecMatcher: TRegEx;
    fHost: string;
    fDomainName: string;
    fProcessName: string;
  private
    function URI: string;
  private
    { IGrayLogDispatcher }
    function Get_Port: integer;
    function Get_Server: string;
    function Get_ServerCount: integer;
    procedure AddLogServer( const AGrayLogServer: string; const AGrayLogUdpPort: integer );
    { ILogItemTarget }
    procedure Send( const ALogItem: IBasicLogItem );
  public
    { Initialization }
    constructor Create( const AGrayLogHost: string; const APort: integer; const AUseCustomExtractors: boolean = false ); overload;
    destructor Destroy; override;
  end;

const
  DEFAULT_GRAYLOG_PORT   = 12201;

  { IniFile settings }
  SECTION_GRAYLOG = 'Logging';
  KEY_LOG_SERVER  = 'GrayLogServer';

const
  RGX_DB_OBJECT        = '(?<=\s)[a-z][a-z0-9]+(\.[a-z][a-z0-9]+)?';
  RGX_STORED_PROCEDURE = 'EXEC\s*' + RGX_DB_OBJECT;
  RGX_SELECT_STATEMENT = 'SELECT\s+.*FROM\s*' + RGX_DB_OBJECT;
  RGX_NUMBER           = '\d+([\.,]\d+)?';
  RGX_ANONYMIZE_THIS   = '\{\{.*\}\}';
  RGX_MILLISECONDS     = RGX_NUMBER + '\s?ms([^\w]|$)';
  RGX_KEY              = '\p{L}+[\w\.]*'; { Starts with letter, may contain periods }
  RGX_VALUE            = '("[^"]*"|[^\p{Z}\p{C},;]*)'; { Either quoted, capturing all non-quote characters, or all visible characters, except commas and semicolons }
  RGX_KEY_VALUE_PAIR   = '(' + RGX_KEY + ')\s*=\s*(' + RGX_VALUE + ')';

implementation

uses
{$IFDEF Android}
  Androidapi.JNI.Os, // TJBuild
  Androidapi.JNI.Javatypes,
  Androidapi.Helpers, // StringToJString
{$ENDIF}
{$IFDEF MSWINDOWS}
  Emetra.Win.User,
{$ENDIF}
  System.IOUtils, System.JSON,
  {Standard}
  System.DateUtils, System.StrUtils, System.SysUtils;

resourcestring
  rsAnonymized = '<anonymisert>';

{$REGION 'Initialization'}

constructor TGrayLogDispatcher.Create( const AGrayLogHost: string; const APort: integer; const AUseCustomExtractors: boolean = false );
begin
  inherited Create;
  fHost := 'COMPUTER';
  fDomainName := 'DOMAIN';
  fProcessName := ExtractFileName( ParamStr( 0 ) );
{$IFDEF MSWINDOWS}
  fHost := GetWindowsComputerName;
  fDomainName := GetWindowsDomainName;
{$ENDIF}
{$IFDEF ANDROID}
  fDomainName := 'ANDROID';
  fHost := JStringToString( TJBuild.JavaClass.Host );
{$ENDIF}
  { Create RegEx for matching log item content }
  fDbObjectNameMatcher.Create( RGX_DB_OBJECT, [roIgnoreCase] );
  fDbExecMatcher.Create( RGX_STORED_PROCEDURE, [roIgnoreCase] );
  fDbSelectMatcher.Create( RGX_SELECT_STATEMENT, [roIgnoreCase] );
  fKeyValueMatcher.Create( RGX_KEY_VALUE_PAIR );
  fHandlebarsMatcher.Create( RGX_ANONYMIZE_THIS );
  { Create a list of udp clients, one per server }
  fGrayLogUdpClients := TObjectList<TIdUDPClient>.Create( True );
  fUseCustomExtractors := AUseCustomExtractors;
  AddLogServer( AGrayLogHost, APort );
end;

destructor TGrayLogDispatcher.Destroy;
begin
  fGrayLogUdpClients.Free;
  inherited;
end;

{$ENDREGION}
{$REGION 'ILogTarget'}

function TGrayLogDispatcher.URI: string;
var
  udp: TIdUDPClient;
begin
  Result := EmptyStr;
  for udp in fGrayLogUdpClients do
    Result := Result + Format( ',%s:%d', [udp.Host, udp.Port] );
  Result := Copy( Result, 2, maxint );
end;

procedure TGrayLogDispatcher.Send( const ALogItem: IBasicLogItem );
var
  udp: TIdUDPClient;
  currMatch: TMatch;
  anonymousMessage: string;
  jsonDatagram: TJSONObject;
begin
  if fGrayLogUdpClients.Count > 0 then
  begin
    anonymousMessage := fHandlebarsMatcher.Replace( ALogItem.LogText, rsAnonymized );
    jsonDatagram := TJSONObject.Create;
    try
      jsonDatagram.AddPair( 'version', '1.1' );
      jsonDatagram.AddPair( 'level', IntToStr( integer( ALogItem.LogLevel ) ) );
      jsonDatagram.AddPair( 'timestamp', TJsonNumber.Create( ALogItem.UnixTimestamp ) );
      jsonDatagram.AddPair( 'host', fHost );

      { Add a shortened version of the message due to UDP max packet size of 8192 }
      jsonDatagram.AddPair( 'short_message', Copy( anonymousMessage, 1, 255 ) );

      { Add custom field for executable name }
      jsonDatagram.AddPair( '_process', fProcessName );

      { Extract custom data as needed }

      if fUseCustomExtractors then
      begin
        for currMatch in fKeyValueMatcher.Matches( anonymousMessage ) do
          jsonDatagram.AddPair( '_' + currMatch.Groups[1].Value, currMatch.Groups[2].Value );

        currMatch := fDbExecMatcher.Match( anonymousMessage );
        if currMatch.Success then
        begin
          currMatch := fDbObjectNameMatcher.Match( currMatch.Value );
          if currMatch.Success then
            jsonDatagram.AddPair( '_proc', currMatch.Value );
        end;

        currMatch := fDbSelectMatcher.Match( anonymousMessage );
        if currMatch.Success then
        begin
          currMatch := fDbObjectNameMatcher.Match( currMatch.Value );
          if currMatch.Success then
            jsonDatagram.AddPair( '_tbl', currMatch.Value );
        end;
      end;

      { Send to all registered servers }

      for udp in fGrayLogUdpClients do
        udp.Send( jsonDatagram.ToJSON );

    except
      on Exception do
        inc( fErrCount );
    end;
    jsonDatagram.Free;
  end;
end;

{$ENDREGION}
{$REGION 'IGrayLogDispatcher'}

procedure TGrayLogDispatcher.AddLogServer( const AGrayLogServer: string; const AGrayLogUdpPort: integer );
var
  udp: TIdUDPClient;
begin
  udp := TIdUDPClient.Create( nil );
  udp.Host := AGrayLogServer;
  udp.Port := AGrayLogUdpPort;
  fGrayLogUdpClients.Add( udp );
end;

function TGrayLogDispatcher.Get_Server: string;
begin
  if fGrayLogUdpClients.Count > 0 then
    Result := fGrayLogUdpClients[0].Host
  else
    Result := EmptyStr;
end;

function TGrayLogDispatcher.Get_ServerCount: integer;
begin
  Result := fGrayLogUdpClients.Count;
end;

function TGrayLogDispatcher.Get_Port: integer;
begin
  if fGrayLogUdpClients.Count > 0 then
    Result := fGrayLogUdpClients[0].Port
  else
    Result := 0;
end;
{$ENDREGION}

end.

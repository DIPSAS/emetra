unit Emetra.Logging.Target.GrayLog.Interfaces;

interface

uses
  Emetra.Logging.Target.Interfaces,
  Emetra.Logging.LogItem.Interfaces;

type
  IGrayLogDispatcher = interface( ILogItemTarget )
    ['{46338DCD-636D-4FF0-B5B2-7E37EAE7D53C}']
    function Get_Port: integer;
    function Get_Server: string;
    function Get_ServerCount: integer;
    { Add more than one target }
    procedure AddLogServer( const AGrayLogHost: string; const APort: integer );
    { Properties }
    property Server: string read Get_Server;
    property Port: integer read Get_Port;
    property ServerCount: integer read Get_ServerCount;
  end;

implementation

end.

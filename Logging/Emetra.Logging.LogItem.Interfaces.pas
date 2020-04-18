unit Emetra.Logging.LogItem.Interfaces;

interface

uses
  System.UITypes,
  Emetra.Logging.Interfaces;

type
  IBasicLogItem = interface
    ['{C1DD9E17-C32E-4ED8-B675-AB6CEA64756A}']
    { Property accessors }
    function Get_Indent: integer;
    function Get_LogLevel: TLogLevel;
    function Get_LogText: string;
    function Get_Timestamp: TDateTime;
    function Get_UnixTimestamp: double;
    { Other members }
    function LevelText: string;
    function PlainText: string;
    { Properties }
    property Indent: integer read Get_Indent;
    property LogLevel: TLogLevel read Get_LogLevel;
    property LogText: string read Get_LogText;
    property Timestamp: TDateTime read Get_Timestamp;
    property UnixTimestamp: double read Get_UnixTimestamp;
  end;

  IColoredLogItem = interface( IBasicLogItem )
    ['{A5EFDAB0-572D-4C7C-BEE0-93A4F093E88C}']
    { Property accessors }
    function Get_BrushColor: TColor;
    function Get_FontColor: TColor;
    { Properties }
    property BrushColor: TColor read Get_BrushColor;
    property FontColor: TColor read Get_FontColor;
  end;

  ILogItemList = interface
    ['{45A09ED6-DF43-4A47-82A2-1D874E954798}']
    { Property accessors }
    function Get_Count: integer;
    function Get_Text: string;
    { Other members }
    function TryGetItem( const AIndex: integer; out AItem: IBasicLogItem ): boolean;
    procedure SaveToFile( const AFileName: string );
    procedure Clear;
    { Properies }
    property Count: integer read Get_Count;
    property Text: string read Get_Text;
  end;

implementation

end.

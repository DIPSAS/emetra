unit Emetra.Logging.Target.Interfaces;

interface

uses
  Emetra.Logging.LogItem.Interfaces;

type
  ILogItemTarget = interface
    ['{05454F30-A14C-4A7D-B32E-B7BDBAEC7ADA}']
    procedure Send( const ALogItem: IBasicLogItem );
    function URI: string;
  end;

  ILogMultiTarget = interface
    ['{2DBF8ACB-756F-418B-A11E-C6C150A211A2}']
    function TargetCount: integer;
    procedure ClearAllTargets;
    procedure AddTarget( const ATarget: ILogItemTarget );
  end;

implementation

end.

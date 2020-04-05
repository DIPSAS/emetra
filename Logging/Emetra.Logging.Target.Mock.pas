unit Emetra.Logging.Target.Mock;

interface

uses
  Emetra.Logging.LogItem.Interfaces,
  Emetra.Logging.Target.Interfaces;

type
  TMockTarget = class( TInterfacedObject, ILogItemTarget )
  private
    procedure Send( ALogItem: IBasicLogItem );
    function URI: string;
  end;

implementation

{ TDummyTarget }

procedure TMockTarget.Send( ALogItem: IBasicLogItem );
begin
  { Do nothing }
end;

function TMockTarget.URI: string;
begin
  Result := 'NULL';
end;

end.

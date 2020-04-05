unit Emetra.Logging.PlainText.ItemList;

interface

uses
  Emetra.Logging.LogItem.Interfaces,
  Emetra.Logging.Target.Interfaces,
  Emetra.Logging.PlainText.LogItem,
  { General }
  System.Generics.Collections,
  System.SysUtils, System.SyncObjs, System.Classes;

type
  TLogItemList = class( TObjectList<TLogItem> )
  strict private
    fLogItemTargetList: TList<ILogItemTarget>;
    fCriticalSection: TCriticalSection;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure Add( AItem: TLogItem ); reintroduce;
    procedure Clear; reintroduce;
    { Target handling }
    function TargetCount: integer;
    procedure AddTarget( ATarget: ILogItemTarget );
    procedure ClearAllTargets;
  end;

implementation

uses
  Emetra.Logging.Utilities;

{ TLogItemList }

constructor TLogItemList.Create;
begin
  inherited Create( true );
  fLogItemTargetList := TList<ILogItemTarget>.Create;
  fCriticalSection := TCriticalSection.Create;
end;

destructor TLogItemList.Destroy;
begin
  ClearAllTargets;
  FreeAndNil( fCriticalSection );
  fLogItemTargetList.Free;
  inherited;
end;

procedure TLogItemList.Add( AItem: TLogItem );
var
  target: ILogItemTarget;
begin
  fCriticalSection.Enter;
  try
    AItem.Text := AnonymizeLogMessage( AItem.Text );
    inherited Add( AItem );
    if fLogItemTargetList.Count > 0 then
      for target in fLogItemTargetList do
        target.Send( AItem );
  finally
    fCriticalSection.Leave;
  end;
end;

procedure TLogItemList.AddTarget( ATarget: ILogItemTarget );
begin
  fLogItemTargetList.Add( ATarget );
end;

procedure TLogItemList.Clear;
begin
  fCriticalSection.Enter;
  try
    inherited Clear;
  finally
    fCriticalSection.Leave;
  end;
end;

procedure TLogItemList.ClearAllTargets;
begin
  fLogItemTargetList.Clear;
end;

function TLogItemList.TargetCount: integer;
begin
  Result := fLogItemTargetList.Count;
end;

end.


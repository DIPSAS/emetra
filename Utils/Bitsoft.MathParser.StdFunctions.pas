unit Bitsoft.MathParser.StdFunctions;

interface

uses
  Classes, SysUtils;

type
  TFunctionCall = function( const Value: extended ): extended of object;

  TCallMethod = function( Sender: TObject; AClassType: TClass; const AMethodName: String; var AParams: Variant): Variant of object;
  IScriptObject = interface ['{17B28DB7-F2E7-4EA0-9906-345BF712A137}']
    function Alias: string;
    function CallMethod(Sender: TObject; AClassType: TClass; const AMethodName: String; var AParams: Variant): Variant;
  end;

  TFunctionInfo = class( TObject )
  private
    FOnCall: TFunctionCall;
    FName: string;
  public
    constructor Create( const AName: string; AOnCall: TFunctionCall );
    property Name: string read FName;
    property OnCall: TFunctionCall read FOnCall;
  end;

  TStdFunctions = class( TInterfacedPersistent, IScriptObject )
  private
    procedure ClearFunctions;
  protected
    FFunctionNames: TStringList;
    function Alias: string;
    function Evaluate( const AFuncName: string; const AValue: Extended ): extended;
    function IsPos( const AValue: Extended ): Extended;
    function IsNeg( const AValue: Extended ): Extended;
    function IsNotPos( const AValue: Extended ): Extended;
    function IsNotNeg( const AValue: Extended ): Extended;
    function IsZero( const AValue: Extended ): Extended;
    function Signum( const AValue: Extended ): Extended;
    function YearOf( const AValue: Extended ): Extended;
    function MonthOf( const AValue: Extended ): Extended;
    function DayOf( const AValue: Extended ): Extended;
    function WeekOf( const AValue: Extended ): Extended;
  public
    constructor Create; dynamic;
    destructor Destroy; override;
    function CallMethod(Instance: TObject; AClassType: TClass; const AMethodName: String; var AParams: Variant): Variant;
    procedure RegisterFunction( const AFunctionName: string; AOnCall: TFunctionCall );
  end;

implementation

uses
  System.DateUtils;

{ TSavedCall }

constructor TFunctionInfo.Create(const AName: string; AOnCall: TFunctionCall);
begin
  FName := AName;
  FOnCall := AOnCall;
end;

{TStdFunctions}

constructor TStdFunctions.Create;
begin
  inherited;
  FFunctionNames := TStringList.Create;
  with FFunctionNames do
  begin
    Sorted := true;
    Duplicates := dupError;
    CaseSensitive := false;
  end;
  RegisterFunction( 'ISPOS', IsPos );
  RegisterFunction( 'IS_POS', IsPos );
  RegisterFunction( 'POS', IsPos );
  RegisterFunction( 'HASDATA', IsPos );
  RegisterFunction( 'HAS_DATA', IsPos );
  RegisterFunction( 'ISNEG', IsNeg );
  RegisterFunction( 'IS_NEG', IsNeg );
  RegisterFunction( 'NEG', IsNeg );
  RegisterFunction( 'ISNULL', IsZero );
  RegisterFunction( 'IS_NULL', IsZero );
  RegisterFunction( 'IS0', IsZero );
  RegisterFunction( 'ISZERO', IsZero );
  RegisterFunction( 'IS_ZERO', IsZero );
  RegisterFunction( 'NONNEG', IsNotNeg );
  RegisterFunction( 'NONPOS', IsNotPos );
  RegisterFunction( 'SIGN', Signum );
  RegisterFunction( 'YearOf', YearOf );
  RegisterFunction( 'MonthOf', MonthOf );
  RegisterFunction( 'DayOf', DayOf );
  RegisterFunction( 'WeekOf', WeekOf );
end;

destructor TStdFunctions.Destroy;
begin
  ClearFunctions;
  FFunctionNames.Free;
  inherited;
end;

function TStdFunctions.Alias: string;
begin
  Result := 'Std';
end;

function TStdFunctions.CallMethod(Instance: TObject; AClassType: TClass; const AMethodName: String; var AParams: Variant): Variant;
var
  floatVal: double;
begin
  if SameText( AMethodName, 'IsNull' ) then
  begin
    floatVal := AParams[0];
    Result := IsZero( floatVal );
  end
  else if SameText( AMethodName, 'IsPos' ) then
  begin
    floatVal := AParams[0];
    Result := IsPos( floatVal );
  end
  else if SameText( AMethodName, 'IsNeg' ) then
  begin
    floatVal := AParams[0];
    Result := IsNeg( floatVal );
  end
  else
    raise Exception.CreateFmt( 'Unknown method: %s', [AMethodName] );
end;

function TStdFunctions.Evaluate(const AFuncName: string; const AValue: Extended): extended;
var
  foundAt: integer;
  savedCall: TFunctionInfo;
begin
  if FFunctionNames.Find( AFuncName, foundAt ) then
  begin
    savedCall := TFunctionInfo( FFunctionNames.Objects[foundAt] );
    if Assigned( savedCall ) and Assigned( savedCall.OnCall ) then
      Result := savedCall.OnCall( AValue )
    else
      raise Exception.CreateFmt( 'OnCall unassigned: %s', [AFuncName] );
  end
  else
    raise Exception.CreateFmt( 'Unknown function: %s', [AFuncName] );
end;

function TStdFunctions.IsPos( const AValue: Extended ): Extended;
begin
  if AValue > 0 then Result := 1
  else Result := 0;
end;

function TStdFunctions.IsNeg( const AValue: Extended ): Extended;
begin
  if AValue < 0 then Result := 1
  else Result := 0;
end;

function TStdFunctions.IsNotPos( const AValue: Extended ): Extended;
begin
  Result := 1 - IsPos( AValue );
end;

function TStdFunctions.IsNotNeg( const AValue: Extended ): Extended;
begin
  Result := 1 - IsNeg( AValue );
end;

function TStdFunctions.IsZero( const AValue: Extended ): Extended;
begin
  if AValue = 0 then Result := 1
  else Result := 0;
end;

function TStdFunctions.Signum(const AValue: Extended): Extended;
begin
  if AValue < 0 then Result := -1
  else if AValue > 0 then Result := 1
  else Result := 0;
end;

procedure TStdFunctions.RegisterFunction(const AFunctionName: string; AOnCall: TFunctionCall );
begin
  FFunctionNames.AddObject( AFunctionName, TFunctionInfo.Create( AFunctionName, AOnCall ) );
end;

procedure TStdFunctions.ClearFunctions;
var
  thisObject: TObject;
begin
  while FFunctionNames.Count > 0 do
  begin
    thisObject := FFunctionNames.Objects[0];
    thisObject.Free;
    FFunctionNames.Delete(0);
  end;
end;

function TStdFunctions.DayOf(const AValue: Extended): Extended;
begin
  Result := System.DateUtils.DayOf( AValue );
end;

function TStdFunctions.MonthOf(const AValue: Extended): Extended;
begin
  Result := System.DateUtils.MonthOf( AValue );
end;

function TStdFunctions.WeekOf(const AValue: Extended): Extended;
begin
  Result := System.DateUtils.WeekOf( AValue );
end;

function TStdFunctions.YearOf(const AValue: Extended): Extended;
begin
  Result := System.DateUtils.YearOf( AValue );
end;


end.

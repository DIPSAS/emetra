/// <summary>
/// This unit is refactored from the Bitsoft Math parser. It keeps registered
/// standard functions together in a specialized unit.
/// </summary>
unit Bitsoft.MathParser.StdFunctions;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

type

  TFunctionMethodCall = function( const Value: extended ): extended of object;

  TStdFunctions = class( TObject )
  strict private
    fFunctionMethods: TObjectDictionary<string, TFunctionMethodCall>;
  private
    procedure ClearFunctions;
  protected
    function Evaluate( const AFuncName: string; const AValue: extended ): extended;
    function FunctionExists( const AFuncName: string ): boolean;
    { Math }
    function Sqrt( const AValue: extended ): extended;
    { Trigonometric functions }
    function Sin( const AValue: extended ): extended;
    function Cos( const AValue: extended ): extended;
    function Atan( const AValue: extended ): extended;
    function Tan( const AValue: extended ): extended;
    { Logical funtions, returing 0 or 1 }
    function IsNeg( const AValue: extended ): extended;
    function IsNotNeg( const AValue: extended ): extended;
    function IsNotPos( const AValue: extended ): extended;
    function IsPos( const AValue: extended ): extended;
    function IsZero( const AValue: extended ): extended;
    { Signum function, returning -1, 0 or 1 }
    function Signum( const AValue: extended ): extended;
    { Date functions that map directly to System.DateUtils equivalents }
    function DayOf( const AValue: extended ): extended;
    function MonthOf( const AValue: extended ): extended;
    function WeekOf( const AValue: extended ): extended;
    function YearOf( const AValue: extended ): extended;
  public
    { Initialization }
    constructor Create; reintroduce;
    destructor Destroy; override;
    { Other methods }
    procedure RegisterFunction( const AFunctionName: string; AOnCall: TFunctionMethodCall );
  end;

implementation

uses
  System.DateUtils;

{ TStdFunctions }

constructor TStdFunctions.Create;
begin
  inherited;
  fFunctionMethods := TObjectDictionary<string, TFunctionMethodCall>.Create;
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
  RegisterFunction( 'Cos', Cos );
  RegisterFunction( 'Sin', Sin );
  RegisterFunction( 'Tan', Tan );
  RegisterFunction( 'ATan', Atan );
  RegisterFunction( 'ArcTan', Atan );
  RegisterFunction( 'SQR', Sqrt );
  RegisterFunction( 'SQRT', Sqrt );
end;

destructor TStdFunctions.Destroy;
begin
  ClearFunctions;
  fFunctionMethods.Free;
  inherited;
end;

procedure TStdFunctions.ClearFunctions;
begin
  fFunctionMethods.Clear;
end;

function TStdFunctions.Evaluate( const AFuncName: string; const AValue: extended ): extended;
var
  functionToCall: TFunctionMethodCall;
begin
  if fFunctionMethods.TryGetValue( AnsiUppercase( AFuncName ), functionToCall ) then
    Result := functionToCall( AValue )
  else
    raise Exception.CreateFmt( 'Unknown function: %s', [AFuncName] );
end;

function TStdFunctions.FunctionExists( const AFuncName: string ): boolean;
begin
  Result := fFunctionMethods.ContainsKey( AnsiUppercase( AFuncName ) );
end;

procedure TStdFunctions.RegisterFunction( const AFunctionName: string; AOnCall: TFunctionMethodCall );
begin
  fFunctionMethods.Add( AnsiUppercase( AFunctionName ), AOnCall );
end;

function TStdFunctions.Signum( const AValue: extended ): extended;
begin
  if AValue < 0 then
    Result := -1
  else if AValue > 0 then
    Result := 1
  else
    Result := 0;
end;

{$REGION 'Trigonometric functions'}

function TStdFunctions.Cos( const AValue: extended ): extended;
begin
  Result := System.Cos( AValue );
end;

function TStdFunctions.Sin( const AValue: extended ): extended;
begin
  Result := System.Sin( AValue );
end;

function TStdFunctions.Sqrt( const AValue: extended ): extended;
begin
  Result := System.Sqrt( AValue );
end;

function TStdFunctions.Tan( const AValue: extended ): extended;
begin
  Result := System.Tangent( AValue );
end;

function TStdFunctions.Atan( const AValue: extended ): extended;
begin
  Result := System.ArcTan( AValue );
end;

{$ENDREGION}
{$REGION 'Logical functions'}

function TStdFunctions.IsNeg( const AValue: extended ): extended;
begin
  if AValue < 0 then
    Result := 1
  else
    Result := 0;
end;

function TStdFunctions.IsNotNeg( const AValue: extended ): extended;
begin
  Result := 1 - IsNeg( AValue );
end;

function TStdFunctions.IsNotPos( const AValue: extended ): extended;
begin
  Result := 1 - IsPos( AValue );
end;

function TStdFunctions.IsPos( const AValue: extended ): extended;
begin
  if AValue > 0 then
    Result := 1
  else
    Result := 0;
end;

function TStdFunctions.IsZero( const AValue: extended ): extended;
begin
  if AValue = 0 then
    Result := 1
  else
    Result := 0;
end;

{$ENDREGION}
{$REGION 'Date functions'}

function TStdFunctions.DayOf( const AValue: extended ): extended;
begin
  Result := System.DateUtils.DayOf( AValue );
end;

function TStdFunctions.MonthOf( const AValue: extended ): extended;
begin
  Result := System.DateUtils.MonthOf( AValue );
end;

function TStdFunctions.WeekOf( const AValue: extended ): extended;
begin
  Result := System.DateUtils.WeekOf( AValue );
end;

function TStdFunctions.YearOf( const AValue: extended ): extended;
begin
  Result := System.DateUtils.YearOf( AValue );
end;

{$ENDREGION}

end.

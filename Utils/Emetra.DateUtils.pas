unit Emetra.DateUtils;

interface

uses
  System.DateUtils;

function TryISO8601ToDate( const AISODate: string; out Value: TDateTime; AReturnUTC: Boolean = True ): Boolean;
function YearsOld( const ANow, ADateOfBirth: TDateTime ): integer;
function BirthdayToday( const ADateOfBirth: TDateTime ): Boolean;

implementation

uses
  System.SysUtils;

function IsNeg( const AExpression: double ): integer;
begin
  if AExpression < 0 then
    Result := 1
  else
    Result := 0;
end;

function YearsOld( const ANow, ADateOfBirth: TDateTime ): integer;
begin
  Result := YearOf( ANow ) - YearOf( ADateOfBirth ) - IsNeg( ( MonthOf( ANow ) - MonthOf( ADateOfBirth ) ) * 50 + DayOf( ANow ) - DayOf( ADateOfBirth ) );
end;

function BirthdayToday( const ADateOfBirth: TDateTime ): Boolean;
begin
  Result := ( MonthOf( Now ) = MonthOf( ADateOfBirth ) ) and ( DayOf( Now ) = DayOf( ADateOfBirth ) );
end;

function TryISO8601ToDate( const AISODate: string; out Value: TDateTime; AReturnUTC: Boolean = True ): Boolean;
begin
  Result := False;
  if AISODate <> '' then
    try
      Value := ISO8601ToDate( AISODate, AReturnUTC );
      Result := True
    except
      on Exception do
        { Swallow this exception for very good reasons }
    end;
end;

end.

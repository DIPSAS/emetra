unit TestCaseFunctionYearsOld;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TTestBirthday = class( TObject )
  private
    fMonth: integer;
    fDay: integer;
  public
    procedure AfterConstruction; override;
    [Test]
    [TestCase( '1896', '1896' )]
    [TestCase( '1897', '1897' )]
    [TestCase( '1898', '1898' )]
    [TestCase( '1899', '1899' )]
    [TestCase( '1900', '1900' )]
    [TestCase( '1999', '1999' )]
    [TestCase( '2000', '2000' )]
    [TestCase( '2001', '2001' )]
    [TestCase( '2002', '2002' )]
    [TestCase( '2003', '2003' )]
    procedure TestBirthdayToday( const AYear: integer );
    [Test]
    [TestCase( '1896', '1896' )]
    [TestCase( '1897', '1897' )]
    [TestCase( '1898', '1898' )]
    [TestCase( '1899', '1899' )]
    [TestCase( '1900', '1900' )]
    [TestCase( '1999', '1999' )]
    [TestCase( '2000', '2000' )]
    [TestCase( '2001', '2001' )]
    [TestCase( '2002', '2002' )]
    [TestCase( '2003', '2003' )]
    procedure TestBirthdayYesterday( const AYear: integer );
    [Test]
    [TestCase( '1896', '1896' )]
    [TestCase( '1897', '1897' )]
    [TestCase( '1898', '1898' )]
    [TestCase( '1899', '1899' )]
    [TestCase( '1900', '1900' )]
    [TestCase( '1999', '1999' )]
    [TestCase( '2000', '2000' )]
    [TestCase( '2001', '2001' )]
    [TestCase( '2002', '2002' )]
    [TestCase( '2003', '2003' )]
    procedure TestYearSpanTomorrow( const AYear: integer );
    [Test]
    [TestCase( '1896', '1896' )]
    [TestCase( '1897', '1897' )]
    [TestCase( '1898', '1898' )]
    [TestCase( '1899', '1899' )]
    [TestCase( '1900', '1900' )]
    [TestCase( '1999', '1999' )]
    [TestCase( '2000', '2000' )]
    [TestCase( '2001', '2001' )]
    [TestCase( '2002', '2002' )]
    [TestCase( '2003', '2003' )]
    procedure TestYearSpanToday( const AYear: integer );
    [Test]
    [TestCase( '1896', '1896' )]
    [TestCase( '1897', '1897' )]
    [TestCase( '1898', '1898' )]
    [TestCase( '1899', '1899' )]
    [TestCase( '1900', '1900' )]
    [TestCase( '1999', '1999' )]
    [TestCase( '2000', '2000' )]
    [TestCase( '2001', '2001' )]
    [TestCase( '2002', '2002' )]
    [TestCase( '2003', '2003' )]
    procedure TestYearSpanYesterday( const AYear: integer );
    [Test]
    [TestCase( '1896', '1896' )]
    [TestCase( '1897', '1897' )]
    [TestCase( '1898', '1898' )]
    [TestCase( '1899', '1899' )]
    [TestCase( '1900', '1900' )]
    [TestCase( '1999', '1999' )]
    [TestCase( '2000', '2000' )]
    [TestCase( '2001', '2001' )]
    [TestCase( '2002', '2002' )]
    [TestCase( '2003', '2003' )]
    procedure TestBirthdayTomorrow( const AYear: integer );
  end;

implementation

uses
  Emetra.DateUtils,
  System.DateUtils, System.Math, System.SysUtils;

const
  YEARS_OLD = 19;

procedure TTestBirthday.AfterConstruction;
begin
  inherited;
  fMonth := MonthOf( Now );
  fDay := DayOf( Now );
end;

{$REGION 'Tests using YearsOld will always give correct result'}

procedure TTestBirthday.TestBirthdayToday( const AYear: integer );
begin
  Assert.AreEqual( YEARS_OLD, YearsOld( EncodeDate( AYear + YEARS_OLD, 10, 31 ), EncodeDate( AYear, 10, 31 ) ) );
end;

procedure TTestBirthday.TestBirthdayYesterday( const AYear: integer );
begin
  Assert.AreEqual( YEARS_OLD, YearsOld( EncodeDate( AYear + YEARS_OLD, 10, 31 ), EncodeDate( AYear, 10, 30 ) ) );
end;

procedure TTestBirthday.TestBirthdayTomorrow( const AYear: integer );
begin
  Assert.AreEqual( YEARS_OLD - 1, YearsOld( EncodeDate( AYear + YEARS_OLD, 10, 30 ), EncodeDate( AYear, 10, 31 ) ) );
end;
{$ENDREGION}
{$REGION 'Tests using YearsSpan will give varying results'}

procedure TTestBirthday.TestYearSpanToday( const AYear: integer );
var
  y: integer;
begin
  y := trunc( YearSpan( EncodeDate( AYear + YEARS_OLD, 10, 31 ), EncodeDate( AYear, 10, 31 ) ) );
  if ( AYear - 1880 ) in [16, 17, 18, 19, 20, 120] then
    Assert.AreEqual( YEARS_OLD - 1, y )
  else
    Assert.AreEqual( YEARS_OLD, y );
end;

procedure TTestBirthday.TestYearSpanYesterday( const AYear: integer );
var
  y: integer;
begin
  y := trunc( YearSpan( EncodeDate( AYear + YEARS_OLD, 10, 31 ), EncodeDate( AYear, 10, 31 ) ) );
  if ( AYear - 1880 ) in [16, 17, 18, 19, 20, 120] then
    Assert.AreEqual( YEARS_OLD - 1, y )
  else
    Assert.AreEqual( YEARS_OLD, y );
end;

procedure TTestBirthday.TestYearSpanTomorrow( const AYear: integer );
var
  y: integer;
begin
  y := trunc( YearSpan( EncodeDate( AYear + YEARS_OLD, 10, 31 ), EncodeDate( AYear, 10, 31 ) ) );
  if ( AYear - 1900 ) in [99, 101, 102, 103] then
    Assert.AreEqual( YEARS_OLD, y )
  else
    Assert.AreEqual( YEARS_OLD - 1, y );
end;

{$ENDREGION}

initialization

TDUnitX.RegisterTestFixture( TTestBirthday );

end.

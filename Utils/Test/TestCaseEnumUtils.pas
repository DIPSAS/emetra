unit TestCaseEnumUtils;

{ M+ }
interface

uses
  Emetra.EnumUtils,
  System.SysUtils,
  DUnitX.TestFramework;

type

  TEnumWithCamelCase = ( ewuFirstValue, ewuSecondValue, ewuThirdValue );
  TEnumWithStrangeNumbering = ( ewoZeroValue = 0, ewoThirdValue = 3, ewoTenthValue = 10 );

  [TestFixture]
  TTestEnumMapper = class
  public
    [Test]
    procedure TestFindPrefix;
    [Test]
    procedure TestMapDunitXEnums;
    [Test]
    procedure TestMapStrings;
    [Test]
    procedure TestMapInaccurateInput;
    [Test]
    procedure TestMapEnumWithUnderscores;
    [Test]
    procedure TestEnumWithStrangeNumbering;
    [Test]
    procedure TestFailedMappings;
  end;

implementation

{ TTestEnumMapper }

procedure TTestEnumMapper.TestFailedMappings;
begin
  try
    Assert.AreEqual( ord( TLogLevel.Error ), ord( TEnumMapper.GetValue<TLogLevel>( 'Errror' ) ) );
  except
    on E: Exception do
      Assert.AreEqual( E.ClassType, EEnumConversionError );
  end;
end;

procedure TTestEnumMapper.TestFindPrefix;
begin
  Assert.AreEqual( '', TEnumMapper.GetPrefix<TLogLevel>( TLogLevel.Information ) );
  Assert.AreEqual( 'ewu', TEnumMapper.GetPrefix<TEnumWithCamelCase>( ewuFirstValue ) );
end;

procedure TTestEnumMapper.TestEnumWithStrangeNumbering;
const
  EXC_STRANGELY_NUMBERERED_FAILED = 'Strangely numbered enum not working as expected';
begin
  Assert.AreEqual( 0, ord( ewoZeroValue ), EXC_STRANGELY_NUMBERERED_FAILED );
  Assert.AreEqual( 3, ord( ewoThirdValue ), EXC_STRANGELY_NUMBERERED_FAILED );
  Assert.AreEqual( 10, ord( ewoTenthValue ), EXC_STRANGELY_NUMBERERED_FAILED );
  try
    Assert.AreEqual( 0, ord( TEnumMapper.GetValue<TEnumWithStrangeNumbering>( 'ZERO_VALUE', 'ewo' ) ) );
  except
    on E: Exception do
      Assert.AreEqual( E.ClassType, EEnumConversionError );
  end;
end;

procedure TTestEnumMapper.TestMapDunitXEnums;
begin
  Assert.AreEqual( 'Information', TEnumMapper.GetName<TLogLevel>( TLogLevel.Information ) );
  Assert.AreEqual( 'Warning', TEnumMapper.GetName<TLogLevel>( TLogLevel.Warning ) );
  Assert.AreEqual( 'Error', TEnumMapper.GetName<TLogLevel>( TLogLevel.Error ) );
end;

procedure TTestEnumMapper.TestMapEnumWithUnderscores;
begin
  { With sample value }
  Assert.AreEqual( ord( ewuFirstValue ), ord( TEnumMapper.GetValue<TEnumWithCamelCase>( 'FIRST_VALUE', ewuFirstValue ) ) );
  Assert.AreEqual( ord( ewuSecondValue ), ord( TEnumMapper.GetValue<TEnumWithCamelCase>( 'second_value', ewuFirstValue ) ) );
  Assert.AreEqual( ord( ewuThirdValue ), ord( TEnumMapper.GetValue<TEnumWithCamelCase>( 'THIRD_value', ewuFirstValue ) ) );
  { With prefix }
  Assert.AreEqual( ord( ewuFirstValue ), ord( TEnumMapper.GetValue<TEnumWithCamelCase>( 'FIRST_VALUE', 'ewu' ) ) );
  Assert.AreEqual( ord( ewuSecondValue ), ord( TEnumMapper.GetValue<TEnumWithCamelCase>( 'second_value', 'ewu' ) ) );
  Assert.AreEqual( ord( ewuThirdValue ), ord( TEnumMapper.GetValue<TEnumWithCamelCase>( 'THIRD_value', 'ewu' ) ) );
end;

procedure TTestEnumMapper.TestMapInaccurateInput;
begin
  Assert.AreEqual( ord( TLogLevel.Information ), ord( TEnumMapper.GetValue<TLogLevel>( 'Information'#9 ) ) );
  Assert.AreEqual( ord( TLogLevel.Warning ), ord( TEnumMapper.GetValue<TLogLevel>( ' WaRning'#9#10#13 ) ) );
  Assert.AreEqual( ord( TLogLevel.Error ), ord( TEnumMapper.GetValue<TLogLevel>( ' ErrOR' ) ) );
end;

procedure TTestEnumMapper.TestMapStrings;
begin
  Assert.AreEqual( ord( TLogLevel.Information ), ord( TEnumMapper.GetValue<TLogLevel>( 'Information' ) ) );
  Assert.AreEqual( ord( TLogLevel.Warning ), ord( TEnumMapper.GetValue<TLogLevel>( 'Warning' ) ) );
  Assert.AreEqual( ord( TLogLevel.Error ), ord( TEnumMapper.GetValue<TLogLevel>( 'Error' ) ) );
end;

initialization

TDUnitX.RegisterTestFixture( TTestEnumMapper );

end.

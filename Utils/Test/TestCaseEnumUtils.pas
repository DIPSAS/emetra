unit TestCaseEnumUtils;

{ M+ }
interface

uses
  Emetra.EnumUtils,
  System.SysUtils,
  DUnitX.TestFramework;

type

  TEnumWithCamelCase = ( ewuFirstValue, ewuSecondValue, ewuThirdValue );
  {
  For some reason, Enumerated types with explcitly assigned ordinalities have no RTTI:
  http://docwiki.embarcadero.com/RADStudio/Tokyo/en/Simple_Types_(Delphi)#Enumerated_Types_with_Explicitly_Assigned_Ordinality

  }
  TEnumWithNullAndCamelCase = ( ewnacNull, ewnacStuff );
  TEnumWithStrangeNumbering = ( ewsnZeroValue = 0, ewsnThirdValue = 3, ewsnTenthValue = 10 );
{$SCOPEDENUMS ON}
  TScopedEnum = ( NullValue = 0, ThirdValue = 3, TenthValue = 10 );
{$SCOPEDENUMS OFF}

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
    procedure TestScopedEnumWithStrangeNumbering;
    [Test]
    procedure TestFailedMappings;
    [Test]
    procedure TestEnumNullable;
  end;

implementation

resourcestring
  EXT_UNREACHABLE_CODE = 'Execution should not reach this point. If it does, the Delphi bug has been fixed.';

  { TTestEnumMapper }

const
  EXC_STRANGELY_NUMBERERED_FAILED = 'Strangely numbered enum not working as expected';

procedure TTestEnumMapper.TestFailedMappings;
begin
  try
    Assert.AreEqual( ord( TLogLevel.Error ), ord( TEnumMapper.GetValue<TLogLevel>( 'Errror' ) ) ); { Yes, this Assert should fail }
  except
    on E: Exception do
      Assert.AreEqual( E.ClassType, EEnumMapperError );
  end;
end;

procedure TTestEnumMapper.TestFindPrefix;
begin
  Assert.AreEqual( '', TEnumMapper.GetPrefix<TLogLevel>( TLogLevel.Information ) );
  Assert.AreEqual( 'ewu', TEnumMapper.GetPrefix<TEnumWithCamelCase>( ewuFirstValue ) );
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

procedure TTestEnumMapper.TestEnumWithStrangeNumbering;
begin
  Assert.AreEqual( 0, ord( ewsnZeroValue ), EXC_STRANGELY_NUMBERERED_FAILED );
  Assert.AreEqual( 3, ord( ewsnThirdValue ), EXC_STRANGELY_NUMBERERED_FAILED );
  Assert.AreEqual( 10, ord( ewsnTenthValue ), EXC_STRANGELY_NUMBERERED_FAILED );
  try
    Assert.AreEqual( 0, ord( TEnumMapper.GetValue<TEnumWithStrangeNumbering>( 'ZERO_VALUE', 'ewsn' ) ) );
    Assert.IsTrue( false, EXT_UNREACHABLE_CODE );
  except
    on E: Exception do
      Assert.AreEqual( E.ClassType, EEnumMapperError );
  end;
end;

procedure TTestEnumMapper.TestScopedEnumWithStrangeNumbering;
begin
  Assert.AreEqual( 0, ord( TScopedEnum.NullValue ), EXC_STRANGELY_NUMBERERED_FAILED );
  Assert.AreEqual( 3, ord( TScopedEnum.ThirdValue ), EXC_STRANGELY_NUMBERERED_FAILED );
  Assert.AreEqual( 10, ord( TScopedEnum.TenthValue ), EXC_STRANGELY_NUMBERERED_FAILED );
  try
    Assert.AreEqual( 0, ord( TEnumMapper.GetValue<TScopedEnum>( 'NULL_VALUE' ) ) );
    Assert.IsTrue( false, EXT_UNREACHABLE_CODE );
  except
    on E: Exception do
      Assert.AreEqual( E.ClassType, EEnumMapperError );
  end;
end;

procedure TTestEnumMapper.TestEnumNullable;
begin
  Assert.AreEqual( ord( TEnumWithNullAndCamelCase.ewnacNull ), ord( TEnumMapper.GetValueNullable<TEnumWithNullAndCamelCase>( '', 'ewnac' ) ),           'Expected to get conv to null then enum' );
  Assert.AreEqual( ord( TEnumWithNullAndCamelCase.ewnacNull ), ord( TEnumMapper.GetValueNullable<TEnumWithNullAndCamelCase>( '       ', 'ewnac' ) ),    'Expected to get conv to null then enum' );
  Assert.AreEqual( ord( TEnumWithNullAndCamelCase.ewnacNull ), ord( TEnumMapper.GetValueNullable<TEnumWithNullAndCamelCase>( '   null    ', 'ewnac' ) ),'Expected to get conv to null then enum' );
  
  Assert.AreEqual( ord( TEnumWithNullAndCamelCase.ewnacStuff ), ord( TEnumMapper.GetValueNullable<TEnumWithNullAndCamelCase>( 'STUFF', 'ewnac' ) ),     'Expected to get conv to enum just like regular GetValue<T>' );
  Assert.AreEqual( ord( TEnumWithNullAndCamelCase.ewnacStuff ), ord( TEnumMapper.GetValueNullable<TEnumWithNullAndCamelCase>( 'stuff', 'ewnac' ) ),     'Expected to get conv to enum just like regular GetValue<T>' );
  try
    Assert.AreEqual( -1, TEnumMapper.GetValueNullable<TEnumWithNullAndCamelCase>( '   s TufF', 'ewnac' ), 'Expected to fail because of unexpected space in string' );
  except
    on E: Exception do
      Assert.AreEqual( E.ClassType, EEnumMapperError );
  end;

  try
    Assert.AreEqual( -1, TEnumMapper.GetValueNullable<TEnumWithNullAndCamelCase>( 'fafsdfe', 'ewnac' ), 'Skal feile');
  except
    on E: Exception do
      Assert.AreEqual( E.ClassType, EEnumMapperError );
  end;
end;

initialization

TDUnitX.RegisterTestFixture( TTestEnumMapper );

end.

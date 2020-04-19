﻿unit TestCaseMathParser;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit
  being tested.

}

interface

uses
  TestFramework,
  Bitsoft.MathParser,
  Bitsoft.MathParser.StdFunctions,
  {General classes, utilities}
  Emetra.Logging.Interfaces,
  {Standard}
  System.SysUtils, System.Math;

type
  // Test methods for class TMathParser

  TestTMathParser = class( TTestCase )
  strict private
    fMathParser: TMathParser;
  private
  public
    procedure HandleGetVar( Sender: TObject; AVarName: string; var AValue: Extended; var AFound: Boolean );
    procedure HandleParseError( Sender: TMathParser; const ATokenError: TTokenError );
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestInvalidInput;
    procedure TestIsNull;
    procedure TestIsPositive;
    procedure TestSignum;
    procedure TestUnknownVariables;
    procedure TestRounding;
    procedure TestTruncation;
    procedure TestTrigononmetry;
    procedure TestSquareRoot;
    procedure TestNegativeSquareRoot;
    procedure TestDateFunctions;
  end;

implementation

uses
  System.DateUtils;

const
  TXT_SHOULD_BE_ONE       = 'The expression shold evaluate to 1.';
  TXT_SHOULD_BE_ZERO      = 'The expression should evaluate to 0.';
  TXT_SHOULD_BE_MINUS_ONE = 'The expression should evaluate to -1.';
  TXT_SHOULD_BE_INTEGER   = 'The expression should evaluate to %d.';

const
  EPSILON = 0.0001;

{$REGION 'Initialization'}

procedure TestTMathParser.SetUp;
begin
  fMathParser := TMathParser.Create;
  fMathParser.OnGetVar := Self.HandleGetVar;
  fMathParser.OnParseError := Self.HandleParseError;
end;

procedure TestTMathParser.TearDown;
begin
  fMathParser.Free;
end;

{$ENDREGION}

procedure TestTMathParser.HandleGetVar( Sender: TObject; AVarName: string; var AValue: Extended; var AFound: Boolean );
begin
  GlobalLog.Event( LOG_STUB + 'Asked for %s', [ClassName, 'HandleGetVar', AVarName] );
  AValue := 1;
  AFound := true;
end;

procedure TestTMathParser.HandleParseError( Sender: TMathParser; const ATokenError: TTokenError );
begin
  GlobalLog.SilentWarning( LOG_STUB + 'Error = %d, Expession = "%s".', [ClassName, 'HandleParseError', ord( ATokenError ), Sender.LogText] );
end;

procedure TestTMathParser.TestInvalidInput;
begin
  try
    fMathParser.Evaluate( 'THIS IS #ONE TEST' );
    CheckEquals( true, false, 'This code should never be reached' );
  except
    on E: Exception do
    begin
      GlobalLog.SilentWarning( E.Message );
      CheckEquals( EInvalidArgument.ClassName, E.ClassName );
      CheckEquals( true, true, 'But this code should always be reached' );
    end;
  end;
end;

procedure TestTMathParser.TestIsNull;
begin
  CheckEquals( 1, fMathParser.Evaluate( 'ISNULL(0)' ), TXT_SHOULD_BE_ONE );
  CheckEquals( 0, fMathParser.Evaluate( 'ISNULL(1)' ), TXT_SHOULD_BE_ZERO );
  CheckEquals( 0, fMathParser.Evaluate( 'ISNULL(-1)' ), TXT_SHOULD_BE_ZERO );
end;

procedure TestTMathParser.TestIsPositive;
begin
  CheckEquals( 0, fMathParser.Evaluate( 'ISPOS(0)' ), TXT_SHOULD_BE_ZERO );
  CheckEquals( 1, fMathParser.Evaluate( 'ISPOS(1)' ), TXT_SHOULD_BE_ONE );
  CheckEquals( 1, fMathParser.Evaluate( 'ISPOS(0.01)' ), TXT_SHOULD_BE_ONE );
  CheckEquals( 0, fMathParser.Evaluate( 'ISPOS(-0.01)' ), TXT_SHOULD_BE_ZERO );
  CheckEquals( 0, fMathParser.Evaluate( 'ISPOS(-1)' ), TXT_SHOULD_BE_ZERO );
end;

procedure TestTMathParser.TestRounding;
begin
  CheckEquals( 3, fMathParser.Evaluate( 'ROUND(3.49)' ) );
  CheckEquals( 4, fMathParser.Evaluate( 'ROUND(3.501)' ) );
  CheckEquals( -4, fMathParser.Evaluate( 'ROUND(-3.501)' ) );
end;

procedure TestTMathParser.TestTrigononmetry;
begin
  CheckTrue( SameValue( 0, fMathParser.Evaluate( 'SIN(PI)' ), EPSILON ) );
  CheckTrue( SameValue( -1, fMathParser.Evaluate( 'COS(PI)' ), EPSILON ) );
  CheckTrue( SameValue( 1, fMathParser.Evaluate( 'SIN(PI/2)' ), EPSILON ) );
  CheckTrue( SameValue( 0, fMathParser.Evaluate( 'COS(PI/2)' ), EPSILON ) );
  CheckTrue( SameValue( 0.5, fMathParser.Evaluate( 'SIN(PI/6)' ), EPSILON ) );
  CheckTrue( SameValue( 1, fMathParser.Evaluate( 'TAN(PI/4)' ), EPSILON ) );
  CheckTrue( SameValue( -1, fMathParser.Evaluate( 'TAN(3*PI/4)' ), EPSILON ) );
end;

procedure TestTMathParser.TestTruncation;
begin
  CheckEquals( 3, fMathParser.Evaluate( 'TRUNC(3.49)' ) );
  CheckEquals( 3, fMathParser.Evaluate( 'TRUNC(3.501)' ) );
  CheckEquals( -3, fMathParser.Evaluate( 'TRUNC(-3.49)' ) );
  CheckEquals( -3, fMathParser.Evaluate( 'TRUNC(-3.501)' ) );
end;

procedure TestTMathParser.TestSignum;
begin
  CheckEquals( 1, fMathParser.Evaluate( 'SIGN(2)' ), TXT_SHOULD_BE_ONE );
  CheckEquals( -1, fMathParser.Evaluate( 'SIGN(-1)' ), TXT_SHOULD_BE_MINUS_ONE );
  CheckEquals( 0, fMathParser.Evaluate( 'SIGN(0)' ), TXT_SHOULD_BE_ZERO );
end;

procedure TestTMathParser.TestSquareRoot;
begin
  CheckEquals( 4, fMathParser.Evaluate( 'SQRT(16)' ) );
  CheckEquals( 3, fMathParser.Evaluate( 'SQRT(9)' ) );
  CheckTrue( SameValue( 2.5, fMathParser.Evaluate( 'SQRT(6.25)' ), EPSILON ) );
end;

procedure TestTMathParser.TestUnknownVariables;
const
  TEST_EXPR =
  { } '(0.5*(ISNULL(MNA_K1-1) + ' + sLineBreak +
  { } 'ISNULL(MNA_K2-1) + ' + sLineBreak +
  { } 'ISNULL(MNA_K3-1))-0.5) * (1-ISNEG(( ISNULL( MNA_K1-1 ) + ' + sLineBreak +
  { } 'ISNULL(MNA_K2-1) + ISNULL(MNA_K3-1))-0.5))';

begin
  { Unknown variables are retrieved with HandleGetVar }
  CheckEquals( 1, fMathParser.Evaluate( TEST_EXPR ), TXT_SHOULD_BE_ONE );
end;

procedure TestTMathParser.TestDateFunctions;
begin
  { Casing is odd on purpose }
  CheckEquals( YearOf( Now ), fMathParser.Evaluate( 'YEAROF(NOW)' ), Format( TXT_SHOULD_BE_INTEGER, [YearOf( Now )] ) );
  CheckEquals( MonthOf( Now ), fMathParser.Evaluate( 'MonthOf(Now)' ), Format( TXT_SHOULD_BE_INTEGER, [MonthOf( Now )] ) );
  CheckEquals( DayOf( Now ), fMathParser.Evaluate( 'dAYOf( NOW )' ), Format( TXT_SHOULD_BE_INTEGER, [DayOf( Now )] ) );
  CheckEquals( WeekOf( Now ), fMathParser.Evaluate( 'weekOF( now )' ), Format( TXT_SHOULD_BE_INTEGER, [WeekOf( Now )] ) );
end;

procedure TestTMathParser.TestNegativeSquareRoot;
begin
  try
    fMathParser.Evaluate( 'SQRT(-1)' );
    CheckFalse( true ); { Should not be reached }
  except
    on E: Exception do
      CheckEquals( E.ClassName, EInvalidOp.ClassName );
  end;
end;

initialization

// Register any test cases with the test runner
RegisterTest( TestTMathParser.Suite );

end.
